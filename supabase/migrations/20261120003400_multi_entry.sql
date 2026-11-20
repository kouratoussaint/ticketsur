-- =============================================================================
-- Tikéo — Pass à plusieurs entrées (lot 4-4c, ADR 0024)
-- =============================================================================
-- Décision de Toussaint (20/11/2026) : exception explicite à la règle « au
-- plus une validation acceptée par ticket », pour les seules catégories que
-- le promoteur règle ainsi :
--   * single  : une seule entrée (par défaut, comportement inchangé) ;
--   * per_day : une entrée par jour, jours comptés dans le fuseau de
--               l'événement ;
--   * limited : N entrées au total (2 à 100).
-- La validation reste en ligne, atomique (un seul UPDATE gagne par entrée)
-- et idempotente. L'invariant défensif devient « au plus une tentative
-- acceptée par (ticket, numéro d'entrée) » : pour une entrée unique, c'est
-- exactement l'ancien invariant.
-- Un pass reste « valable » (issued) tant qu'il lui reste des entrées ;
-- « Entrés » (tableaux de bord) = tickets entrés au moins une fois
-- et non annulés (entries_used > 0), première porte =
-- first_entry_checkpoint_id ; « Restants » = jamais entrés ; les
-- entrées sont comptées par les tentatives acceptées.
-- =============================================================================

alter table public.ticket_categories
  add column entry_policy text not null default 'single'
    check (entry_policy in ('single', 'per_day', 'limited')),
  add column max_entries integer check (max_entries between 2 and 100),
  add constraint ticket_categories_entry_policy_max_check
    check ((entry_policy = 'limited') = (max_entries is not null));

alter table public.tickets
  add column entries_used integer not null default 0 check (entries_used >= 0),
  add column first_entry_at timestamptz,
  add column first_entry_checkpoint_id uuid references public.checkpoints (id),
  add column last_entry_at timestamptz,
  add column last_entry_checkpoint_id uuid references public.checkpoints (id);
update public.tickets t
   set entries_used = 1, first_entry_at = t.redeemed_at,
       first_entry_checkpoint_id = t.redeemed_checkpoint_id,
       last_entry_at = t.redeemed_at, last_entry_checkpoint_id = t.redeemed_checkpoint_id
 where t.redeemed_at is not null;

alter table public.scan_attempts add column entry_number integer check (entry_number >= 1);
drop index public.scan_attempts_one_accept_per_ticket;
-- Invariant défensif : au plus UNE tentative acceptée par entrée d'un ticket
-- (une seule pour un ticket à entrée unique, comme avant).
create unique index scan_attempts_one_accept_per_entry
  on public.scan_attempts (ticket_id, coalesce(entry_number, 1)) where outcome = 'accepted';

-- -----------------------------------------------------------------------------
-- Règle d'entrée d'une catégorie
-- -----------------------------------------------------------------------------
create function public.set_category_entry_policy(
  p_category_id uuid,
  p_policy text,
  p_max_entries integer default null
)
returns public.ticket_categories
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event_id uuid;
  v_event public.events%rowtype;
  v_category public.ticket_categories%rowtype;
  v_max integer := case when p_policy = 'limited' then p_max_entries end;
begin
  select c.event_id into v_event_id from public.ticket_categories c where c.id = p_category_id;
  if v_event_id is null then
    raise exception 'category_not_found'
      using errcode = '42501', detail = 'Catégorie introuvable ou droits insuffisants.';
  end if;
  v_event := private.lock_managed_event(v_event_id);
  if v_event.status in ('closed', 'cancelled', 'archived') then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement clôturé, annulé ou archivé.';
  end if;
  if p_policy is null or p_policy not in ('single', 'per_day', 'limited')
     or (p_policy = 'limited' and (v_max is null or v_max not between 2 and 100)) then
    raise exception 'category_entries_invalid'
      using errcode = '22023', detail = 'Règle d''entrée invalide (2 à 100 entrées).';
  end if;
  select * into v_category from public.ticket_categories c where c.id = p_category_id for update;
  if v_category.entry_policy = p_policy and v_category.max_entries is not distinct from v_max then
    return v_category;
  end if;
  -- Règle figée dès la première entrée d'un de ses tickets.
  if exists (select 1 from public.tickets t
              where t.category_id = p_category_id and t.entries_used > 0) then
    raise exception 'category_has_entries'
      using errcode = '55000', detail = 'Des tickets de cette catégorie sont déjà entrés.';
  end if;
  update public.ticket_categories c
     set entry_policy = p_policy, max_entries = v_max
   where c.id = p_category_id
  returning * into v_category;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'category.entries_changed', 'ticket_category',
          v_category.id, jsonb_strip_nulls(jsonb_build_object('policy', p_policy, 'max', v_max)));
  return v_category;
end;
$$;
revoke all on function public.set_category_entry_policy(uuid, text, integer) from public, anon;
grant execute on function public.set_category_entry_policy(uuid, text, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- Validation (corps recopié de la migration 2900, étapes 6 et 7 modifiées)
-- -----------------------------------------------------------------------------
create or replace function public.validate_scan(
  p_request_id uuid,
  p_event_id uuid,
  p_checkpoint_id uuid,
  p_qr_token text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  c_rate_limit_per_minute constant integer := 120;
  v_actor uuid := auth.uid();
  v_now timestamptz := now();
  v_request_pk uuid;
  v_stored jsonb;
  v_event public.events%rowtype;
  v_ticket public.tickets%rowtype;
  v_ticket_id uuid;
  v_category text;
  v_checkpoint_label text;
  v_result public.scan_result;
  v_validation_id uuid;
  v_first_at timestamptz;
  v_response jsonb;
  v_policy text := 'single';
  v_max integer;
  v_used integer;
  v_today date;
begin
  -- 0. Session obligatoire et compte actif. Sans profil actif, rien n'est
  --    enregistré (le journal référence profiles).
  if v_actor is null or p_request_id is null
     or not exists (select 1 from public.profiles pr
                    where pr.id = v_actor and pr.status = 'active') then
    return jsonb_build_object('version', 1, 'request_id', p_request_id,
                              'result', 'unauthorized', 'server_time', v_now);
  end if;

  -- 1. Idempotence : la première requête (actor, request_id) gagne la ligne.
  --    Une reprise concurrente attend le commit de la première, puis relit.
  insert into public.scan_requests (actor_id, request_id, event_id, checkpoint_id, received_at)
  values (v_actor, p_request_id, p_event_id, p_checkpoint_id, v_now)
  on conflict (actor_id, request_id) do nothing
  returning id into v_request_pk;

  if v_request_pk is null then
    select sr.response into v_stored
    from public.scan_requests sr
    where sr.actor_id = v_actor and sr.request_id = p_request_id;
    return coalesce(v_stored, jsonb_build_object('request_id', p_request_id, 'result', 'pending',
                                                 'server_time', v_now));
  end if;

  <<decide>>
  begin
    -- 2. Limitation de débit par contrôleur.
    if (select count(*) from public.scan_attempts sa
        where sa.actor_id = v_actor and sa.server_time > v_now - interval '1 minute')
       >= c_rate_limit_per_minute then
      v_result := 'rate_limited';
      exit decide;
    end if;

    -- 3. Compte actif, membre actif, affectation active à l'événement et à la porte.
    select e.* into v_event from public.events e where e.id = p_event_id;
    if not found
       or not exists (
         select 1
         from public.event_assignments a
         join public.checkpoints cp on cp.id = p_checkpoint_id and cp.event_id = p_event_id and cp.active
         where a.event_id = p_event_id
           and a.user_id = v_actor
           and a.active
           and (a.checkpoint_id is null or a.checkpoint_id = p_checkpoint_id)
       )
       or not private.has_org_role(v_event.organization_id,
                                   array['owner','manager','controller']::public.member_role[]) then
      v_result := 'unauthorized';
      exit decide;
    end if;

    select cp.name into v_checkpoint_label from public.checkpoints cp where cp.id = p_checkpoint_id;

    -- 4. Contrôle ouvert par l'organisateur (« Démarrer le contrôle ») et
    --    pas encore arrêté : seul le statut compte, plus aucune fenêtre horaire.
    if v_event.status <> 'in_progress' then
      v_result := 'event_inactive';
      exit decide;
    end if;

    -- 5. Format du jeton puis recherche par HMAC (jamais en clair).
    if p_qr_token is null or p_qr_token !~ '^TS1\.[A-Za-z0-9_-]{43}$' then
      v_result := 'not_found';
      exit decide;
    end if;

    select s.ticket_id into v_ticket_id
    from private.ticket_secrets s
    where s.token_hmac = private.token_hmac(p_qr_token);
    if v_ticket_id is null then
      v_result := 'not_found';
      exit decide;
    end if;

    select t.* into v_ticket from public.tickets t where t.id = v_ticket_id;
    if v_ticket.event_id <> p_event_id then
      v_ticket_id := null; -- ne rien révéler du billet d'un autre événement
      v_result := 'wrong_event';
      exit decide;
    end if;

    -- 6. Consommation atomique : un seul UPDATE peut réussir pour une même
    --    entrée. Règle de la catégorie (ADR 0024) : une seule entrée (par
    --    défaut), une par jour (dans le fuseau de l'événement) ou N au total.
    select c.entry_policy, c.max_entries into v_policy, v_max
      from public.ticket_categories c where c.id = v_ticket.category_id;
    v_today := (v_now at time zone v_event.timezone)::date;

    if v_policy = 'per_day' then
      update public.tickets t
         set entries_used = t.entries_used + 1,
             first_entry_at = coalesce(t.first_entry_at, v_now),
             first_entry_checkpoint_id = coalesce(t.first_entry_checkpoint_id, p_checkpoint_id),
             last_entry_at = v_now,
             last_entry_checkpoint_id = p_checkpoint_id
       where t.id = v_ticket_id
         and t.status = 'issued'
         and (t.expires_at is null or t.expires_at > v_now)
         and (t.last_entry_at is null
              or (t.last_entry_at at time zone v_event.timezone)::date < v_today)
      returning t.entries_used into v_used;
    elsif v_policy = 'limited' then
      update public.tickets t
         set entries_used = t.entries_used + 1,
             first_entry_at = coalesce(t.first_entry_at, v_now),
             first_entry_checkpoint_id = coalesce(t.first_entry_checkpoint_id, p_checkpoint_id),
             last_entry_at = v_now,
             last_entry_checkpoint_id = p_checkpoint_id,
             -- Dernière entrée : le pass devient « utilisé » (première entrée
             -- gardée comme date d'utilisation).
             status = case when t.entries_used + 1 >= v_max
                           then 'redeemed'::public.ticket_status else t.status end,
             redeemed_at = case when t.entries_used + 1 >= v_max
                                then coalesce(t.first_entry_at, v_now) end,
             redeemed_by = case when t.entries_used + 1 >= v_max then v_actor end,
             redeemed_checkpoint_id = case when t.entries_used + 1 >= v_max
                                           then coalesce(t.first_entry_checkpoint_id, p_checkpoint_id) end
       where t.id = v_ticket_id
         and t.status = 'issued'
         and (t.expires_at is null or t.expires_at > v_now)
         and t.entries_used < v_max
      returning t.entries_used into v_used;
    else
      update public.tickets t
         set status = 'redeemed',
             redeemed_at = v_now,
             redeemed_by = v_actor,
             redeemed_checkpoint_id = p_checkpoint_id,
             entries_used = 1,
             first_entry_at = v_now,
             first_entry_checkpoint_id = p_checkpoint_id,
             last_entry_at = v_now,
             last_entry_checkpoint_id = p_checkpoint_id
       where t.id = v_ticket_id
         and t.status = 'issued'
         and (t.expires_at is null or t.expires_at > v_now)
      returning t.entries_used into v_used;
    end if;

    if found then
      v_first_at := v_now;
      v_result := 'accepted';
      exit decide;
    end if;

    -- 7. Échec de l'UPDATE : on relit l'état COMMITÉ pour qualifier le refus.
    select t.* into v_ticket from public.tickets t where t.id = v_ticket_id;
    v_used := v_ticket.entries_used;
    v_result := case
      when v_ticket.status = 'redeemed' then 'already_used'
      when v_ticket.status = 'revoked' then 'revoked'
      when v_policy = 'per_day' and v_ticket.last_entry_at is not null
           and (v_ticket.last_entry_at at time zone v_event.timezone)::date >= v_today
        then 'already_used'
      else 'expired'
    end::public.scan_result;
    if v_result = 'already_used' then
      -- Une seule entrée : la première ; pass : la dernière.
      v_first_at := case when v_policy = 'single' then v_ticket.redeemed_at
                         else v_ticket.last_entry_at end;
      select cp.name into v_checkpoint_label
      from public.checkpoints cp
      where cp.id = case when v_policy = 'single' then v_ticket.redeemed_checkpoint_id
                         else v_ticket.last_entry_checkpoint_id end;
    end if;
  end decide;

  -- 8. Journal de la tentative (append-only) et réponse versionnée.
  insert into public.scan_attempts (scan_request_id, ticket_id, actor_id, event_id, checkpoint_id,
                                    outcome, server_time, entry_number)
  values (v_request_pk, v_ticket_id, v_actor, p_event_id, p_checkpoint_id, v_result, v_now,
          case when v_result = 'accepted' then v_used end)
  returning id into v_validation_id;

  if v_ticket_id is not null then
    select tc.name into v_category from public.ticket_categories tc where tc.id = v_ticket.category_id;
  end if;

  v_response := jsonb_strip_nulls(jsonb_build_object(
    'version', 1,
    'request_id', p_request_id,
    'result', v_result,
    'validation_id', case when v_result = 'accepted' then v_validation_id end,
    'ticket', case when v_result in ('accepted', 'already_used', 'revoked', 'expired')
                   then jsonb_strip_nulls(jsonb_build_object(
                          'public_reference', v_ticket.public_reference,
                          'category', v_category,
                          'holder_name', v_ticket.holder_name)) end,
    'first_validated_at', case when v_result in ('accepted', 'already_used') then v_first_at end,
    'checkpoint_label', case when v_result in ('accepted', 'already_used') then v_checkpoint_label end,
    -- Pass à plusieurs entrées : règle et compteur (champ facultatif du v1).
    'entries', case when v_policy <> 'single' and v_result in ('accepted', 'already_used')
                    then jsonb_strip_nulls(jsonb_build_object(
                           'policy', v_policy, 'used', v_used, 'max', v_max)) end,
    'server_time', v_now
  ));

  update public.scan_requests sr
     set result_code = v_result, ticket_id = v_ticket_id, response = v_response
   where sr.id = v_request_pk;

  return v_response;
end;
$$;
revoke all on function public.validate_scan(uuid, uuid, uuid, text) from public, anon;
grant execute on function public.validate_scan(uuid, uuid, uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Lectures : « entrés » = entrés au moins une fois ; règle des catégories
-- -----------------------------------------------------------------------------
drop function public.event_categories(uuid);
create function public.event_categories(p_event_id uuid)
returns table (
  id uuid,
  event_id uuid,
  name text,
  capacity integer,
  is_invitation boolean,
  indicative_price integer,
  issued integer,
  redeemed integer,
  entry_policy text,
  max_entries integer
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
    select c.id, c.event_id, c.name, c.capacity, c.is_invitation, c.indicative_price,
           count(t.id) filter (where t.status <> 'revoked')::integer,
           count(t.id) filter (where t.status <> 'revoked' and t.entries_used > 0)::integer,
           c.entry_policy, c.max_entries
    from public.ticket_categories c
    left join public.tickets t on t.category_id = c.id
    where c.event_id = p_event_id
    group by c.id
    order by c.created_at, c.name;
end;
$$;
revoke all on function public.event_categories(uuid) from public, anon;
grant execute on function public.event_categories(uuid) to authenticated;

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

  -- Période de contrôle : du démarrage à l'arrêt par l'organisateur.
  v_opens := coalesce(v_event.control_started_at, v_event.starts_at);
  v_closes := coalesce(v_event.control_stopped_at, greatest(v_now, v_event.ends_at));

  -- Tickets ------------------------------------------------------------------
  select jsonb_build_object(
           'issued', count(*) filter (where t.status <> 'revoked'),
           'admitted', count(*) filter (where t.status <> 'revoked' and t.entries_used > 0),
           'remaining', count(*) filter (
             where t.status = 'issued' and t.entries_used = 0
               and (t.expires_at is null or t.expires_at > v_now)),
           'revoked', count(*) filter (where t.status = 'revoked'),
           'invitations', count(*) filter (where t.status <> 'revoked' and tc.is_invitation),
           'invitations_admitted', count(*) filter (where (t.status <> 'revoked' and t.entries_used > 0) and tc.is_invitation),
           'expired', count(*) filter (
             where t.entries_used = 0
               and (t.status = 'expired'
                    or (t.status = 'issued' and t.expires_at is not null and t.expires_at <= v_now))))
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
           count(t.id) filter (where t.status <> 'revoked' and t.entries_used > 0) as admitted
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
    select coalesce(t.first_entry_checkpoint_id, t.redeemed_checkpoint_id) as checkpoint_id,
           count(*) as n
    from public.tickets t
    where t.event_id = p_event_id and (t.status <> 'revoked' and t.entries_used > 0)
    group by 1
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
    'scan_opens_at', v_event.control_started_at,
    'scan_closes_at', v_event.control_stopped_at,
    'control_open', v_event.status = 'in_progress',
    'tickets', v_tickets,
    'scans', v_scans,
    'categories', v_categories,
    'checkpoints', v_checkpoints,
    'controllers', v_controllers,
    'timeline', jsonb_build_object('step_minutes', v_step_minutes, 'buckets', v_buckets)
  );
end;
$$;

create or replace function public.admin_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return jsonb_build_object(
    'version', 1,
    'server_time', now(),
    'organizations', (
      select jsonb_build_object(
        'total', count(*),
        'active', count(*) filter (where o.status = 'active'),
        'disabled', count(*) filter (where o.status = 'disabled'),
        'new_7d', count(*) filter (where o.created_at > now() - interval '7 days'))
      from public.organizations o),
    'accounts', (
      select jsonb_build_object(
        'total', count(*) filter (where p.deleted_at is null),
        'disabled', count(*) filter (where p.status = 'disabled' and p.deleted_at is null),
        'deletion_requested', count(*) filter (
          where p.deletion_requested_at is not null and p.deleted_at is null),
        'deletion_due', count(*) filter (
          where p.deleted_at is null
            and p.deletion_requested_at <= now() - private.account_deletion_delay()),
        'deleted', count(*) filter (where p.deleted_at is not null),
        'new_7d', count(*) filter (where p.created_at > now() - interval '7 days'))
      from public.profiles p),
    'events', (
      select jsonb_build_object(
        'total', count(*),
        'upcoming', count(*) filter (where e.status = 'published' and e.ends_at > now()),
        'in_progress', count(*) filter (where e.status = 'in_progress'),
        'listed', count(*) filter (where private.is_listed(e)),
        'blocked', count(*) filter (where e.public_blocked_at is not null))
      from public.events e),
    'tickets', (
      select jsonb_build_object(
        'issued', count(*),
        'redeemed', count(*) filter (where t.status <> 'revoked' and t.entries_used > 0),
        'issued_7d', count(*) filter (where t.issued_at > now() - interval '7 days'))
      from public.tickets t),
    'scans_24h', (
      select jsonb_build_object(
        'accepted', count(*) filter (where s.outcome = 'accepted'),
        'refused', count(*) filter (where s.outcome <> 'accepted'))
      from public.scan_attempts s
      where s.server_time > now() - interval '24 hours')
  );
end;
$$;

-- Duplication : la règle d'entrée des catégories est recopiée.
create or replace function public.duplicate_event(
  p_event_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_source public.events%rowtype;
  v_title text := private.normalize_text(p_title);
  v_id uuid;
begin
  select * into v_source from public.events e where e.id = p_event_id;
  if v_actor is null or not found
     or not private.has_org_role(v_source.organization_id,
                                 array['owner','manager']::public.member_role[]) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  perform private.check_event_fields(v_title, v_source.venue, v_source.timezone,
                                     p_starts_at, p_ends_at, v_source.capacity);

  insert into public.events (organization_id, title, venue, timezone, starts_at, ends_at,
                             capacity, status, created_by, city, country_code, venue_address,
                             latitude, longitude, description, kind, is_public, tagline)
  values (v_source.organization_id, v_title, v_source.venue, v_source.timezone, p_starts_at,
          p_ends_at, v_source.capacity, 'draft', v_actor, v_source.city, v_source.country_code,
          v_source.venue_address, v_source.latitude, v_source.longitude, v_source.description,
          v_source.kind, v_source.is_public and v_source.public_blocked_at is null,
          v_source.tagline)
  returning id into v_id;

  insert into public.ticket_categories (event_id, name, capacity, is_invitation, indicative_price,
                                       entry_policy, max_entries)
  select v_id, c.name, c.capacity, c.is_invitation, c.indicative_price, c.entry_policy, c.max_entries
    from public.ticket_categories c where c.event_id = p_event_id;

  -- Thèmes intégrés, catégorie retrouvée par son nom (unique par événement).
  insert into public.ticket_category_templates
    (category_id, kind, builtin_theme, single_font_title, cover_x, cover_y, cover_zoom,
     updated_by, updated_at)
  select n.id, 'builtin', m.builtin_theme, m.single_font_title, m.cover_x, m.cover_y,
         m.cover_zoom, v_actor, now()
    from public.ticket_category_templates m
    join public.ticket_categories o on o.id = m.category_id and o.event_id = p_event_id
    join public.ticket_categories n on n.event_id = v_id and n.name = o.name
   where m.kind = 'builtin';

  insert into public.checkpoints (event_id, name, active)
  select v_id, c.name, c.active from public.checkpoints c where c.event_id = p_event_id;

  -- Affectations actives, porte retrouvée par son nom.
  insert into public.event_assignments (event_id, user_id, checkpoint_id, active)
  select v_id, a.user_id, n.id, true
    from public.event_assignments a
    left join public.checkpoints o on o.id = a.checkpoint_id
    left join public.checkpoints n on n.event_id = v_id and n.name = o.name
   where a.event_id = p_event_id and a.active
  on conflict do nothing;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_source.organization_id, v_actor, 'event.duplicated', 'event', v_id,
          jsonb_build_object('source', p_event_id));
  return v_id;
end;
$$;

-- -----------------------------------------------------------------------------
-- Titulaire figé dès la première entrée d'un pass (corps recopié de la 1400)
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
  -- Un pass déjà entré une fois garde son titulaire (pas de prêt du pass).
  if v_ticket.status <> 'issued' or v_ticket.entries_used > 0 then
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
