-- =============================================================================
-- TicketSûr — Migration 1700 : catégories d'invitations (lot 2)
-- =============================================================================
-- Une catégorie peut être marquée « invitation » : ses tickets sont présentés
-- comme des invitations (carte, PDF, message d'envoi) et comptés à part dans
-- le tableau de bord et le rapport. Le contrôle à l'entrée est inchangé : une
-- invitation est un ticket comme un autre (même QR, mêmes règles).
--
-- Compatibilité des APK déjà installées :
-- * create/update_ticket_category gardent leurs paramètres ; le nouveau
--   p_is_invitation vaut NULL par défaut = « ne pas changer » (une ancienne
--   APK qui renomme une catégorie d'invitations ne la transforme pas) ;
-- * les fonctions de lecture gagnent une colonne, ignorée par les anciennes
--   versions.
-- =============================================================================

alter table public.ticket_categories
  add column is_invitation boolean not null default false;

-- -----------------------------------------------------------------------------
-- Création et modification d'une catégorie
-- -----------------------------------------------------------------------------
drop function public.create_ticket_category(uuid, text, integer);
drop function public.update_ticket_category(uuid, text, integer);
create function public.create_ticket_category(
  p_event_id uuid,
  p_name text,
  p_capacity integer default null,
  p_is_invitation boolean default null
)
returns public.ticket_categories
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_name text := private.normalize_text(p_name);
  v_event public.events%rowtype;
  v_category public.ticket_categories%rowtype;
begin
  v_event := private.lock_configurable_event(p_event_id);
  perform private.check_category_fields(v_name, p_capacity);
  if exists (select 1 from public.ticket_categories c
             where c.event_id = p_event_id and lower(c.name) = lower(v_name)) then
    raise exception 'category_name_taken'
      using errcode = '23505', detail = 'Une catégorie porte déjà ce nom.';
  end if;

  insert into public.ticket_categories (event_id, name, capacity, is_invitation)
  values (p_event_id, v_name, p_capacity, coalesce(p_is_invitation, false))
  returning * into v_category;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'category.created', 'ticket_category', v_category.id,
          jsonb_build_object('event_id', p_event_id, 'name', v_name, 'capacity', p_capacity,
                             'is_invitation', v_category.is_invitation));
  return v_category;
end;
$$;
revoke all on function public.create_ticket_category(uuid, text, integer, boolean) from public, anon;
grant execute on function public.create_ticket_category(uuid, text, integer, boolean) to authenticated;
create function public.update_ticket_category(
  p_category_id uuid,
  p_name text,
  p_capacity integer default null,
  p_is_invitation boolean default null
)
returns public.ticket_categories
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_name text := private.normalize_text(p_name);
  v_event_id uuid;
  v_event public.events%rowtype;
  v_category public.ticket_categories%rowtype;
  v_issued integer;
begin
  select c.event_id into v_event_id from public.ticket_categories c where c.id = p_category_id;
  if v_event_id is null then
    raise exception 'category_not_found'
      using errcode = '42501', detail = 'Catégorie introuvable ou droits insuffisants.';
  end if;
  -- Ordre de verrouillage : événement, puis catégorie (comme issue_tickets).
  v_event := private.lock_configurable_event(v_event_id);
  select * into v_category from public.ticket_categories c where c.id = p_category_id for update;
  perform private.check_category_fields(v_name, p_capacity);
  if exists (select 1 from public.ticket_categories c
             where c.event_id = v_event_id and c.id <> p_category_id
               and lower(c.name) = lower(v_name)) then
    raise exception 'category_name_taken'
      using errcode = '23505', detail = 'Une catégorie porte déjà ce nom.';
  end if;
  if p_capacity is not null then
    select count(*) into v_issued from public.tickets t
    where t.category_id = p_category_id and t.status <> 'revoked';
    if v_issued > p_capacity then
      raise exception 'category_capacity_below_issued'
        using errcode = '22023', detail = format('%s billets déjà émis.', v_issued);
    end if;
  end if;

  update public.ticket_categories c
     set name = v_name, capacity = p_capacity,
         is_invitation = coalesce(p_is_invitation, c.is_invitation)
   where c.id = p_category_id
  returning * into v_category;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'category.updated', 'ticket_category', p_category_id,
          jsonb_build_object('name', v_name, 'capacity', p_capacity,
                             'is_invitation', v_category.is_invitation));
  return v_category;
end;
$$;
revoke all on function public.update_ticket_category(uuid, text, integer, boolean) from public, anon;
grant execute on function public.update_ticket_category(uuid, text, integer, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Lectures : la colonne is_invitation / category_is_invitation s'ajoute
-- -----------------------------------------------------------------------------
drop function public.event_categories(uuid);
create function public.event_categories(p_event_id uuid)
returns table (
  id uuid,
  event_id uuid,
  name text,
  capacity integer,
  is_invitation boolean,
  issued integer,
  redeemed integer
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
    select c.id, c.event_id, c.name, c.capacity, c.is_invitation,
           count(t.id) filter (where t.status <> 'revoked')::integer,
           count(t.id) filter (where t.status = 'redeemed')::integer
    from public.ticket_categories c
    left join public.tickets t on t.category_id = c.id
    where c.event_id = p_event_id
    group by c.id
    order by c.created_at, c.name;
end;
$$;
revoke all on function public.event_categories(uuid) from public, anon;
grant execute on function public.event_categories(uuid) to authenticated;

drop function public.issue_named_tickets(uuid, jsonb);

create function public.issue_named_tickets(p_event_id uuid, p_rows jsonb)
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
     or jsonb_array_length(p_rows) not between 1 and 500 then
    raise exception 'issue_rows_invalid'
      using errcode = '22023', detail = 'De 1 à 500 tickets par envoi.';
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

drop function public.export_tickets(uuid[]);

create function public.export_tickets(p_ticket_ids uuid[])
returns table (
  ticket_id uuid,
  public_reference text,
  qr_token text,
  status public.ticket_status,
  category_name text,
  event_id uuid,
  holder_name text,
  category_is_invitation boolean
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
           t.status, c.name, t.event_id, t.holder_name, c.is_invitation
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

drop function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean);

create function public.event_tickets(
  p_event_id uuid,
  p_status public.ticket_status default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_undelivered boolean default false
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
           d.channel, d.sent_at, c.is_invitation,
           count(*) over ()
    from public.tickets t
    join public.ticket_categories c on c.id = t.category_id
    left join public.checkpoints cp on cp.id = t.redeemed_checkpoint_id
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
revoke all on function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean)
  from public, anon;
grant execute on function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean)
  to authenticated;

drop function public.event_report_rows(uuid);

create function public.event_report_rows(p_event_id uuid)
returns table (
  public_reference text,
  category_name text,
  category_is_invitation boolean,
  status public.ticket_status,
  holder_name text,
  holder_phone text,
  holder_email text,
  issued_at timestamptz,
  redeemed_at timestamptz,
  redeemed_checkpoint_name text,
  revoked_at timestamptz,
  last_delivery_channel public.delivery_channel,
  last_delivery_at timestamptz
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_org uuid;
  v_count integer;
begin
  select e.organization_id into v_org
  from public.events e
  where e.id = p_event_id
    and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[]);
  if v_org is null then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;

  select count(*) into v_count from public.tickets t where t.event_id = p_event_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org, auth.uid(), 'event.report_exported', 'event', p_event_id,
          jsonb_build_object('rows', least(v_count, 50000)));

  return query
    select t.public_reference, c.name, c.is_invitation, t.status,
           t.holder_name, t.holder_phone, t.holder_email,
           t.issued_at, t.redeemed_at, cp.name, t.revoked_at,
           d.channel, d.sent_at
    from public.tickets t
    join public.ticket_categories c on c.id = t.category_id
    left join public.checkpoints cp on cp.id = t.redeemed_checkpoint_id
    left join lateral (
      select td.channel, td.sent_at
      from public.ticket_deliveries td
      where td.ticket_id = t.id
      order by td.sent_at desc, td.id desc
      limit 1
    ) d on true
    where t.event_id = p_event_id
    order by c.created_at, c.name, t.holder_name nulls last, t.public_reference
    limit 50000;
end;
$$;
revoke all on function public.event_report_rows(uuid) from public, anon;
grant execute on function public.event_report_rows(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Tableau de bord : invitations comptées à part
-- -----------------------------------------------------------------------------
create or replace function public.event_dashboard(p_event_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  c_recent constant interval := interval '15 minutes';
  c_max_buckets constant integer := 48;
  v_now timestamptz := now();
  v_event public.events%rowtype;
  v_opens timestamptz;
  v_closes timestamptz;
  v_first timestamptz;
  v_to timestamptz;
  v_origin timestamptz;
  v_step_minutes integer;
  v_step interval;
  v_tickets jsonb;
  v_scans jsonb;
  v_by_outcome jsonb;
  v_categories jsonb;
  v_checkpoints jsonb;
  v_controllers jsonb;
  v_buckets jsonb;
begin
  select e.* into v_event
  from public.events e
  where e.id = p_event_id
    and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[]);
  if not found then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;

  v_opens := v_event.starts_at - v_event.scan_opens_before;
  v_closes := v_event.ends_at + v_event.scan_closes_after;

  -- Tickets ------------------------------------------------------------------
  select jsonb_build_object(
           'issued', count(*) filter (where t.status <> 'revoked'),
           'admitted', count(*) filter (where t.status = 'redeemed'),
           'remaining', count(*) filter (
             where t.status = 'issued' and (t.expires_at is null or t.expires_at > v_now)),
           'revoked', count(*) filter (where t.status = 'revoked'),
           'invitations', count(*) filter (where t.status <> 'revoked' and tc.is_invitation),
           'invitations_admitted', count(*) filter (where t.status = 'redeemed' and tc.is_invitation),
           'expired', count(*) filter (
             where t.status = 'expired'
                or (t.status = 'issued' and t.expires_at is not null and t.expires_at <= v_now)))
    into v_tickets
  from public.tickets t
  join public.ticket_categories tc on tc.id = t.category_id
  where t.event_id = p_event_id;

  -- Tentatives de scan ---------------------------------------------------------
  select jsonb_build_object(
           'total', count(*),
           'accepted', count(*) filter (where sa.outcome = 'accepted'),
           'refused', count(*) filter (where sa.outcome <> 'accepted'),
           'last_at', max(sa.server_time),
           'last_accepted_at', max(sa.server_time) filter (where sa.outcome = 'accepted'),
           'recent_accepted', count(*) filter (
             where sa.outcome = 'accepted' and sa.server_time > v_now - c_recent),
           'recent_minutes', extract(epoch from c_recent)::integer / 60)
    into v_scans
  from public.scan_attempts sa
  where sa.event_id = p_event_id and sa.outcome <> 'pending';

  select coalesce(jsonb_object_agg(o.outcome, o.n), '{}'::jsonb)
    into v_by_outcome
  from (
    select sa.outcome::text as outcome, count(*) as n
    from public.scan_attempts sa
    where sa.event_id = p_event_id and sa.outcome not in ('accepted', 'pending')
    group by sa.outcome
  ) o;
  v_scans := v_scans || jsonb_build_object('by_outcome', v_by_outcome);

  -- Catégories -----------------------------------------------------------------
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', c.id, 'name', c.name, 'capacity', c.capacity, 'is_invitation', c.is_invitation,
           'issued', c.issued, 'admitted', c.admitted)
         order by c.created_at, c.name), '[]'::jsonb)
    into v_categories
  from (
    select tc.id, tc.name, tc.capacity, tc.is_invitation, tc.created_at,
           count(t.id) filter (where t.status <> 'revoked') as issued,
           count(t.id) filter (where t.status = 'redeemed') as admitted
    from public.ticket_categories tc
    left join public.tickets t on t.category_id = tc.id
    where tc.event_id = p_event_id
    group by tc.id
  ) c;

  -- Portes ---------------------------------------------------------------------
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', cp.id, 'name', cp.name, 'active', cp.active,
           'admitted', coalesce(adm.n, 0),
           'refused', coalesce(att.refused, 0),
           'last_at', att.last_at)
         order by cp.created_at, cp.name), '[]'::jsonb)
    into v_checkpoints
  from public.checkpoints cp
  left join (
    select t.redeemed_checkpoint_id as checkpoint_id, count(*) as n
    from public.tickets t
    where t.event_id = p_event_id and t.status = 'redeemed'
    group by t.redeemed_checkpoint_id
  ) adm on adm.checkpoint_id = cp.id
  left join (
    select sa.checkpoint_id,
           count(*) filter (where sa.outcome <> 'accepted') as refused,
           max(sa.server_time) as last_at
    from public.scan_attempts sa
    where sa.event_id = p_event_id and sa.outcome <> 'pending'
    group by sa.checkpoint_id
  ) att on att.checkpoint_id = cp.id
  where cp.event_id = p_event_id;

  -- Contrôleurs ----------------------------------------------------------------
  select coalesce(jsonb_agg(jsonb_build_object(
           'user_id', a.actor_id, 'display_name', p.display_name,
           'accepted', a.accepted, 'refused', a.refused, 'last_at', a.last_at)
         order by a.accepted desc, a.last_at desc), '[]'::jsonb)
    into v_controllers
  from (
    select sa.actor_id,
           count(*) filter (where sa.outcome = 'accepted') as accepted,
           count(*) filter (where sa.outcome <> 'accepted') as refused,
           max(sa.server_time) as last_at
    from public.scan_attempts sa
    where sa.event_id = p_event_id and sa.outcome <> 'pending'
    group by sa.actor_id
    order by count(*) filter (where sa.outcome = 'accepted') desc, max(sa.server_time) desc
    limit 20
  ) a
  join public.profiles p on p.id = a.actor_id;

  -- Chronologie ----------------------------------------------------------------
  select min(sa.server_time) into v_first
  from public.scan_attempts sa
  where sa.event_id = p_event_id and sa.outcome <> 'pending'
    and sa.server_time between v_opens and v_closes;

  v_buckets := '[]'::jsonb;
  if v_first is not null then
    v_to := least(v_now, v_closes);
    select s.minutes into v_step_minutes
    from unnest(array[5, 10, 15, 30, 60, 120, 180, 360, 720, 1440]) as s(minutes)
    where extract(epoch from (v_to - v_first)) / 60 < s.minutes * c_max_buckets
    order by s.minutes
    limit 1;
    v_step_minutes := coalesce(v_step_minutes, 1440);
    v_step := make_interval(mins => v_step_minutes);
    v_origin := date_trunc('day', v_first at time zone v_event.timezone)
                at time zone v_event.timezone;

    select coalesce(jsonb_agg(jsonb_build_object(
             'at', b.at, 'accepted', coalesce(n.accepted, 0), 'refused', coalesce(n.refused, 0))
           order by b.at), '[]'::jsonb)
      into v_buckets
    from generate_series(date_bin(v_step, v_first, v_origin), v_to, v_step) as b(at)
    left join (
      select date_bin(v_step, sa.server_time, v_origin) as at,
             count(*) filter (where sa.outcome = 'accepted') as accepted,
             count(*) filter (where sa.outcome <> 'accepted') as refused
      from public.scan_attempts sa
      where sa.event_id = p_event_id and sa.outcome <> 'pending'
        and sa.server_time between v_opens and v_closes
      group by 1
    ) n on n.at = b.at;
  end if;

  return jsonb_build_object(
    'version', 1,
    'server_time', v_now,
    'event_id', v_event.id,
    'status', v_event.status,
    'capacity', v_event.capacity,
    'scan_opens_at', v_opens,
    'scan_closes_at', v_closes,
    'tickets', v_tickets,
    'scans', v_scans,
    'categories', v_categories,
    'checkpoints', v_checkpoints,
    'controllers', v_controllers,
    'timeline', jsonb_build_object('step_minutes', v_step_minutes, 'buckets', v_buckets)
  );
end;
$$;
revoke all on function public.event_dashboard(uuid) from public, anon;
grant execute on function public.event_dashboard(uuid) to authenticated;
