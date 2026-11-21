-- =============================================================================
-- Tikéo — Console : attribuer une structure à un compte (#10, ADR 0030)
-- =============================================================================
-- * admin_account_structures(compte) : structures du compte (rôle, état).
-- * admin_assign_organization(compte, structure, rôle, motif) :
--   - « owner » : transfert ; l'ancien propriétaire devient gestionnaire ;
--     quota « structures » du pack du nouveau propriétaire vérifié ;
--   - « manager » / « controller » : ajout ou changement de rôle ;
--   - motif obligatoire, gardé dans une table privée (pas dans le journal) ;
--   - journal `admin.organization_assigned` (rôle, transfert : pas de nom) ;
--   - notification aux comptes concernés, dans leur langue.
-- =============================================================================

-- Historique des attributions, avec le motif (jamais lu par l'API).
create table private.organization_assignments (
  id bigint generated always as identity primary key,
  organization_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.member_role not null,
  previous_owner_id uuid references public.profiles (id) on delete set null,
  reason text not null check (char_length(reason) between 1 and 500),
  assigned_by uuid references public.profiles (id) on delete set null,
  assigned_at timestamptz not null default now()
);
revoke all on private.organization_assignments from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Structures d'un compte
-- -----------------------------------------------------------------------------
create function public.admin_account_structures(p_user_id uuid)
returns table (
  organization_id uuid,
  name text,
  role public.member_role,
  active boolean,
  organization_status text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return query
  select o.id, o.name, m.role, m.active, o.status::text
    from public.organization_members m
    join public.organizations o on o.id = m.organization_id
   where m.user_id = p_user_id
   order by m.active desc, (m.role = 'owner') desc, o.name;
end;
$$;
revoke all on function public.admin_account_structures(uuid) from public, anon;
grant execute on function public.admin_account_structures(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Attribution
-- -----------------------------------------------------------------------------
create function public.admin_assign_organization(
  p_user_id uuid,
  p_organization_id uuid,
  p_role public.member_role,
  p_reason text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
  v_profile public.profiles%rowtype;
  v_org public.organizations%rowtype;
  v_previous uuid;
  v_transfer boolean := p_role = 'owner';
begin
  perform private.require_platform_admin();
  if p_role is null then
    raise exception 'role_invalid' using errcode = '22023', detail = 'Rôle manquant.';
  end if;
  if v_reason is null then
    raise exception 'reason_required'
      using errcode = '22023', detail = 'Indiquez le motif de l''attribution.';
  end if;
  if char_length(v_reason) > 500 then
    raise exception 'reason_too_long'
      using errcode = '22023', detail = 'Motif trop long (500 caractères au plus).';
  end if;

  select * into v_profile from public.profiles p where p.id = p_user_id;
  if not found then
    raise exception 'account_not_found' using errcode = 'P0002', detail = 'Compte introuvable.';
  end if;
  if v_profile.deleted_at is not null or v_profile.status <> 'active' then
    raise exception 'account_inactive'
      using errcode = '55000', detail = 'Ce compte est désactivé ou supprimé.';
  end if;

  select * into v_org from public.organizations o where o.id = p_organization_id for update;
  if not found then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable.';
  end if;
  v_previous := v_org.owner_id;

  if v_transfer then
    if v_previous = p_user_id then
      raise exception 'already_owner'
        using errcode = '55000', detail = 'Ce compte est déjà propriétaire de cette structure.';
    end if;
    -- Quota « structures » du pack du nouveau propriétaire.
    perform pg_advisory_xact_lock(hashtextextended('billing:' || p_user_id::text, 0));
    perform private.billing_check_limit(private.billing_account_plan(p_user_id), 'structures',
      1 + (select count(*) from public.organizations o
            where o.owner_id = p_user_id and o.status = 'active'));
    update public.organizations o
       set owner_id = p_user_id, updated_at = now()
     where o.id = p_organization_id;
    -- L'ancien propriétaire reste dans l'équipe, comme gestionnaire.
    insert into public.organization_members (organization_id, user_id, role, active)
    values (p_organization_id, v_previous, 'manager', true)
    on conflict (organization_id, user_id)
      do update set role = 'manager', active = true;
  elsif v_previous = p_user_id then
    raise exception 'owner_role_locked'
      using errcode = '55000',
            detail = 'Ce compte est propriétaire : transférez d''abord la structure à un autre compte.';
  end if;

  insert into public.organization_members (organization_id, user_id, role, active)
  values (p_organization_id, p_user_id, p_role, true)
  on conflict (organization_id, user_id)
    do update set role = excluded.role, active = true;

  insert into private.organization_assignments
    (organization_id, user_id, role, previous_owner_id, reason, assigned_by)
  values (p_organization_id, p_user_id, p_role,
          case when v_transfer then v_previous end, v_reason, auth.uid());

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, auth.uid(), 'admin.organization_assigned', 'account', p_user_id,
          jsonb_build_object('role', p_role, 'transfer', v_transfer));

  -- Notifications, dans la langue de chacun.
  insert into public.push_outbox (user_id, title, body, route)
  select p.id,
         case p.locale when 'en' then 'New organization' else 'Nouvelle structure' end,
         case p.locale
           when 'en' then 'You are now '
             || case p_role when 'owner' then 'the owner' when 'manager' then 'a manager'
                            else 'a controller' end
             || ' of “' || v_org.name || '”.'
           else 'Vous êtes maintenant '
             || case p_role when 'owner' then 'propriétaire' when 'manager' then 'gestionnaire'
                            else 'contrôleur' end
             || ' de « ' || v_org.name || ' ».'
         end,
         '/profil'
    from public.profiles p
   where p.id = p_user_id;
  if v_transfer then
    insert into public.push_outbox (user_id, title, body, route)
    select p.id,
           case p.locale when 'en' then 'Organization transferred' else 'Structure transférée' end,
           case p.locale
             when 'en' then '“' || v_org.name || '” has a new owner. You remain a manager.'
             else '« ' || v_org.name || ' » a un nouveau propriétaire. Vous restez gestionnaire.'
           end,
           '/profil'
      from public.profiles p
     where p.id = v_previous;
  end if;

  return jsonb_build_object(
    'organization_id', p_organization_id,
    'user_id', p_user_id,
    'role', p_role,
    'previous_owner_id', case when v_transfer then v_previous end);
end;
$$;
revoke all on function public.admin_assign_organization(uuid, uuid, public.member_role, text)
  from public, anon;
grant execute on function public.admin_assign_organization(uuid, uuid, public.member_role, text)
  to authenticated;
