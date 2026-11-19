-- =============================================================================
-- TicketSûr — Migration 1200 : profil modifiable et fiche d'organisation
-- =============================================================================
-- Profil : nom affiché, photo, téléphone, langue, demande de suppression du
-- compte (délai de 30 jours, purge effectuée plus tard par l'administration).
-- L'e-mail et le mot de passe restent gérés par Supabase Auth.
--
-- Organisation : nom, logo, téléphone, e-mail de contact, ville, modifiables
-- par les propriétaires ; un membre peut quitter une organisation, sauf le
-- dernier propriétaire actif.
--
-- Images : buckets publics « avatars » (<utilisateur>/<fichier>) et
-- « org-logos » (<organisation>/<fichier>), 1 Mo, JPEG/PNG/WebP.
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   22023 profile_name_invalid | profile_phone_invalid | profile_locale_invalid
--         | profile_avatar_invalid | org_name_invalid | org_phone_invalid
--         | org_email_invalid | org_city_invalid | org_logo_invalid
--   42501 org_not_found          organisation inconnue ou droits insuffisants
--   55000 org_last_owner         dernier propriétaire actif : départ refusé
-- =============================================================================

alter table public.profiles
  add column avatar_path text check (avatar_path is null or char_length(avatar_path) <= 200),
  add column phone text check (phone is null or phone ~ '^\+[1-9][0-9]{7,14}$'),
  add column locale text not null default 'fr' check (locale in ('fr', 'en')),
  add column deletion_requested_at timestamptz;

alter table public.organizations
  add column logo_path text check (logo_path is null or char_length(logo_path) <= 200),
  add column phone text check (phone is null or phone ~ '^\+[1-9][0-9]{7,14}$'),
  add column contact_email text check (contact_email is null or char_length(contact_email) <= 254),
  add column city text check (city is null or char_length(city) between 2 and 80);

-- Téléphone saisi librement (+226 70 00 00 00, 0022670000000, 70000000) →
-- format international ; null si vide. Numéro à 8 chiffres : Burkina Faso.
create or replace function private.normalize_phone(p_phone text)
returns text
language sql
immutable
set search_path = ''
as $$
  with digits as (
    select case
      when trim(coalesce(p_phone, '')) = '' then null
      when trim(p_phone) like '+%' then '+' || regexp_replace(p_phone, '[^0-9]', '', 'g')
      when regexp_replace(p_phone, '[^0-9]', '', 'g') like '00%'
        then '+' || substr(regexp_replace(p_phone, '[^0-9]', '', 'g'), 3)
      when char_length(regexp_replace(p_phone, '[^0-9]', '', 'g')) = 8
        then '+226' || regexp_replace(p_phone, '[^0-9]', '', 'g')
      else '+' || regexp_replace(p_phone, '[^0-9]', '', 'g')
    end as value
  )
  select value from digits
$$;
revoke all on function private.normalize_phone(text) from public, anon, authenticated;

-- Fichier image placé dans le dossier [p_folder] d'un bucket, nom aléatoire.
create or replace function private.image_name_ok(p_name text, p_folder text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select p_folder is not null
     and split_part(coalesce(p_name, ''), '/', 1) = p_folder
     and array_length(string_to_array(p_name, '/'), 1) = 2
     and split_part(p_name, '/', 2) ~ '^[A-Za-z0-9_-]{8,64}\.(jpg|jpeg|png|webp)$'
$$;
revoke all on function private.image_name_ok(text, text) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Buckets et règles d'accès
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 1048576, array['image/jpeg', 'image/png', 'image/webp']),
  ('org-logos', 'org-logos', true, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Dossier <organisation>/ géré par l'appelant (propriétaire).
create or replace function private.can_manage_org_logo(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_folder text := split_part(coalesce(p_name, ''), '/', 1);
begin
  if v_folder !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     or not private.image_name_ok(p_name, v_folder) then
    return false;
  end if;
  return private.has_org_role(v_folder::uuid, array['owner']::public.member_role[]);
end;
$$;
revoke all on function private.can_manage_org_logo(text) from public, anon;
grant execute on function private.can_manage_org_logo(text) to authenticated;

create policy avatars_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and private.image_name_ok(name, auth.uid()::text));
create policy avatars_select on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and private.image_name_ok(name, auth.uid()::text));
create policy avatars_delete on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and private.image_name_ok(name, auth.uid()::text));

create policy org_logos_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'org-logos' and private.can_manage_org_logo(name));
create policy org_logos_select on storage.objects for select to authenticated
  using (bucket_id = 'org-logos' and private.can_manage_org_logo(name));
create policy org_logos_delete on storage.objects for delete to authenticated
  using (bucket_id = 'org-logos' and private.can_manage_org_logo(name));

grant execute on function private.image_name_ok(text, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Profil
-- -----------------------------------------------------------------------------
-- Profil de l'utilisateur connecté (lecture seule, sans statut interne).
create or replace function public.my_profile()
returns table (
  id uuid, display_name text, avatar_path text, phone text, locale text,
  deletion_requested_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select p.id, p.display_name, p.avatar_path, p.phone, p.locale, p.deletion_requested_at
  from public.profiles p
  where p.id = auth.uid()
$$;
revoke all on function public.my_profile() from public, anon;
grant execute on function public.my_profile() to authenticated;

create or replace function private.require_active_profile()
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
     or not exists (select 1 from public.profiles p where p.id = v_actor and p.status = 'active') then
    raise exception 'Authentification requise' using errcode = '42501';
  end if;
  return v_actor;
end;
$$;
revoke all on function private.require_active_profile() from public, anon, authenticated;

create or replace function public.update_my_profile(
  p_display_name text,
  p_phone text default null,
  p_locale text default 'fr'
)
returns setof public.profiles
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_active_profile();
  v_name text := private.normalize_text(p_display_name);
  v_phone text := private.normalize_phone(p_phone);
begin
  if v_name is null or char_length(v_name) not between 2 and 60 then
    raise exception 'profile_name_invalid'
      using errcode = '22023', detail = 'Nom de 2 à 60 caractères.';
  end if;
  if v_phone is not null and v_phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'profile_phone_invalid'
      using errcode = '22023', detail = 'Numéro de téléphone invalide.';
  end if;
  if p_locale is null or p_locale not in ('fr', 'en') then
    raise exception 'profile_locale_invalid'
      using errcode = '22023', detail = 'Langue inconnue.';
  end if;

  return query
  update public.profiles p
     set display_name = v_name, phone = v_phone, locale = p_locale, updated_at = now()
   where p.id = v_actor
  returning p.*;
end;
$$;
revoke all on function public.update_my_profile(text, text, text) from public, anon;
grant execute on function public.update_my_profile(text, text, text) to authenticated;

create or replace function public.set_my_avatar(p_path text)
returns setof public.profiles
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_active_profile();
begin
  if p_path is not null
     and (not private.image_name_ok(p_path, v_actor::text)
          or not exists (select 1 from storage.objects o
                         where o.bucket_id = 'avatars' and o.name = p_path)) then
    raise exception 'profile_avatar_invalid'
      using errcode = '22023', detail = 'Photo introuvable ou mal placée.';
  end if;
  return query
  update public.profiles p
     set avatar_path = p_path, updated_at = now()
   where p.id = v_actor
  returning p.*;
end;
$$;
revoke all on function public.set_my_avatar(text) from public, anon;
grant execute on function public.set_my_avatar(text) to authenticated;

-- Demande (true) ou annulation (false) de la suppression du compte. La purge
-- effective, après 30 jours, sera faite par la console d'administration.
create or replace function public.request_account_deletion(p_requested boolean)
returns timestamptz
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_active_profile();
  v_at timestamptz;
begin
  update public.profiles p
     set deletion_requested_at = case when p_requested then coalesce(p.deletion_requested_at, now()) end,
         updated_at = now()
   where p.id = v_actor
  returning p.deletion_requested_at into v_at;
  return v_at;
end;
$$;
revoke all on function public.request_account_deletion(boolean) from public, anon;
grant execute on function public.request_account_deletion(boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Organisation
-- -----------------------------------------------------------------------------
drop function public.my_organizations();
create function public.my_organizations()
returns table (
  id uuid, name text, slug text, role public.member_role,
  logo_path text, phone text, contact_email text, city text
)
language sql
stable
security invoker
set search_path = ''
as $$
  select o.id, o.name, o.slug, m.role, o.logo_path, o.phone, o.contact_email, o.city
  from public.organization_members m
  join public.organizations o on o.id = m.organization_id
  where m.user_id = auth.uid()
    and m.active
    and o.status = 'active'
  order by o.created_at, o.name
$$;
revoke all on function public.my_organizations() from public, anon;
grant execute on function public.my_organizations() to authenticated;

create or replace function private.lock_owned_organization(p_org uuid)
returns public.organizations
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_org public.organizations%rowtype;
begin
  select * into v_org from public.organizations o where o.id = p_org for update;
  if not found or v_org.status <> 'active'
     or not private.has_org_role(p_org, array['owner']::public.member_role[]) then
    raise exception 'org_not_found'
      using errcode = '42501', detail = 'Organisation introuvable ou droits insuffisants.';
  end if;
  return v_org;
end;
$$;
revoke all on function private.lock_owned_organization(uuid) from public, anon, authenticated;

create or replace function public.update_organization(
  p_organization_id uuid,
  p_name text,
  p_phone text default null,
  p_contact_email text default null,
  p_city text default null
)
returns public.organizations
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_name text := private.normalize_text(p_name);
  v_phone text := private.normalize_phone(p_phone);
  v_email text := lower(private.normalize_text(p_contact_email));
  v_city text := private.normalize_text(p_city);
  v_org public.organizations%rowtype;
begin
  v_org := private.lock_owned_organization(p_organization_id);
  if v_name is null or char_length(v_name) not between 2 and 120 then
    raise exception 'org_name_invalid'
      using errcode = '22023', detail = 'Nom de 2 à 120 caractères.';
  end if;
  if v_phone is not null and v_phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'org_phone_invalid'
      using errcode = '22023', detail = 'Numéro de téléphone invalide.';
  end if;
  if v_email is not null
     and (char_length(v_email) > 254 or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$') then
    raise exception 'org_email_invalid'
      using errcode = '22023', detail = 'Adresse e-mail invalide.';
  end if;
  if v_city is not null and char_length(v_city) not between 2 and 80 then
    raise exception 'org_city_invalid'
      using errcode = '22023', detail = 'Ville de 2 à 80 caractères.';
  end if;

  update public.organizations o
     set name = v_name, phone = v_phone, contact_email = v_email, city = v_city,
         updated_at = now()
   where o.id = p_organization_id
  returning * into v_org;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org.id, v_actor, 'organization.updated', 'organization', v_org.id, '{}'::jsonb);
  return v_org;
end;
$$;
revoke all on function public.update_organization(uuid, text, text, text, text) from public, anon;
grant execute on function public.update_organization(uuid, text, text, text, text) to authenticated;

create or replace function public.set_organization_logo(p_organization_id uuid, p_path text)
returns public.organizations
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_org public.organizations%rowtype;
begin
  v_org := private.lock_owned_organization(p_organization_id);
  if p_path is not null
     and (not private.image_name_ok(p_path, p_organization_id::text)
          or not exists (select 1 from storage.objects o
                         where o.bucket_id = 'org-logos' and o.name = p_path)) then
    raise exception 'org_logo_invalid'
      using errcode = '22023', detail = 'Logo introuvable ou mal placé.';
  end if;
  update public.organizations o
     set logo_path = p_path, updated_at = now()
   where o.id = p_organization_id
  returning * into v_org;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org.id, v_actor, 'organization.logo_changed', 'organization', v_org.id,
          jsonb_build_object('removed', p_path is null));
  return v_org;
end;
$$;
revoke all on function public.set_organization_logo(uuid, text) from public, anon;
grant execute on function public.set_organization_logo(uuid, text) to authenticated;

-- Quitter une organisation : l'appartenance et les affectations aux
-- événements de l'organisation sont retirées. Le dernier propriétaire actif
-- ne peut pas partir (l'organisation resterait sans responsable).
create or replace function public.leave_organization(p_organization_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_active_profile();
  v_member public.organization_members%rowtype;
begin
  -- Verrou de l'organisation : deux propriétaires qui partent en même temps
  -- ne la laissent pas sans propriétaire.
  perform 1 from public.organizations o where o.id = p_organization_id for update;
  select * into v_member from public.organization_members m
  where m.organization_id = p_organization_id and m.user_id = v_actor and m.active;
  if not found then
    raise exception 'org_not_found'
      using errcode = '42501', detail = 'Vous n''êtes pas membre de cette organisation.';
  end if;
  if v_member.role = 'owner'
     and not exists (select 1 from public.organization_members m
                     where m.organization_id = p_organization_id and m.role = 'owner'
                       and m.active and m.user_id <> v_actor) then
    raise exception 'org_last_owner'
      using errcode = '55000',
            detail = 'Nommez un autre propriétaire avant de quitter l''organisation.';
  end if;

  delete from public.event_assignments a
  using public.events e
  where a.event_id = e.id and e.organization_id = p_organization_id and a.user_id = v_actor;

  update public.organization_members m
     set active = false
   where m.organization_id = p_organization_id and m.user_id = v_actor;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, v_actor, 'member.left', 'member', v_actor, '{}'::jsonb);
end;
$$;
revoke all on function public.leave_organization(uuid) from public, anon;
grant execute on function public.leave_organization(uuid) to authenticated;
