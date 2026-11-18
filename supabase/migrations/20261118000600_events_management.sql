-- =============================================================================
-- TicketSûr — Migration 0600 : gestion des événements (EVT-01, EVT-02)
-- =============================================================================
-- Création, édition et cycle de vie des événements, réservés aux
-- propriétaires et gestionnaires de l'organisation. Toutes les écritures
-- passent par ces fonctions : aucune écriture directe n'est accordée sur la
-- table (RLS en lecture seule, migration 0100).
--
-- Cycle de vie (transitions contrôlées côté serveur, sous verrou de ligne) :
--   draft ──► published ──► in_progress ──► closed ──► archived
--     │          │  ▲
--     │          ▼  │ (retour en brouillon si aucun billet émis)
--     │        draft
--     └──────────┴──► cancelled ──► archived
--   published ──► closed est aussi permis (clôture sans phase « en cours »).
--
-- Dates enregistrées en UTC (timestamptz) ; le fuseau IANA de l'événement
-- sert à l'affichage et est validé contre pg_timezone_names (EVT-02).
--
-- Erreurs : le MESSAGE est un code stable lu par l'application, le DETAIL un
-- texte lisible.
--   42501 event_not_found      événement inconnu ou droits insuffisants
--   22023 event_title_invalid | event_dates_invalid | event_timezone_invalid
--         | event_capacity_invalid | event_capacity_below_issued
--         | event_venue_invalid
--   55000 event_locked          édition impossible dans ce statut
--         event_invalid_transition | event_has_tickets | event_already_ended
-- =============================================================================

create or replace function private.normalize_text(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(regexp_replace(trim(coalesce(p_text, '')), '\s+', ' ', 'g'), '')
$$;
revoke all on function private.normalize_text(text) from public, anon, authenticated;

-- Contrôles communs à la création et à l'édition.
create or replace function private.check_event_fields(
  p_title text,
  p_venue text,
  p_timezone text,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_capacity integer
)
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if p_title is null or char_length(p_title) not between 2 and 160 then
    raise exception 'event_title_invalid'
      using errcode = '22023', detail = 'Titre de 2 à 160 caractères.';
  end if;
  if p_venue is not null and char_length(p_venue) > 160 then
    raise exception 'event_venue_invalid'
      using errcode = '22023', detail = 'Lieu de 160 caractères au plus.';
  end if;
  if p_timezone is null
     or not exists (select 1 from pg_catalog.pg_timezone_names z where z.name = p_timezone) then
    raise exception 'event_timezone_invalid'
      using errcode = '22023', detail = 'Fuseau horaire IANA inconnu.';
  end if;
  if p_starts_at is null or p_ends_at is null or p_ends_at <= p_starts_at
     or p_ends_at - p_starts_at > interval '31 days' then
    raise exception 'event_dates_invalid'
      using errcode = '22023', detail = 'La fin doit suivre le début (31 jours au plus).';
  end if;
  if p_capacity is not null and (p_capacity < 1 or p_capacity > 1000000) then
    raise exception 'event_capacity_invalid'
      using errcode = '22023', detail = 'Capacité de 1 à 1 000 000.';
  end if;
end;
$$;
revoke all on function private.check_event_fields(text, text, text, timestamptz, timestamptz, integer)
  from public, anon, authenticated;

-- Événement verrouillé pour modification, si l'appelant le gère.
create or replace function private.lock_managed_event(p_event_id uuid)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
begin
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found
     or not private.has_org_role(v_event.organization_id,
                                 array['owner','manager']::public.member_role[]) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  return v_event;
end;
$$;
revoke all on function private.lock_managed_event(uuid) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Création (toujours en brouillon)
-- -----------------------------------------------------------------------------
create or replace function public.create_event(
  p_organization_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_timezone text default 'Africa/Ouagadougou',
  p_venue text default null,
  p_capacity integer default null
)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_title text := private.normalize_text(p_title);
  v_venue text := private.normalize_text(p_venue);
  v_event public.events%rowtype;
begin
  if v_actor is null
     or not private.has_org_role(p_organization_id,
                                 array['owner','manager']::public.member_role[]) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Organisation introuvable ou droits insuffisants.';
  end if;
  perform private.check_event_fields(v_title, v_venue, p_timezone, p_starts_at, p_ends_at, p_capacity);

  insert into public.events (organization_id, title, venue, timezone, starts_at, ends_at,
                             capacity, status, created_by)
  values (p_organization_id, v_title, v_venue, p_timezone, p_starts_at, p_ends_at,
          p_capacity, 'draft', v_actor)
  returning * into v_event;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, v_actor, 'event.created', 'event', v_event.id,
          jsonb_build_object('title', v_event.title));
  return v_event;
end;
$$;
revoke all on function public.create_event(uuid, text, timestamptz, timestamptz, text, text, integer)
  from public, anon;
grant execute on function public.create_event(uuid, text, timestamptz, timestamptz, text, text, integer)
  to authenticated;

-- -----------------------------------------------------------------------------
-- Édition (brouillon ou publié uniquement)
-- -----------------------------------------------------------------------------
create or replace function public.update_event(
  p_event_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_timezone text,
  p_venue text default null,
  p_capacity integer default null
)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_title text := private.normalize_text(p_title);
  v_venue text := private.normalize_text(p_venue);
  v_event public.events%rowtype;
  v_issued integer;
begin
  v_event := private.lock_managed_event(p_event_id);
  if v_event.status not in ('draft', 'published') then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement en cours, clôturé, annulé ou archivé.';
  end if;
  perform private.check_event_fields(v_title, v_venue, p_timezone, p_starts_at, p_ends_at, p_capacity);

  if p_capacity is not null then
    select count(*) into v_issued from public.tickets t
    where t.event_id = p_event_id and t.status <> 'revoked';
    if v_issued > p_capacity then
      raise exception 'event_capacity_below_issued'
        using errcode = '22023', detail = format('%s billets déjà émis.', v_issued);
    end if;
  end if;

  update public.events e
     set title = v_title, venue = v_venue, timezone = p_timezone,
         starts_at = p_starts_at, ends_at = p_ends_at, capacity = p_capacity,
         updated_at = now()
   where e.id = p_event_id
  returning * into v_event;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, v_actor, 'event.updated', 'event', v_event.id, '{}'::jsonb);
  return v_event;
end;
$$;
revoke all on function public.update_event(uuid, text, timestamptz, timestamptz, text, text, integer)
  from public, anon;
grant execute on function public.update_event(uuid, text, timestamptz, timestamptz, text, text, integer)
  to authenticated;

-- -----------------------------------------------------------------------------
-- Changement de statut
-- -----------------------------------------------------------------------------
create or replace function private.event_transition_allowed(
  p_from public.event_status,
  p_to public.event_status
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select (p_from, p_to) in (
    ('draft'::public.event_status, 'published'::public.event_status),
    ('draft', 'cancelled'),
    ('published', 'draft'),
    ('published', 'in_progress'),
    ('published', 'closed'),
    ('published', 'cancelled'),
    ('in_progress', 'closed'),
    ('closed', 'archived'),
    ('cancelled', 'archived')
  )
$$;
revoke all on function private.event_transition_allowed(public.event_status, public.event_status)
  from public, anon, authenticated;

create or replace function public.set_event_status(
  p_event_id uuid,
  p_status public.event_status
)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_event public.events%rowtype;
  v_from public.event_status;
begin
  v_event := private.lock_managed_event(p_event_id);
  v_from := v_event.status;
  if p_status is null or not private.event_transition_allowed(v_from, p_status) then
    raise exception 'event_invalid_transition'
      using errcode = '55000', detail = format('%s → %s interdit.', v_from, p_status);
  end if;
  if p_status = 'published' and v_event.ends_at <= now() then
    raise exception 'event_already_ended'
      using errcode = '55000', detail = 'Impossible de publier un événement terminé.';
  end if;
  if v_from = 'published' and p_status = 'draft'
     and exists (select 1 from public.tickets t where t.event_id = p_event_id) then
    raise exception 'event_has_tickets'
      using errcode = '55000', detail = 'Des billets existent : retour en brouillon impossible.';
  end if;

  update public.events e
     set status = p_status, updated_at = now()
   where e.id = p_event_id
  returning * into v_event;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, v_actor, 'event.status_changed', 'event', v_event.id,
          jsonb_build_object('from', v_from, 'to', p_status));
  return v_event;
end;
$$;
revoke all on function public.set_event_status(uuid, public.event_status) from public, anon;
grant execute on function public.set_event_status(uuid, public.event_status) to authenticated;
