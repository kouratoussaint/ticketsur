-- =============================================================================
-- TicketSûr — Migration 0500 : création d'organisation en libre-service
-- =============================================================================
-- Décision du 2026-11-18 (ADR 0007) : tout utilisateur connecté et actif peut
-- créer une organisation et en devient propriétaire. Garde-fou anti-abus
-- (inscription ouverte) : 5 organisations actives au plus par propriétaire.
-- =============================================================================

-- Identifiant d'URL lisible : « Nuits Sacrées 2026 » → « nuits-sacrees-2026 ».
create or replace function private.slugify(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select coalesce(
    nullif(
      left(
        trim(both '-' from regexp_replace(
          translate(
            lower(coalesce(p_text, '')),
            'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ',
            'aaaaaaceeeeiiiinooooouuuuyyoa'
          ),
          '[^a-z0-9]+', '-', 'g'
        )),
        50
      ),
      ''
    ),
    'organisation'
  )
$$;
revoke all on function private.slugify(text) from public, anon, authenticated;

create or replace function public.create_organization(p_name text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  c_max_owned constant integer := 5;
  v_actor uuid := auth.uid();
  v_name text := regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_base text;
  v_slug text;
  v_org public.organizations%rowtype;
begin
  if v_actor is null
     or not exists (select 1 from public.profiles p
                    where p.id = v_actor and p.status = 'active') then
    raise exception 'Authentification requise' using errcode = '42501';
  end if;
  if char_length(v_name) not between 2 and 120 then
    raise exception 'Nom d''organisation invalide (2 à 120 caractères)'
      using errcode = '22023';
  end if;

  -- Verrou par utilisateur : deux créations simultanées ne contournent pas
  -- la limite.
  perform pg_advisory_xact_lock(hashtextextended('create_organization:' || v_actor::text, 0));
  if (select count(*) from public.organizations o
      where o.owner_id = v_actor and o.status = 'active') >= c_max_owned then
    raise exception 'Limite de % organisations atteinte', c_max_owned
      using errcode = '53400';
  end if;

  v_base := private.slugify(v_name);
  if char_length(v_base) < 2 then
    v_base := v_base || '-org';
  end if;
  v_slug := v_base;
  while exists (select 1 from public.organizations o where o.slug = v_slug) loop
    v_slug := left(v_base, 45) || '-' || lower(substr(md5(gen_random_uuid()::text), 1, 4));
  end loop;

  insert into public.organizations (name, slug, owner_id)
  values (v_name, v_slug, v_actor)
  returning * into v_org;

  insert into public.organization_members (organization_id, user_id, role)
  values (v_org.id, v_actor, 'owner');

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org.id, v_actor, 'organization.created', 'organization', v_org.id,
          jsonb_build_object('slug', v_org.slug));

  return jsonb_build_object('id', v_org.id, 'name', v_org.name,
                            'slug', v_org.slug, 'role', 'owner');
end;
$$;
revoke all on function public.create_organization(text) from public, anon;
grant execute on function public.create_organization(text) to authenticated;

-- Organisations de l'utilisateur courant, avec son rôle (RLS appliquée :
-- fonction exécutée avec les droits de l'appelant).
create or replace function public.my_organizations()
returns table (id uuid, name text, slug text, role public.member_role)
language sql
stable
security invoker
set search_path = ''
as $$
  select o.id, o.name, o.slug, m.role
  from public.organization_members m
  join public.organizations o on o.id = m.organization_id
  where m.user_id = auth.uid()
    and m.active
    and o.status = 'active'
  order by o.created_at, o.name
$$;
revoke all on function public.my_organizations() from public, anon;
grant execute on function public.my_organizations() to authenticated;
