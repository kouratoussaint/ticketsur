-- =============================================================================
-- Tikéo — Migration 2000 : contrôle démarré et arrêté par l'organisateur
-- =============================================================================
-- Décision de Toussaint (19/11/2026, ADR 0014) : la fenêtre horaire du
-- contrôle (3 h avant le début, 6 h après la fin) est supprimée.
-- * Le contrôle est possible dès que l'organisateur touche « Démarrer le
--   contrôle » (statut `in_progress`), quelle que soit l'heure.
-- * Il devient impossible dès qu'il touche « Arrêter le contrôle » (statut
--   `closed`, définitif). Un événement seulement publié n'est pas contrôlable.
-- * Les heures de démarrage et d'arrêt sont enregistrées
--   (`control_started_at`, `control_stopped_at`) pour le tableau de bord.
-- Les colonnes `scan_opens_before` et `scan_closes_after` ne sont plus lues.
-- =============================================================================

alter table public.events
  add column control_started_at timestamptz,
  add column control_stopped_at timestamptz;

comment on column public.events.scan_opens_before is 'Obsolète depuis 2000 : plus lu.';
comment on column public.events.scan_closes_after is 'Obsolète depuis 2000 : plus lu.';

-- Événements déjà en cours ou terminés : heures reconstituées avec l'ancienne
-- règle, pour que le tableau de bord garde sa chronologie.
update public.events e
   set control_started_at = e.starts_at - e.scan_opens_before
 where e.status in ('in_progress', 'closed', 'archived');
update public.events e
   set control_stopped_at = least(e.ends_at + e.scan_closes_after, greatest(e.updated_at, e.starts_at))
 where e.status in ('closed', 'archived');

-- -----------------------------------------------------------------------------
-- Démarrage et arrêt horodatés
-- -----------------------------------------------------------------------------
create or replace function public.set_event_status(
  p_event_id uuid,
  p_status public.event_status
)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_event public.events%rowtype;
  v_from public.event_status;
begin
  v_event := private.lock_managed_event(p_event_id);
  v_from := v_event.status;
  if p_status is null or not private.event_transition_allowed(v_from, p_status) then
    raise exception 'event_invalid_transition'
      using errcode = '55000', detail = format('%s → %s interdit.', v_from, p_status);
  end if;
  if p_status = 'published' and v_event.ends_at <= now() then
    raise exception 'event_already_ended'
      using errcode = '55000', detail = 'Impossible de publier un événement terminé.';
  end if;
  if p_status = 'published' and (v_event.cover_path is null or v_event.city is null) then
    raise exception 'event_incomplete'
      using errcode = '55000',
            detail = 'Ajoutez une photo de couverture et une ville avant de publier.';
  end if;
  if v_from = 'published' and p_status = 'draft'
     and exists (select 1 from public.tickets t where t.event_id = p_event_id) then
    raise exception 'event_has_tickets'
      using errcode = '55000', detail = 'Des tickets existent : retour en brouillon impossible.';
  end if;

  update public.events e
     set status = p_status,
         control_started_at = case when p_status = 'in_progress' then now()
                                   else e.control_started_at end,
         control_stopped_at = case when v_from = 'in_progress' and p_status = 'closed' then now()
                                   else e.control_stopped_at end,
         updated_at = now()
   where e.id = p_event_id
  returning * into v_event;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, v_actor, 'event.status_changed', 'event', v_event.id,
          jsonb_build_object('from', v_from, 'to', p_status));
  return v_event;
end;
$$;

-- -----------------------------------------------------------------------------
-- Validation : seul le statut « contrôle en cours » ouvre les portes
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

    -- 6. Consommation atomique : un seul UPDATE peut réussir.
    update public.tickets t
       set status = 'redeemed',
           redeemed_at = v_now,
           redeemed_by = v_actor,
           redeemed_checkpoint_id = p_checkpoint_id
     where t.id = v_ticket_id
       and t.status = 'issued'
       and (t.expires_at is null or t.expires_at > v_now)
    returning t.redeemed_at into v_first_at;

    if found then
      v_result := 'accepted';
      exit decide;
    end if;

    -- 7. Échec de l'UPDATE : on relit l'état COMMITÉ pour qualifier le refus.
    select t.* into v_ticket from public.tickets t where t.id = v_ticket_id;
    v_result := case
      when v_ticket.status = 'redeemed' then 'already_used'
      when v_ticket.status = 'revoked' then 'revoked'
      else 'expired'
    end::public.scan_result;
    if v_result = 'already_used' then
      v_first_at := v_ticket.redeemed_at;
      select cp.name into v_checkpoint_label
      from public.checkpoints cp where cp.id = v_ticket.redeemed_checkpoint_id;
    end if;
  end decide;

  -- 8. Journal de la tentative (append-only) et réponse versionnée.
  insert into public.scan_attempts (scan_request_id, ticket_id, actor_id, event_id, checkpoint_id, outcome, server_time)
  values (v_request_pk, v_ticket_id, v_actor, p_event_id, p_checkpoint_id, v_result, v_now)
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
                   then jsonb_build_object('public_reference', v_ticket.public_reference,
                                           'category', v_category) end,
    'first_validated_at', case when v_result in ('accepted', 'already_used') then v_first_at end,
    'checkpoint_label', case when v_result in ('accepted', 'already_used') then v_checkpoint_label end,
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
-- Postes du contrôleur : événements en cours (sans limite d'heure) et
-- événements publiés non terminés (contrôle pas encore démarré). Les colonnes d'heures restent pour les
-- anciennes versions de l'application : démarrage réel, sinon le début.
-- -----------------------------------------------------------------------------
create or replace function public.my_scan_posts()
returns table (
  event_id uuid,
  event_title text,
  event_status public.event_status,
  venue text,
  timezone text,
  starts_at timestamptz,
  ends_at timestamptz,
  scan_opens_at timestamptz,
  scan_closes_at timestamptz,
  organization_id uuid,
  organization_name text,
  checkpoint_id uuid,
  checkpoint_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct on (e.id, cp.id)
         e.id, e.title, e.status, e.venue, e.timezone, e.starts_at, e.ends_at,
         coalesce(e.control_started_at, e.starts_at),
         greatest(e.ends_at, now()) + interval '1 day',
         o.id, o.name, cp.id, cp.name
  from public.event_assignments a
  join public.events e on e.id = a.event_id
  join public.organizations o on o.id = e.organization_id
  join public.organization_members m
    on m.organization_id = e.organization_id and m.user_id = a.user_id
  join public.profiles p on p.id = a.user_id
  join public.checkpoints cp
    on cp.event_id = e.id and (a.checkpoint_id is null or cp.id = a.checkpoint_id)
  where a.user_id = auth.uid()
    and a.active and m.active and p.status = 'active' and o.status = 'active'
    -- En cours : toujours listé. Publié : seulement s'il n'est pas terminé.
    and (e.status = 'in_progress' or (e.status = 'published' and e.ends_at > now()))
    and cp.active
  order by e.id, cp.id
$$;
revoke all on function public.my_scan_posts() from public, anon;
grant execute on function public.my_scan_posts() to authenticated;

-- -----------------------------------------------------------------------------
-- Tableau de bord : période de contrôle réelle, `control_open`
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

  -- Période de contrôle : du démarrage à l'arrêt par l'organisateur.
  v_opens := coalesce(v_event.control_started_at, v_event.starts_at);
  v_closes := coalesce(v_event.control_stopped_at, greatest(v_now, v_event.ends_at));

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
revoke all on function public.event_dashboard(uuid) from public, anon;
grant execute on function public.event_dashboard(uuid) to authenticated;
