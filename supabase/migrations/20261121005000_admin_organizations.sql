-- =============================================================================
-- Tikéo — Lot 4-11b : structures depuis la console, fermeture et corbeille
-- (ADR 0039)
-- =============================================================================
-- Décisions de Toussaint (21/11) : la console crée, modifie et supprime une
-- structure ; une structure qui a servi (au moins un événement) n'est jamais
-- effacée : elle est FERMÉE (suspendue pour toujours, événements à venir
-- annulés, tickets non entrés de ces événements annulés et détenteurs
-- prévenus, factures gardées). Une structure vide va à la CORBEILLE :
-- restauration possible pendant 30 jours, puis anonymisation automatique.
--
-- Permissions (migration 4900) : `organizations` (support, super) pour
-- créer, modifier, gérer les membres et restaurer ; `organizations_delete`
-- (super seulement) et double authentification pour supprimer.
--
-- Motifs dans `private.admin_action_log` (jamais dans audit_logs).
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   P0002 organization_not_found | member_not_found | invitation_not_found
--   55000 organization_closed | organization_trashed | organization_not_trashed
--         | member_is_owner | owner_inactive
--   22023 org_name_invalid | org_phone_invalid | org_email_invalid | org_city_invalid
--         | role_invalid | confirmation_mismatch
--   54000 billing_limit_structures (quota du pack du propriétaire)

alter table public.organizations
  add column closed_at timestamptz,
  add column trashed_at timestamptz,
  add column purged_at timestamptz;

-- Supprimer une structure : super administrateur seulement.
create or replace function private.role_permissions(p_role text)
returns text[]
language sql
immutable
set search_path = ''
as $$
  select case p_role
    when 'super' then array['accounts', 'accounts_delete', 'organizations',
                            'organizations_delete', 'org_status', 'events', 'tickets',
                            'catalog', 'announcements', 'support', 'billing', 'legal',
                            'admins', 'settings']
    when 'support' then array['accounts', 'organizations', 'org_status', 'tickets', 'support']
    when 'moderation' then array['org_status', 'events', 'catalog', 'announcements']
    when 'finance' then array['billing']
    else '{}'::text[]
  end
$$;
revoke all on function private.role_permissions(text) from public, anon, authenticated;

-- Notification dans la langue du destinataire.
create function private.notify_user(
  p_user uuid, p_title_fr text, p_title_en text, p_body_fr text, p_body_en text,
  p_route text default '/profil'
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  insert into public.push_outbox (user_id, title, body, route)
  select p.id,
         case when p.locale = 'en' then p_title_en else p_title_fr end,
         left(case when p.locale = 'en' then p_body_en else p_body_fr end, 240),
         p_route
    from public.profiles p
   where p.id = p_user and p.deleted_at is null;
end;
$$;
revoke all on function private.notify_user(uuid, text, text, text, text, text)
  from public, anon, authenticated;

-- Une structure fermée ou à la corbeille ne reçoit plus de membre actif
-- (invitation, attribution par la console…).
create function private.organization_members_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.active and exists (
       select 1 from public.organizations o
        where o.id = new.organization_id
          and (o.closed_at is not null or o.trashed_at is not null)) then
    raise exception 'organization_closed'
      using errcode = '55000', detail = 'Cette structure est fermée ou à la corbeille.';
  end if;
  return new;
end;
$$;
create trigger organization_members_guard
  before insert or update of active on public.organization_members
  for each row execute function private.organization_members_guard();

-- Structure visée par une action de la console : verrouillée, ouverte.
create function private.lock_console_organization(p_organization_id uuid)
returns public.organizations
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_org public.organizations%rowtype;
begin
  select * into v_org from public.organizations o where o.id = p_organization_id for update;
  if not found or v_org.purged_at is not null then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable.';
  end if;
  if v_org.closed_at is not null then
    raise exception 'organization_closed'
      using errcode = '55000', detail = 'Cette structure est fermée.';
  end if;
  if v_org.trashed_at is not null then
    raise exception 'organization_trashed'
      using errcode = '55000', detail = 'Cette structure est à la corbeille : restaurez-la d''abord.';
  end if;
  return v_org;
end;
$$;
revoke all on function private.lock_console_organization(uuid) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Liste (drop + create : deux colonnes de plus ; sans les structures à la
-- corbeille ni effacées, visibles dans la corbeille).
-- -----------------------------------------------------------------------------
drop function public.admin_organizations(text, public.account_status, integer, integer);
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
  disabled_reason text,
  closed_at timestamptz
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
         o.disabled_at, o.disabled_reason, o.closed_at
    from public.organizations o
    join public.profiles pr on pr.id = o.owner_id
   where o.trashed_at is null and o.purged_at is null
     and (p_status is null or o.status = p_status)
     and (v_search is null
          or private.fold(o.name) like '%' || v_search || '%'
          or o.slug like '%' || v_search || '%')
   order by o.created_at desc, o.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_organizations(text, public.account_status, integer, integer) from public, anon;
grant execute on function public.admin_organizations(text, public.account_status, integer, integer) to authenticated;

-- Suspendre / réactiver (corps de 1900) : jamais une structure fermée ou à
-- la corbeille. Permission `org_status` conservée (create or replace
-- remplace les paramètres de la fonction).
create or replace function public.admin_set_organization_status(
  p_organization_id uuid,
  p_status public.account_status,
  p_reason text default null
)
returns public.organizations
language plpgsql
volatile
security definer
set search_path = ''
set application_name = 'tikeo.perm:org_status'
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
  v_org := private.lock_console_organization(p_organization_id);
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

-- -----------------------------------------------------------------------------
-- Fiche d'une structure
-- -----------------------------------------------------------------------------
create function public.admin_organization_detail(p_organization_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org public.organizations%rowtype;
  v_plan jsonb;
begin
  perform private.require_platform_admin();
  select * into v_org from public.organizations o where o.id = p_organization_id;
  if not found then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable.';
  end if;
  v_plan := private.billing_account_plan(v_org.owner_id);
  return jsonb_build_object(
    'id', v_org.id,
    'name', v_org.name,
    'slug', v_org.slug,
    'status', v_org.status,
    'created_at', v_org.created_at,
    'logo_path', v_org.logo_path,
    'phone', v_org.phone,
    'contact_email', v_org.contact_email,
    'city', v_org.city,
    'public_phone', v_org.public_phone,
    'disabled_at', v_org.disabled_at,
    'disabled_reason', v_org.disabled_reason,
    'closed_at', v_org.closed_at,
    'trashed_at', v_org.trashed_at,
    'purged_at', v_org.purged_at,
    'purge_due_at', v_org.trashed_at + interval '30 days',
    'owner', (select jsonb_build_object('id', p.id, 'display_name', p.display_name,
                                        'email', u.email)
                from public.profiles p left join auth.users u on u.id = p.id
               where p.id = v_org.owner_id),
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
               'user_id', m.user_id, 'display_name', p.display_name, 'email', u.email,
               'role', m.role, 'active', m.active, 'joined_at', m.created_at)
             order by m.active desc,
                      case m.role when 'owner' then 0 when 'manager' then 1 else 2 end,
                      p.display_name)
        from public.organization_members m
        join public.profiles p on p.id = m.user_id
        left join auth.users u on u.id = m.user_id
       where m.organization_id = v_org.id), '[]'::jsonb),
    'invitations', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', i.id, 'role', i.role, 'code_hint', i.code_hint,
               'created_at', i.created_at, 'expires_at', i.expires_at,
               'uses', i.uses, 'max_uses', i.max_uses) order by i.created_at desc)
        from public.organization_invitations i
       where i.organization_id = v_org.id and i.revoked_at is null
         and i.expires_at > now() and i.uses < i.max_uses), '[]'::jsonb),
    'events_total', (select count(*) from public.events e where e.organization_id = v_org.id),
    'events_upcoming', (select count(*) from public.events e
                         where e.organization_id = v_org.id and e.ends_at > now()
                           and e.status in ('draft', 'published', 'in_progress')),
    'events', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', x.id, 'title', x.title, 'status', x.status, 'starts_at', x.starts_at,
               'tickets', x.tickets, 'admitted', x.admitted)
             order by x.starts_at desc)
        from (select e.id, e.title, e.status, e.starts_at,
                     (select count(*) from public.tickets t where t.event_id = e.id) as tickets,
                     (select count(*) from public.tickets t
                       where t.event_id = e.id and t.status <> 'revoked'
                         and t.entries_used > 0) as admitted
                from public.events e where e.organization_id = v_org.id
               order by e.starts_at desc limit 20) x), '[]'::jsonb),
    'tickets_issued', (select count(*) from public.tickets t
                        join public.events e on e.id = t.event_id
                       where e.organization_id = v_org.id),
    'tickets_admitted', (select count(*) from public.tickets t
                          join public.events e on e.id = t.event_id
                         where e.organization_id = v_org.id and t.status <> 'revoked'
                           and t.entries_used > 0),
    'pack_name', v_plan->'snapshot'->>'name',
    'pack_ends_at', case when v_plan->>'subscription_id' is not null
                         then v_plan->>'period_end' end,
    'invoices', (select count(*) from public.billing_invoices b
                   join public.events e on e.id = b.event_id
                  where e.organization_id = v_org.id),
    'invoices_due', (select count(*) from public.billing_invoices b
                       join public.events e on e.id = b.event_id
                      where e.organization_id = v_org.id and b.status = 'due'),
    'actions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'action', a.action, 'at', a.created_at, 'reason', a.reason,
               'by', coalesce(p.display_name, '—')) order by a.created_at desc, a.id desc)
        from (select * from private.admin_action_log l
               where l.target_id = v_org.id
               order by l.created_at desc, l.id desc limit 20) a
        left join public.profiles p on p.id = a.actor_id), '[]'::jsonb));
end;
$$;
revoke all on function public.admin_organization_detail(uuid) from public, anon;
grant execute on function public.admin_organization_detail(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Créer une structure pour un compte (au pack de ce compte)
-- -----------------------------------------------------------------------------
create function public.admin_create_organization(
  p_owner_id uuid,
  p_name text,
  p_city text,
  p_reason text,
  p_notify boolean default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_name text := private.normalize_text(p_name);
  v_city text := private.normalize_text(p_city);
  v_owner public.profiles%rowtype;
  v_base text;
  v_slug text;
  v_id uuid;
begin
  perform private.require_admin('organizations');
  if v_name is null or char_length(v_name) not between 2 and 120 then
    raise exception 'org_name_invalid'
      using errcode = '22023', detail = 'Nom de 2 à 120 caractères.';
  end if;
  if v_city is not null and char_length(v_city) not between 2 and 80 then
    raise exception 'org_city_invalid'
      using errcode = '22023', detail = 'Ville de 2 à 80 caractères.';
  end if;
  select * into v_owner from public.profiles p where p.id = p_owner_id;
  if not found then
    raise exception 'account_not_found' using errcode = 'P0002', detail = 'Compte introuvable.';
  end if;
  if v_owner.deleted_at is not null or v_owner.status <> 'active' then
    raise exception 'account_inactive'
      using errcode = '55000', detail = 'Ce compte est désactivé ou supprimé.';
  end if;

  v_base := private.slugify(v_name);
  if char_length(v_base) < 2 then
    v_base := v_base || '-org';
  end if;
  v_slug := v_base;
  while exists (select 1 from public.organizations o where o.slug = v_slug) loop
    v_slug := left(v_base, 45) || '-' || lower(substr(md5(gen_random_uuid()::text), 1, 4));
  end loop;

  -- Le déclencheur de facturation vérifie le quota « structures » du compte.
  insert into public.organizations (name, slug, owner_id, city)
  values (v_name, v_slug, p_owner_id, v_city)
  returning id into v_id;
  insert into public.organization_members (organization_id, user_id, role)
  values (v_id, p_owner_id, 'owner');

  perform private.log_admin_action('admin.organization_created', 'organization', v_id,
    v_reason, jsonb_build_object('slug', v_slug), v_id);
  if private.should_notify(p_notify) then
    perform private.notify_user(p_owner_id,
      'Nouvelle structure', 'New organization',
      'L''équipe Tikéo a créé « ' || v_name || ' » pour vous. Motif : ' || v_reason,
      'The Tikéo team created “' || v_name || '” for you. Reason: ' || v_reason);
  end if;
  return v_id;
end;
$$;
revoke all on function public.admin_create_organization(uuid, text, text, text, boolean) from public, anon;
grant execute on function public.admin_create_organization(uuid, text, text, text, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Modifier les informations ; retirer le logo
-- -----------------------------------------------------------------------------
create function public.admin_update_organization(
  p_organization_id uuid,
  p_name text,
  p_city text,
  p_phone text,
  p_contact_email text,
  p_public_phone text,
  p_reason text,
  p_notify boolean default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_name text := private.normalize_text(p_name);
  v_city text := private.normalize_text(p_city);
  v_phone text := private.normalize_phone(p_phone);
  v_public text := private.normalize_phone(p_public_phone);
  v_email text := lower(private.normalize_text(p_contact_email));
  v_org public.organizations%rowtype;
  v_fields text[] := '{}';
begin
  perform private.require_admin('organizations');
  v_org := private.lock_console_organization(p_organization_id);
  if v_name is null or char_length(v_name) not between 2 and 120 then
    raise exception 'org_name_invalid'
      using errcode = '22023', detail = 'Nom de 2 à 120 caractères.';
  end if;
  if v_city is not null and char_length(v_city) not between 2 and 80 then
    raise exception 'org_city_invalid'
      using errcode = '22023', detail = 'Ville de 2 à 80 caractères.';
  end if;
  if (v_phone is not null and v_phone !~ '^\+[1-9][0-9]{7,14}$')
     or (v_public is not null and v_public !~ '^\+[1-9][0-9]{7,14}$') then
    raise exception 'org_phone_invalid'
      using errcode = '22023', detail = 'Numéro de téléphone invalide.';
  end if;
  if v_email is not null
     and (char_length(v_email) > 254 or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$') then
    raise exception 'org_email_invalid'
      using errcode = '22023', detail = 'Adresse e-mail invalide.';
  end if;

  if v_name is distinct from v_org.name then v_fields := v_fields || 'name'::text; end if;
  if v_city is distinct from v_org.city then v_fields := v_fields || 'city'::text; end if;
  if v_phone is distinct from v_org.phone then v_fields := v_fields || 'phone'::text; end if;
  if v_email is distinct from v_org.contact_email then
    v_fields := v_fields || 'contact_email'::text;
  end if;
  if v_public is distinct from v_org.public_phone then
    v_fields := v_fields || 'public_phone'::text;
  end if;

  update public.organizations o
     set name = v_name, city = v_city, phone = v_phone, contact_email = v_email,
         public_phone = v_public, updated_at = now()
   where o.id = p_organization_id;

  perform private.log_admin_action('admin.organization_updated', 'organization',
    p_organization_id, v_reason, jsonb_build_object('fields', to_jsonb(v_fields)),
    p_organization_id);
  if private.should_notify(p_notify) then
    perform private.notify_user(v_org.owner_id,
      'Structure modifiée', 'Organization updated',
      'L''équipe Tikéo a modifié « ' || v_name || ' ». Motif : ' || v_reason,
      'The Tikéo team updated “' || v_name || '”. Reason: ' || v_reason);
  end if;
  return jsonb_build_object('fields', to_jsonb(v_fields));
end;
$$;
revoke all on function public.admin_update_organization(uuid, text, text, text, text, text, text, boolean) from public, anon;
grant execute on function public.admin_update_organization(uuid, text, text, text, text, text, text, boolean) to authenticated;

-- Logo inapproprié : retiré de la structure (le fichier reste au stockage).
create function public.admin_remove_organization_logo(
  p_organization_id uuid,
  p_reason text,
  p_notify boolean default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_org public.organizations%rowtype;
begin
  perform private.require_admin('organizations');
  v_org := private.lock_console_organization(p_organization_id);
  if v_org.logo_path is null then
    return;
  end if;
  update public.organizations o set logo_path = null, updated_at = now()
   where o.id = p_organization_id;
  perform private.log_admin_action('admin.organization_logo_removed', 'organization',
    p_organization_id, v_reason, '{}'::jsonb, p_organization_id);
  if private.should_notify(p_notify) then
    perform private.notify_user(v_org.owner_id,
      'Logo retiré', 'Logo removed',
      'L''équipe Tikéo a retiré le logo de « ' || v_org.name || ' ». Motif : ' || v_reason,
      'The Tikéo team removed the logo of “' || v_org.name || '”. Reason: ' || v_reason);
  end if;
end;
$$;
revoke all on function public.admin_remove_organization_logo(uuid, text, boolean) from public, anon;
grant execute on function public.admin_remove_organization_logo(uuid, text, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Membres et invitations (ajout et transfert : admin_assign_organization)
-- -----------------------------------------------------------------------------
create function private.lock_console_member(p_organization_id uuid, p_user_id uuid)
returns public.organization_members
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_member public.organization_members%rowtype;
begin
  select * into v_member from public.organization_members m
   where m.organization_id = p_organization_id and m.user_id = p_user_id
     and m.active
   for update;
  if not found then
    raise exception 'member_not_found' using errcode = 'P0002', detail = 'Membre introuvable.';
  end if;
  if v_member.role = 'owner' then
    raise exception 'member_is_owner'
      using errcode = '55000',
            detail = 'Le propriétaire ne se modifie pas : transférez d''abord la structure.';
  end if;
  return v_member;
end;
$$;
revoke all on function private.lock_console_member(uuid, uuid) from public, anon, authenticated;

create function public.admin_set_member_role(
  p_organization_id uuid,
  p_user_id uuid,
  p_role public.member_role,
  p_reason text,
  p_notify boolean default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_org public.organizations%rowtype;
  v_member public.organization_members%rowtype;
begin
  perform private.require_admin('organizations');
  if p_role is null or p_role = 'owner' then
    raise exception 'role_invalid'
      using errcode = '22023', detail = 'Rôle : gestionnaire ou contrôleur.';
  end if;
  v_org := private.lock_console_organization(p_organization_id);
  v_member := private.lock_console_member(p_organization_id, p_user_id);
  if v_member.role = p_role then
    return;
  end if;
  update public.organization_members m set role = p_role
   where m.organization_id = p_organization_id and m.user_id = p_user_id;
  perform private.log_admin_action('admin.member_role_changed', 'member', p_user_id, v_reason,
    jsonb_build_object('from_role', v_member.role, 'role', p_role), p_organization_id);
  if private.should_notify(p_notify) then
    perform private.notify_user(p_user_id,
      'Rôle modifié', 'Role changed',
      'Vous êtes maintenant '
        || case p_role when 'manager' then 'gestionnaire' else 'contrôleur' end
        || ' de « ' || v_org.name || ' ». Motif : ' || v_reason,
      'You are now ' || case p_role when 'manager' then 'a manager' else 'a controller' end
        || ' of “' || v_org.name || '”. Reason: ' || v_reason);
  end if;
end;
$$;
revoke all on function public.admin_set_member_role(uuid, uuid, public.member_role, text, boolean) from public, anon;
grant execute on function public.admin_set_member_role(uuid, uuid, public.member_role, text, boolean) to authenticated;

create function public.admin_remove_member(
  p_organization_id uuid,
  p_user_id uuid,
  p_reason text,
  p_notify boolean default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_org public.organizations%rowtype;
  v_member public.organization_members%rowtype;
begin
  perform private.require_admin('organizations');
  v_org := private.lock_console_organization(p_organization_id);
  v_member := private.lock_console_member(p_organization_id, p_user_id);
  update public.organization_members m set active = false
   where m.organization_id = p_organization_id and m.user_id = p_user_id;
  perform private.log_admin_action('admin.member_removed', 'member', p_user_id, v_reason,
    jsonb_build_object('role', v_member.role), p_organization_id);
  if private.should_notify(p_notify) then
    perform private.notify_user(p_user_id,
      'Retiré d''une structure', 'Removed from an organization',
      'Vous ne faites plus partie de « ' || v_org.name || ' ». Motif : ' || v_reason,
      'You are no longer part of “' || v_org.name || '”. Reason: ' || v_reason);
  end if;
end;
$$;
revoke all on function public.admin_remove_member(uuid, uuid, text, boolean) from public, anon;
grant execute on function public.admin_remove_member(uuid, uuid, text, boolean) to authenticated;

create function public.admin_revoke_invitation(p_invitation_id uuid, p_reason text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_invitation public.organization_invitations%rowtype;
begin
  perform private.require_admin('organizations');
  select * into v_invitation from public.organization_invitations i
   where i.id = p_invitation_id for update;
  if not found then
    raise exception 'invitation_not_found'
      using errcode = 'P0002', detail = 'Invitation introuvable.';
  end if;
  update public.organization_invitations i set revoked_at = coalesce(i.revoked_at, now())
   where i.id = p_invitation_id;
  perform private.log_admin_action('admin.invitation_revoked', 'invitation', p_invitation_id,
    v_reason, '{}'::jsonb, v_invitation.organization_id);
end;
$$;
revoke all on function public.admin_revoke_invitation(uuid, text) from public, anon;
grant execute on function public.admin_revoke_invitation(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Supprimer : corbeille (structure vide) ou fermeture définitive
-- -----------------------------------------------------------------------------
-- Ce que ferait la suppression, montré avant de confirmer.
create function public.admin_organization_delete_preview(p_organization_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org public.organizations%rowtype;
begin
  perform private.require_admin('organizations_delete');
  select * into v_org from public.organizations o where o.id = p_organization_id;
  if not found or v_org.purged_at is not null then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable.';
  end if;
  return jsonb_build_object(
    'mode', case when exists (select 1 from public.events e where e.organization_id = v_org.id)
                 then 'close' else 'trash' end,
    'events_to_cancel', (select count(*) from public.events e
                          where e.organization_id = v_org.id and e.ends_at > now()
                            and e.status in ('draft', 'published', 'in_progress')),
    'tickets_to_cancel', (select count(*) from public.tickets t
                            join public.events e on e.id = t.event_id
                           where e.organization_id = v_org.id and e.ends_at > now()
                             and e.status in ('draft', 'published', 'in_progress')
                             and t.status = 'issued' and t.entries_used = 0),
    'holders_to_notify', (select count(distinct t.holder_user_id) from public.tickets t
                            join public.events e on e.id = t.event_id
                           where e.organization_id = v_org.id and e.ends_at > now()
                             and e.status in ('draft', 'published', 'in_progress')
                             and t.status = 'issued' and t.entries_used = 0
                             and t.holder_user_id is not null),
    'members', (select count(*) from public.organization_members m
                 where m.organization_id = v_org.id and m.active),
    'invoices', (select count(*) from public.billing_invoices b
                   join public.events e on e.id = b.event_id
                  where e.organization_id = v_org.id));
end;
$$;
revoke all on function public.admin_organization_delete_preview(uuid) from public, anon;
grant execute on function public.admin_organization_delete_preview(uuid) to authenticated;

create function public.admin_delete_organization(
  p_organization_id uuid,
  p_confirm_name text,
  p_reason text,
  p_notify boolean default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_actor uuid := auth.uid();
  v_org public.organizations%rowtype;
  v_mode text;
  v_cancelled uuid[] := '{}';
  v_archived integer := 0;
  v_tickets integer := 0;
  v_holders integer := 0;
begin
  perform private.require_admin('organizations_delete');
  perform private.require_admin_mfa();
  v_org := private.lock_console_organization(p_organization_id);
  if lower(btrim(coalesce(p_confirm_name, ''))) <> lower(v_org.name) then
    raise exception 'confirmation_mismatch'
      using errcode = '22023', detail = 'Saisissez exactement le nom de la structure.';
  end if;
  v_mode := case when exists (select 1 from public.events e where e.organization_id = v_org.id)
                 then 'close' else 'trash' end;

  -- Invitations en cours : plus utilisables.
  update public.organization_invitations i set revoked_at = now()
   where i.organization_id = v_org.id and i.revoked_at is null;

  if v_mode = 'trash' then
    update public.organizations o
       set status = 'disabled', disabled_at = coalesce(o.disabled_at, now()),
           disabled_reason = v_reason, trashed_at = now(), updated_at = now()
     where o.id = v_org.id;
    perform private.log_admin_action('admin.organization_trashed', 'organization', v_org.id,
      v_reason, '{}'::jsonb, v_org.id);
  else
    -- Événements à venir ou en cours : annulés ; les autres : archivés.
    with cancelled as (
      update public.events e set status = 'cancelled', updated_at = now()
       where e.organization_id = v_org.id and e.ends_at > now()
         and e.status in ('draft', 'published', 'in_progress')
      returning e.id
    )
    select coalesce(array_agg(c.id), '{}') into v_cancelled from cancelled c;
    with archived as (
      update public.events e set status = 'archived', updated_at = now()
       where e.organization_id = v_org.id
         and e.status not in ('archived', 'cancelled')
      returning 1
    )
    select count(*) into v_archived from archived;

    -- Tickets non entrés des événements annulés ; leurs détenteurs sont
    -- prévenus (un message par détenteur et par événement) ; une ligne de
    -- journal par événement. Une seule requête : les sous-requêtes qui
    -- modifient s'exécutent toutes.
    with revoked as (
      update public.tickets t
         set status = 'revoked', revoked_at = now(), revoked_by = v_actor
       where t.event_id = any (v_cancelled) and t.status = 'issued' and t.entries_used = 0
      returning t.id, t.event_id, t.holder_user_id
    ), pushed as (
      insert into public.push_outbox (user_id, title, body, route)
      select p.id,
             case when p.locale = 'en' then 'Event cancelled' else 'Événement annulé' end,
             left(case when p.locale = 'en'
                       then '“' || e.title || '” is cancelled: your ticket is no longer valid. Organizer: '
                            || v_org.name || '.'
                       else '« ' || e.title || ' » est annulé : votre ticket n''est plus valable. Organisateur : '
                            || v_org.name || '.' end, 240),
             '/portefeuille'
        from (select distinct r.holder_user_id, r.event_id from revoked r
               where r.holder_user_id is not null) h
        join public.profiles p on p.id = h.holder_user_id and p.deleted_at is null
        join public.events e on e.id = h.event_id
      returning 1
    ), logged as (
      insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
      select v_org.id, v_actor, 'admin.event_cancelled', 'event', c.id,
             jsonb_build_object('tickets', (select count(*) from revoked r where r.event_id = c.id))
        from unnest(v_cancelled) as c(id)
      returning 1
    )
    select count(*), count(distinct r.holder_user_id) into v_tickets, v_holders from revoked r;

    update public.organizations o
       set status = 'disabled', disabled_at = coalesce(o.disabled_at, now()),
           disabled_reason = v_reason, closed_at = now(), updated_at = now()
     where o.id = v_org.id;
    perform private.log_admin_action('admin.organization_closed', 'organization', v_org.id,
      v_reason,
      jsonb_build_object('events_cancelled', cardinality(v_cancelled),
                         'events_archived', v_archived, 'tickets_cancelled', v_tickets,
                         'holders_notified', v_holders),
      v_org.id);
  end if;

  if private.should_notify(p_notify) then
    perform private.notify_user(v_org.owner_id,
      'Structure supprimée', 'Organization deleted',
      'L''équipe Tikéo a supprimé « ' || v_org.name || ' ». Motif : ' || v_reason,
      'The Tikéo team deleted “' || v_org.name || '”. Reason: ' || v_reason);
  end if;
  return jsonb_build_object('mode', v_mode, 'events_cancelled', cardinality(v_cancelled),
                            'events_archived', v_archived, 'tickets_cancelled', v_tickets,
                            'holders_notified', v_holders);
end;
$$;
revoke all on function public.admin_delete_organization(uuid, text, text, boolean) from public, anon;
grant execute on function public.admin_delete_organization(uuid, text, text, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Corbeille : liste, restauration, effacement (anonymisation)
-- -----------------------------------------------------------------------------
create function public.admin_trash()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'kind', 'organization', 'id', o.id, 'name', o.name,
             'owner_name', p.display_name, 'trashed_at', o.trashed_at,
             'purge_due_at', o.trashed_at + interval '30 days')
           order by o.trashed_at desc)
      from public.organizations o
      join public.profiles p on p.id = o.owner_id
     where o.trashed_at is not null and o.purged_at is null), '[]'::jsonb);
end;
$$;
revoke all on function public.admin_trash() from public, anon;
grant execute on function public.admin_trash() to authenticated;

create function public.admin_restore_organization(
  p_organization_id uuid,
  p_reason text,
  p_notify boolean default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_org public.organizations%rowtype;
begin
  perform private.require_admin('organizations');
  select * into v_org from public.organizations o where o.id = p_organization_id for update;
  if not found or v_org.purged_at is not null then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable.';
  end if;
  if v_org.trashed_at is null then
    raise exception 'organization_not_trashed'
      using errcode = '55000', detail = 'Cette structure n''est pas à la corbeille.';
  end if;
  if not exists (select 1 from public.profiles p
                  where p.id = v_org.owner_id and p.status = 'active' and p.deleted_at is null) then
    raise exception 'owner_inactive'
      using errcode = '55000', detail = 'Le propriétaire est désactivé ou supprimé.';
  end if;
  -- Quota « structures » du pack du propriétaire.
  perform pg_advisory_xact_lock(hashtextextended('billing:' || v_org.owner_id::text, 0));
  perform private.billing_check_limit(private.billing_account_plan(v_org.owner_id), 'structures',
    1 + (select count(*) from public.organizations o
          where o.owner_id = v_org.owner_id and o.status = 'active'));
  update public.organizations o
     set status = 'active', disabled_at = null, disabled_reason = null, trashed_at = null,
         updated_at = now()
   where o.id = p_organization_id;
  perform private.log_admin_action('admin.organization_restored', 'organization',
    p_organization_id, v_reason, '{}'::jsonb, p_organization_id);
  if private.should_notify(p_notify) then
    perform private.notify_user(v_org.owner_id,
      'Structure restaurée', 'Organization restored',
      'L''équipe Tikéo a restauré « ' || v_org.name || ' ». Motif : ' || v_reason,
      'The Tikéo team restored “' || v_org.name || '”. Reason: ' || v_reason);
  end if;
end;
$$;
revoke all on function public.admin_restore_organization(uuid, text, boolean) from public, anon;
grant execute on function public.admin_restore_organization(uuid, text, boolean) to authenticated;

-- Effacement : la ligne reste (journal, assignations) mais anonymisée ;
-- membres, invitations et réglages sont effacés.
create function private.purge_trashed_organization(p_organization_id uuid, p_reason text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  delete from public.organization_members m where m.organization_id = p_organization_id;
  delete from public.organization_invitations i where i.organization_id = p_organization_id;
  delete from public.organization_settings s where s.organization_id = p_organization_id;
  update public.organizations o
     set name = 'Structure supprimée',
         slug = 'supprimee-' || replace(o.id::text, '-', ''),
         logo_path = null, phone = null, contact_email = null, city = null,
         public_phone = null, disabled_reason = null, purged_at = now(), updated_at = now()
   where o.id = p_organization_id;
  perform private.log_admin_action('admin.organization_purged', 'organization',
    p_organization_id, p_reason, '{}'::jsonb, p_organization_id);
end;
$$;
revoke all on function private.purge_trashed_organization(uuid, text) from public, anon, authenticated;

-- Tâche planifiée : corbeille de plus de 30 jours.
create function private.purge_due_organizations()
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  r record;
  v_count integer := 0;
begin
  for r in
    select o.id from public.organizations o
     where o.trashed_at is not null and o.purged_at is null
       and o.trashed_at <= now() - interval '30 days'
     for update skip locked
  loop
    perform private.purge_trashed_organization(r.id, 'Corbeille : 30 jours écoulés');
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;
revoke all on function private.purge_due_organizations() from public, anon, authenticated;

create function public.admin_purge_organization_now(
  p_organization_id uuid,
  p_confirm_name text,
  p_reason text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_org public.organizations%rowtype;
begin
  perform private.require_admin('organizations_delete');
  perform private.require_admin_mfa();
  select * into v_org from public.organizations o where o.id = p_organization_id for update;
  if not found or v_org.purged_at is not null then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable.';
  end if;
  if v_org.trashed_at is null then
    raise exception 'organization_not_trashed'
      using errcode = '55000', detail = 'Cette structure n''est pas à la corbeille.';
  end if;
  if lower(btrim(coalesce(p_confirm_name, ''))) <> lower(v_org.name) then
    raise exception 'confirmation_mismatch'
      using errcode = '22023', detail = 'Saisissez exactement le nom de la structure.';
  end if;
  perform private.purge_trashed_organization(p_organization_id, v_reason);
end;
$$;
revoke all on function public.admin_purge_organization_now(uuid, text, text) from public, anon;
grant execute on function public.admin_purge_organization_now(uuid, text, text) to authenticated;

-- Effacement automatique chaque nuit, là où pg_cron existe (staging).
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('tikeo-trash-purge', '23 3 * * *',
                          'select private.purge_due_organizations()');
  else
    raise notice 'pg_cron absent : corbeille non vidée automatiquement.';
  end if;
end;
$$;
