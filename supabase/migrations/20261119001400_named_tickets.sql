-- =============================================================================
-- TicketSûr — Migration 1400 : tickets nominatifs (lot 2)
-- =============================================================================
-- * tickets : titulaire facultatif (nom, téléphone international, e-mail).
--   Visible des seuls propriétaires et gestionnaires (RLS inchangée) ; jamais
--   dans le QR, jamais dans le journal d'audit.
-- * private.issue_ticket_rows : cœur unique de l'émission. Une ligne = un
--   ticket (catégorie + titulaire facultatif). Tout ou rien : quotas des
--   catégories et capacité de l'événement vérifiés sous verrou de l'événement,
--   comme avant.
-- * issue_tickets : contrat inchangé (lot anonyme d'une catégorie), désormais
--   adossé au cœur.
-- * issue_named_tickets : 1 à 500 lignes, catégories mélangées possibles
--   (import d'une liste). Erreurs de titulaire avec le numéro de ligne.
-- * set_ticket_holder : renseigne ou corrige le titulaire d'un ticket valable.
-- * event_tickets, export_tickets : renvoient aussi le titulaire ; la
--   recherche porte aussi sur le nom et le téléphone.
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   22023 holder_name_invalid | holder_phone_invalid | holder_email_invalid
--         issue_rows_invalid | category_not_found
--   55000 ticket_not_editable
--   42501 ticket_not_found
--   (et celles de l'émission : event_not_published, category_capacity_exceeded,
--    event_capacity_exceeded)
-- =============================================================================

alter table public.tickets
  add column holder_name text
    check (holder_name is null or char_length(holder_name) between 1 and 120),
  add column holder_phone text
    check (holder_phone is null or holder_phone ~ '^\+[1-9][0-9]{7,14}$'),
  add column holder_email text
    check (holder_email is null
           or (char_length(holder_email) <= 254
               and holder_email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'));

-- -----------------------------------------------------------------------------
-- Titulaire : normalisation et contrôle (p_line > 0 : numéro de ligne cité)
-- -----------------------------------------------------------------------------
create or replace function private.check_holder(
  p_name text,
  p_phone text,
  p_email text,
  p_line integer,
  out name text,
  out phone text,
  out email text
)
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_where text := case when coalesce(p_line, 0) > 0 then format('Ligne %s : ', p_line) else '' end;
begin
  name := private.normalize_text(p_name);
  phone := private.normalize_phone(p_phone);
  email := lower(private.normalize_text(p_email));
  if name is not null and char_length(name) > 120 then
    raise exception 'holder_name_invalid'
      using errcode = '22023', detail = v_where || 'nom de 120 caractères au plus.';
  end if;
  if phone is not null and phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'holder_phone_invalid'
      using errcode = '22023', detail = v_where || 'numéro de téléphone invalide.';
  end if;
  if email is not null
     and (char_length(email) > 254 or email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') then
    raise exception 'holder_email_invalid'
      using errcode = '22023', detail = v_where || 'adresse e-mail invalide.';
  end if;
end;
$$;
revoke all on function private.check_holder(text, text, text, integer) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Cœur de l'émission
-- -----------------------------------------------------------------------------
-- p_rows : tableau JSON d'objets {category_id, name?, phone?, email?}.
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

  v_hmac_key := private.vault_secret('ticketsur_qr_hmac_key');
  v_enc_key := private.vault_secret('ticketsur_qr_encryption_key');

  for v_row in select r.* from pg_temp.issue_rows r order by r.line loop
    v_token := private.new_qr_token();
    loop
      v_reference := private.new_public_reference();
      begin
        insert into public.tickets (event_id, category_id, public_reference, issued_by,
                                    holder_name, holder_phone, holder_email)
        values (p_event_id, v_row.category_id, v_reference, v_actor,
                v_row.holder_name, v_row.holder_phone, v_row.holder_email)
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
         jsonb_build_object('event_id', p_event_id, 'quantity', count(*),
                            'named', count(*) filter (where r.holder_name is not null
                                                         or r.holder_phone is not null
                                                         or r.holder_email is not null))
  from pg_temp.issue_rows r
  group by r.category_id;
end;
$$;
revoke all on function private.issue_ticket_rows(uuid, jsonb) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Émission anonyme : contrat inchangé
-- -----------------------------------------------------------------------------
create or replace function public.issue_tickets(
  p_event_id uuid,
  p_category_id uuid,
  p_quantity integer
)
returns table (ticket_id uuid, public_reference text, qr_token text)
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentification requise' using errcode = '42501';
  end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 5000 then
    raise exception 'Quantité hors limites (1 à 5000 par lot)' using errcode = '22023';
  end if;
  return query
    select r.ticket_id, r.public_reference, r.qr_token
    from private.issue_ticket_rows(
      p_event_id,
      (select jsonb_agg(jsonb_build_object('category_id', p_category_id))
       from generate_series(1, p_quantity))
    ) r
    order by r.line;
end;
$$;
revoke all on function public.issue_tickets(uuid, uuid, integer) from public, anon;
grant execute on function public.issue_tickets(uuid, uuid, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- Émission nominative (import d'une liste)
-- -----------------------------------------------------------------------------
create or replace function public.issue_named_tickets(p_event_id uuid, p_rows jsonb)
returns table (
  line integer,
  ticket_id uuid,
  public_reference text,
  qr_token text,
  category_id uuid,
  category_name text,
  holder_name text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  if p_rows is null or jsonb_typeof(p_rows) <> 'array'
     or jsonb_array_length(p_rows) not between 1 and 500 then
    raise exception 'issue_rows_invalid'
      using errcode = '22023', detail = 'De 1 à 500 tickets par envoi.';
  end if;
  return query
    select r.line, r.ticket_id, r.public_reference, r.qr_token, r.category_id, c.name,
           r.holder_name
    from private.issue_ticket_rows(p_event_id, p_rows) r
    join public.ticket_categories c on c.id = r.category_id
    order by r.line;
end;
$$;
revoke all on function public.issue_named_tickets(uuid, jsonb) from public, anon;
grant execute on function public.issue_named_tickets(uuid, jsonb) to authenticated;

-- -----------------------------------------------------------------------------
-- Titulaire d'un ticket existant
-- -----------------------------------------------------------------------------
create or replace function public.set_ticket_holder(
  p_ticket_id uuid,
  p_name text default null,
  p_phone text default null,
  p_email text default null
)
returns table (holder_name text, holder_phone text, holder_email text)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets%rowtype;
  v_org uuid;
  v_holder record;
begin
  select t.* into v_ticket from public.tickets t where t.id = p_ticket_id for update;
  if not found then
    raise exception 'ticket_not_found'
      using errcode = '42501', detail = 'Ticket introuvable ou droits insuffisants.';
  end if;
  select e.organization_id into v_org from public.events e where e.id = v_ticket.event_id;
  if auth.uid() is null
     or not private.has_org_role(v_org, array['owner','manager']::public.member_role[]) then
    raise exception 'ticket_not_found'
      using errcode = '42501', detail = 'Ticket introuvable ou droits insuffisants.';
  end if;
  if v_ticket.status <> 'issued' then
    raise exception 'ticket_not_editable'
      using errcode = '55000', detail = 'Seul un ticket valable, pas encore utilisé, peut changer de titulaire.';
  end if;

  select * into v_holder from private.check_holder(p_name, p_phone, p_email, null);
  update public.tickets t
     set holder_name = v_holder.name,
         holder_phone = v_holder.phone,
         holder_email = v_holder.email
   where t.id = p_ticket_id;

  -- Journal : quels champs ont changé, jamais leur valeur.
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org, auth.uid(), 'ticket.holder_updated', 'ticket', p_ticket_id,
          jsonb_build_object(
            'name', v_holder.name is distinct from v_ticket.holder_name,
            'phone', v_holder.phone is distinct from v_ticket.holder_phone,
            'email', v_holder.email is distinct from v_ticket.holder_email));

  holder_name := v_holder.name;
  holder_phone := v_holder.phone;
  holder_email := v_holder.email;
  return next;
end;
$$;
revoke all on function public.set_ticket_holder(uuid, text, text, text) from public, anon;
grant execute on function public.set_ticket_holder(uuid, text, text, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Liste et ré-export : titulaire en plus (type de retour modifié)
-- -----------------------------------------------------------------------------
drop function public.event_tickets(uuid, public.ticket_status, text, integer, integer);

create function public.event_tickets(
  p_event_id uuid,
  p_status public.ticket_status default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
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
           count(*) over ()
    from public.tickets t
    join public.ticket_categories c on c.id = t.category_id
    left join public.checkpoints cp on cp.id = t.redeemed_checkpoint_id
    where t.event_id = p_event_id
      and (p_status is null or t.status = p_status)
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
revoke all on function public.event_tickets(uuid, public.ticket_status, text, integer, integer)
  from public, anon;
grant execute on function public.event_tickets(uuid, public.ticket_status, text, integer, integer)
  to authenticated;

drop function public.export_tickets(uuid[]);

create function public.export_tickets(p_ticket_ids uuid[])
returns table (
  ticket_id uuid,
  public_reference text,
  qr_token text,
  status public.ticket_status,
  category_name text,
  event_id uuid,
  holder_name text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_enc_key text;
  v_count integer;
  v_events uuid[];
  v_orgs uuid[];
begin
  if p_ticket_ids is null or cardinality(p_ticket_ids) not between 1 and 200 then
    raise exception 'export_params_invalid'
      using errcode = '22023', detail = 'De 1 à 200 tickets par export.';
  end if;

  -- Tous les tickets demandés doivent exister et être gérés par l'appelant.
  select count(*), array_agg(distinct t.event_id), array_agg(distinct e.organization_id)
    into v_count, v_events, v_orgs
  from public.tickets t
  join public.events e on e.id = t.event_id
  where t.id = any (p_ticket_ids)
    and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[]);
  if v_actor is null or v_count <> (select count(distinct x) from unnest(p_ticket_ids) x) then
    raise exception 'ticket_not_found'
      using errcode = '42501', detail = 'Ticket introuvable ou droits insuffisants.';
  end if;

  v_enc_key := private.vault_secret('ticketsur_qr_encryption_key');

  -- Journal : un enregistrement par organisation concernée (en pratique une).
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  select o, v_actor, 'tickets.exported', 'event',
         case when cardinality(v_events) = 1 then v_events[1] end,
         jsonb_build_object('count', v_count, 'ticket_ids', to_jsonb(p_ticket_ids))
  from unnest(v_orgs) o;

  return query
    select t.id, t.public_reference,
           extensions.pgp_sym_decrypt(s.token_ciphertext, v_enc_key),
           t.status, c.name, t.event_id, t.holder_name
    from public.tickets t
    join private.ticket_secrets s on s.ticket_id = t.id
    join public.ticket_categories c on c.id = t.category_id
    where t.id = any (p_ticket_ids)
      and t.status <> 'revoked'
    order by t.public_reference;
end;
$$;
revoke all on function public.export_tickets(uuid[]) from public, anon;
grant execute on function public.export_tickets(uuid[]) to authenticated;
