-- =============================================================================
-- Tikéo — Migration 4800 : double authentification des administrateurs
-- (lot 4-8b, ADR 0037)
-- =============================================================================
-- Proposée, pas obligatoire (décision du 21/11). Un administrateur qui a un
-- facteur TOTP vérifié (Supabase Auth, auth.mfa_factors) n'utilise la console
-- qu'avec une session de niveau aal2 (claim `aal` du jeton) : sinon
-- `mfa_required`. Sans facteur, rien ne change.
--
-- Codes de secours : 8 codes à usage unique, affichés une seule fois, gardés
-- en empreinte SHA-256 (jamais en clair). Un code de secours retire les
-- facteurs du compte (la console redevient accessible à aal1) ; 5 essais par
-- heure.
--
--   admin_mfa_status()               : facteur, niveau de la session, codes restants
--   admin_generate_recovery_codes()  : nouveaux codes (remplacent les anciens), aal2
--   admin_use_recovery_code(code)    : à aal1, retire les facteurs du compte
--
-- Erreurs : 42501 forbidden | mfa_required ; 55000 mfa_not_enrolled ;
--           54000 recovery_rate_limited (un code inconnu renvoie faux)
-- =============================================================================

-- Compte administrateur actif (sans condition de double authentification).
create function private.is_admin_account()
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
revoke all on function private.is_admin_account() from public, anon, authenticated;

-- Facteur TOTP vérifié pour le compte ?
create function private.has_verified_factor(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from auth.mfa_factors f
    where f.user_id = p_user and f.status::text = 'verified'
  )
$$;
revoke all on function private.has_verified_factor(uuid) from public, anon, authenticated;

-- Niveau de la session (claim `aal` du jeton).
create function private.session_aal()
returns text
language sql
stable
set search_path = ''
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'aal',
    'aal1')
$$;
revoke all on function private.session_aal() from public, anon, authenticated;

-- Administrateur autorisé : compte actif ET, s'il a un facteur, session aal2.
create or replace function private.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_admin_account()
     and (not private.has_verified_factor(auth.uid()) or private.session_aal() = 'aal2')
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
end;
$$;
revoke all on function private.require_platform_admin() from public, anon, authenticated;

-- L'entrée « Console » reste visible : le code est demandé à l'ouverture.
create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_admin_account()
$$;

-- -----------------------------------------------------------------------------
-- Codes de secours
-- -----------------------------------------------------------------------------
create table private.admin_recovery_codes (
  user_id uuid not null references public.profiles (id) on delete cascade,
  code_hash text not null,
  created_at timestamptz not null default now(),
  used_at timestamptz,
  primary key (user_id, code_hash)
);
revoke all on private.admin_recovery_codes from public, anon, authenticated;

create table private.admin_recovery_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  at timestamptz not null default now()
);
create index admin_recovery_attempts_user_idx on private.admin_recovery_attempts (user_id, at desc);
revoke all on private.admin_recovery_attempts from public, anon, authenticated;

-- Code saisi → forme canonique (majuscules, sans tiret ni espace).
create function private.recovery_code_hash(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select encode(extensions.digest(
    upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g')), 'sha256'), 'hex')
$$;
revoke all on function private.recovery_code_hash(text) from public, anon, authenticated;

create function public.admin_mfa_status()
returns jsonb
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
  return jsonb_build_object(
    'enrolled', private.has_verified_factor(auth.uid()),
    'aal', private.session_aal(),
    'recovery_codes_left',
      (select count(*) from private.admin_recovery_codes c
        where c.user_id = auth.uid() and c.used_at is null));
end;
$$;
revoke all on function public.admin_mfa_status() from public, anon;
grant execute on function public.admin_mfa_status() to authenticated;

-- 8 nouveaux codes (XXXXX-XXXXX), renvoyés une seule fois ; les anciens
-- sont effacés.
create function public.admin_generate_recovery_codes()
returns text[]
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_codes text[] := '{}';
  v_code text;
  v_bytes bytea;
begin
  perform private.require_platform_admin();
  if not private.has_verified_factor(auth.uid()) then
    raise exception 'mfa_not_enrolled'
      using errcode = '55000', detail = 'Activez d''abord la double authentification.';
  end if;
  delete from private.admin_recovery_codes c where c.user_id = auth.uid();
  for i in 1..8 loop
    v_bytes := extensions.gen_random_bytes(10);
    v_code := '';
    for j in 0..9 loop
      v_code := v_code || substr(v_alphabet, (get_byte(v_bytes, j) % 31) + 1, 1);
    end loop;
    v_codes := v_codes || (substr(v_code, 1, 5) || '-' || substr(v_code, 6, 5));
    insert into private.admin_recovery_codes (user_id, code_hash)
    values (auth.uid(), private.recovery_code_hash(v_code))
    on conflict do nothing;
  end loop;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.mfa_codes_generated', 'profile', auth.uid(),
          jsonb_build_object('count', 8));
  return v_codes;
end;
$$;
revoke all on function public.admin_generate_recovery_codes() from public, anon;
grant execute on function public.admin_generate_recovery_codes() to authenticated;

-- Téléphone perdu : un code de secours retire les facteurs du compte.
-- Renvoie faux pour un code inconnu (sans erreur : l'essai reste compté).
create function public.admin_use_recovery_code(p_code text)
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
begin
  if not private.is_admin_account() then
    raise exception 'forbidden'
      using errcode = '42501', detail = 'Réservé aux administrateurs de Tikéo.';
  end if;
  if not private.has_verified_factor(v_user) then
    raise exception 'mfa_not_enrolled'
      using errcode = '55000', detail = 'La double authentification n''est pas activée.';
  end if;
  if (select count(*) from private.admin_recovery_attempts a
       where a.user_id = v_user and a.at > now() - interval '1 hour') >= 5 then
    raise exception 'recovery_rate_limited'
      using errcode = '54000', detail = 'Trop d''essais : réessayez dans une heure.';
  end if;
  insert into private.admin_recovery_attempts (user_id) values (v_user);
  update private.admin_recovery_codes c
     set used_at = now()
   where c.user_id = v_user and c.code_hash = private.recovery_code_hash(p_code)
     and c.used_at is null;
  if not found then
    return false;
  end if;
  delete from auth.mfa_factors f where f.user_id = v_user;
  delete from private.admin_recovery_codes c where c.user_id = v_user;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, v_user, 'admin.mfa_recovered', 'profile', v_user, '{}'::jsonb);
  return true;
end;
$$;
revoke all on function public.admin_use_recovery_code(text) from public, anon;
grant execute on function public.admin_use_recovery_code(text) to authenticated;
