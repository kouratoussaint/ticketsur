-- =============================================================================
-- Tikéo — Migration 1900 : console d'administration de la plateforme (lot 3a)
-- =============================================================================
-- Décision de Toussaint (19/11/2026, ADR 0013) : la console est un espace
-- réservé de l'application Android, visible des seuls administrateurs de la
-- plateforme (`profiles.is_platform_admin`, déjà présent depuis 0100).
--
-- * Le rôle ne s'attribue jamais depuis l'application : uniquement en SQL,
--   par le propriétaire de la base (tableau de bord Supabase).
-- * Chaque fonction `admin_*` vérifie le rôle côté serveur ; un compte
--   désactivé perd ses droits d'administrateur.
-- * Chaque action est tracée dans `audit_logs` (`admin.*`), sans donnée
--   personnelle ni motif libre : le motif reste sur la ligne concernée.
-- =============================================================================

-- Modération du catalogue public : un événement retiré par la plateforme ne
-- peut plus être rendu public par son organisateur.
alter table public.events
  add column public_blocked_at timestamptz,
  add column public_blocked_reason text
    check (public_blocked_reason is null or char_length(public_blocked_reason) <= 500);

-- Suspension d'une organisation : `status = 'disabled'` (existant) coupe déjà
-- tous les droits d'organisateur et de contrôleur (`private.has_org_role`).
alter table public.organizations
  add column disabled_at timestamptz,
  add column disabled_reason text
    check (disabled_reason is null or char_length(disabled_reason) <= 500);

-- -----------------------------------------------------------------------------
-- Habilitation
-- -----------------------------------------------------------------------------
create function private.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.is_platform_admin and p.status = 'active'
  )
$$;
revoke all on function private.is_platform_admin() from public, anon, authenticated;

create function private.require_platform_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'forbidden'
      using errcode = '42501', detail = 'Réservé aux administrateurs de Tikéo.';
  end if;
end;
$$;
revoke all on function private.require_platform_admin() from public, anon, authenticated;

-- L'application s'en sert pour montrer (ou non) l'entrée « Console ».
create function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_platform_admin()
$$;
revoke all on function public.is_platform_admin() from public, anon;
grant execute on function public.is_platform_admin() to authenticated;

-- -----------------------------------------------------------------------------
-- Vue d'ensemble
-- -----------------------------------------------------------------------------
create function public.admin_overview()
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
        'total', count(*),
        'disabled', count(*) filter (where p.status = 'disabled'),
        'deletion_requested', count(*) filter (where p.deletion_requested_at is not null),
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
        'redeemed', count(*) filter (where t.status = 'redeemed'),
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
revoke all on function public.admin_overview() from public, anon;
grant execute on function public.admin_overview() to authenticated;

-- -----------------------------------------------------------------------------
-- Organisations
-- -----------------------------------------------------------------------------
create function public.admin_organizations(
  p_search text default null,
  p_status public.account_status default null,
  p_limit integer default 30,
  p_offset integer default 0
)
returns table (
  id uuid,
  name text,
  slug text,
  status public.account_status,
  created_at timestamptz,
  owner_name text,
  members integer,
  events integer,
  tickets integer,
  last_event_at timestamptz,
  disabled_at timestamptz,
  disabled_reason text
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
  return query
  select o.id, o.name, o.slug, o.status, o.created_at,
         pr.display_name,
         (select count(*)::integer from public.organization_members m
           where m.organization_id = o.id and m.active),
         (select count(*)::integer from public.events e where e.organization_id = o.id),
         (select count(*)::integer from public.tickets t
           join public.events e on e.id = t.event_id where e.organization_id = o.id),
         (select max(e.starts_at) from public.events e where e.organization_id = o.id),
         o.disabled_at, o.disabled_reason
    from public.organizations o
    join public.profiles pr on pr.id = o.owner_id
   where (p_status is null or o.status = p_status)
     and (v_search is null
          or private.fold(o.name) like '%' || v_search || '%'
          or o.slug like '%' || v_search || '%')
   order by o.created_at desc, o.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_organizations(text, public.account_status, integer, integer) from public, anon;
grant execute on function public.admin_organizations(text, public.account_status, integer, integer) to authenticated;

create function public.admin_set_organization_status(
  p_organization_id uuid,
  p_status public.account_status,
  p_reason text default null
)
returns public.organizations
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
  v_org public.organizations%rowtype;
begin
  perform private.require_platform_admin();
  if p_status is null then
    raise exception 'status_invalid' using errcode = '22023', detail = 'Statut manquant.';
  end if;
  if p_status = 'disabled' and v_reason is null then
    raise exception 'reason_required'
      using errcode = '22023', detail = 'Indiquez le motif de la suspension.';
  end if;
  if char_length(v_reason) > 500 then
    raise exception 'reason_too_long' using errcode = '22023', detail = 'Motif trop long (500 caractères au plus).';
  end if;
  select * into v_org from public.organizations o where o.id = p_organization_id for update;
  if not found then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Organisation introuvable.';
  end if;
  update public.organizations o
     set status = p_status,
         disabled_at = case when p_status = 'disabled' then coalesce(o.disabled_at, now()) end,
         disabled_reason = case when p_status = 'disabled' then v_reason end,
         updated_at = now()
   where o.id = p_organization_id
  returning * into v_org;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org.id, auth.uid(), 'admin.organization_status_changed', 'organization', v_org.id,
          jsonb_build_object('status', p_status));
  return v_org;
end;
$$;
revoke all on function public.admin_set_organization_status(uuid, public.account_status, text) from public, anon;
grant execute on function public.admin_set_organization_status(uuid, public.account_status, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Modération du catalogue public
-- -----------------------------------------------------------------------------
create or replace function private.is_listed(p_event public.events)
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_event.is_public
     and p_event.public_blocked_at is null
     and p_event.status in ('published', 'in_progress')
     and p_event.ends_at > now()
     and exists (select 1 from public.organizations o
                 where o.id = p_event.organization_id and o.status = 'active')
$$;
revoke all on function private.is_listed(public.events) from public, anon, authenticated;

-- Événements publics (ou retirés par la plateforme), du plus proche au plus
-- lointain ; les retirés d'abord quand `p_blocked_only`.
create function public.admin_public_events(
  p_search text default null,
  p_blocked_only boolean default false,
  p_limit integer default 30,
  p_offset integer default 0
)
returns table (
  id uuid,
  title text,
  organization_id uuid,
  organization_name text,
  kind public.event_kind,
  status public.event_status,
  starts_at timestamptz,
  ends_at timestamptz,
  city text,
  cover_path text,
  description text,
  listed boolean,
  blocked_at timestamptz,
  blocked_reason text
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
  return query
  select e.id, e.title, o.id, o.name, e.kind, e.status, e.starts_at, e.ends_at, e.city,
         e.cover_path, e.description, private.is_listed(e), e.public_blocked_at,
         e.public_blocked_reason
    from public.events e
    join public.organizations o on o.id = e.organization_id
   where (e.is_public or e.public_blocked_at is not null)
     and (not coalesce(p_blocked_only, false) or e.public_blocked_at is not null)
     and (v_search is null
          or private.fold(e.title) like '%' || v_search || '%'
          or private.fold(o.name) like '%' || v_search || '%'
          or private.fold(e.city) like '%' || v_search || '%')
   order by (e.ends_at < now()), e.starts_at, e.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_public_events(text, boolean, integer, integer) from public, anon;
grant execute on function public.admin_public_events(text, boolean, integer, integer) to authenticated;

create function public.admin_set_event_blocked(
  p_event_id uuid,
  p_blocked boolean,
  p_reason text default null
)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
  v_event public.events%rowtype;
begin
  perform private.require_platform_admin();
  if p_blocked is null then
    raise exception 'status_invalid' using errcode = '22023', detail = 'Choix manquant.';
  end if;
  if p_blocked and v_reason is null then
    raise exception 'reason_required'
      using errcode = '22023', detail = 'Indiquez le motif du retrait.';
  end if;
  if char_length(v_reason) > 500 then
    raise exception 'reason_too_long' using errcode = '22023', detail = 'Motif trop long (500 caractères au plus).';
  end if;
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    raise exception 'event_not_found' using errcode = 'P0002', detail = 'Événement introuvable.';
  end if;
  -- Retrait : l'événement quitte le catalogue. Rétablissement : l'organisateur
  -- peut de nouveau le rendre public ; rien n'est republié automatiquement.
  update public.events e
     set is_public = case when p_blocked then false else e.is_public end,
         public_blocked_at = case when p_blocked then coalesce(e.public_blocked_at, now()) end,
         public_blocked_reason = case when p_blocked then v_reason end,
         updated_at = now()
   where e.id = p_event_id
  returning * into v_event;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'admin.event_moderated', 'event', v_event.id,
          jsonb_build_object('blocked', p_blocked));
  return v_event;
end;
$$;
revoke all on function public.admin_set_event_blocked(uuid, boolean, text) from public, anon;
grant execute on function public.admin_set_event_blocked(uuid, boolean, text) to authenticated;

-- L'organisateur ne peut pas republier un événement retiré par la plateforme.
create or replace function public.set_event_public(p_event_id uuid, p_public boolean)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
begin
  if p_public is null then
    raise exception 'event_visibility_invalid'
      using errcode = '22023', detail = 'Visibilité manquante.';
  end if;
  v_event := private.lock_managed_event(p_event_id);
  if v_event.status in ('cancelled', 'archived') and p_public then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement annulé ou archivé.';
  end if;
  if p_public and v_event.public_blocked_at is not null then
    raise exception 'event_blocked'
      using errcode = '55000',
            detail = 'Cet événement a été retiré du catalogue par Tikéo. Contactez le support.';
  end if;
  update public.events e
     set is_public = p_public, updated_at = now()
   where e.id = p_event_id
  returning * into v_event;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'event.visibility_changed', 'event', v_event.id,
          jsonb_build_object('public', p_public));
  return v_event;
end;
$$;
revoke all on function public.set_event_public(uuid, boolean) from public, anon;
grant execute on function public.set_event_public(uuid, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Journal d'audit
-- -----------------------------------------------------------------------------
create index audit_logs_time_idx on public.audit_logs (created_at desc, id);

create function public.admin_audit_logs(
  p_action_prefix text default null,
  p_limit integer default 50,
  p_offset integer default 0
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
  details jsonb
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
         o.name, pr.display_name, a.details
    from public.audit_logs a
    left join public.organizations o on o.id = a.organization_id
    left join public.profiles pr on pr.id = a.actor_id
   where (v_prefix is null or a.action like v_prefix || '%')
   order by a.created_at desc, a.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_audit_logs(text, integer, integer) from public, anon;
grant execute on function public.admin_audit_logs(text, integer, integer) to authenticated;
