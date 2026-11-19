-- =============================================================================
-- TicketSûr — Migration 1300 : tableau de bord en direct d'un événement
-- (lot 2, DASH-01, S19)
-- =============================================================================
-- * event_dashboard : un seul appel, lecture seule, réservé aux propriétaires
--   et gestionnaires de l'organisation. Renvoie un document JSON versionné :
--   - tickets : émis (hors annulés), entrés, restants, annulés, expirés.
--     Toujours : émis = entrés + restants + expirés ;
--   - scans : tentatives, acceptées, refusées, refus par motif, derniers scans,
--     entrées des 15 dernières minutes (débit) ;
--   - categories, checkpoints : remplissage et passages par catégorie et porte
--     (les entrées viennent des tickets, les refus du journal des tentatives) ;
--   - controllers : activité des 20 contrôleurs les plus actifs ;
--   - timeline : entrées et refus par tranche, de la première tentative de la
--     fenêtre de contrôle jusqu'à maintenant (48 tranches au plus, pas de 5 min
--     à 1 jour, alignées sur minuit dans le fuseau de l'événement).
-- * Aucun jeton QR, aucune référence de ticket : seulement des compteurs.
-- * L'heure de référence est celle du serveur (server_time).
-- =============================================================================

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
           'expired', count(*) filter (
             where t.status = 'expired'
                or (t.status = 'issued' and t.expires_at is not null and t.expires_at <= v_now)))
    into v_tickets
  from public.tickets t
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
           'id', c.id, 'name', c.name, 'capacity', c.capacity,
           'issued', c.issued, 'admitted', c.admitted)
         order by c.created_at, c.name), '[]'::jsonb)
    into v_categories
  from (
    select tc.id, tc.name, tc.capacity, tc.created_at,
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
