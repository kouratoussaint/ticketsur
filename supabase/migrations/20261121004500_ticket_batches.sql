-- =============================================================================
-- Tikéo — Migration 4500 : lots de génération des tickets, 1 000 par lot
-- =============================================================================
-- Chaque appel d'émission (lot rapide, nominatif ou import) crée un lot
-- numéroté dans l'événement ; chaque ticket porte son lot. Les tickets émis
-- avant cette migration sont regroupés par appel d'origine (même événement,
-- même auteur, même heure d'émission, qui est l'heure de la transaction).
--   ticket_batches (fermée à l'API), tickets.batch_id
--   event_ticket_batches(événement) : lots avec leurs compteurs
--   batch_ticket_ids(lot) : tous les tickets d'un lot (sélection, planche)
--   event_tickets(..., p_batch_id) : filtre et numéro du lot
--   issue_named_tickets : 1 à 1 000 lignes (au lieu de 500)
-- Aucun jeton, aucun nom ni téléphone dans les lots ni dans le journal.
-- =============================================================================

create table public.ticket_batches (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete restrict,
  number integer not null check (number > 0),
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles (id),
  unique (event_id, number)
);
alter table public.ticket_batches enable row level security;
revoke all on public.ticket_batches from anon, authenticated;

alter table public.tickets
  add column batch_id uuid references public.ticket_batches (id);
create index tickets_batch_idx on public.tickets (batch_id);

-- Tickets existants : un lot par (événement, auteur, heure d'émission).
insert into public.ticket_batches (event_id, number, created_at, created_by)
select g.event_id,
       row_number() over (partition by g.event_id order by g.issued_at, g.issued_by)::integer,
       g.issued_at, g.issued_by
  from (select distinct t.event_id, t.issued_by, t.issued_at from public.tickets t) g;

update public.tickets t
   set batch_id = b.id
  from public.ticket_batches b
 where t.batch_id is null
   and t.event_id = b.event_id
   and t.issued_at = b.created_at
   and t.issued_by is not distinct from b.created_by;

-- -----------------------------------------------------------------------------
-- Émission : corps de la migration 1400, plus le lot.
-- -----------------------------------------------------------------------------
create or replace function private.issue_ticket_rows(p_event_id uuid, p_rows jsonb)
returns table (
  line integer,
  ticket_id uuid,
  public_reference text,
  qr_token text,
  category_id uuid,
  holder_name text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_event public.events%rowtype;
  v_row record;
  v_holder record;
  v_quota record;
  v_event_existing integer;
  v_total integer;
  v_token text;
  v_ticket_id uuid;
  v_reference text;
  v_hmac_key text;
  v_enc_key text;
  v_batch_id uuid;
  v_batch_number integer;
begin
  if v_actor is null then
    raise exception 'Authentification requise' using errcode = '42501';
  end if;
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) < 1 then
    raise exception 'issue_rows_invalid'
      using errcode = '22023', detail = 'Aucun ticket à émettre.';
  end if;
  v_total := jsonb_array_length(p_rows);

  -- Verrou de l'événement : sérialise les émissions de TOUTES ses catégories
  -- (capacité globale exacte) et les changements de capacité.
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found
     or not private.has_org_role(v_event.organization_id, array['owner','manager']::public.member_role[]) then
    raise exception 'Événement introuvable ou droits insuffisants' using errcode = '42501';
  end if;
  if v_event.status in ('closed', 'archived', 'cancelled') then
    raise exception 'Événement fermé : émission impossible' using errcode = '22023';
  end if;
  if v_event.status = 'draft' then
    raise exception 'event_not_published'
      using errcode = '55000', detail = 'Publiez l''événement avant d''émettre des tickets.';
  end if;

  -- Lignes normalisées (le titulaire est contrôlé avant toute écriture).
  create temp table if not exists pg_temp.issue_rows (
    line integer primary key,
    category_id uuid,
    holder_name text,
    holder_phone text,
    holder_email text
  ) on commit drop;
  truncate pg_temp.issue_rows;

  for v_row in
    select r.ordinality::integer as line, r.value as item
    from jsonb_array_elements(p_rows) with ordinality r
  loop
    if jsonb_typeof(v_row.item) <> 'object' then
      raise exception 'issue_rows_invalid'
        using errcode = '22023', detail = format('Ligne %s : format invalide.', v_row.line);
    end if;
    select * into v_holder
    from private.check_holder(v_row.item->>'name', v_row.item->>'phone',
                              v_row.item->>'email', case when v_total > 1 then v_row.line end);
    insert into pg_temp.issue_rows
    values (v_row.line,
            nullif(v_row.item->>'category_id', '')::uuid,
            v_holder.name, v_holder.phone, v_holder.email);
  end loop;

  if exists (
    select 1 from pg_temp.issue_rows r
    where r.category_id is null
       or not exists (select 1 from public.ticket_categories c
                      where c.id = r.category_id and c.event_id = p_event_id)
  ) then
    raise exception 'category_not_found'
      using errcode = '22023', detail = 'Catégorie inconnue pour cet événement.';
  end if;

  -- Quotas des catégories concernées (verrouillées dans un ordre stable).
  perform 1 from public.ticket_categories c
  where c.id in (select r.category_id from pg_temp.issue_rows r)
  order by c.id
  for update;

  for v_quota in
    select c.name, c.capacity, count(r.line)::integer as wanted,
           (select count(*) from public.tickets t
            where t.category_id = c.id and t.status <> 'revoked')::integer as existing
    from pg_temp.issue_rows r
    join public.ticket_categories c on c.id = r.category_id
    group by c.id, c.name, c.capacity
  loop
    if v_quota.capacity is not null and v_quota.existing + v_quota.wanted > v_quota.capacity then
      raise exception 'category_capacity_exceeded'
        using errcode = '22023',
              detail = format('Quota de la catégorie « %s » dépassé (%s restants).',
                              v_quota.name, greatest(v_quota.capacity - v_quota.existing, 0));
    end if;
  end loop;

  if v_event.capacity is not null then
    select count(*) into v_event_existing from public.tickets t
    where t.event_id = p_event_id and t.status <> 'revoked';
    if v_event_existing + v_total > v_event.capacity then
      raise exception 'event_capacity_exceeded'
        using errcode = '22023',
              detail = format('Capacité de l''événement dépassée (%s restants).',
                              greatest(v_event.capacity - v_event_existing, 0));
    end if;
  end if;

  -- Lot de génération : un par appel, numéroté dans l'événement (l'événement
  -- est verrouillé plus haut : numérotation sans trou ni doublon).
  select coalesce(max(b.number), 0) + 1 into v_batch_number
    from public.ticket_batches b where b.event_id = p_event_id;
  insert into public.ticket_batches (event_id, number, created_by)
  values (p_event_id, v_batch_number, v_actor)
  returning id into v_batch_id;

  v_hmac_key := private.vault_secret('ticketsur_qr_hmac_key');
  v_enc_key := private.vault_secret('ticketsur_qr_encryption_key');

  for v_row in select r.* from pg_temp.issue_rows r order by r.line loop
    v_token := private.new_qr_token();
    loop
      v_reference := private.new_public_reference();
      begin
        insert into public.tickets (event_id, category_id, public_reference, issued_by,
                                    holder_name, holder_phone, holder_email, batch_id)
        values (p_event_id, v_row.category_id, v_reference, v_actor,
                v_row.holder_name, v_row.holder_phone, v_row.holder_email, v_batch_id)
        returning id into v_ticket_id;
        exit;
      exception when unique_violation then
        -- Collision de référence publique (~1e-5 pour 10 000 tickets) : on retire.
        null;
      end;
    end loop;

    insert into private.ticket_secrets (ticket_id, token_hmac, token_ciphertext)
    values (
      v_ticket_id,
      extensions.hmac(convert_to(v_token, 'UTF8'), convert_to(v_hmac_key, 'UTF8'), 'sha256'),
      extensions.pgp_sym_encrypt(v_token, v_enc_key, 'cipher-algo=aes256')
    );

    line := v_row.line;
    ticket_id := v_ticket_id;
    public_reference := v_reference;
    qr_token := v_token;
    category_id := v_row.category_id;
    holder_name := v_row.holder_name;
    return next;
  end loop;

  -- Journal : une entrée par catégorie, sans aucune donnée personnelle.
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  select v_event.organization_id, v_actor, 'tickets.issued', 'ticket_category', r.category_id,
         jsonb_build_object('event_id', p_event_id, 'quantity', count(*), 'batch', v_batch_number,
                            'named', count(*) filter (where r.holder_name is not null
                                                         or r.holder_phone is not null
                                                         or r.holder_email is not null))
  from pg_temp.issue_rows r
  group by r.category_id;
end;
$$;
revoke all on function private.issue_ticket_rows(uuid, jsonb) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Émission nominative et import : 1 000 lignes au plus.
-- -----------------------------------------------------------------------------
create or replace function public.issue_named_tickets(p_event_id uuid, p_rows jsonb)
returns table (
  line integer,
  ticket_id uuid,
  public_reference text,
  qr_token text,
  category_id uuid,
  category_name text,
  category_is_invitation boolean,
  holder_name text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  if p_rows is null or jsonb_typeof(p_rows) <> 'array'
     or jsonb_array_length(p_rows) not between 1 and 1000 then
    raise exception 'issue_rows_invalid'
      using errcode = '22023', detail = 'De 1 à 1 000 tickets par envoi.';
  end if;
  return query
    select r.line, r.ticket_id, r.public_reference, r.qr_token, r.category_id, c.name,
           c.is_invitation, r.holder_name
    from private.issue_ticket_rows(p_event_id, p_rows) r
    join public.ticket_categories c on c.id = r.category_id
    order by r.line;
end;
$$;
revoke all on function public.issue_named_tickets(uuid, jsonb) from public, anon;
grant execute on function public.issue_named_tickets(uuid, jsonb) to authenticated;

-- -----------------------------------------------------------------------------
-- Liste des tickets : filtre par lot et numéro du lot.
-- -----------------------------------------------------------------------------
drop function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean, uuid);

create function public.event_tickets(
  p_event_id uuid,
  p_status public.ticket_status default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_undelivered boolean default false,
  p_category_id uuid default null,
  p_batch_id uuid default null
)
returns table (
  id uuid,
  public_reference text,
  category_id uuid,
  category_name text,
  status public.ticket_status,
  issued_at timestamptz,
  redeemed_at timestamptz,
  redeemed_checkpoint_name text,
  revoked_at timestamptz,
  holder_name text,
  holder_phone text,
  holder_email text,
  last_delivery_channel public.delivery_channel,
  last_delivery_at timestamptz,
  category_is_invitation boolean,
  batch_number integer,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_search text := nullif(upper(trim(coalesce(p_search, ''))), '');
  -- Recherche de téléphone : au moins 4 chiffres saisis.
  v_digits text := nullif(regexp_replace(coalesce(p_search, ''), '[^0-9]', '', 'g'), '');
begin
  if not exists (
    select 1 from public.events e
    where e.id = p_event_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  ) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  return query
    select t.id, t.public_reference, t.category_id, c.name, t.status, t.issued_at,
           t.redeemed_at, cp.name, t.revoked_at,
           t.holder_name, t.holder_phone, t.holder_email,
           d.channel, d.sent_at, c.is_invitation, b.number,
           count(*) over ()
    from public.tickets t
    join public.ticket_categories c on c.id = t.category_id
    left join public.checkpoints cp on cp.id = t.redeemed_checkpoint_id
    left join public.ticket_batches b on b.id = t.batch_id
    left join lateral (
      select td.channel, td.sent_at
      from public.ticket_deliveries td
      where td.ticket_id = t.id
      order by td.sent_at desc, td.id desc
      limit 1
    ) d on true
    where t.event_id = p_event_id
      and (p_status is null or t.status = p_status)
      and (not coalesce(p_undelivered, false) or d.sent_at is null)
      and (p_category_id is null or t.category_id = p_category_id)
      and (p_batch_id is null or t.batch_id = p_batch_id)
      and (v_search is null
           or t.public_reference like '%' || v_search || '%'
           or upper(c.name) like '%' || v_search || '%'
           or upper(t.holder_name) like '%' || v_search || '%'
           or upper(t.holder_email) like '%' || v_search || '%'
           or (char_length(v_digits) >= 4 and t.holder_phone like '%' || v_digits || '%'))
    order by t.issued_at desc, t.public_reference
    limit least(greatest(coalesce(p_limit, 50), 1), 200)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;
revoke all on function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean, uuid, uuid)
  from public, anon;
grant execute on function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean, uuid, uuid)
  to authenticated;

-- -----------------------------------------------------------------------------
-- Lots d'un événement, du plus récent au plus ancien.
-- -----------------------------------------------------------------------------
create function public.event_ticket_batches(p_event_id uuid)
returns table (
  id uuid,
  number integer,
  created_at timestamptz,
  created_by_name text,
  total integer,
  issued integer,
  redeemed integer,
  revoked integer,
  named integer,
  categories text[]
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.events e
    where e.id = p_event_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  ) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  return query
    select b.id, b.number, b.created_at, p.display_name,
           count(t.id)::integer,
           count(t.id) filter (where t.status = 'issued')::integer,
           count(t.id) filter (where t.status = 'redeemed')::integer,
           count(t.id) filter (where t.status = 'revoked')::integer,
           count(t.id) filter (where t.holder_name is not null)::integer,
           coalesce(array_agg(distinct c.name order by c.name)
                      filter (where c.name is not null), '{}')
    from public.ticket_batches b
    left join public.profiles p on p.id = b.created_by
    left join public.tickets t on t.batch_id = b.id
    left join public.ticket_categories c on c.id = t.category_id
    where b.event_id = p_event_id
    group by b.id, b.number, b.created_at, p.display_name
    order by b.number desc;
end;
$$;
revoke all on function public.event_ticket_batches(uuid) from public, anon;
grant execute on function public.event_ticket_batches(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Tous les tickets d'un lot (identifiant et statut), dans l'ordre d'émission.
-- -----------------------------------------------------------------------------
create function public.batch_ticket_ids(p_batch_id uuid)
returns table (id uuid, status public.ticket_status)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.ticket_batches b
    join public.events e on e.id = b.event_id
    where b.id = p_batch_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  ) then
    raise exception 'batch_not_found'
      using errcode = '42501', detail = 'Lot introuvable ou droits insuffisants.';
  end if;
  return query
    select t.id, t.status
    from public.tickets t
    where t.batch_id = p_batch_id
    order by t.issued_at, t.public_reference;
end;
$$;
revoke all on function public.batch_ticket_ids(uuid) from public, anon;
grant execute on function public.batch_ticket_ids(uuid) to authenticated;
