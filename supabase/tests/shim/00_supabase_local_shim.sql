-- =============================================================================
-- TicketSûr — Shim Supabase pour PostgreSQL « nu » (CI et tests locaux)
-- =============================================================================
-- NE JAMAIS appliquer sur un projet Supabase : ces objets y existent déjà.
-- Reproduit le strict nécessaire pour exécuter les migrations et les tests :
--   * rôles anon / authenticated / service_role ;
--   * schéma auth (auth.users, auth.sessions, auth.mfa_factors, auth.uid()) ;
--   * schéma extensions avec pgcrypto ;
--   * vue vault.decrypted_secrets (Supabase Vault) alimentée par une table locale.
-- =============================================================================

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
end $$;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
grant usage on schema extensions to anon, authenticated, service_role;

create schema if not exists auth;
grant usage on schema auth to anon, authenticated, service_role;

create table if not exists auth.users (
  id uuid primary key,
  email text unique,
  raw_user_meta_data jsonb not null default '{}'::jsonb,
  -- Attention : sur Supabase, created_at n'a PAS de valeur par défaut
  -- (GoTrue la remplit). Un test qui en dépend la donne explicitement.
  created_at timestamptz not null default now()
);
-- Colonnes de Supabase Auth lues ou vidées par la console (migration 2200).
alter table auth.users
  add column if not exists last_sign_in_at timestamptz,
  add column if not exists banned_until timestamptz,
  add column if not exists encrypted_password text,
  add column if not exists phone text,
  -- Métadonnées posées par le serveur seulement (migration 5300).
  add column if not exists raw_app_meta_data jsonb;

-- Comme Supabase : l'identité vient des claims JWT posés par PostgREST.
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'),
    ''
  )::uuid
$$;
grant execute on function auth.uid() to anon, authenticated, service_role;

-- Sessions de Supabase Auth (une par appareil connecté ; migration 4300).
-- Sur Supabase, `session_id` est une claim du jeton d'accès.
create table if not exists auth.sessions (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  refreshed_at timestamp,
  user_agent text,
  not_after timestamptz
);

-- Facteurs de double authentification (migration 4800). Sur Supabase,
-- factor_type et status sont des énumérations ; le code les lit en texte.
create table if not exists auth.mfa_factors (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  friendly_name text,
  factor_type text not null,
  status text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  secret text
);

create schema if not exists vault;
create table if not exists vault.local_secrets (
  name text primary key,
  decrypted_secret text not null
);
create or replace view vault.decrypted_secrets as
  select name, decrypted_secret from vault.local_secrets;

-- Même signature que la fonction Supabase Vault.
create or replace function vault.create_secret(
  new_secret text, new_name text default null, new_description text default ''
) returns uuid language sql as $$
  insert into vault.local_secrets (name, decrypted_secret) values (new_name, new_secret);
  select gen_random_uuid();
$$;
revoke all on schema vault from public, anon, authenticated;

-- Le schéma public n'accorde rien par défaut aux rôles applicatifs, comme sur
-- Supabase : chaque migration accorde explicitement ce qu'elle expose.
grant usage on schema public to anon, authenticated, service_role;

-- Supabase Storage : tables minimales (buckets, objets) avec RLS, comme sur
-- un projet Supabase où les règles d'accès sont des politiques sur
-- storage.objects.
create schema if not exists storage;
grant usage on schema storage to anon, authenticated, service_role;
create table if not exists storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false,
  file_size_limit bigint,
  allowed_mime_types text[]
);
create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets (id),
  name text not null,
  owner uuid default auth.uid(),
  created_at timestamptz not null default now(),
  unique (bucket_id, name)
);
alter table storage.objects enable row level security;
grant select, insert, delete on storage.objects to authenticated;
grant select on storage.buckets to anon, authenticated;
