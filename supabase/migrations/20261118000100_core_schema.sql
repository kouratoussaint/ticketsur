-- =============================================================================
-- TicketSûr — Migration 0100 : schéma cœur multi-organisations + RLS de lecture
-- =============================================================================
-- Principes (cahier §8, §10) :
--   * chaque table métier est rattachée à une organisation (tenant) ;
--   * RLS activée partout ; lecture filtrée par appartenance active ;
--   * AUCUNE écriture directe des tickets par les clients : seules des fonctions
--     serveur (security definer, search_path verrouillé) modifient tickets et
--     scans ;
--   * les secrets QR vivent dans le schéma « private », jamais exposé à l'API.
-- Les politiques d'écriture « gestion d'événements » arrivent en Phase 2.
-- =============================================================================

create extension if not exists pgcrypto with schema extensions;

create schema if not exists private;
revoke all on schema private from public;

-- -----------------------------------------------------------------------------
-- Types énumérés
-- -----------------------------------------------------------------------------
create type public.member_role as enum ('owner', 'manager', 'controller');
create type public.account_status as enum ('active', 'disabled');
create type public.event_status as enum
  ('draft', 'published', 'in_progress', 'closed', 'archived', 'cancelled');
create type public.ticket_status as enum ('issued', 'redeemed', 'revoked', 'expired');
create type public.scan_result as enum (
  'accepted', 'already_used', 'revoked', 'expired', 'not_found', 'wrong_event',
  'unauthorized', 'event_inactive', 'rate_limited', 'pending', 'unavailable'
);

-- -----------------------------------------------------------------------------
-- Identités et organisations
-- -----------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 120),
  status public.account_status not null default 'active',
  is_platform_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{1,62}$'),
  status public.account_status not null default 'active',
  owner_id uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_members (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.member_role not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);
create index organization_members_user_idx on public.organization_members (user_id);

-- -----------------------------------------------------------------------------
-- Événements, catégories, points de contrôle, affectations
-- -----------------------------------------------------------------------------
create table public.events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  title text not null check (char_length(title) between 2 and 160),
  venue text,
  timezone text not null default 'Africa/Ouagadougou',
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  -- Fenêtre de scan autour de l'événement (paramétrable par événement).
  scan_opens_before interval not null default interval '3 hours',
  scan_closes_after interval not null default interval '6 hours',
  capacity integer check (capacity is null or capacity > 0),
  status public.event_status not null default 'draft',
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at),
  check (scan_opens_before >= interval '0' and scan_closes_after >= interval '0'),
  unique (id, organization_id)
);
create index events_org_idx on public.events (organization_id, starts_at desc);

create table public.ticket_categories (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  capacity integer check (capacity is null or capacity > 0),
  created_at timestamptz not null default now(),
  unique (event_id, name),
  unique (id, event_id)
);

create table public.checkpoints (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (event_id, name),
  unique (id, event_id)
);

-- checkpoint_id NULL = toutes les portes de l'événement.
create table public.event_assignments (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  checkpoint_id uuid,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  foreign key (checkpoint_id, event_id) references public.checkpoints (id, event_id)
);
create unique index event_assignments_unique_idx
  on public.event_assignments (event_id, user_id, coalesce(checkpoint_id, '00000000-0000-0000-0000-000000000000'::uuid));
create index event_assignments_user_idx on public.event_assignments (user_id) where active;

-- -----------------------------------------------------------------------------
-- Tickets (aucun secret ici) et secrets QR (schéma privé)
-- -----------------------------------------------------------------------------
create table public.tickets (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete restrict,
  category_id uuid not null,
  public_reference text not null check (public_reference ~ '^TS-[0-9A-Z]{4}-[0-9A-Z]{4}$'),
  status public.ticket_status not null default 'issued',
  issued_at timestamptz not null default now(),
  issued_by uuid references public.profiles (id),
  expires_at timestamptz,
  redeemed_at timestamptz,
  redeemed_by uuid references public.profiles (id),
  redeemed_checkpoint_id uuid,
  revoked_at timestamptz,
  revoked_by uuid references public.profiles (id),
  replaces_ticket_id uuid references public.tickets (id),
  foreign key (category_id, event_id) references public.ticket_categories (id, event_id),
  foreign key (redeemed_checkpoint_id, event_id) references public.checkpoints (id, event_id),
  unique (event_id, public_reference),
  -- Cohérence d'état : un billet consommé porte toujours sa première validation.
  check ((status = 'redeemed') = (redeemed_at is not null and redeemed_by is not null)),
  check ((status = 'revoked') = (revoked_at is not null))
);
create index tickets_event_status_idx on public.tickets (event_id, status);

create table private.ticket_secrets (
  ticket_id uuid primary key references public.tickets (id) on delete cascade,
  -- HMAC-SHA256(jeton, poivre Vault) : sert à la recherche au scan.
  token_hmac bytea not null unique,
  -- Copie chiffrée (clé Vault distincte) pour le ré-export autorisé et audité.
  token_ciphertext bytea not null
);

-- -----------------------------------------------------------------------------
-- Scans : idempotence et journal append-only
-- -----------------------------------------------------------------------------
create table public.scan_requests (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references public.profiles (id),
  request_id uuid not null,
  event_id uuid,
  checkpoint_id uuid,
  received_at timestamptz not null default now(),
  result_code public.scan_result not null default 'pending',
  ticket_id uuid references public.tickets (id),
  response jsonb,
  unique (actor_id, request_id)
);
create index scan_requests_event_idx on public.scan_requests (event_id, received_at desc);

create table public.scan_attempts (
  id uuid primary key default gen_random_uuid(),
  scan_request_id uuid references public.scan_requests (id),
  ticket_id uuid references public.tickets (id),
  actor_id uuid not null references public.profiles (id),
  event_id uuid,
  checkpoint_id uuid,
  outcome public.scan_result not null,
  server_time timestamptz not null default now()
);
create index scan_attempts_event_time_idx on public.scan_attempts (event_id, server_time desc);
create index scan_attempts_actor_time_idx on public.scan_attempts (actor_id, server_time desc);
-- Invariant défensif : au plus UNE tentative acceptée par billet.
create unique index scan_attempts_one_accept_per_ticket
  on public.scan_attempts (ticket_id) where outcome = 'accepted';

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations (id),
  actor_id uuid references public.profiles (id),
  action text not null,
  resource_type text not null,
  resource_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_logs_org_time_idx on public.audit_logs (organization_id, created_at desc);

-- -----------------------------------------------------------------------------
-- Fonctions d'habilitation (utilisées par les politiques RLS)
-- -----------------------------------------------------------------------------
create or replace function private.has_org_role(p_org uuid, p_roles public.member_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_members m
    join public.profiles p on p.id = m.user_id
    join public.organizations o on o.id = m.organization_id
    where m.organization_id = p_org
      and m.user_id = auth.uid()
      and m.active
      and m.role = any (p_roles)
      and p.status = 'active'
      and o.status = 'active'
  )
$$;

create or replace function private.can_see_event(p_event uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.events e
    where e.id = p_event
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  ) or exists (
    select 1 from public.event_assignments a
    join public.events e on e.id = a.event_id
    where a.event_id = p_event
      and a.user_id = auth.uid()
      and a.active
      and private.has_org_role(e.organization_id, array['owner','manager','controller']::public.member_role[])
  )
$$;

grant usage on schema private to authenticated;
revoke all on all tables in schema private from public, anon, authenticated;
revoke all on function private.has_org_role(uuid, public.member_role[]) from public, anon;
revoke all on function private.can_see_event(uuid) from public, anon;
grant execute on function private.has_org_role(uuid, public.member_role[]) to authenticated;
grant execute on function private.can_see_event(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- RLS : activée partout, lecture uniquement dans cette migration
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.events enable row level security;
alter table public.ticket_categories enable row level security;
alter table public.checkpoints enable row level security;
alter table public.event_assignments enable row level security;
alter table public.tickets enable row level security;
alter table public.scan_requests enable row level security;
alter table public.scan_attempts enable row level security;
alter table public.audit_logs enable row level security;

revoke all on all tables in schema public from anon, authenticated;
grant select on public.profiles, public.organizations, public.organization_members,
  public.events, public.ticket_categories, public.checkpoints, public.event_assignments,
  public.tickets, public.scan_requests, public.scan_attempts, public.audit_logs
  to authenticated;

create policy profiles_self_or_same_org on public.profiles for select to authenticated
using (
  id = auth.uid()
  or exists (
    select 1 from public.organization_members m
    where m.user_id = profiles.id
      and private.has_org_role(m.organization_id, array['owner','manager']::public.member_role[])
  )
);

create policy organizations_members on public.organizations for select to authenticated
using (private.has_org_role(id, array['owner','manager','controller']::public.member_role[]));

create policy members_same_org on public.organization_members for select to authenticated
using (
  user_id = auth.uid()
  or private.has_org_role(organization_id, array['owner','manager']::public.member_role[])
);

create policy events_visible on public.events for select to authenticated
using (private.can_see_event(id));

create policy categories_visible on public.ticket_categories for select to authenticated
using (private.can_see_event(event_id));

create policy checkpoints_visible on public.checkpoints for select to authenticated
using (private.can_see_event(event_id));

create policy assignments_visible on public.event_assignments for select to authenticated
using (
  user_id = auth.uid()
  or exists (
    select 1 from public.events e
    where e.id = event_assignments.event_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  )
);

-- Les contrôleurs ne lisent PAS la liste des billets : ils n'en voient que ce
-- que renvoie validate_scan.
create policy tickets_managers on public.tickets for select to authenticated
using (
  exists (
    select 1 from public.events e
    where e.id = tickets.event_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  )
);

create policy scan_requests_own on public.scan_requests for select to authenticated
using (actor_id = auth.uid());

create policy scan_attempts_visible on public.scan_attempts for select to authenticated
using (
  actor_id = auth.uid()
  or exists (
    select 1 from public.events e
    where e.id = scan_attempts.event_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  )
);

create policy audit_owner on public.audit_logs for select to authenticated
using (private.has_org_role(organization_id, array['owner']::public.member_role[]));
