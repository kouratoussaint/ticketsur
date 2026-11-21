-- =============================================================================
-- Tikéo — Migration 4900 : rôles d'administration et gestion des comptes
-- (lot 4-11a, ADR 0038)
-- =============================================================================
-- Décisions de Toussaint (21/11, `claude/proposition-console-admin.md`) :
--   * 4 rôles : super (tout), support, modération, finance ;
--   * double authentification exigée pour créer ou supprimer un compte et
--     donner ou retirer un rôle d'administration ;
--   * prévenir la personne concernée : non par défaut, réglable ;
--   * émettre des tickets à la place d'un promoteur : non par défaut,
--     réglable (utilisé au lot 4-11c).
--
-- Rôles : `private.platform_admin_roles`. Un administrateur posé à la main
-- (`profiles.is_platform_admin = true` sans ligne de rôle) est super.
-- Permissions des fonctions existantes de la console : paramètre de
-- fonction `tikeo.admin_permission`, lu par `private.require_platform_admin()`
-- et `private.is_platform_admin()` ; sans paramètre : lecture, ouverte à
-- tout administrateur.
--
-- Motifs : `private.admin_action_log` (jamais dans audit_logs, que le
-- propriétaire d'une structure peut lire en partie).
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   42501 admin_role_forbidden | admin_mfa_needed | account_admin_protected
--         | self_forbidden
--   22023 reason_required | reason_too_long | confirmation_mismatch
--         | admin_role_invalid | action_invalid | profile_name_invalid
--         | profile_phone_invalid
--   55000 last_super_admin | deletion_not_requested | account_not_new
--         | account_inactive
--   P0002 account_not_found
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Rôles et permissions
-- -----------------------------------------------------------------------------
create table private.platform_admin_roles (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  role text not null check (role in ('super', 'support', 'moderation', 'finance')),
  granted_by uuid references public.profiles (id) on delete set null,
  granted_at timestamptz not null default now()
);
revoke all on private.platform_admin_roles from public, anon, authenticated;

-- Administrateurs actuels : super.
insert into private.platform_admin_roles (user_id, role)
select p.id, 'super' from public.profiles p where p.is_platform_admin
on conflict do nothing;

-- Rôle d'un compte (null : pas administrateur actif).
create function private.admin_role_of(p_user uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case when p.is_platform_admin and p.status = 'active' and p.deleted_at is null
              then coalesce(r.role, 'super') end
    from public.profiles p
    left join private.platform_admin_roles r on r.user_id = p.id
   where p.id = p_user
$$;
revoke all on function private.admin_role_of(uuid) from public, anon, authenticated;

-- Permissions d'un rôle. Lecture des listes, fiches et journal : tous.
create function private.role_permissions(p_role text)
returns text[]
language sql
immutable
set search_path = ''
as $$
  select case p_role
    when 'super' then array['accounts', 'accounts_delete', 'organizations', 'org_status',
                            'events', 'tickets', 'catalog', 'announcements', 'support',
                            'billing', 'legal', 'admins', 'settings']
    when 'support' then array['accounts', 'organizations', 'org_status', 'tickets', 'support']
    when 'moderation' then array['org_status', 'events', 'catalog', 'announcements']
    when 'finance' then array['billing']
    else '{}'::text[]
  end
$$;
revoke all on function private.role_permissions(text) from public, anon, authenticated;

-- Permission de la fonction en cours (paramètre `tikeo.admin_permission`).
create function private.current_admin_permission()
returns text
language sql
stable
set search_path = ''
as $$
  select nullif(current_setting('tikeo.admin_permission', true), '')
$$;
revoke all on function private.current_admin_permission() from public, anon, authenticated;

-- Le compte connecté a-t-il cette permission ? (null : lecture, toujours vrai)
create function private.admin_can(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_permission is null
      or p_permission = any (private.role_permissions(private.admin_role_of(auth.uid())))
$$;
revoke all on function private.admin_can(text) from public, anon, authenticated;

-- Administrateur autorisé : compte actif, double authentification si
-- activée (4800), et permission de la fonction en cours.
create or replace function private.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_admin_account()
     and (not private.has_verified_factor(auth.uid()) or private.session_aal() = 'aal2')
     and private.admin_can(private.current_admin_permission())
$$;
revoke all on function private.is_platform_admin() from public, anon, authenticated;

create or replace function private.require_platform_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_admin_account() then
    raise exception 'forbidden'
      using errcode = '42501', detail = 'Réservé aux administrateurs de Tikéo.';
  end if;
  if private.has_verified_factor(auth.uid()) and private.session_aal() <> 'aal2' then
    raise exception 'mfa_required'
      using errcode = '42501', detail = 'Saisissez le code de double authentification.';
  end if;
  if not private.admin_can(private.current_admin_permission()) then
    raise exception 'admin_role_forbidden'
      using errcode = '42501', detail = 'Votre rôle d''administration ne permet pas cette action.';
  end if;
end;
$$;
revoke all on function private.require_platform_admin() from public, anon, authenticated;

-- Nouvelles fonctions : permission explicite.
create function private.require_admin(p_permission text)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  if not private.admin_can(p_permission) then
    raise exception 'admin_role_forbidden'
      using errcode = '42501', detail = 'Votre rôle d''administration ne permet pas cette action.';
  end if;
end;
$$;
revoke all on function private.require_admin(text) from public, anon, authenticated;

-- Actions sensibles : double authentification activée (décision 4).
create function private.require_admin_mfa()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.has_verified_factor(auth.uid()) then
    raise exception 'admin_mfa_needed'
      using errcode = '42501',
            detail = 'Activez la double authentification (Profil › Sécurité) pour cette action.';
  end if;
end;
$$;
revoke all on function private.require_admin_mfa() from public, anon, authenticated;

-- Permissions des fonctions existantes de la console.
do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as signature, m.permission
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
      join (values
        ('admin_set_account_status', 'accounts'),
        ('admin_purge_account', 'accounts'),
        ('admin_purge_due_accounts', 'accounts'),
        ('admin_assign_organization', 'organizations'),
        ('admin_set_organization_status', 'org_status'),
        ('admin_set_event_blocked', 'catalog'),
        ('admin_add_featured_event', 'catalog'),
        ('admin_move_featured_event', 'catalog'),
        ('admin_remove_featured_event', 'catalog'),
        ('admin_set_featured_period', 'catalog'),
        ('admin_publish_announcement', 'announcements'),
        ('admin_update_announcement', 'announcements'),
        ('admin_archive_announcement', 'announcements'),
        ('admin_save_support_template', 'support'),
        ('admin_delete_support_template', 'support'),
        ('support_thread', 'support'),
        ('reply_support_request', 'support'),
        ('close_support_request', 'support'),
        ('admin_activate_request', 'billing'),
        ('admin_refuse_request', 'billing'),
        ('admin_cancel_subscription', 'billing'),
        ('admin_change_subscription_pack', 'billing'),
        ('admin_extend_subscription', 'billing'),
        ('admin_grant_subscription', 'billing'),
        ('admin_issue_invoice', 'billing'),
        ('admin_mark_invoice_paid', 'billing'),
        ('admin_save_billing_settings', 'billing'),
        ('admin_save_pack', 'billing'),
        ('admin_set_pack_status', 'billing'),
        ('admin_set_subscription_addons', 'billing'),
        ('admin_set_event_billing', 'billing'),
        ('admin_save_legal_document', 'legal')
      ) as m (name, permission) on m.name = p.proname
  loop
    execute format('alter function %s set tikeo.admin_permission = %L', r.signature, r.permission);
  end loop;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. Réglages de la console
-- -----------------------------------------------------------------------------
create table private.console_settings (
  key text primary key check (key in ('notify_users', 'admin_issue_tickets')),
  value jsonb not null,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now()
);
revoke all on private.console_settings from public, anon, authenticated;
insert into private.console_settings (key, value) values
  ('notify_users', 'false'::jsonb),
  ('admin_issue_tickets', 'false'::jsonb);

create function private.console_setting_bool(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select (s.value #>> '{}')::boolean from private.console_settings s
                    where s.key = p_key), false)
$$;
revoke all on function private.console_setting_bool(text) from public, anon, authenticated;

create function public.admin_console_settings()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return jsonb_build_object(
    'notify_users', private.console_setting_bool('notify_users'),
    'admin_issue_tickets', private.console_setting_bool('admin_issue_tickets'));
end;
$$;
revoke all on function public.admin_console_settings() from public, anon;
grant execute on function public.admin_console_settings() to authenticated;

-- Null : inchangé.
create function public.admin_save_console_settings(
  p_notify_users boolean default null,
  p_admin_issue_tickets boolean default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.require_admin('settings');
  if p_notify_users is not null then
    update private.console_settings s
       set value = to_jsonb(p_notify_users), updated_by = auth.uid(), updated_at = now()
     where s.key = 'notify_users';
  end if;
  if p_admin_issue_tickets is not null then
    update private.console_settings s
       set value = to_jsonb(p_admin_issue_tickets), updated_by = auth.uid(), updated_at = now()
     where s.key = 'admin_issue_tickets';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.console_settings_updated', 'platform', null,
          public.admin_console_settings());
  return public.admin_console_settings();
end;
$$;
revoke all on function public.admin_save_console_settings(boolean, boolean) from public, anon;
grant execute on function public.admin_save_console_settings(boolean, boolean) to authenticated;

-- Ce que l'app doit savoir de l'administrateur connecté (aussi à aal1).
create function public.admin_me()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role text := private.admin_role_of(auth.uid());
begin
  if v_role is null then
    raise exception 'forbidden'
      using errcode = '42501', detail = 'Réservé aux administrateurs de Tikéo.';
  end if;
  return jsonb_build_object(
    'role', v_role,
    'permissions', to_jsonb(private.role_permissions(v_role)),
    'mfa_enrolled', private.has_verified_factor(auth.uid()),
    'notify_users', private.console_setting_bool('notify_users'),
    'admin_issue_tickets', private.console_setting_bool('admin_issue_tickets'));
end;
$$;
revoke all on function public.admin_me() from public, anon;
grant execute on function public.admin_me() to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Outils communs des actions sur les comptes
-- -----------------------------------------------------------------------------
-- Motifs des actions de la console (lus par les administrateurs seulement).
create table private.admin_action_log (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles (id) on delete set null,
  action text not null,
  target_type text not null,
  target_id uuid,
  reason text not null,
  created_at timestamptz not null default now()
);
create index admin_action_log_target_idx on private.admin_action_log (target_id, created_at desc);
revoke all on private.admin_action_log from public, anon, authenticated;

create function private.clean_admin_reason(p_reason text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  if v_reason is null or char_length(v_reason) < 3 then
    raise exception 'reason_required' using errcode = '22023', detail = 'Indiquez le motif.';
  end if;
  if char_length(v_reason) > 500 then
    raise exception 'reason_too_long'
      using errcode = '22023', detail = 'Motif trop long (500 caractères au plus).';
  end if;
  return v_reason;
end;
$$;
revoke all on function private.clean_admin_reason(text) from public, anon, authenticated;

-- Journal (sans motif) + motif à part.
create function private.log_admin_action(
  p_action text, p_target_type text, p_target_id uuid, p_reason text,
  p_details jsonb default '{}'::jsonb, p_organization_id uuid default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, auth.uid(), p_action, p_target_type, p_target_id,
          coalesce(p_details, '{}'::jsonb));
  insert into private.admin_action_log (actor_id, action, target_type, target_id, reason)
  values (auth.uid(), p_action, p_target_type, p_target_id, p_reason);
end;
$$;
revoke all on function private.log_admin_action(text, text, uuid, text, jsonb, uuid)
  from public, anon, authenticated;

-- Compte visé : existe, pas supprimé, pas soi-même ; le compte d'un
-- administrateur n'est modifiable que par un super administrateur.
create function private.require_manageable_account(p_user uuid)
returns public.profiles
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
begin
  if p_user = auth.uid() then
    raise exception 'self_forbidden'
      using errcode = '42501', detail = 'Vous ne pouvez pas modifier votre propre compte ici.';
  end if;
  select * into v_profile from public.profiles p where p.id = p_user for update;
  if not found then
    raise exception 'account_not_found' using errcode = 'P0002', detail = 'Compte introuvable.';
  end if;
  if v_profile.deleted_at is not null then
    raise exception 'account_deleted' using errcode = '55000', detail = 'Ce compte a été supprimé.';
  end if;
  if v_profile.is_platform_admin and not private.admin_can('admins') then
    raise exception 'account_admin_protected'
      using errcode = '42501',
            detail = 'Seul un super administrateur peut agir sur le compte d''un administrateur.';
  end if;
  return v_profile;
end;
$$;
revoke all on function private.require_manageable_account(uuid) from public, anon, authenticated;

-- Notification à la personne concernée (dans sa langue), avec le motif.
create function private.notify_account(p_user uuid, p_kind text, p_reason text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_en boolean := coalesce((select p.locale from public.profiles p where p.id = p_user), 'fr') = 'en';
  v_title text;
  v_body text;
begin
  v_title := case p_kind
    when 'account_updated' then
      case when v_en then 'Your Tikéo account was updated' else 'Votre compte Tikéo a été modifié' end
    when 'account_signed_out' then
      case when v_en then 'You were signed out of Tikéo' else 'Vous avez été déconnecté de Tikéo' end
    when 'account_password_reset' then
      case when v_en then 'New Tikéo password' else 'Nouveau mot de passe Tikéo' end
    when 'account_email_changed' then
      case when v_en then 'Your email address was changed' else 'Votre adresse e-mail a été modifiée' end
    when 'account_deletion_cancelled' then
      case when v_en then 'Account deletion cancelled' else 'Suppression de votre compte annulée' end
    else case when v_en then 'Message from Tikéo' else 'Message de Tikéo' end
  end;
  v_body := case when v_en then 'By the Tikéo team. Reason: ' else 'Par l''équipe Tikéo. Motif : ' end
            || p_reason;
  insert into public.push_outbox (user_id, title, body, route)
  values (p_user, v_title, left(v_body, 240), '/profil');
end;
$$;
revoke all on function private.notify_account(uuid, text, text) from public, anon, authenticated;

create function private.should_notify(p_notify boolean)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(p_notify, private.console_setting_bool('notify_users'))
$$;
revoke all on function private.should_notify(boolean) from public, anon, authenticated;

create function private.end_account_sessions(p_user uuid)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_count integer := 0;
begin
  if to_regclass('auth.sessions') is not null then
    execute 'with gone as (delete from auth.sessions where user_id = $1 returning 1)
             select count(*) from gone' into v_count using p_user;
  end if;
  delete from public.account_devices d where d.user_id = p_user;
  return v_count;
end;
$$;
revoke all on function private.end_account_sessions(uuid) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 4. Mot de passe provisoire à changer
-- -----------------------------------------------------------------------------
alter table public.profiles add column must_change_password boolean not null default false;

create function public.my_account_flags()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object('must_change_password', coalesce(p.must_change_password, false))
    from public.profiles p where p.id = auth.uid()
$$;
revoke all on function public.my_account_flags() from public, anon;
grant execute on function public.my_account_flags() to authenticated;

create function public.clear_must_change_password()
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  update public.profiles p set must_change_password = false, updated_at = now()
   where p.id = auth.uid() and p.must_change_password;
end;
$$;
revoke all on function public.clear_must_change_password() from public, anon;
grant execute on function public.clear_must_change_password() to authenticated;

-- -----------------------------------------------------------------------------
-- 5. Fiche d'un compte
-- -----------------------------------------------------------------------------
create function public.admin_account_detail(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
  v_email text;
  v_last_sign_in timestamptz;
begin
  perform private.require_platform_admin();
  select * into v_profile from public.profiles p where p.id = p_user_id;
  if not found then
    raise exception 'account_not_found' using errcode = 'P0002', detail = 'Compte introuvable.';
  end if;
  select u.email, u.last_sign_in_at into v_email, v_last_sign_in
    from auth.users u where u.id = p_user_id;
  return jsonb_build_object(
    'id', v_profile.id,
    'display_name', v_profile.display_name,
    'email', v_email,
    'phone', v_profile.phone,
    'locale', v_profile.locale,
    'status', v_profile.status,
    'disabled_reason', v_profile.disabled_reason,
    'created_at', v_profile.created_at,
    'last_sign_in_at', v_last_sign_in,
    'deletion_requested_at', v_profile.deletion_requested_at,
    'deleted_at', v_profile.deleted_at,
    'must_change_password', v_profile.must_change_password,
    'admin_role', private.admin_role_of(p_user_id),
    'mfa_enrolled', private.has_verified_factor(p_user_id),
    'organizations', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', o.id, 'name', o.name, 'role', m.role, 'active', m.active,
               'status', o.status) order by m.active desc, o.name)
        from public.organization_members m
        join public.organizations o on o.id = m.organization_id
       where m.user_id = p_user_id), '[]'::jsonb),
    'wallet_tickets', (select count(*) from public.tickets t where t.holder_user_id = p_user_id),
    'support_requests', (select count(*) from public.support_requests r where r.user_id = p_user_id),
    'support_open', (select count(*) from public.support_requests r
                      where r.user_id = p_user_id and r.status <> 'closed'),
    'devices', coalesce((
      select jsonb_agg(jsonb_build_object(
               'label', d.label, 'platform', d.platform, 'app_build', d.app_build,
               'last_seen_at', d.last_seen_at) order by d.last_seen_at desc)
        from public.account_devices d where d.user_id = p_user_id), '[]'::jsonb),
    'actions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'action', a.action, 'at', a.created_at, 'reason', a.reason,
               'by', coalesce(p.display_name, '—')) order by a.created_at desc, a.id desc)
        from (select * from private.admin_action_log l
               where l.target_id = p_user_id
               order by l.created_at desc, l.id desc limit 20) a
        left join public.profiles p on p.id = a.actor_id), '[]'::jsonb));
end;
$$;
revoke all on function public.admin_account_detail(uuid) from public, anon;
grant execute on function public.admin_account_detail(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Actions sur un compte
-- -----------------------------------------------------------------------------
create function public.admin_update_account(
  p_user_id uuid, p_display_name text, p_phone text, p_reason text, p_notify boolean default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
  v_reason text := private.clean_admin_reason(p_reason);
  v_name text := private.normalize_text(p_display_name);
  v_phone text := private.normalize_phone(p_phone);
  v_fields text[] := '{}';
begin
  perform private.require_admin('accounts');
  v_profile := private.require_manageable_account(p_user_id);
  if v_name is null or char_length(v_name) not between 2 and 60 then
    raise exception 'profile_name_invalid' using errcode = '22023', detail = 'Nom de 2 à 60 caractères.';
  end if;
  if v_phone is not null and v_phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'profile_phone_invalid' using errcode = '22023', detail = 'Numéro de téléphone invalide.';
  end if;
  if v_name is distinct from v_profile.display_name then v_fields := v_fields || 'display_name'::text; end if;
  if v_phone is distinct from v_profile.phone then v_fields := v_fields || 'phone'::text; end if;
  if cardinality(v_fields) = 0 then
    return;
  end if;
  update public.profiles p set display_name = v_name, phone = v_phone, updated_at = now()
   where p.id = p_user_id;
  perform private.log_admin_action('admin.account_updated', 'account', p_user_id, v_reason,
                                   jsonb_build_object('fields', to_jsonb(v_fields)));
  if private.should_notify(p_notify) then
    perform private.notify_account(p_user_id, 'account_updated', v_reason);
  end if;
end;
$$;
revoke all on function public.admin_update_account(uuid, text, text, text, boolean) from public, anon;
grant execute on function public.admin_update_account(uuid, text, text, text, boolean) to authenticated;

-- Déconnecte tous les appareils du compte.
create function public.admin_sign_out_account(p_user_id uuid, p_reason text, p_notify boolean default null)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_count integer;
begin
  perform private.require_admin('accounts');
  perform private.require_manageable_account(p_user_id);
  v_count := private.end_account_sessions(p_user_id);
  perform private.log_admin_action('admin.account_signed_out', 'account', p_user_id, v_reason,
                                   jsonb_build_object('sessions', v_count));
  if private.should_notify(p_notify) then
    perform private.notify_account(p_user_id, 'account_signed_out', v_reason);
  end if;
  return v_count;
end;
$$;
revoke all on function public.admin_sign_out_account(uuid, text, boolean) from public, anon;
grant execute on function public.admin_sign_out_account(uuid, text, boolean) to authenticated;

create function public.admin_cancel_account_deletion(p_user_id uuid, p_reason text, p_notify boolean default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
  v_reason text := private.clean_admin_reason(p_reason);
begin
  perform private.require_admin('accounts');
  v_profile := private.require_manageable_account(p_user_id);
  if v_profile.deletion_requested_at is null then
    raise exception 'deletion_not_requested'
      using errcode = '55000', detail = 'Aucune demande de suppression pour ce compte.';
  end if;
  update public.profiles p set deletion_requested_at = null, updated_at = now() where p.id = p_user_id;
  perform private.log_admin_action('admin.account_deletion_cancelled', 'account', p_user_id, v_reason);
  if private.should_notify(p_notify) then
    perform private.notify_account(p_user_id, 'account_deletion_cancelled', v_reason);
  end if;
end;
$$;
revoke all on function public.admin_cancel_account_deletion(uuid, text, boolean) from public, anon;
grant execute on function public.admin_cancel_account_deletion(uuid, text, boolean) to authenticated;

-- Suppression immédiate (super, double authentification) : même effet que
-- la suppression à échéance (anonymisation, structures suspendues).
create function public.admin_delete_account_now(p_user_id uuid, p_confirm_email text, p_reason text)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_email text;
  v_suspended integer;
begin
  perform private.require_admin('accounts_delete');
  perform private.require_admin_mfa();
  perform private.require_manageable_account(p_user_id);
  select u.email into v_email from auth.users u where u.id = p_user_id;
  if v_email is null or lower(v_email) <> lower(btrim(coalesce(p_confirm_email, ''))) then
    raise exception 'confirmation_mismatch'
      using errcode = '22023', detail = 'Saisissez exactement l''adresse e-mail du compte.';
  end if;
  -- Échéance atteinte : le corps de la suppression existante s'applique.
  update public.profiles p
     set deletion_requested_at = now() - private.account_deletion_delay() - interval '1 minute'
   where p.id = p_user_id;
  v_suspended := private.purge_account(p_user_id);
  perform private.log_admin_action('admin.account_deleted_now', 'account', p_user_id, v_reason,
                                   jsonb_build_object('structures_suspended', v_suspended));
  return v_suspended;
end;
$$;
revoke all on function public.admin_delete_account_now(uuid, text, text) from public, anon;
grant execute on function public.admin_delete_account_now(uuid, text, text) to authenticated;

-- Rôle d'administration (super, double authentification). Null : retiré.
create function public.admin_set_admin_role(p_user_id uuid, p_role text, p_reason text)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_profile public.profiles%rowtype;
  v_current text;
  v_role text := nullif(btrim(coalesce(p_role, '')), '');
begin
  perform private.require_admin('admins');
  perform private.require_admin_mfa();
  if v_role is not null and v_role not in ('super', 'support', 'moderation', 'finance') then
    raise exception 'admin_role_invalid' using errcode = '22023', detail = 'Rôle inconnu.';
  end if;
  select * into v_profile from public.profiles p where p.id = p_user_id for update;
  if not found then
    raise exception 'account_not_found' using errcode = 'P0002', detail = 'Compte introuvable.';
  end if;
  if v_profile.deleted_at is not null or (v_role is not null and v_profile.status <> 'active') then
    raise exception 'account_inactive'
      using errcode = '55000', detail = 'Le compte doit être actif.';
  end if;
  v_current := private.admin_role_of(p_user_id);
  -- Toujours au moins un super administrateur actif.
  perform pg_advisory_xact_lock(hashtext('platform_admin_roles'));
  if v_current = 'super' and v_role is distinct from 'super'
     and not exists (select 1 from public.profiles p
                      where p.is_platform_admin and p.id <> p_user_id
                        and private.admin_role_of(p.id) = 'super') then
    raise exception 'last_super_admin'
      using errcode = '55000', detail = 'Il faut garder au moins un super administrateur.';
  end if;
  update public.profiles p set is_platform_admin = v_role is not null, updated_at = now()
   where p.id = p_user_id;
  if v_role is null then
    delete from private.platform_admin_roles r where r.user_id = p_user_id;
  else
    insert into private.platform_admin_roles (user_id, role, granted_by)
    values (p_user_id, v_role, auth.uid())
    on conflict (user_id) do update
       set role = excluded.role, granted_by = excluded.granted_by, granted_at = now();
  end if;
  perform private.log_admin_action('admin.admin_role_changed', 'account', p_user_id, v_reason,
                                   jsonb_build_object('role', v_role));
  return v_role;
end;
$$;
revoke all on function public.admin_set_admin_role(uuid, text, text) from public, anon;
grant execute on function public.admin_set_admin_role(uuid, text, text) to authenticated;

-- Administrateurs de la plateforme.
create function public.admin_platform_admins()
returns table (id uuid, display_name text, email text, role text, mfa_enrolled boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return query
  select p.id, p.display_name, u.email::text, private.admin_role_of(p.id),
         private.has_verified_factor(p.id)
    from public.profiles p
    left join auth.users u on u.id = p.id
   where p.is_platform_admin and p.deleted_at is null
   order by p.display_name, p.id;
end;
$$;
revoke all on function public.admin_platform_admins() from public, anon;
grant execute on function public.admin_platform_admins() to authenticated;

-- Retire la double authentification d'un autre administrateur (téléphone
-- et codes de secours perdus).
create function public.admin_remove_account_mfa(p_user_id uuid, p_reason text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
begin
  perform private.require_admin('admins');
  perform private.require_admin_mfa();
  perform private.require_manageable_account(p_user_id);
  delete from auth.mfa_factors f where f.user_id = p_user_id;
  delete from private.admin_recovery_codes c where c.user_id = p_user_id;
  perform private.log_admin_action('admin.account_mfa_removed', 'account', p_user_id, v_reason);
end;
$$;
revoke all on function public.admin_remove_account_mfa(uuid, text) from public, anon;
grant execute on function public.admin_remove_account_mfa(uuid, text) to authenticated;

-- Désactivation et réactivation (corps de la 2200) : le compte d'un
-- administrateur est protégé, motif gardé à part.
create or replace function public.admin_set_account_status(
  p_user_id uuid,
  p_status public.account_status,
  p_reason text default null
)
returns public.account_status
language plpgsql
volatile
security definer
set search_path = ''
set tikeo.admin_permission = 'accounts'
as $$
declare
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
  v_profile public.profiles%rowtype;
begin
  perform private.require_platform_admin();
  if p_status is null then
    raise exception 'status_invalid' using errcode = '22023', detail = 'Statut manquant.';
  end if;
  if p_status = 'disabled' and v_reason is null then
    raise exception 'reason_required'
      using errcode = '22023', detail = 'Indiquez le motif de la désactivation.';
  end if;
  if char_length(v_reason) > 500 then
    raise exception 'reason_too_long' using errcode = '22023', detail = 'Motif trop long (500 caractères au plus).';
  end if;
  v_profile := private.require_manageable_account(p_user_id);
  update public.profiles p
     set status = p_status,
         disabled_at = case when p_status = 'disabled' then coalesce(p.disabled_at, now()) end,
         disabled_reason = case when p_status = 'disabled' then v_reason end,
         updated_at = now()
   where p.id = p_user_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.account_status_changed', 'account', p_user_id,
          jsonb_build_object('status', p_status));
  if v_reason is not null then
    insert into private.admin_action_log (actor_id, action, target_type, target_id, reason)
    values (auth.uid(), 'admin.account_status_changed', 'account', p_user_id, v_reason);
  end if;
  return p_status;
end;
$$;

-- -----------------------------------------------------------------------------
-- 7. Fonction serveur `admin-accounts` (création, mot de passe, e-mail)
-- -----------------------------------------------------------------------------
-- La fonction Edge appelle d'abord ce contrôle avec le jeton de
-- l'administrateur, fait l'opération d'authentification avec la clé
-- serveur, puis enregistre le résultat (journal, drapeaux) avec ce même
-- jeton.
create function public.admin_account_guard(p_action text, p_user_id uuid default null,
                                           p_phone text default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_phone text := private.normalize_phone(p_phone);
begin
  case p_action
    when 'create' then
      perform private.require_admin('accounts');
      perform private.require_admin_mfa();
      if v_phone is not null and v_phone !~ '^\+[1-9][0-9]{7,14}$' then
        raise exception 'profile_phone_invalid'
          using errcode = '22023', detail = 'Numéro de téléphone invalide.';
      end if;
    when 'password', 'email' then
      perform private.require_admin('accounts');
      perform private.require_manageable_account(p_user_id);
    else
      raise exception 'action_invalid' using errcode = '22023', detail = 'Action inconnue.';
  end case;
end;
$$;
revoke all on function public.admin_account_guard(text, uuid, text) from public, anon;
grant execute on function public.admin_account_guard(text, uuid, text) to authenticated;

create function public.admin_record_account_created(p_user_id uuid, p_phone text, p_reason text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_phone text := private.normalize_phone(p_phone);
begin
  perform private.require_admin('accounts');
  perform private.require_admin_mfa();
  if not exists (select 1 from auth.users u
                  where u.id = p_user_id and u.created_at > now() - interval '10 minutes')
     or not exists (select 1 from public.profiles p where p.id = p_user_id) then
    raise exception 'account_not_new'
      using errcode = '55000', detail = 'Compte introuvable ou créé il y a plus de 10 minutes.';
  end if;
  if v_phone is not null and v_phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'profile_phone_invalid' using errcode = '22023', detail = 'Numéro de téléphone invalide.';
  end if;
  update public.profiles p set phone = v_phone, must_change_password = true, updated_at = now()
   where p.id = p_user_id;
  perform private.log_admin_action('admin.account_created', 'account', p_user_id, v_reason);
end;
$$;
revoke all on function public.admin_record_account_created(uuid, text, text) from public, anon;
grant execute on function public.admin_record_account_created(uuid, text, text) to authenticated;

create function public.admin_record_password_reset(p_user_id uuid, p_reason text, p_notify boolean default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
begin
  perform private.require_admin('accounts');
  perform private.require_manageable_account(p_user_id);
  update public.profiles p set must_change_password = true, updated_at = now() where p.id = p_user_id;
  perform private.end_account_sessions(p_user_id);
  perform private.log_admin_action('admin.account_password_reset', 'account', p_user_id, v_reason);
  if private.should_notify(p_notify) then
    perform private.notify_account(p_user_id, 'account_password_reset', v_reason);
  end if;
end;
$$;
revoke all on function public.admin_record_password_reset(uuid, text, boolean) from public, anon;
grant execute on function public.admin_record_password_reset(uuid, text, boolean) to authenticated;

create function public.admin_record_email_changed(p_user_id uuid, p_reason text, p_notify boolean default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
begin
  perform private.require_admin('accounts');
  perform private.require_manageable_account(p_user_id);
  perform private.log_admin_action('admin.account_email_changed', 'account', p_user_id, v_reason);
  if private.should_notify(p_notify) then
    perform private.notify_account(p_user_id, 'account_email_changed', v_reason);
  end if;
end;
$$;
revoke all on function public.admin_record_email_changed(uuid, text, boolean) from public, anon;
grant execute on function public.admin_record_email_changed(uuid, text, boolean) to authenticated;
