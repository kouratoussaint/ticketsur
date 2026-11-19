-- =============================================================================
-- Tikéo — Migration 2300 : support et annonces (lot 3a-3, ADR 0017)
-- =============================================================================
-- Décisions de Toussaint (19/11/2026) :
-- * support par formulaire dans l'application : l'utilisateur ouvre une
--   demande (sujet, catégorie, message), les administrateurs répondent depuis
--   la console, l'échange continue des deux côtés jusqu'à la fermeture ;
-- * annonces publiées depuis la console avec des destinataires choisis :
--   visiteurs sans compte, comptes classiques, promoteurs (propriétaires et
--   gestionnaires), contrôleurs.
--
-- Tables sans aucun accès direct (RLS sans politique) : tout passe par les
-- fonctions ci-dessous. Le contenu des messages n'entre jamais dans
-- `audit_logs`.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Support
-- -----------------------------------------------------------------------------
create table public.support_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  -- Structure active au moment de la demande (contexte), facultative.
  organization_id uuid references public.organizations (id),
  subject text not null check (char_length(subject) between 3 and 120),
  category text not null default 'other'
    check (category in ('question', 'problem', 'account', 'payment', 'other')),
  status text not null default 'open' check (status in ('open', 'answered', 'closed')),
  user_unread boolean not null default false,
  admin_unread boolean not null default true,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  closed_at timestamptz
);
create index support_requests_user_idx on public.support_requests (user_id, last_message_at desc);
create index support_requests_status_idx on public.support_requests (status, last_message_at desc);
alter table public.support_requests enable row level security;

create table public.support_messages (
  id uuid primary key default gen_random_uuid(),
  -- Ordre d'écriture, même à heure égale (une transaction).
  seq bigint generated always as identity,
  request_id uuid not null references public.support_requests (id) on delete cascade,
  author_id uuid not null references public.profiles (id),
  from_admin boolean not null,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index support_messages_request_idx on public.support_messages (request_id, seq);
alter table public.support_messages enable row level security;

-- Compte connecté et non supprimé (un compte désactivé peut écrire au support).
create function private.require_support_user()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null
     or not exists (select 1 from public.profiles p
                    where p.id = v_actor and p.deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501', detail = 'Connectez-vous pour contacter le support.';
  end if;
  return v_actor;
end;
$$;
revoke all on function private.require_support_user() from public, anon, authenticated;

create function private.clean_support_text(p_text text, p_min integer, p_max integer, p_code text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_text text := trim(coalesce(p_text, ''));
begin
  if char_length(v_text) < p_min or char_length(v_text) > p_max then
    raise exception '%', p_code
      using errcode = '22023',
            detail = format('Entre %s et %s caractères.', p_min, p_max);
  end if;
  return v_text;
end;
$$;
revoke all on function private.clean_support_text(text, integer, integer, text) from public, anon, authenticated;

-- Ouvre une demande ; 5 demandes non fermées au plus par compte.
create function public.create_support_request(
  p_subject text,
  p_category text,
  p_body text,
  p_organization_id uuid default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_support_user();
  v_subject text := private.clean_support_text(p_subject, 3, 120, 'support_subject_invalid');
  v_body text := private.clean_support_text(p_body, 1, 2000, 'support_body_invalid');
  v_category text := coalesce(nullif(trim(p_category), ''), 'other');
  v_org uuid;
  v_id uuid;
begin
  if v_category not in ('question', 'problem', 'account', 'payment', 'other') then
    raise exception 'support_category_invalid' using errcode = '22023', detail = 'Catégorie inconnue.';
  end if;
  if (select count(*) from public.support_requests r
       where r.user_id = v_actor and r.status <> 'closed') >= 5 then
    raise exception 'support_limit'
      using errcode = '54000',
            detail = 'Vous avez déjà 5 demandes en cours. Fermez-en une ou attendez une réponse.';
  end if;
  -- Structure retenue seulement si l'utilisateur en est membre.
  select m.organization_id into v_org from public.organization_members m
   where m.organization_id = p_organization_id and m.user_id = v_actor and m.active;
  insert into public.support_requests (user_id, organization_id, subject, category)
  values (v_actor, v_org, v_subject, v_category)
  returning id into v_id;
  insert into public.support_messages (request_id, author_id, from_admin, body)
  values (v_id, v_actor, false, v_body);
  return v_id;
end;
$$;
revoke all on function public.create_support_request(text, text, text, uuid) from public, anon;
grant execute on function public.create_support_request(text, text, text, uuid) to authenticated;

-- Demandes de l'utilisateur connecté.
create function public.my_support_requests()
returns table (
  id uuid, subject text, category text, status text, unread boolean,
  created_at timestamptz, last_message_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.id, r.subject, r.category, r.status, r.user_unread, r.created_at, r.last_message_at
    from public.support_requests r
   where r.user_id = auth.uid()
   order by (r.status = 'closed'), r.last_message_at desc
   limit 100
$$;
revoke all on function public.my_support_requests() from public, anon;
grant execute on function public.my_support_requests() to authenticated;

-- Fil d'une demande, pour son auteur ou un administrateur ; le marque lu
-- pour le lecteur.
create function public.support_thread(p_request_id uuid)
returns table (
  id uuid, from_admin boolean, author_name text, body text, created_at timestamptz
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_support_user();
  v_admin boolean := private.is_platform_admin();
  v_request public.support_requests%rowtype;
begin
  select * into v_request from public.support_requests r where r.id = p_request_id;
  if not found or (v_request.user_id <> v_actor and not v_admin) then
    raise exception 'support_not_found' using errcode = '42501', detail = 'Demande introuvable.';
  end if;
  if v_request.user_id = v_actor then
    update public.support_requests r set user_unread = false where r.id = p_request_id;
  end if;
  if v_admin and v_request.user_id <> v_actor then
    update public.support_requests r set admin_unread = false where r.id = p_request_id;
  end if;
  return query
  select m.id, m.from_admin,
         -- Côté utilisateur, l'équipe répond sous le nom « Support Tikéo ».
         case when m.from_admin and not v_admin then 'Support Tikéo' else p.display_name end,
         m.body, m.created_at
    from public.support_messages m
    join public.profiles p on p.id = m.author_id
   where m.request_id = p_request_id
   order by m.seq;
end;
$$;
revoke all on function public.support_thread(uuid) from public, anon;
grant execute on function public.support_thread(uuid) to authenticated;

-- Réponse de l'auteur ou d'un administrateur ; rouvre une demande fermée
-- quand l'auteur y répond.
create function public.reply_support_request(p_request_id uuid, p_body text)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_support_user();
  v_body text := private.clean_support_text(p_body, 1, 2000, 'support_body_invalid');
  v_request public.support_requests%rowtype;
  v_as_admin boolean;
  v_status text;
begin
  select * into v_request from public.support_requests r where r.id = p_request_id for update;
  v_as_admin := private.is_platform_admin() and found and v_request.user_id <> v_actor;
  if not found or (v_request.user_id <> v_actor and not v_as_admin) then
    raise exception 'support_not_found' using errcode = '42501', detail = 'Demande introuvable.';
  end if;
  if (select count(*) from public.support_messages m
       where m.author_id = v_actor and m.created_at > now() - interval '1 hour') >= 30 then
    raise exception 'support_rate_limited'
      using errcode = '54000', detail = 'Trop de messages : réessayez dans une heure.';
  end if;
  insert into public.support_messages (request_id, author_id, from_admin, body)
  values (p_request_id, v_actor, v_as_admin, v_body);
  update public.support_requests r
     set status = case when v_as_admin then 'answered' else 'open' end,
         user_unread = v_as_admin,
         admin_unread = not v_as_admin,
         last_message_at = now(),
         closed_at = null
   where r.id = p_request_id
  returning r.status into v_status;
  if v_as_admin then
    insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
    values (v_request.organization_id, v_actor, 'admin.support_replied', 'support_request',
            p_request_id, '{}'::jsonb);
  end if;
  return v_status;
end;
$$;
revoke all on function public.reply_support_request(uuid, text) from public, anon;
grant execute on function public.reply_support_request(uuid, text) to authenticated;

create function public.close_support_request(p_request_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_support_user();
  v_request public.support_requests%rowtype;
begin
  select * into v_request from public.support_requests r where r.id = p_request_id for update;
  if not found or (v_request.user_id <> v_actor and not private.is_platform_admin()) then
    raise exception 'support_not_found' using errcode = '42501', detail = 'Demande introuvable.';
  end if;
  update public.support_requests r
     set status = 'closed', closed_at = now(), user_unread = false, admin_unread = false
   where r.id = p_request_id;
end;
$$;
revoke all on function public.close_support_request(uuid) from public, anon;
grant execute on function public.close_support_request(uuid) to authenticated;

-- Console : demandes, les non lues et ouvertes d'abord.
create function public.admin_support_requests(
  p_status text default null,
  p_search text default null,
  p_limit integer default 30,
  p_offset integer default 0
)
returns table (
  id uuid, subject text, category text, status text, unread boolean,
  requester_name text, requester_email text, organization_name text,
  messages integer, created_at timestamptz, last_message_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_search text := nullif(private.fold(trim(coalesce(p_search, ''))), '');
begin
  perform private.require_platform_admin();
  if p_limit is null or p_limit not between 1 and 50 or p_offset is null or p_offset < 0 then
    raise exception 'page_invalid' using errcode = '22023', detail = 'Page invalide.';
  end if;
  if p_status is not null and p_status not in ('open', 'answered', 'closed') then
    raise exception 'filter_invalid' using errcode = '22023', detail = 'Filtre inconnu.';
  end if;
  return query
  select r.id, r.subject, r.category, r.status, r.admin_unread,
         p.display_name, u.email::text, o.name,
         (select count(*)::integer from public.support_messages m where m.request_id = r.id),
         r.created_at, r.last_message_at
    from public.support_requests r
    join public.profiles p on p.id = r.user_id
    left join auth.users u on u.id = r.user_id
    left join public.organizations o on o.id = r.organization_id
   where (p_status is null or r.status = p_status)
     and (v_search is null
          or private.fold(r.subject) like '%' || v_search || '%'
          or private.fold(p.display_name) like '%' || v_search || '%'
          or lower(coalesce(u.email::text, '')) like '%' || lower(trim(p_search)) || '%')
   order by r.admin_unread desc, (r.status = 'closed'), r.last_message_at desc, r.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_support_requests(text, text, integer, integer) from public, anon;
grant execute on function public.admin_support_requests(text, text, integer, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- Annonces
-- -----------------------------------------------------------------------------
create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 3 and 80),
  body text not null check (char_length(body) between 1 and 1000),
  -- visitors : sans compte ; users : comptes classiques (sans structure) ;
  -- promoters : propriétaires et gestionnaires ; controllers : contrôleurs.
  audiences text[] not null
    check (cardinality(audiences) between 1 and 4
           and audiences <@ array['visitors', 'users', 'promoters', 'controllers']),
  level text not null default 'info' check (level in ('info', 'important')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  archived_at timestamptz,
  check (ends_at is null or ends_at > starts_at)
);
create index announcements_active_idx on public.announcements (starts_at desc)
  where archived_at is null;
alter table public.announcements enable row level security;

-- Destinataires de l'appelant : visiteur, ou ses rôles actifs.
create function private.my_audiences()
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when auth.uid() is null then array['visitors']
    else coalesce(
      (select array_agg(distinct case when m.role = 'controller' then 'controllers' else 'promoters' end)
         from public.organization_members m
         join public.organizations o on o.id = m.organization_id
         join public.profiles p on p.id = m.user_id
        where m.user_id = auth.uid() and m.active and o.status = 'active' and p.status = 'active'),
      array['users'])
  end
$$;
revoke all on function private.my_audiences() from public, anon, authenticated;

-- Annonces en cours pour l'appelant (avec ou sans compte).
create function public.my_announcements()
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
     and a.audiences && private.my_audiences()
   order by (a.level = 'important') desc, a.starts_at desc
   limit 5
$$;
revoke all on function public.my_announcements() from public;
grant execute on function public.my_announcements() to anon, authenticated;

create function public.admin_publish_announcement(
  p_title text,
  p_body text,
  p_audiences text[],
  p_level text default 'info',
  p_ends_at timestamptz default null
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
  v_id uuid;
begin
  perform private.require_platform_admin();
  select array_agg(distinct a order by a) into v_audiences from unnest(p_audiences) a;
  if v_audiences is null or cardinality(v_audiences) = 0
     or not v_audiences <@ array['visitors', 'users', 'promoters', 'controllers'] then
    raise exception 'announcement_audience_invalid'
      using errcode = '22023', detail = 'Choisissez au moins un destinataire.';
  end if;
  if coalesce(p_level, 'info') not in ('info', 'important') then
    raise exception 'announcement_level_invalid' using errcode = '22023', detail = 'Importance inconnue.';
  end if;
  if p_ends_at is not null and p_ends_at <= now() then
    raise exception 'announcement_dates_invalid'
      using errcode = '22023', detail = 'La fin doit être dans le futur.';
  end if;
  insert into public.announcements (title, body, audiences, level, ends_at, created_by)
  values (v_title, v_body, v_audiences, coalesce(p_level, 'info'), p_ends_at, auth.uid())
  returning id into v_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.announcement_published', 'announcement', v_id,
          jsonb_build_object('audiences', to_jsonb(v_audiences), 'level', coalesce(p_level, 'info')));
  return v_id;
end;
$$;
revoke all on function public.admin_publish_announcement(text, text, text[], text, timestamptz) from public, anon;
grant execute on function public.admin_publish_announcement(text, text, text[], text, timestamptz) to authenticated;

create function public.admin_archive_announcement(p_announcement_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  update public.announcements a
     set archived_at = coalesce(a.archived_at, now())
   where a.id = p_announcement_id;
  if not found then
    raise exception 'announcement_not_found' using errcode = 'P0002', detail = 'Annonce introuvable.';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.announcement_archived', 'announcement', p_announcement_id, '{}'::jsonb);
end;
$$;
revoke all on function public.admin_archive_announcement(uuid) from public, anon;
grant execute on function public.admin_archive_announcement(uuid) to authenticated;

create function public.admin_announcements(p_limit integer default 50, p_offset integer default 0)
returns table (
  id uuid, title text, body text, audiences text[], level text,
  starts_at timestamptz, ends_at timestamptz, archived_at timestamptz,
  active boolean, author_name text
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
         p.display_name
    from public.announcements a
    join public.profiles p on p.id = a.created_by
   order by a.created_at desc, a.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_announcements(integer, integer) from public, anon;
grant execute on function public.admin_announcements(integer, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- Vue d'ensemble : demandes de support (ajout compatible)
-- -----------------------------------------------------------------------------
create function public.admin_support_counts()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return (
    select jsonb_build_object(
      'open', count(*) filter (where r.status = 'open'),
      'unread', count(*) filter (where r.admin_unread and r.status <> 'closed'),
      'answered', count(*) filter (where r.status = 'answered'))
    from public.support_requests r);
end;
$$;
revoke all on function public.admin_support_counts() from public, anon;
grant execute on function public.admin_support_counts() to authenticated;
