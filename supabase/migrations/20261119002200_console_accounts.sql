-- =============================================================================
-- Tikéo — Migration 2200 : comptes dans la console (lot 3a-2)
-- =============================================================================
-- * Liste et recherche des comptes (nom, adresse), désactivation avec motif,
--   réactivation. Un compte désactivé perd tous ses droits dans ses
--   structures (`private.has_org_role` exige un profil actif).
-- * Suppression définitive des comptes dont la suppression a été demandée il
--   y a 30 jours au moins (ADR 0015, ADR 0016) :
--   - les structures dont il est propriétaire sont SUSPENDUES ;
--   - le profil est anonymisé (« Compte supprimé »), ses appartenances et
--     affectations désactivées ;
--   - le compte d'authentification est vidé (adresse remplacée, identités et
--     sessions effacées, compte banni) : plus aucune connexion possible.
--   Les lignes ne sont pas effacées : tickets, scans et journaux gardent
--   leur auteur, désormais anonyme.
-- * Le journal ne contient que des effets (statut, nombre de structures
--   suspendues) : ni nom, ni adresse, ni motif.
-- =============================================================================

alter table public.profiles
  add column disabled_at timestamptz,
  add column disabled_reason text
    check (disabled_reason is null or char_length(disabled_reason) <= 500),
  add column deleted_at timestamptz;

-- Délai entre la demande de suppression et la suppression définitive.
create function private.account_deletion_delay()
returns interval
language sql
immutable
set search_path = ''
as $$ select interval '30 days' $$;
revoke all on function private.account_deletion_delay() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Vue d'ensemble : comptes supprimés et à supprimer (ajouts compatibles)
-- -----------------------------------------------------------------------------
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
-- Liste des comptes
-- -----------------------------------------------------------------------------
-- p_filter : 'all' | 'disabled' | 'deletion' (demandée, pas encore faite) |
--            'due' (échéance passée) | 'deleted'.
create function public.admin_accounts(
  p_search text default null,
  p_filter text default 'all',
  p_limit integer default 30,
  p_offset integer default 0
)
returns table (
  id uuid,
  display_name text,
  email text,
  status public.account_status,
  is_platform_admin boolean,
  created_at timestamptz,
  last_sign_in_at timestamptz,
  deletion_requested_at timestamptz,
  deletion_due_at timestamptz,
  deleted_at timestamptz,
  disabled_at timestamptz,
  disabled_reason text,
  memberships integer,
  owned_structures integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_search text := nullif(private.fold(trim(coalesce(p_search, ''))), '');
  v_filter text := coalesce(nullif(trim(p_filter), ''), 'all');
begin
  perform private.require_platform_admin();
  if p_limit is null or p_limit not between 1 and 50 or p_offset is null or p_offset < 0 then
    raise exception 'page_invalid' using errcode = '22023', detail = 'Page invalide.';
  end if;
  if v_filter not in ('all', 'disabled', 'deletion', 'due', 'deleted') then
    raise exception 'filter_invalid' using errcode = '22023', detail = 'Filtre inconnu.';
  end if;
  return query
  select p.id, p.display_name, u.email::text, p.status, p.is_platform_admin, p.created_at,
         u.last_sign_in_at, p.deletion_requested_at,
         p.deletion_requested_at + private.account_deletion_delay(),
         p.deleted_at, p.disabled_at, p.disabled_reason,
         (select count(*)::integer from public.organization_members m
           where m.user_id = p.id and m.active),
         (select count(*)::integer from public.organizations o where o.owner_id = p.id)
    from public.profiles p
    left join auth.users u on u.id = p.id
   where (v_search is null
          or private.fold(p.display_name) like '%' || v_search || '%'
          or lower(coalesce(u.email::text, '')) like '%' || lower(trim(p_search)) || '%')
     and case v_filter
           when 'disabled' then p.status = 'disabled' and p.deleted_at is null
           when 'deletion' then p.deletion_requested_at is not null and p.deleted_at is null
           when 'due' then p.deleted_at is null
                       and p.deletion_requested_at <= now() - private.account_deletion_delay()
           when 'deleted' then p.deleted_at is not null
           else true
         end
   order by p.created_at desc, p.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_accounts(text, text, integer, integer) from public, anon;
grant execute on function public.admin_accounts(text, text, integer, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- Désactivation et réactivation
-- -----------------------------------------------------------------------------
create function public.admin_set_account_status(
  p_user_id uuid,
  p_status public.account_status,
  p_reason text default null
)
returns public.account_status
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
  v_profile public.profiles%rowtype;
begin
  perform private.require_platform_admin();
  if p_status is null then
    raise exception 'status_invalid' using errcode = '22023', detail = 'Statut manquant.';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'self_forbidden'
      using errcode = '42501', detail = 'Vous ne pouvez pas modifier votre propre compte ici.';
  end if;
  if p_status = 'disabled' and v_reason is null then
    raise exception 'reason_required'
      using errcode = '22023', detail = 'Indiquez le motif de la désactivation.';
  end if;
  if char_length(v_reason) > 500 then
    raise exception 'reason_too_long' using errcode = '22023', detail = 'Motif trop long (500 caractères au plus).';
  end if;
  select * into v_profile from public.profiles p where p.id = p_user_id for update;
  if not found then
    raise exception 'account_not_found' using errcode = 'P0002', detail = 'Compte introuvable.';
  end if;
  if v_profile.deleted_at is not null then
    raise exception 'account_deleted' using errcode = '55000', detail = 'Ce compte a été supprimé.';
  end if;
  update public.profiles p
     set status = p_status,
         disabled_at = case when p_status = 'disabled' then coalesce(p.disabled_at, now()) end,
         disabled_reason = case when p_status = 'disabled' then v_reason end,
         updated_at = now()
   where p.id = p_user_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.account_status_changed', 'account', p_user_id,
          jsonb_build_object('status', p_status));
  return p_status;
end;
$$;
revoke all on function public.admin_set_account_status(uuid, public.account_status, text) from public, anon;
grant execute on function public.admin_set_account_status(uuid, public.account_status, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Suppression définitive
-- -----------------------------------------------------------------------------
-- Vide le compte d'authentification. Les colonnes et tables propres à
-- Supabase Auth sont traitées seulement si elles existent (base de test).
create function private.scrub_auth_user(p_user_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_column text;
begin
  update auth.users u
     set email = 'supprime-' || p_user_id || '@supprime.invalid',
         raw_user_meta_data = '{}'::jsonb
   where u.id = p_user_id;
  foreach v_column in array array['phone', 'encrypted_password'] loop
    if exists (select 1 from information_schema.columns c
               where c.table_schema = 'auth' and c.table_name = 'users'
                 and c.column_name = v_column) then
      execute format('update auth.users set %I = null where id = $1', v_column) using p_user_id;
    end if;
  end loop;
  if exists (select 1 from information_schema.columns c
             where c.table_schema = 'auth' and c.table_name = 'users'
               and c.column_name = 'banned_until') then
    execute 'update auth.users set banned_until = ''infinity'' where id = $1' using p_user_id;
  end if;
  if to_regclass('auth.sessions') is not null then
    execute 'delete from auth.sessions where user_id = $1' using p_user_id;
  end if;
  if to_regclass('auth.identities') is not null then
    execute 'delete from auth.identities where user_id = $1' using p_user_id;
  end if;
end;
$$;
revoke all on function private.scrub_auth_user(uuid) from public, anon, authenticated;

-- Supprime un compte arrivé à échéance ; renvoie le nombre de structures
-- suspendues.
create function private.purge_account(p_user_id uuid)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
  v_org record;
  v_suspended integer := 0;
begin
  select * into v_profile from public.profiles p where p.id = p_user_id for update;
  if not found then
    raise exception 'account_not_found' using errcode = 'P0002', detail = 'Compte introuvable.';
  end if;
  if v_profile.deleted_at is not null then
    raise exception 'account_deleted' using errcode = '55000', detail = 'Ce compte est déjà supprimé.';
  end if;
  if v_profile.deletion_requested_at is null
     or v_profile.deletion_requested_at > now() - private.account_deletion_delay() then
    raise exception 'deletion_not_due'
      using errcode = '55000',
            detail = 'La suppression n''est possible que 30 jours après la demande.';
  end if;
  if v_profile.is_platform_admin then
    raise exception 'account_is_admin'
      using errcode = '55000', detail = 'Retirez d''abord le rôle d''administrateur.';
  end if;

  -- Structures du propriétaire : suspendues (ADR 0015).
  for v_org in
    select o.id from public.organizations o
     where o.owner_id = p_user_id and o.status = 'active'
     for update
  loop
    update public.organizations o
       set status = 'disabled', disabled_at = now(),
           disabled_reason = 'Compte du propriétaire supprimé.', updated_at = now()
     where o.id = v_org.id;
    insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
    values (v_org.id, auth.uid(), 'admin.organization_status_changed', 'organization', v_org.id,
            jsonb_build_object('status', 'disabled', 'cause', 'owner_deleted'));
    v_suspended := v_suspended + 1;
  end loop;

  update public.organization_members m set active = false where m.user_id = p_user_id;
  update public.event_assignments a set active = false where a.user_id = p_user_id;
  update public.profiles p
     set display_name = 'Compte supprimé', avatar_path = null, phone = null,
         status = 'disabled', disabled_at = coalesce(p.disabled_at, now()),
         disabled_reason = null, deleted_at = now(), updated_at = now()
   where p.id = p_user_id;
  perform private.scrub_auth_user(p_user_id);

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.account_purged', 'account', p_user_id,
          jsonb_build_object('structures_suspended', v_suspended));
  return v_suspended;
end;
$$;
revoke all on function private.purge_account(uuid) from public, anon, authenticated;

create function public.admin_purge_account(p_user_id uuid)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return private.purge_account(p_user_id);
end;
$$;
revoke all on function public.admin_purge_account(uuid) from public, anon;
grant execute on function public.admin_purge_account(uuid) to authenticated;

-- Tous les comptes arrivés à échéance (hors administrateurs).
create function public.admin_purge_due_accounts()
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user uuid;
  v_accounts integer := 0;
  v_structures integer := 0;
begin
  perform private.require_platform_admin();
  for v_user in
    select p.id from public.profiles p
     where p.deleted_at is null and not p.is_platform_admin
       and p.deletion_requested_at <= now() - private.account_deletion_delay()
     order by p.deletion_requested_at
  loop
    v_structures := v_structures + private.purge_account(v_user);
    v_accounts := v_accounts + 1;
  end loop;
  return jsonb_build_object('accounts', v_accounts, 'structures_suspended', v_structures);
end;
$$;
revoke all on function public.admin_purge_due_accounts() from public, anon;
grant execute on function public.admin_purge_due_accounts() to authenticated;
