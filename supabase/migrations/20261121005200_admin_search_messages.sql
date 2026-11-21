-- =============================================================================
-- Tikéo — Migration 5200 : recherche globale, messages ciblés, journal
-- filtrable (lot 4-11d-1, ADR 0041)
-- =============================================================================
-- 1. Recherche globale de la console : un seul texte, quatre listes (comptes,
--    structures, événements, tickets), avec les règles de recherche des
--    listes de la console.
-- 2. Messages ciblés :
--    - à un compte : une conversation du support ouverte par l'équipe (le
--      compte peut répondre ; notification par le déclencheur du support) ;
--    - aux membres actifs d'une structure, ou aux détenteurs (comptes qui ont
--      le ticket dans « Mes tickets ») d'un événement : une annonce réservée
--      (bandeau dans l'app pendant 1 à 30 jours) et une notification à chacun.
--    Le journal ne garde jamais le texte : seulement le public (account,
--    members, holders) et le nombre de destinataires.
-- 3. Journal filtrable par administrateur, compte, structure, événement.
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   22023 search_query_invalid | message_title_invalid | message_body_invalid
--         | message_days_invalid | message_target_invalid
--   55000 message_no_recipients | announcement_targeted
--   42501 admin_role_forbidden | self_forbidden
--   P0002 account_not_found
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Recherche globale
-- -----------------------------------------------------------------------------
create function public.admin_global_search(p_query text, p_limit integer default 5)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_query text := trim(coalesce(p_query, ''));
  v_limit integer := least(greatest(coalesce(p_limit, 5), 1), 20);
  v_accounts jsonb;
  v_organizations jsonb;
  v_events jsonb;
  v_tickets jsonb := '[]'::jsonb;
begin
  perform private.require_platform_admin();
  if char_length(v_query) not between 2 and 60 then
    raise exception 'search_query_invalid'
      using errcode = '22023', detail = 'De 2 à 60 caractères.';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', a.id, 'name', a.display_name, 'email', a.email, 'status', a.status,
           'deleted', a.deleted_at is not null)), '[]'::jsonb)
    into v_accounts
    from public.admin_accounts(v_query, 'all', v_limit, 0) a;

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', o.id, 'name', o.name, 'status', o.status, 'owner_name', o.owner_name,
           'closed', o.closed_at is not null)), '[]'::jsonb)
    into v_organizations
    from public.admin_organizations(v_query, null, v_limit, 0) o;

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', e.id, 'title', e.title, 'status', e.status, 'starts_at', e.starts_at,
           'organization_name', e.organization_name)), '[]'::jsonb)
    into v_events
    from public.admin_events(p_search => v_query, p_limit => v_limit) e;

  -- La recherche de tickets demande au moins 3 caractères.
  if char_length(v_query) >= 3 then
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', t.id, 'reference', t.public_reference, 'status', t.status,
             'holder_name', t.holder_name, 'event_title', t.event_title)), '[]'::jsonb)
      into v_tickets
      from public.admin_find_tickets(v_query, v_limit) t;
  end if;

  return jsonb_build_object(
    'accounts', v_accounts,
    'organizations', v_organizations,
    'events', v_events,
    'tickets', v_tickets);
end;
$$;
revoke all on function public.admin_global_search(text, integer) from public, anon;
grant execute on function public.admin_global_search(text, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Annonces réservées (structure ou événement)
-- -----------------------------------------------------------------------------
alter table public.announcements
  add column organization_id uuid references public.organizations (id) on delete cascade,
  add column event_id uuid references public.events (id) on delete cascade;
alter table public.announcements drop constraint announcements_audiences_check;
alter table public.announcements add constraint announcements_target_check check (
  (organization_id is null and event_id is null
   and cardinality(audiences) between 1 and 4
   and audiences <@ array['visitors', 'users', 'promoters', 'controllers'])
  or (num_nonnulls(organization_id, event_id) = 1 and cardinality(audiences) = 0)
);
create index announcements_organization_idx on public.announcements (organization_id)
  where organization_id is not null;
create index announcements_event_idx on public.announcements (event_id)
  where event_id is not null;

-- Notification d'une annonce générale importante (corps de 4700) ; une
-- annonce réservée part par la fonction d'envoi, compte par compte.
create or replace function private.push_on_announcement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.starts_at <= now() then
    if new.level = 'important' and new.organization_id is null and new.event_id is null then
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

create or replace function private.push_due_announcements(p_now timestamptz)
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
    returning a.title, a.body, a.audiences, a.level, a.organization_id, a.event_id
  ), queued as (
    insert into public.push_outbox (topic_condition, title, body, route)
    select (select string_agg(format('''tikeo_%s'' in topics', x), ' || ' order by x)
              from unnest(d.audiences) x),
           d.title, left(d.body, 240), '/'
      from due d
     where d.level = 'important' and d.organization_id is null and d.event_id is null
    returning 1
  )
  select count(*) into v_count from queued;
  return v_count;
end;
$$;

-- Bandeaux de l'appelant : annonces générales selon ses rôles, et annonces
-- réservées à ses structures ou aux événements dont il a un ticket.
create or replace function public.my_announcements()
returns table (
  id uuid, title text, body text, level text, starts_at timestamptz, ends_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select a.id, a.title, a.body, a.level, a.starts_at, a.ends_at
    from public.announcements a
   where a.archived_at is null
     and a.starts_at <= now()
     and (a.ends_at is null or a.ends_at > now())
     and (
       (a.organization_id is null and a.event_id is null
        and a.audiences && private.my_audiences())
       or (a.organization_id is not null and exists (
             select 1 from public.organization_members m
              where m.organization_id = a.organization_id
                and m.user_id = auth.uid() and m.active))
       or (a.event_id is not null and exists (
             select 1 from public.tickets t
              where t.event_id = a.event_id
                and t.holder_user_id = auth.uid()
                and t.status <> 'revoked'))
     )
   order by (a.organization_id is not null or a.event_id is not null) desc,
            (a.level = 'important') desc, a.starts_at desc
   limit 5
$$;

-- Liste de la console : destinataire réservé en plus (drop + create).
drop function public.admin_announcements(integer, integer);
create function public.admin_announcements(p_limit integer default 50, p_offset integer default 0)
returns table (
  id uuid, title text, body text, audiences text[], level text,
  starts_at timestamptz, ends_at timestamptz, archived_at timestamptz,
  active boolean, author_name text, scheduled boolean,
  target_kind text, target_id uuid, target_name text
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
         a.archived_at is null and a.starts_at > now(),
         case when a.organization_id is not null then 'organization'
              when a.event_id is not null then 'event' end,
         coalesce(a.organization_id, a.event_id),
         coalesce(o.name, e.title)
    from public.announcements a
    join public.profiles p on p.id = a.created_by
    left join public.organizations o on o.id = a.organization_id
    left join public.events e on e.id = a.event_id
   order by a.created_at desc, a.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_announcements(integer, integer) from public, anon;
grant execute on function public.admin_announcements(integer, integer) to authenticated;

-- Modification d'une annonce programmée (corps de 4700) : jamais une annonce
-- réservée (elle part tout de suite). Permission `announcements` reposée.
create or replace function public.admin_update_announcement(
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
set application_name = 'tikeo.perm:announcements'
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
  if v_row.organization_id is not null or v_row.event_id is not null then
    raise exception 'announcement_targeted'
      using errcode = '55000', detail = 'Un message réservé ne se modifie pas : archivez-le.';
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
  perform private.push_due_announcements(now());
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.announcement_updated', 'announcement', p_announcement_id,
          jsonb_build_object('audiences', to_jsonb(v_audiences), 'level', coalesce(p_level, 'info')));
end;
$$;

-- Envoi d'un message ciblé. Permission `support` ou `announcements`.
create function public.admin_send_message(
  p_target_kind text,
  p_target_id uuid,
  p_title text,
  p_body text,
  p_days integer default 7
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_title text := private.clean_support_text(p_title, 3, 80, 'message_title_invalid');
  v_body text := private.clean_support_text(p_body, 1, 1000, 'message_body_invalid');
  v_recipients uuid[];
  v_request uuid;
  v_announcement uuid;
  v_org uuid;
  v_event public.events%rowtype;
  v_route text := '/';
begin
  perform private.require_platform_admin();
  if not (private.admin_can('support') or private.admin_can('announcements')) then
    raise exception 'admin_role_forbidden'
      using errcode = '42501', detail = 'Votre rôle d''administration ne permet pas cette action.';
  end if;
  if p_days is null or p_days not between 1 and 30 then
    raise exception 'message_days_invalid'
      using errcode = '22023', detail = 'Durée d''affichage de 1 à 30 jours.';
  end if;

  if p_target_kind = 'account' then
    if p_target_id = auth.uid() then
      raise exception 'self_forbidden'
        using errcode = '42501', detail = 'Vous ne pouvez pas vous écrire.';
    end if;
    if not exists (select 1 from public.profiles p
                    where p.id = p_target_id and p.deleted_at is null) then
      raise exception 'account_not_found' using errcode = 'P0002', detail = 'Compte introuvable.';
    end if;
    -- Conversation ouverte par l'équipe : notification par le déclencheur
    -- du support, réponse possible depuis « Support ».
    insert into public.support_requests (user_id, subject, category, status, user_unread, admin_unread)
    values (p_target_id, v_title, 'other', 'answered', true, false)
    returning id into v_request;
    insert into public.support_messages (request_id, author_id, from_admin, body)
    values (v_request, auth.uid(), true, v_body);
    perform private.log_admin_action('admin.message_sent', 'account', p_target_id, 'message',
      jsonb_build_object('audience', 'account', 'recipients', 1));
    return jsonb_build_object('recipients', 1, 'request_id', v_request);
  elsif p_target_kind = 'organization' then
    v_org := (private.lock_console_organization(p_target_id)).id;
    select array_agg(m.user_id) into v_recipients
      from public.organization_members m
      join public.profiles p on p.id = m.user_id and p.deleted_at is null
     where m.organization_id = v_org and m.active;
  elsif p_target_kind = 'event' then
    v_event := private.lock_console_event(p_target_id);
    v_org := v_event.organization_id;
    v_route := '/portefeuille';
    select array_agg(distinct t.holder_user_id) into v_recipients
      from public.tickets t
      join public.profiles p on p.id = t.holder_user_id and p.deleted_at is null
     where t.event_id = v_event.id and t.status <> 'revoked';
  else
    raise exception 'message_target_invalid'
      using errcode = '22023', detail = 'Destinataire inconnu.';
  end if;

  if coalesce(cardinality(v_recipients), 0) = 0 then
    raise exception 'message_no_recipients'
      using errcode = '55000',
            detail = 'Aucun destinataire : personne n''a de compte relié (« Mes tickets » ou membre actif).';
  end if;

  insert into public.announcements (title, body, audiences, level, starts_at, ends_at, created_by,
                                    organization_id, event_id)
  values (v_title, v_body, '{}', 'info', now(), now() + make_interval(days => p_days), auth.uid(),
          case when p_target_kind = 'organization' then v_org end,
          case when p_target_kind = 'event' then v_event.id end)
  returning id into v_announcement;

  insert into public.push_outbox (user_id, title, body, route)
  select r, v_title, left(v_body, 240), v_route from unnest(v_recipients) r;

  perform private.log_admin_action('admin.message_sent', p_target_kind, p_target_id, 'message',
    jsonb_build_object('audience', case p_target_kind when 'organization' then 'members' else 'holders' end,
                       'recipients', cardinality(v_recipients)), v_org);
  return jsonb_build_object('recipients', cardinality(v_recipients),
                            'announcement_id', v_announcement);
end;
$$;
revoke all on function public.admin_send_message(text, uuid, text, text, integer) from public, anon;
grant execute on function public.admin_send_message(text, uuid, text, text, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Journal filtrable (drop + create : filtres et auteur en plus ; les
--    anciennes APK appellent avec les trois premiers paramètres)
-- -----------------------------------------------------------------------------
drop function public.admin_audit_logs(text, integer, integer);
create function public.admin_audit_logs(
  p_action_prefix text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_actor_id uuid default null,
  p_account_id uuid default null,
  p_organization_id uuid default null,
  p_event_id uuid default null
)
returns table (
  id uuid,
  created_at timestamptz,
  action text,
  resource_type text,
  resource_id uuid,
  organization_id uuid,
  organization_name text,
  actor_name text,
  details jsonb,
  actor_id uuid
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_prefix text := nullif(trim(coalesce(p_action_prefix, '')), '');
begin
  perform private.require_platform_admin();
  if p_limit is null or p_limit not between 1 and 100 or p_offset is null or p_offset < 0 then
    raise exception 'page_invalid' using errcode = '22023', detail = 'Page invalide.';
  end if;
  return query
  select a.id, a.created_at, a.action, a.resource_type, a.resource_id, a.organization_id,
         o.name, pr.display_name, a.details, a.actor_id
    from public.audit_logs a
    left join public.organizations o on o.id = a.organization_id
    left join public.profiles pr on pr.id = a.actor_id
   where (v_prefix is null or a.action like v_prefix || '%')
     and (p_actor_id is null or a.actor_id = p_actor_id)
     and (p_account_id is null
          or a.actor_id = p_account_id
          or (a.resource_type in ('account', 'profile') and a.resource_id = p_account_id))
     and (p_organization_id is null
          or a.organization_id = p_organization_id
          or (a.resource_type = 'organization' and a.resource_id = p_organization_id))
     and (p_event_id is null
          or (a.resource_type = 'event' and a.resource_id = p_event_id)
          or (a.resource_type = 'ticket' and exists (
                select 1 from public.tickets t
                 where t.id = a.resource_id and t.event_id = p_event_id)))
   order by a.created_at desc, a.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_audit_logs(text, integer, integer, uuid, uuid, uuid, uuid)
  from public, anon;
grant execute on function public.admin_audit_logs(text, integer, integer, uuid, uuid, uuid, uuid)
  to authenticated;
