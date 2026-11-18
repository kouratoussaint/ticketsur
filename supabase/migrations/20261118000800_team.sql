-- =============================================================================
-- TicketSûr — Migration 0800 : équipe — invitations, membres, affectations
-- (ORG-02, ORG-03, EVT-04 / S16, S17)
-- =============================================================================
-- Invitations par CODE à partager (WhatsApp, SMS…), sans service d'e-mail :
--   * code « TSI-XXXX-XXXX-XXXX » (12 caractères base32, 60 bits), renvoyé UNE
--     fois à la création ; seule son empreinte SHA-256 est conservée ;
--   * expiration (7 jours par défaut), nombre d'utilisations (1 par défaut),
--     révocation ;
--   * propriétaire : invite gestionnaires et contrôleurs ; gestionnaire :
--     contrôleurs uniquement ;
--   * essais de codes invalides limités : 10 échecs par compte sur 15 min.
--     accept_invitation RENVOIE un résultat au lieu de lever une exception
--     pour que l'échec soit bien enregistré (une exception annulerait
--     l'écriture du compteur).
-- Membres : rôle (propriétaire seul) et activation. Désactiver un membre
-- coupe ses scans au prochain appel (validate_scan exige m.active).
-- Affectations : membre actif → événement, porte précise ou toutes.
--
-- Erreurs (MESSAGE = code stable) :
--   42501 org_forbidden | event_not_found | invitation_not_found | assignment_not_found
--   22023 invitation_role_invalid | invitation_params_invalid | member_not_found
--         | checkpoint_not_found
--   55000 member_is_owner | member_is_self | event_locked
-- =============================================================================

create table public.organization_invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  role public.member_role not null check (role in ('manager', 'controller')),
  code_hash bytea not null unique,
  -- Quatre derniers caractères, pour reconnaître un code dans la liste.
  code_hint text not null check (code_hint ~ '^[0-9A-Z]{4}$'),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  max_uses integer not null default 1 check (max_uses between 1 and 100),
  uses integer not null default 0 check (uses >= 0),
  revoked_at timestamptz,
  check (uses <= max_uses)
);
create index organization_invitations_org_idx
  on public.organization_invitations (organization_id, created_at desc);
alter table public.organization_invitations enable row level security;
-- Aucun accès direct : lecture par organization_invitations_list().
revoke all on public.organization_invitations from anon, authenticated;

create table private.invitation_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  succeeded boolean not null,
  attempted_at timestamptz not null default now()
);
create index invitation_attempts_user_idx on private.invitation_attempts (user_id, attempted_at desc);
revoke all on private.invitation_attempts from public, anon, authenticated;

-- Code d'invitation : 32 symboles sans 0/O ni 1/I (dictée au téléphone).
create or replace function private.new_invitation_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_bytes bytea := extensions.gen_random_bytes(12);
  v_out text := '';
begin
  for i in 0..11 loop
    v_out := v_out || substr(v_alphabet, (get_byte(v_bytes, i) % 32) + 1, 1);
  end loop;
  return 'TSI-' || substr(v_out, 1, 4) || '-' || substr(v_out, 5, 4) || '-' || substr(v_out, 9, 4);
end;
$$;
revoke all on function private.new_invitation_code() from public, anon, authenticated;

-- Forme canonique d'un code saisi : majuscules, sans espaces ni tirets,
-- préfixe « TSI » ajouté s'il a été omis.
create or replace function private.normalize_invitation_code(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case when char_length(v) = 12 then 'TSI' || v else v end
  from (select upper(regexp_replace(coalesce(p_code, ''), '[^0-9A-Za-z]', '', 'g')) as v) x
$$;
revoke all on function private.normalize_invitation_code(text) from public, anon, authenticated;

create or replace function private.invitation_code_hash(p_code text)
returns bytea
language sql
immutable
set search_path = ''
as $$
  select extensions.digest(convert_to(private.normalize_invitation_code(p_code), 'UTF8'), 'sha256')
$$;
revoke all on function private.invitation_code_hash(text) from public, anon, authenticated;

-- L'appelant peut-il inviter / gérer un membre de rôle p_role ?
create or replace function private.can_manage_role(p_org uuid, p_role public.member_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_role = 'owner' then false
    when p_role = 'manager' then private.has_org_role(p_org, array['owner']::public.member_role[])
    else private.has_org_role(p_org, array['owner','manager']::public.member_role[])
  end
$$;
revoke all on function private.can_manage_role(uuid, public.member_role) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Invitations
-- -----------------------------------------------------------------------------
create or replace function public.create_invitation(
  p_organization_id uuid,
  p_role public.member_role,
  p_valid_days integer default 7,
  p_max_uses integer default 1
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_code text;
  v_invitation public.organization_invitations%rowtype;
begin
  if not private.has_org_role(p_organization_id, array['owner','manager']::public.member_role[]) then
    raise exception 'org_forbidden'
      using errcode = '42501', detail = 'Organisation introuvable ou droits insuffisants.';
  end if;
  if p_role is null or p_role = 'owner' then
    raise exception 'invitation_role_invalid'
      using errcode = '22023', detail = 'Rôle : gestionnaire ou contrôleur.';
  end if;
  if not private.can_manage_role(p_organization_id, p_role) then
    raise exception 'org_forbidden'
      using errcode = '42501', detail = 'Seul le propriétaire invite des gestionnaires.';
  end if;
  if p_valid_days is null or p_valid_days not between 1 and 30
     or p_max_uses is null or p_max_uses not between 1 and 100 then
    raise exception 'invitation_params_invalid'
      using errcode = '22023', detail = 'Validité de 1 à 30 jours, 1 à 100 utilisations.';
  end if;

  loop
    v_code := private.new_invitation_code();
    begin
      insert into public.organization_invitations
        (organization_id, role, code_hash, code_hint, created_by, expires_at, max_uses)
      values
        (p_organization_id, p_role, private.invitation_code_hash(v_code), right(v_code, 4),
         auth.uid(), now() + make_interval(days => p_valid_days), p_max_uses)
      returning * into v_invitation;
      exit;
    exception when unique_violation then
      null; -- collision (≈ 2^-60) : nouveau tirage
    end;
  end loop;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, auth.uid(), 'invitation.created', 'invitation', v_invitation.id,
          jsonb_build_object('role', p_role, 'expires_at', v_invitation.expires_at,
                             'max_uses', p_max_uses));

  -- Seul moment où le code existe en clair.
  return jsonb_build_object(
    'id', v_invitation.id,
    'code', v_code,
    'role', v_invitation.role,
    'code_hint', v_invitation.code_hint,
    'expires_at', v_invitation.expires_at,
    'max_uses', v_invitation.max_uses,
    'uses', 0
  );
end;
$$;
revoke all on function public.create_invitation(uuid, public.member_role, integer, integer) from public, anon;
grant execute on function public.create_invitation(uuid, public.member_role, integer, integer) to authenticated;

-- Invitations encore utilisables (non révoquées, non expirées, non épuisées).
create or replace function public.organization_invitations_list(p_organization_id uuid)
returns table (
  id uuid,
  role public.member_role,
  code_hint text,
  expires_at timestamptz,
  max_uses integer,
  uses integer,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.has_org_role(p_organization_id, array['owner','manager']::public.member_role[]) then
    raise exception 'org_forbidden'
      using errcode = '42501', detail = 'Organisation introuvable ou droits insuffisants.';
  end if;
  return query
    select i.id, i.role, i.code_hint, i.expires_at, i.max_uses, i.uses, i.created_at
    from public.organization_invitations i
    where i.organization_id = p_organization_id
      and i.revoked_at is null and i.expires_at > now() and i.uses < i.max_uses
    order by i.created_at desc;
end;
$$;
revoke all on function public.organization_invitations_list(uuid) from public, anon;
grant execute on function public.organization_invitations_list(uuid) to authenticated;

create or replace function public.revoke_invitation(p_invitation_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_invitation public.organization_invitations%rowtype;
begin
  select * into v_invitation from public.organization_invitations i
  where i.id = p_invitation_id for update;
  if not found or not private.can_manage_role(v_invitation.organization_id, v_invitation.role) then
    raise exception 'invitation_not_found'
      using errcode = '42501', detail = 'Invitation introuvable ou droits insuffisants.';
  end if;
  update public.organization_invitations i
     set revoked_at = coalesce(i.revoked_at, now())
   where i.id = p_invitation_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_invitation.organization_id, auth.uid(), 'invitation.revoked', 'invitation',
          p_invitation_id, '{}'::jsonb);
end;
$$;
revoke all on function public.revoke_invitation(uuid) from public, anon;
grant execute on function public.revoke_invitation(uuid) to authenticated;

-- Rejoindre une organisation avec un code. Résultat (jamais d'exception
-- pour un code refusé, afin que l'essai soit compté) :
--   {"result": "joined", "organization": {id, name, slug, role}}
--   {"result": "invalid" | "expired" | "already_member" | "rate_limited"
--            | "unauthorized"}
create or replace function public.accept_invitation(p_code text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  c_max_failures constant integer := 10;
  c_window constant interval := interval '15 minutes';
  v_actor uuid := auth.uid();
  v_invitation public.organization_invitations%rowtype;
  v_org public.organizations%rowtype;
  v_member public.organization_members%rowtype;
  v_result text;
begin
  if v_actor is null
     or not exists (select 1 from public.profiles p where p.id = v_actor and p.status = 'active') then
    return jsonb_build_object('result', 'unauthorized');
  end if;

  -- Sérialise les essais d'un même compte (compteur exact).
  perform pg_advisory_xact_lock(hashtextextended('accept_invitation:' || v_actor::text, 0));
  if (select count(*) from private.invitation_attempts a
      where a.user_id = v_actor and not a.succeeded
        and a.attempted_at > now() - c_window) >= c_max_failures then
    return jsonb_build_object('result', 'rate_limited');
  end if;

  select * into v_invitation from public.organization_invitations i
  where i.code_hash = private.invitation_code_hash(p_code)
  for update;

  if not found or v_invitation.revoked_at is not null then
    v_result := 'invalid';
  else
    select * into v_org from public.organizations o where o.id = v_invitation.organization_id;
    select * into v_member from public.organization_members m
    where m.organization_id = v_invitation.organization_id and m.user_id = v_actor;
    if v_org.status <> 'active' then
      v_result := 'invalid';
    elsif v_member.user_id is not null and v_member.active then
      -- Déjà membre (par exemple, code ressaisi juste après l'avoir utilisé).
      v_result := 'already_member';
    elsif v_invitation.expires_at <= now() or v_invitation.uses >= v_invitation.max_uses then
      v_result := 'expired';
    else
      v_result := 'joined';
    end if;
  end if;

  insert into private.invitation_attempts (user_id, succeeded)
  values (v_actor, v_result in ('joined', 'already_member'));

  if v_result <> 'joined' then
    return jsonb_build_object('result', v_result);
  end if;

  -- Un ancien membre désactivé revient avec le rôle de l'invitation.
  insert into public.organization_members (organization_id, user_id, role, active)
  values (v_org.id, v_actor, v_invitation.role, true)
  on conflict (organization_id, user_id)
  do update set role = excluded.role, active = true;

  update public.organization_invitations i set uses = i.uses + 1 where i.id = v_invitation.id;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org.id, v_actor, 'invitation.accepted', 'invitation', v_invitation.id,
          jsonb_build_object('role', v_invitation.role));

  return jsonb_build_object(
    'result', 'joined',
    'organization', jsonb_build_object('id', v_org.id, 'name', v_org.name,
                                       'slug', v_org.slug, 'role', v_invitation.role)
  );
end;
$$;
revoke all on function public.accept_invitation(text) from public, anon;
grant execute on function public.accept_invitation(text) to authenticated;

-- -----------------------------------------------------------------------------
-- Membres
-- -----------------------------------------------------------------------------
create or replace function public.organization_team(p_organization_id uuid)
returns table (
  user_id uuid,
  display_name text,
  email text,
  role public.member_role,
  active boolean,
  joined_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.has_org_role(p_organization_id, array['owner','manager']::public.member_role[]) then
    raise exception 'org_forbidden'
      using errcode = '42501', detail = 'Organisation introuvable ou droits insuffisants.';
  end if;
  return query
    select m.user_id, p.display_name, u.email::text, m.role, m.active, m.created_at
    from public.organization_members m
    join public.profiles p on p.id = m.user_id
    left join auth.users u on u.id = m.user_id
    where m.organization_id = p_organization_id
    order by (m.role = 'owner') desc, m.active desc, (m.role = 'manager') desc,
             p.display_name;
end;
$$;
revoke all on function public.organization_team(uuid) from public, anon;
grant execute on function public.organization_team(uuid) to authenticated;

-- Change le rôle et/ou l'état d'un membre.
--   * personne ne modifie le propriétaire ni ne se modifie soi-même ;
--   * gestionnaire : agit seulement sur des contrôleurs, sans les promouvoir ;
--   * propriétaire : tout, sauf créer un second propriétaire.
create or replace function public.update_member(
  p_organization_id uuid,
  p_user_id uuid,
  p_role public.member_role,
  p_active boolean
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_member public.organization_members%rowtype;
begin
  if not private.has_org_role(p_organization_id, array['owner','manager']::public.member_role[]) then
    raise exception 'org_forbidden'
      using errcode = '42501', detail = 'Organisation introuvable ou droits insuffisants.';
  end if;
  select * into v_member from public.organization_members m
  where m.organization_id = p_organization_id and m.user_id = p_user_id
  for update;
  if not found then
    raise exception 'member_not_found' using errcode = '22023', detail = 'Membre inconnu.';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'member_is_self'
      using errcode = '55000', detail = 'Vous ne pouvez pas modifier votre propre accès.';
  end if;
  if v_member.role = 'owner' then
    raise exception 'member_is_owner'
      using errcode = '55000', detail = 'Le propriétaire ne peut pas être modifié.';
  end if;
  if p_role is null or p_active is null or p_role = 'owner'
     or not private.can_manage_role(p_organization_id, v_member.role)
     or not private.can_manage_role(p_organization_id, p_role) then
    raise exception 'org_forbidden'
      using errcode = '42501', detail = 'Droits insuffisants pour ce changement.';
  end if;

  update public.organization_members m
     set role = p_role, active = p_active
   where m.organization_id = p_organization_id and m.user_id = p_user_id;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, auth.uid(), 'member.updated', 'member', p_user_id,
          jsonb_build_object('from_role', v_member.role, 'role', p_role,
                             'from_active', v_member.active, 'active', p_active));
end;
$$;
revoke all on function public.update_member(uuid, uuid, public.member_role, boolean) from public, anon;
grant execute on function public.update_member(uuid, uuid, public.member_role, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Affectations (S17)
-- -----------------------------------------------------------------------------
create or replace function public.event_team(p_event_id uuid)
returns table (
  id uuid,
  user_id uuid,
  display_name text,
  email text,
  role public.member_role,
  member_active boolean,
  checkpoint_id uuid,
  checkpoint_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org uuid;
begin
  select e.organization_id into v_org from public.events e where e.id = p_event_id;
  if v_org is null
     or not private.has_org_role(v_org, array['owner','manager']::public.member_role[]) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  return query
    select a.id, a.user_id, p.display_name, u.email::text, m.role, m.active,
           a.checkpoint_id, cp.name
    from public.event_assignments a
    join public.profiles p on p.id = a.user_id
    left join auth.users u on u.id = a.user_id
    left join public.organization_members m
      on m.organization_id = v_org and m.user_id = a.user_id
    left join public.checkpoints cp on cp.id = a.checkpoint_id
    where a.event_id = p_event_id and a.active
    order by p.display_name, cp.name nulls first;
end;
$$;
revoke all on function public.event_team(uuid) from public, anon;
grant execute on function public.event_team(uuid) to authenticated;

-- Affecte un membre actif à l'événement (p_checkpoint_id NULL = toutes les
-- portes). Réactive une affectation identique retirée auparavant.
create or replace function public.assign_member(
  p_event_id uuid,
  p_user_id uuid,
  p_checkpoint_id uuid default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
  v_id uuid;
begin
  v_event := private.lock_configurable_event(p_event_id);
  if not exists (select 1 from public.organization_members m
                 join public.profiles p on p.id = m.user_id
                 where m.organization_id = v_event.organization_id
                   and m.user_id = p_user_id and m.active and p.status = 'active') then
    raise exception 'member_not_found'
      using errcode = '22023', detail = 'Membre actif de l''organisation requis.';
  end if;
  if p_checkpoint_id is not null
     and not exists (select 1 from public.checkpoints cp
                     where cp.id = p_checkpoint_id and cp.event_id = p_event_id) then
    raise exception 'checkpoint_not_found'
      using errcode = '22023', detail = 'Porte inconnue pour cet événement.';
  end if;

  select a.id into v_id from public.event_assignments a
  where a.event_id = p_event_id and a.user_id = p_user_id
    and a.checkpoint_id is not distinct from p_checkpoint_id
  for update;
  if v_id is null then
    insert into public.event_assignments (event_id, user_id, checkpoint_id)
    values (p_event_id, p_user_id, p_checkpoint_id)
    returning id into v_id;
  else
    update public.event_assignments a set active = true where a.id = v_id;
  end if;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'assignment.added', 'assignment', v_id,
          jsonb_build_object('event_id', p_event_id, 'user_id', p_user_id,
                             'checkpoint_id', p_checkpoint_id));
  return v_id;
end;
$$;
revoke all on function public.assign_member(uuid, uuid, uuid) from public, anon;
grant execute on function public.assign_member(uuid, uuid, uuid) to authenticated;

-- Retire une affectation (désactivée, conservée pour l'historique des scans).
-- Permis même après clôture : couper un accès doit toujours être possible.
create or replace function public.unassign_member(p_assignment_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_assignment public.event_assignments%rowtype;
  v_event public.events%rowtype;
begin
  select * into v_assignment from public.event_assignments a where a.id = p_assignment_id;
  if not found then
    raise exception 'assignment_not_found'
      using errcode = '42501', detail = 'Affectation introuvable ou droits insuffisants.';
  end if;
  v_event := private.lock_managed_event(v_assignment.event_id);
  update public.event_assignments a set active = false where a.id = p_assignment_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'assignment.removed', 'assignment', p_assignment_id,
          jsonb_build_object('event_id', v_assignment.event_id, 'user_id', v_assignment.user_id));
end;
$$;
revoke all on function public.unassign_member(uuid) from public, anon;
grant execute on function public.unassign_member(uuid) to authenticated;
