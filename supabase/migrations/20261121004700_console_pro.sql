-- =============================================================================
-- Tikéo — Migration 4700 : console pro (lot 4-8a, ADR 0036)
-- =============================================================================
-- 1. Annonces programmées : date de début choisie, modification tant que
--    l'annonce n'a pas commencé ; la notification d'une annonce importante
--    part à son début (tâche push_tick, toutes les 5 minutes), une seule fois
--    (announcements.pushed_at).
-- 2. Réponses types du support : modèles (titre, texte) gérés par les
--    administrateurs, insérés dans une réponse puis modifiables.
-- 3. Courbes sur 30 jours : comptes, structures, événements publiés, tickets
--    émis, entrées validées, par jour (UTC).
-- Journal : jamais le texte d'une annonce ni d'un modèle.
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   22023 announcement_dates_invalid | support_template_title_invalid
--         | support_template_body_invalid | days_invalid
--   55000 announcement_started
--   54000 support_templates_limit
--   P0002 announcement_not_found | support_template_not_found
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Annonces programmées
-- -----------------------------------------------------------------------------
alter table public.announcements add column pushed_at timestamptz;

-- Les annonces existantes sont déjà parties (ou n'avaient rien à envoyer).
update public.announcements a set pushed_at = a.created_at where a.pushed_at is null;

-- Notification à l'insertion seulement si l'annonce commence déjà.
drop trigger announcements_push on public.announcements;
create or replace function private.push_on_announcement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.starts_at <= now() then
    if new.level = 'important' then
      insert into public.push_outbox (topic_condition, title, body, route)
      values (
        (select string_agg(format('''tikeo_%s'' in topics', a), ' || ' order by a)
           from unnest(new.audiences) a),
        new.title, left(new.body, 240), '/');
    end if;
    new.pushed_at := now();
  end if;
  return new;
end;
$$;
create trigger announcements_push
  before insert on public.announcements
  for each row execute function private.push_on_announcement();

-- Annonces importantes arrivées à leur début : notification, une seule fois.
create function private.push_due_announcements(p_now timestamptz)
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
    update public.announcements a
       set pushed_at = p_now
     where a.pushed_at is null
       and a.archived_at is null
       and a.starts_at <= p_now
       and (a.ends_at is null or a.ends_at > p_now)
    returning a.title, a.body, a.audiences, a.level
  ), queued as (
    insert into public.push_outbox (topic_condition, title, body, route)
    select (select string_agg(format('''tikeo_%s'' in topics', x), ' || ' order by x)
              from unnest(d.audiences) x),
           d.title, left(d.body, 240), '/'
      from due d
     where d.level = 'important'
    returning 1
  )
  select count(*) into v_count from queued;
  return v_count;
end;
$$;
revoke all on function private.push_due_announcements(timestamptz) from public, anon, authenticated;

-- push_tick (corps de la 3800) + annonces programmées.
create or replace function private.push_tick()
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
  begin
    perform private.push_due_announcements(now());
  exception when others then
    raise warning 'push_due_announcements: %', sqlerrm;
  end;
  -- Factures à l'usage dues (une erreur ici ne bloque pas les notifications).
  begin
    perform private.billing_tick(now());
  exception when others then
    raise warning 'billing_tick: %', sqlerrm;
  end;
  begin
    perform private.billing_notify(now());
  exception when others then
    raise warning 'billing_notify: %', sqlerrm;
  end;
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

-- Champs communs à la publication et à la modification.
create function private.check_announcement_dates(p_starts_at timestamptz, p_ends_at timestamptz)
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if p_starts_at < now() - interval '5 minutes' or p_starts_at > now() + interval '90 days' then
    raise exception 'announcement_dates_invalid'
      using errcode = '22023', detail = 'Début entre maintenant et dans 90 jours.';
  end if;
  if p_ends_at is not null and (p_ends_at <= p_starts_at or p_ends_at <= now()) then
    raise exception 'announcement_dates_invalid'
      using errcode = '22023', detail = 'La fin doit suivre le début et être dans le futur.';
  end if;
end;
$$;
revoke all on function private.check_announcement_dates(timestamptz, timestamptz)
  from public, anon, authenticated;

create function private.clean_audiences(p_audiences text[])
returns text[]
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_audiences text[];
begin
  select array_agg(distinct a order by a) into v_audiences from unnest(p_audiences) a;
  if v_audiences is null or cardinality(v_audiences) = 0
     or not v_audiences <@ array['visitors', 'users', 'promoters', 'controllers'] then
    raise exception 'announcement_audience_invalid'
      using errcode = '22023', detail = 'Choisissez au moins un destinataire.';
  end if;
  return v_audiences;
end;
$$;
revoke all on function private.clean_audiences(text[]) from public, anon, authenticated;

-- Publication, avec un début facultatif (null = maintenant). Remplace la
-- version à 5 paramètres : les anciennes APK l'appellent sans p_starts_at.
drop function public.admin_publish_announcement(text, text, text[], text, timestamptz);
create function public.admin_publish_announcement(
  p_title text,
  p_body text,
  p_audiences text[],
  p_level text default 'info',
  p_ends_at timestamptz default null,
  p_starts_at timestamptz default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_title text := private.clean_support_text(p_title, 3, 80, 'announcement_title_invalid');
  v_body text := private.clean_support_text(p_body, 1, 1000, 'announcement_body_invalid');
  v_audiences text[];
  v_starts timestamptz := greatest(coalesce(p_starts_at, now()), now());
  v_id uuid;
begin
  perform private.require_platform_admin();
  v_audiences := private.clean_audiences(p_audiences);
  if coalesce(p_level, 'info') not in ('info', 'important') then
    raise exception 'announcement_level_invalid' using errcode = '22023', detail = 'Importance inconnue.';
  end if;
  perform private.check_announcement_dates(coalesce(p_starts_at, now()), p_ends_at);
  insert into public.announcements (title, body, audiences, level, starts_at, ends_at, created_by)
  values (v_title, v_body, v_audiences, coalesce(p_level, 'info'), v_starts, p_ends_at, auth.uid())
  returning id into v_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.announcement_published', 'announcement', v_id,
          jsonb_build_object('audiences', to_jsonb(v_audiences), 'level', coalesce(p_level, 'info'))
          || case when v_starts > now() then '{"scheduled": true}'::jsonb else '{}'::jsonb end);
  return v_id;
end;
$$;
revoke all on function public.admin_publish_announcement(text, text, text[], text, timestamptz, timestamptz)
  from public, anon;
grant execute on function public.admin_publish_announcement(text, text, text[], text, timestamptz, timestamptz)
  to authenticated;

-- Modification d'une annonce programmée (pas encore commencée ni archivée).
create function public.admin_update_announcement(
  p_announcement_id uuid,
  p_title text,
  p_body text,
  p_audiences text[],
  p_level text,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_title text := private.clean_support_text(p_title, 3, 80, 'announcement_title_invalid');
  v_body text := private.clean_support_text(p_body, 1, 1000, 'announcement_body_invalid');
  v_audiences text[];
  v_row public.announcements%rowtype;
begin
  perform private.require_platform_admin();
  select * into v_row from public.announcements a where a.id = p_announcement_id for update;
  if not found then
    raise exception 'announcement_not_found' using errcode = 'P0002', detail = 'Annonce introuvable.';
  end if;
  if v_row.archived_at is not null or v_row.starts_at <= now() or v_row.pushed_at is not null then
    raise exception 'announcement_started'
      using errcode = '55000', detail = 'Annonce déjà diffusée ou archivée : elle ne se modifie plus.';
  end if;
  v_audiences := private.clean_audiences(p_audiences);
  if coalesce(p_level, 'info') not in ('info', 'important') then
    raise exception 'announcement_level_invalid' using errcode = '22023', detail = 'Importance inconnue.';
  end if;
  perform private.check_announcement_dates(coalesce(p_starts_at, now()), p_ends_at);
  update public.announcements a
     set title = v_title, body = v_body, audiences = v_audiences, level = coalesce(p_level, 'info'),
         starts_at = greatest(coalesce(p_starts_at, now()), now()), ends_at = p_ends_at
   where a.id = p_announcement_id;
  -- Début ramené à maintenant : diffusion immédiate.
  perform private.push_due_announcements(now());
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.announcement_updated', 'announcement', p_announcement_id,
          jsonb_build_object('audiences', to_jsonb(v_audiences), 'level', coalesce(p_level, 'info')));
end;
$$;
revoke all on function public.admin_update_announcement(uuid, text, text, text[], text, timestamptz, timestamptz)
  from public, anon;
grant execute on function public.admin_update_announcement(uuid, text, text, text[], text, timestamptz, timestamptz)
  to authenticated;

-- Liste de la console : état « programmée » en plus (colonnes ajoutées).
drop function public.admin_announcements(integer, integer);
create function public.admin_announcements(p_limit integer default 50, p_offset integer default 0)
returns table (
  id uuid, title text, body text, audiences text[], level text,
  starts_at timestamptz, ends_at timestamptz, archived_at timestamptz,
  active boolean, author_name text, scheduled boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  if p_limit is null or p_limit not between 1 and 100 or p_offset is null or p_offset < 0 then
    raise exception 'page_invalid' using errcode = '22023', detail = 'Page invalide.';
  end if;
  return query
  select a.id, a.title, a.body, a.audiences, a.level, a.starts_at, a.ends_at, a.archived_at,
         a.archived_at is null and a.starts_at <= now() and (a.ends_at is null or a.ends_at > now()),
         p.display_name,
         a.archived_at is null and a.starts_at > now()
    from public.announcements a
    join public.profiles p on p.id = a.created_by
   order by a.created_at desc, a.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_announcements(integer, integer) from public, anon;
grant execute on function public.admin_announcements(integer, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Réponses types du support
-- -----------------------------------------------------------------------------
create table public.support_reply_templates (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 2 and 60),
  body text not null check (char_length(body) between 1 and 2000),
  created_by uuid references public.profiles (id) on delete set null,
  updated_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.support_reply_templates enable row level security;
revoke all on public.support_reply_templates from anon, authenticated;

create function public.admin_support_templates()
returns table (id uuid, title text, body text, updated_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return query
  select t.id, t.title, t.body, t.updated_at
    from public.support_reply_templates t
   order by lower(t.title), t.id;
end;
$$;
revoke all on function public.admin_support_templates() from public, anon;
grant execute on function public.admin_support_templates() to authenticated;

-- Crée (p_template_id null) ou modifie un modèle ; 50 modèles au plus.
create function public.admin_save_support_template(p_template_id uuid, p_title text, p_body text)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_title text := private.clean_support_text(p_title, 2, 60, 'support_template_title_invalid');
  v_body text := private.clean_support_text(p_body, 1, 2000, 'support_template_body_invalid');
  v_id uuid;
begin
  perform private.require_platform_admin();
  if p_template_id is null then
    perform pg_advisory_xact_lock(hashtext('support_reply_templates'));
    if (select count(*) from public.support_reply_templates) >= 50 then
      raise exception 'support_templates_limit'
        using errcode = '54000', detail = '50 réponses types au plus.';
    end if;
    insert into public.support_reply_templates (title, body, created_by, updated_by)
    values (v_title, v_body, auth.uid(), auth.uid())
    returning id into v_id;
  else
    update public.support_reply_templates t
       set title = v_title, body = v_body, updated_by = auth.uid(), updated_at = now()
     where t.id = p_template_id
    returning t.id into v_id;
    if v_id is null then
      raise exception 'support_template_not_found'
        using errcode = 'P0002', detail = 'Réponse type introuvable.';
    end if;
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.support_template_saved', 'support_template', v_id,
          jsonb_build_object('created', p_template_id is null));
  return v_id;
end;
$$;
revoke all on function public.admin_save_support_template(uuid, text, text) from public, anon;
grant execute on function public.admin_save_support_template(uuid, text, text) to authenticated;

create function public.admin_delete_support_template(p_template_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  delete from public.support_reply_templates t where t.id = p_template_id;
  if not found then
    raise exception 'support_template_not_found'
      using errcode = 'P0002', detail = 'Réponse type introuvable.';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.support_template_deleted', 'support_template', p_template_id,
          '{}'::jsonb);
end;
$$;
revoke all on function public.admin_delete_support_template(uuid) from public, anon;
grant execute on function public.admin_delete_support_template(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Courbes de la vue d'ensemble
-- -----------------------------------------------------------------------------
-- Une ligne par jour (UTC, plus ancien d'abord), aujourd'hui compris.
create function public.admin_daily_stats(p_days integer default 30)
returns table (
  day date, accounts integer, organizations integer, events_published integer,
  tickets_issued integer, entries integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_from date;
begin
  perform private.require_platform_admin();
  if p_days is null or p_days not between 7 and 90 then
    raise exception 'days_invalid' using errcode = '22023', detail = 'De 7 à 90 jours.';
  end if;
  v_from := (now() at time zone 'UTC')::date - (p_days - 1);
  return query
  with days as (
    select g::date as d from generate_series(v_from, (now() at time zone 'UTC')::date, interval '1 day') g
  ), acc as (
    select (p.created_at at time zone 'UTC')::date as d, count(*)::integer as n
      from public.profiles p where p.created_at >= v_from::timestamp at time zone 'UTC' group by 1
  ), org as (
    select (o.created_at at time zone 'UTC')::date as d, count(*)::integer as n
      from public.organizations o where o.created_at >= v_from::timestamp at time zone 'UTC' group by 1
  ), pub as (
    -- Première publication de chaque événement (journal).
    select (f.at at time zone 'UTC')::date as d, count(*)::integer as n
      from (select l.resource_id, min(l.created_at) as at
              from public.audit_logs l
             where l.action = 'event.status_changed' and l.details->>'to' = 'published'
             group by l.resource_id) f
     where f.at >= v_from::timestamp at time zone 'UTC'
     group by 1
  ), tix as (
    select (t.issued_at at time zone 'UTC')::date as d, count(*)::integer as n
      from public.tickets t where t.issued_at >= v_from::timestamp at time zone 'UTC' group by 1
  ), ent as (
    select (s.server_time at time zone 'UTC')::date as d, count(*)::integer as n
      from public.scan_attempts s
     where s.outcome = 'accepted' and s.server_time >= v_from::timestamp at time zone 'UTC'
     group by 1
  )
  select days.d, coalesce(acc.n, 0), coalesce(org.n, 0), coalesce(pub.n, 0),
         coalesce(tix.n, 0), coalesce(ent.n, 0)
    from days
    left join acc on acc.d = days.d
    left join org on org.d = days.d
    left join pub on pub.d = days.d
    left join tix on tix.d = days.d
    left join ent on ent.d = days.d
   order by days.d;
end;
$$;
revoke all on function public.admin_daily_stats(integer) from public, anon;
grant execute on function public.admin_daily_stats(integer) to authenticated;
