-- =============================================================================
-- Tikéo — Lot 4-5 : rappels avant l'événement, envois automatiques, bilan
-- (ADR 0025)
-- =============================================================================
-- * Rappels aux détenteurs d'un ticket ajouté à « Mes tickets » : la veille
--   (24 h à 3 h avant le début) et peu avant (2 h avant), une seule fois par
--   événement, par personne et par type, dans la langue du destinataire.
--   Désactivables dans les Paramètres (profiles.event_reminders).
-- * Tâche planifiée (pg_cron, toutes les 5 minutes) : prépare les rappels,
--   puis appelle la fonction d'envoi (pg_net) s'il reste des messages en
--   attente. Les messages en échec sont ainsi réessayés (5 essais au plus).
--   L'adresse de la fonction et la clé publiable (publique, déjà dans l'APK)
--   sont posées par le déploiement dans private.app_settings. Sans pg_cron ni
--   pg_net (base locale, CI), rien n'est planifié.
-- * Bilan d'après-événement (event_summary) : affluence par heure et par
--   jour, heure de pointe, entrées des pass, comparaison avec les derniers
--   événements de la structure. Propriétaires et gestionnaires.
-- =============================================================================

-- Réglages de l'environnement (jamais exposés par l'API).
create table private.app_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);
revoke all on private.app_settings from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Préférence « Rappels avant l'événement »
-- -----------------------------------------------------------------------------
alter table public.profiles
  add column event_reminders boolean not null default true;

drop function public.my_profile();
create function public.my_profile()
returns table (
  id uuid, display_name text, avatar_path text, phone text, locale text,
  deletion_requested_at timestamptz, event_reminders boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select p.id, p.display_name, p.avatar_path, p.phone, p.locale, p.deletion_requested_at,
         p.event_reminders
  from public.profiles p
  where p.id = auth.uid()
$$;
revoke all on function public.my_profile() from public, anon;
grant execute on function public.my_profile() to authenticated;

create function public.set_event_reminders(p_enabled boolean)
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
begin
  if p_enabled is null then
    raise exception 'reminders_invalid'
      using errcode = '22023', detail = 'Choix des rappels manquant.';
  end if;
  update public.profiles p set event_reminders = p_enabled where p.id = v_actor;
  return p_enabled;
end;
$$;
revoke all on function public.set_event_reminders(boolean) from public, anon;
grant execute on function public.set_event_reminders(boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Rappels
-- -----------------------------------------------------------------------------
create table private.event_reminders (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('day_before', 'soon')),
  created_at timestamptz not null default now(),
  primary key (event_id, user_id, kind)
);
revoke all on private.event_reminders from public, anon, authenticated;

-- Prépare les rappels dus à [p_now] ; renvoie le nombre de messages créés.
create function private.enqueue_event_reminders(p_now timestamptz default now())
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  with due as (
    -- « Bientôt » à 2 h ; « la veille » de 24 h à 3 h avant (pas les deux
    -- d'un coup pour un événement créé tard).
    select e.id as event_id, e.title, e.starts_at, e.timezone,
           nullif(concat_ws(', ', e.venue, e.city), '') as place,
           case when e.starts_at - p_now <= interval '2 hours' then 'soon'
                else 'day_before' end as kind,
           (e.starts_at at time zone e.timezone)::date
             = (p_now at time zone e.timezone)::date as same_day
      from public.events e
     where e.status in ('published', 'in_progress')
       and e.starts_at > p_now
       and e.starts_at <= p_now + interval '24 hours'
       and (e.starts_at - p_now <= interval '2 hours'
            or e.starts_at - p_now >= interval '3 hours')
  ), holders as (
    select d.event_id, d.title, d.starts_at, d.timezone, d.place, d.kind, d.same_day,
           t.holder_user_id as user_id, count(*) as tickets,
           min(t.id::text)::uuid as ticket_id
      from due d
      join public.tickets t on t.event_id = d.event_id
     where t.holder_user_id is not null and t.status = 'issued'
     group by d.event_id, d.title, d.starts_at, d.timezone, d.place, d.kind, d.same_day,
              t.holder_user_id
  ), fresh as (
    insert into private.event_reminders (event_id, user_id, kind)
    select h.event_id, h.user_id, h.kind
      from holders h
      join public.profiles p on p.id = h.user_id
     where p.event_reminders and p.deleted_at is null and p.disabled_at is null
       and exists (select 1 from public.push_devices pd where pd.user_id = h.user_id)
    on conflict do nothing
    returning event_id, user_id, kind
  )
  insert into public.push_outbox (user_id, title, body, route)
  select f.user_id,
         case when h.kind = 'soon'
              then case p.locale when 'en' then 'Starting soon: ' else 'Bientôt : ' end
              else case p.locale when 'en' then 'Reminder: ' else 'Rappel : ' end
         end || h.title,
         case when h.kind = 'soon'
              then case p.locale when 'en' then 'Starts at ' else 'Début à ' end
              else case p.locale
                     when 'en' then case when h.same_day then 'Today at ' else 'Tomorrow at ' end
                     else case when h.same_day then 'Aujourd''hui à ' else 'Demain à ' end
                   end
         end
         || to_char(h.starts_at at time zone h.timezone, 'HH24:MI')
         || coalesce(' · ' || h.place, '')
         || case when h.kind = 'soon'
                 then case p.locale when 'en' then '. Have your ticket ready.'
                                    else '. Préparez votre ticket.' end
                 else case p.locale when 'en' then '. Your ticket is in Tikéo.'
                                    else '. Votre ticket est dans Tikéo.' end
            end,
         case when h.tickets = 1 then '/mon-ticket/' || h.ticket_id else '/portefeuille' end
    from fresh f
    join holders h on h.event_id = f.event_id and h.user_id = f.user_id and h.kind = f.kind
    join public.profiles p on p.id = f.user_id
   order by f.event_id, f.user_id;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke all on function private.enqueue_event_reminders(timestamptz) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Tâche planifiée : rappels puis envoi de la file
-- -----------------------------------------------------------------------------
create function private.push_tick()
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_key text;
begin
  perform private.enqueue_event_reminders(now());
  select s.value into v_url from private.app_settings s where s.key = 'push_dispatch_url';
  select s.value into v_key from private.app_settings s where s.key = 'publishable_key';
  if v_url is null or v_key is null
     or not exists (select 1 from pg_proc pr join pg_namespace n on n.oid = pr.pronamespace
                     where n.nspname = 'net' and pr.proname = 'http_post')
     or not exists (select 1 from public.push_outbox o where o.sent_at is null and o.attempts < 5)
  then
    return;
  end if;
  -- Appel asynchrone (pg_net) : la fonction vide la file.
  execute 'select net.http_post(url := $1, body := $2, headers := $3, timeout_milliseconds := 30000)'
    using v_url, '{}'::jsonb,
          jsonb_build_object('content-type', 'application/json',
                             'apikey', v_key, 'authorization', 'Bearer ' || v_key);
end;
$$;
revoke all on function private.push_tick() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron')
     and exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net with schema extensions;
    create extension if not exists pg_cron;
    perform cron.schedule('tikeo-push-tick', '*/5 * * * *', 'select private.push_tick()');
  else
    raise notice 'pg_cron ou pg_net absent : rappels et nouvel essai non planifiés.';
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- Bilan d'après-événement
-- -----------------------------------------------------------------------------
create function public.event_summary(p_event_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
  v_hours jsonb;
  v_peak jsonb;
  v_days jsonb;
  v_passes jsonb;
  v_span jsonb;
  v_comparison jsonb;
begin
  select e.* into v_event
  from public.events e
  where e.id = p_event_id
    and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[]);
  if not found then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;

  -- Entrées acceptées par heure locale (10 jours au plus).
  with hours as (
    select date_trunc('hour', sa.server_time at time zone v_event.timezone) as at,
           count(*) as entries
      from public.scan_attempts sa
     where sa.event_id = p_event_id and sa.outcome = 'accepted'
     group by 1
     order by 1
     limit 240
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'at', to_char(h.at, 'YYYY-MM-DD"T"HH24:MI'), 'entries', h.entries) order by h.at),
           '[]'::jsonb),
         (select jsonb_build_object('at', to_char(p.at, 'YYYY-MM-DD"T"HH24:MI'),
                                    'entries', p.entries)
            from hours p order by p.entries desc, p.at limit 1)
    into v_hours, v_peak
  from hours h;

  -- Par jour local : personnes (tickets distincts) et entrées.
  select coalesce(jsonb_agg(jsonb_build_object(
           'date', to_char(d.day, 'YYYY-MM-DD'), 'people', d.people, 'entries', d.entries)
           order by d.day), '[]'::jsonb)
    into v_days
  from (
    select (sa.server_time at time zone v_event.timezone)::date as day,
           count(distinct sa.ticket_id) as people, count(*) as entries
      from public.scan_attempts sa
     where sa.event_id = p_event_id and sa.outcome = 'accepted'
     group by 1
  ) d;

  select jsonb_build_object(
           'tickets', count(*) filter (where t.status <> 'revoked'),
           'entries', coalesce(sum(t.entries_used) filter (where t.status <> 'revoked'), 0))
    into v_passes
  from public.tickets t
  join public.ticket_categories c on c.id = t.category_id
  where t.event_id = p_event_id and c.entry_policy <> 'single';

  select jsonb_build_object('first_at', min(sa.server_time), 'last_at', max(sa.server_time))
    into v_span
  from public.scan_attempts sa
  where sa.event_id = p_event_id and sa.outcome = 'accepted';

  -- Cet événement et les 7 derniers déjà commencés de la structure.
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', x.id, 'title', x.title, 'starts_at', x.starts_at,
           'issued', x.issued, 'admitted', x.admitted, 'current', x.id = p_event_id)
           order by x.starts_at desc), '[]'::jsonb)
    into v_comparison
  from (
    select e.id, e.title, e.starts_at,
           (select count(*) from public.tickets t
             where t.event_id = e.id and t.status <> 'revoked') as issued,
           (select count(*) from public.tickets t
             where t.event_id = e.id and t.status <> 'revoked' and t.entries_used > 0) as admitted
      from public.events e
     where e.id = p_event_id
        or e.id in (select o.id from public.events o
                     where o.organization_id = v_event.organization_id
                       and o.id <> p_event_id
                       and o.status in ('published', 'in_progress', 'closed', 'archived')
                       and o.starts_at <= now()
                     order by o.starts_at desc
                     limit 7)
  ) x;

  return jsonb_build_object(
    'version', 1,
    'event_id', p_event_id,
    'timezone', v_event.timezone,
    'server_time', now(),
    'hours', v_hours,
    'peak', v_peak,
    'days', v_days,
    'passes', v_passes,
    'first_entry_at', v_span->'first_at',
    'last_entry_at', v_span->'last_at',
    'comparison', v_comparison);
end;
$$;
revoke all on function public.event_summary(uuid) from public, anon;
grant execute on function public.event_summary(uuid) to authenticated;
