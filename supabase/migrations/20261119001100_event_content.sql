-- =============================================================================
-- TicketSûr — Migration 1100 : contenu des événements (lot 1)
-- =============================================================================
-- Un événement porte désormais une photo de couverture, une ville, un type,
-- une description, l'adresse du lieu et une position GPS facultative.
--
-- Règles :
--   * un brouillon peut rester incomplet ;
--   * la publication exige une photo de couverture ET une ville ;
--   * un événement publié ne peut pas perdre sa ville ni sa photo.
--
-- Photo : bucket Storage public « event-covers » (2 Mo, JPEG/PNG/WebP).
-- Chemin imposé : <organisation>/<événement>/<fichier>. Seuls les
-- propriétaires et gestionnaires de l'organisation peuvent déposer ou
-- supprimer un fichier ; la photo n'est rattachée à l'événement que par
-- set_event_cover, qui vérifie que l'objet existe au bon endroit.
-- Les images d'événement sont destinées à être vues du public (page
-- publique prévue) : le bucket est en lecture publique, les noms de fichiers
-- sont aléatoires.
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   22023 event_city_invalid | event_description_invalid
--         | event_address_invalid | event_location_invalid
--         | event_country_invalid | event_cover_invalid
--   55000 event_incomplete      photo ou ville manquante pour publier
-- =============================================================================

create type public.event_kind as enum (
  'concert', 'conference', 'worship', 'sport', 'wedding', 'training', 'gala', 'other'
);

alter table public.events
  add column city text check (city is null or char_length(city) between 2 and 80),
  add column country_code text not null default 'BF' check (country_code ~ '^[A-Z]{2}$'),
  add column venue_address text check (venue_address is null or char_length(venue_address) <= 200),
  add column latitude double precision check (latitude is null or latitude between -90 and 90),
  add column longitude double precision check (longitude is null or longitude between -180 and 180),
  add column description text check (description is null or char_length(description) <= 2000),
  add column kind public.event_kind not null default 'other',
  add column cover_path text check (cover_path is null or char_length(cover_path) <= 300),
  add constraint events_location_pair check ((latitude is null) = (longitude is null));

create index events_city_idx on public.events (country_code, city);

-- Texte long : espaces superflus en début et fin retirés, retours à la ligne
-- conservés (au plus deux d'affilée).
create or replace function private.normalize_long_text(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(
    regexp_replace(
      regexp_replace(trim(both e' \t\r\n' from coalesce(p_text, '')), '\r\n?', e'\n', 'g'),
      '\n{3,}', e'\n\n', 'g'),
    '')
$$;
revoke all on function private.normalize_long_text(text) from public, anon, authenticated;

create or replace function private.check_event_content(
  p_city text,
  p_country_code text,
  p_venue_address text,
  p_latitude double precision,
  p_longitude double precision,
  p_description text
)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_city is not null and char_length(p_city) not between 2 and 80 then
    raise exception 'event_city_invalid'
      using errcode = '22023', detail = 'Ville de 2 à 80 caractères.';
  end if;
  if p_country_code is null or p_country_code !~ '^[A-Z]{2}$' then
    raise exception 'event_country_invalid'
      using errcode = '22023', detail = 'Code pays ISO à deux lettres.';
  end if;
  if p_venue_address is not null and char_length(p_venue_address) > 200 then
    raise exception 'event_address_invalid'
      using errcode = '22023', detail = 'Adresse de 200 caractères au plus.';
  end if;
  if (p_latitude is null) <> (p_longitude is null)
     or (p_latitude is not null and p_latitude not between -90 and 90)
     or (p_longitude is not null and p_longitude not between -180 and 180) then
    raise exception 'event_location_invalid'
      using errcode = '22023', detail = 'Position GPS incomplète ou hors limites.';
  end if;
  if p_description is not null and char_length(p_description) > 2000 then
    raise exception 'event_description_invalid'
      using errcode = '22023', detail = 'Description de 2 000 caractères au plus.';
  end if;
end;
$$;
revoke all on function private.check_event_content(text, text, text, double precision, double precision, text)
  from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Création et édition : remplacent les versions de la migration 0600.
-- Les sept premiers paramètres gardent leur ordre (appels existants valides).
-- -----------------------------------------------------------------------------
drop function public.create_event(uuid, text, timestamptz, timestamptz, text, text, integer);
drop function public.update_event(uuid, text, timestamptz, timestamptz, text, text, integer);

create function public.create_event(
  p_organization_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_timezone text default 'Africa/Ouagadougou',
  p_venue text default null,
  p_capacity integer default null,
  p_city text default null,
  p_country_code text default 'BF',
  p_venue_address text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_description text default null,
  p_kind public.event_kind default 'other'
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
  v_city text := private.normalize_text(p_city);
  v_country text := upper(coalesce(private.normalize_text(p_country_code), 'BF'));
  v_address text := private.normalize_text(p_venue_address);
  v_description text := private.normalize_long_text(p_description);
  v_event public.events%rowtype;
begin
  if v_actor is null
     or not private.has_org_role(p_organization_id,
                                 array['owner','manager']::public.member_role[]) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Organisation introuvable ou droits insuffisants.';
  end if;
  perform private.check_event_fields(v_title, v_venue, p_timezone, p_starts_at, p_ends_at, p_capacity);
  perform private.check_event_content(v_city, v_country, v_address, p_latitude, p_longitude, v_description);

  insert into public.events (organization_id, title, venue, timezone, starts_at, ends_at,
                             capacity, status, created_by, city, country_code,
                             venue_address, latitude, longitude, description, kind)
  values (p_organization_id, v_title, v_venue, p_timezone, p_starts_at, p_ends_at,
          p_capacity, 'draft', v_actor, v_city, v_country,
          v_address, p_latitude, p_longitude, v_description, coalesce(p_kind, 'other'))
  returning * into v_event;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, v_actor, 'event.created', 'event', v_event.id,
          jsonb_build_object('title', v_event.title));
  return v_event;
end;
$$;
revoke all on function public.create_event(uuid, text, timestamptz, timestamptz, text, text, integer,
  text, text, text, double precision, double precision, text, public.event_kind) from public, anon;
grant execute on function public.create_event(uuid, text, timestamptz, timestamptz, text, text, integer,
  text, text, text, double precision, double precision, text, public.event_kind) to authenticated;

create function public.update_event(
  p_event_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_timezone text,
  p_venue text default null,
  p_capacity integer default null,
  p_city text default null,
  p_country_code text default 'BF',
  p_venue_address text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_description text default null,
  p_kind public.event_kind default 'other'
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
  v_city text := private.normalize_text(p_city);
  v_country text := upper(coalesce(private.normalize_text(p_country_code), 'BF'));
  v_address text := private.normalize_text(p_venue_address);
  v_description text := private.normalize_long_text(p_description);
  v_event public.events%rowtype;
  v_issued integer;
begin
  v_event := private.lock_managed_event(p_event_id);
  if v_event.status not in ('draft', 'published') then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement en cours, clôturé, annulé ou archivé.';
  end if;
  perform private.check_event_fields(v_title, v_venue, p_timezone, p_starts_at, p_ends_at, p_capacity);
  perform private.check_event_content(v_city, v_country, v_address, p_latitude, p_longitude, v_description);
  if v_event.status = 'published' and v_city is null then
    raise exception 'event_incomplete'
      using errcode = '55000', detail = 'Un événement publié doit garder sa ville.';
  end if;

  if p_capacity is not null then
    select count(*) into v_issued from public.tickets t
    where t.event_id = p_event_id and t.status <> 'revoked';
    if v_issued > p_capacity then
      raise exception 'event_capacity_below_issued'
        using errcode = '22023', detail = format('%s tickets déjà émis.', v_issued);
    end if;
  end if;

  update public.events e
     set title = v_title, venue = v_venue, timezone = p_timezone,
         starts_at = p_starts_at, ends_at = p_ends_at, capacity = p_capacity,
         city = v_city, country_code = v_country, venue_address = v_address,
         latitude = p_latitude, longitude = p_longitude, description = v_description,
         kind = coalesce(p_kind, 'other'), updated_at = now()
   where e.id = p_event_id
  returning * into v_event;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, v_actor, 'event.updated', 'event', v_event.id, '{}'::jsonb);
  return v_event;
end;
$$;
revoke all on function public.update_event(uuid, text, timestamptz, timestamptz, text, text, integer,
  text, text, text, double precision, double precision, text, public.event_kind) from public, anon;
grant execute on function public.update_event(uuid, text, timestamptz, timestamptz, text, text, integer,
  text, text, text, double precision, double precision, text, public.event_kind) to authenticated;

-- -----------------------------------------------------------------------------
-- Publication : photo et ville obligatoires
-- -----------------------------------------------------------------------------
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
  if p_status = 'published' and (v_event.cover_path is null or v_event.city is null) then
    raise exception 'event_incomplete'
      using errcode = '55000',
            detail = 'Ajoutez une photo de couverture et une ville avant de publier.';
  end if;
  if v_from = 'published' and p_status = 'draft'
     and exists (select 1 from public.tickets t where t.event_id = p_event_id) then
    raise exception 'event_has_tickets'
      using errcode = '55000', detail = 'Des tickets existent : retour en brouillon impossible.';
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

-- -----------------------------------------------------------------------------
-- Photo de couverture
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('event-covers', 'event-covers', true, 2097152,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Vrai si le chemin désigne un dossier <organisation>/<événement>/ que
-- l'appelant gère. Tolère n'importe quel texte (aucune erreur de conversion).
create or replace function private.can_manage_event_cover(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_parts text[] := string_to_array(coalesce(p_name, ''), '/');
  v_uuid_re constant text := '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
begin
  if array_length(v_parts, 1) is distinct from 3
     or v_parts[1] !~ v_uuid_re or v_parts[2] !~ v_uuid_re
     or v_parts[3] !~ '^[A-Za-z0-9_-]{8,64}\.(jpg|jpeg|png|webp)$' then
    return false;
  end if;
  return exists (
    select 1 from public.events e
    where e.id = v_parts[2]::uuid
      and e.organization_id = v_parts[1]::uuid
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  );
end;
$$;
revoke all on function private.can_manage_event_cover(text) from public, anon;
grant execute on function private.can_manage_event_cover(text) to authenticated;

create policy event_covers_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'event-covers' and private.can_manage_event_cover(name));
-- La suppression via l'API Storage lit aussi la ligne (SELECT).
create policy event_covers_select on storage.objects for select to authenticated
  using (bucket_id = 'event-covers' and private.can_manage_event_cover(name));
create policy event_covers_delete on storage.objects for delete to authenticated
  using (bucket_id = 'event-covers' and private.can_manage_event_cover(name));

-- Rattache (ou retire, p_path = null) la photo de couverture.
create or replace function public.set_event_cover(
  p_event_id uuid,
  p_path text
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
begin
  v_event := private.lock_managed_event(p_event_id);
  if v_event.status not in ('draft', 'published') then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement en cours, clôturé, annulé ou archivé.';
  end if;
  if p_path is null then
    if v_event.status = 'published' then
      raise exception 'event_incomplete'
        using errcode = '55000', detail = 'Un événement publié doit garder sa photo.';
    end if;
  elsif split_part(p_path, '/', 1) <> v_event.organization_id::text
     or split_part(p_path, '/', 2) <> v_event.id::text
     or not private.can_manage_event_cover(p_path)
     or not exists (select 1 from storage.objects o
                    where o.bucket_id = 'event-covers' and o.name = p_path) then
    raise exception 'event_cover_invalid'
      using errcode = '22023', detail = 'Photo introuvable ou mal placée.';
  end if;

  update public.events e
     set cover_path = p_path, updated_at = now()
   where e.id = p_event_id
  returning * into v_event;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, v_actor, 'event.cover_changed', 'event', v_event.id,
          jsonb_build_object('removed', p_path is null));
  return v_event;
end;
$$;
revoke all on function public.set_event_cover(uuid, text) from public, anon;
grant execute on function public.set_event_cover(uuid, text) to authenticated;
