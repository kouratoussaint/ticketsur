-- =============================================================================
-- Tikéo — Migration 1800 : catalogue public (refonte, étape B)
-- =============================================================================
-- Décisions de Toussaint (19/11/2026, ADR 0012) :
-- * dès l'ouverture, sans compte, l'app montre les événements que leur
--   organisateur a marqués « Visible par le public » (privé par défaut) ;
-- * la fiche publique propose « Obtenir un ticket » vers le numéro WhatsApp
--   public de l'organisation (champ distinct du téléphone de la fiche) ;
-- * chaque catégorie peut porter un prix indicatif (FCFA), facultatif.
--
-- Les lectures publiques (`public_events`, `public_event`) sont ouvertes au
-- rôle `anon`. Elles ne renvoient que des champs de vitrine : jamais de
-- ticket, de titulaire, de chiffre de vente ou d'entrée, ni les catégories
-- d'invitations. Les photos sont déjà dans le bucket public `event-covers`.
-- =============================================================================

alter table public.events
  add column is_public boolean not null default false;
create index events_public_idx on public.events (starts_at)
  where is_public and status in ('published', 'in_progress');

alter table public.organizations
  add column public_phone text
    check (public_phone is null or public_phone ~ '^\+[1-9][0-9]{7,14}$');

alter table public.ticket_categories
  add column indicative_price integer
    check (indicative_price is null or indicative_price between 0 and 10000000);

-- -----------------------------------------------------------------------------
-- Repli des accents et de la casse pour la recherche publique.
-- -----------------------------------------------------------------------------
create or replace function private.fold(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select lower(translate(coalesce(p_text, ''),
    'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñŸÿ’''-',
    'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNnYy   '))
$$;
revoke all on function private.fold(text) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Écritures (organisateurs)
-- -----------------------------------------------------------------------------
create function public.set_event_public(p_event_id uuid, p_public boolean)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
begin
  if p_public is null then
    raise exception 'event_visibility_invalid'
      using errcode = '22023', detail = 'Visibilité manquante.';
  end if;
  v_event := private.lock_managed_event(p_event_id);
  if v_event.status in ('cancelled', 'archived') and p_public then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement annulé ou archivé.';
  end if;
  update public.events e
     set is_public = p_public, updated_at = now()
   where e.id = p_event_id
  returning * into v_event;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'event.visibility_changed', 'event', v_event.id,
          jsonb_build_object('public', p_public));
  return v_event;
end;
$$;
revoke all on function public.set_event_public(uuid, boolean) from public, anon;
grant execute on function public.set_event_public(uuid, boolean) to authenticated;

create function public.set_organization_public_phone(p_organization_id uuid, p_phone text)
returns public.organizations
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_phone text := private.normalize_phone(p_phone);
  v_org public.organizations%rowtype;
begin
  v_org := private.lock_owned_organization(p_organization_id);
  if v_phone is not null and v_phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'org_phone_invalid'
      using errcode = '22023', detail = 'Numéro de téléphone invalide.';
  end if;
  update public.organizations o
     set public_phone = v_phone, updated_at = now()
   where o.id = p_organization_id
  returning * into v_org;
  -- Jamais le numéro dans le journal : seulement s'il est posé ou retiré.
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org.id, auth.uid(), 'organization.public_phone_changed', 'organization', v_org.id,
          jsonb_build_object('removed', v_phone is null));
  return v_org;
end;
$$;
revoke all on function public.set_organization_public_phone(uuid, text) from public, anon;
grant execute on function public.set_organization_public_phone(uuid, text) to authenticated;

create function public.set_category_price(p_category_id uuid, p_price integer)
returns public.ticket_categories
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event_id uuid;
  v_event public.events%rowtype;
  v_category public.ticket_categories%rowtype;
begin
  select c.event_id into v_event_id from public.ticket_categories c where c.id = p_category_id;
  if v_event_id is null then
    raise exception 'category_not_found'
      using errcode = '42501', detail = 'Catégorie introuvable ou droits insuffisants.';
  end if;
  v_event := private.lock_managed_event(v_event_id);
  if v_event.status in ('closed', 'cancelled', 'archived') then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement clôturé, annulé ou archivé.';
  end if;
  if p_price is not null and p_price not between 0 and 10000000 then
    raise exception 'category_price_invalid'
      using errcode = '22023', detail = 'Prix de 0 à 10 000 000 FCFA.';
  end if;
  update public.ticket_categories c
     set indicative_price = p_price
   where c.id = p_category_id
  returning * into v_category;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'category.price_changed', 'ticket_category', v_category.id,
          jsonb_build_object('price', p_price));
  return v_category;
end;
$$;
revoke all on function public.set_category_price(uuid, integer) from public, anon;
grant execute on function public.set_category_price(uuid, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- Lectures des organisateurs : nouvelles colonnes
-- -----------------------------------------------------------------------------
drop function public.my_organizations();
create function public.my_organizations()
returns table (
  id uuid, name text, slug text, role public.member_role,
  logo_path text, phone text, contact_email text, city text, public_phone text
)
language sql
stable
security invoker
set search_path = ''
as $$
  select o.id, o.name, o.slug, m.role, o.logo_path, o.phone, o.contact_email, o.city,
         o.public_phone
  from public.organization_members m
  join public.organizations o on o.id = m.organization_id
  where m.user_id = auth.uid()
    and m.active
    and o.status = 'active'
  order by o.created_at, o.name
$$;
revoke all on function public.my_organizations() from public, anon;
grant execute on function public.my_organizations() to authenticated;

drop function public.event_categories(uuid);

create function public.event_categories(p_event_id uuid)
returns table (
  id uuid,
  event_id uuid,
  name text,
  capacity integer,
  is_invitation boolean,
  indicative_price integer,
  issued integer,
  redeemed integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.events e
    where e.id = p_event_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  ) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  return query
    select c.id, c.event_id, c.name, c.capacity, c.is_invitation, c.indicative_price,
           count(t.id) filter (where t.status <> 'revoked')::integer,
           count(t.id) filter (where t.status = 'redeemed')::integer
    from public.ticket_categories c
    left join public.tickets t on t.category_id = c.id
    where c.event_id = p_event_id
    group by c.id
    order by c.created_at, c.name;
end;
$$;
revoke all on function public.event_categories(uuid) from public, anon;
grant execute on function public.event_categories(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Catalogue public (sans compte)
-- -----------------------------------------------------------------------------
create or replace function private.is_listed(p_event public.events)
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_event.is_public
     and p_event.status in ('published', 'in_progress')
     and p_event.ends_at > now()
     and exists (select 1 from public.organizations o
                 where o.id = p_event.organization_id and o.status = 'active')
$$;
revoke all on function private.is_listed(public.events) from public, anon, authenticated;

create function public.public_events(
  p_search text default null,
  p_kinds public.event_kind[] default null,
  p_city text default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_free_only boolean default false,
  p_limit integer default 30,
  p_offset integer default 0
)
returns table (
  id uuid,
  title text,
  kind public.event_kind,
  starts_at timestamptz,
  ends_at timestamptz,
  timezone text,
  venue text,
  city text,
  cover_path text,
  organization_name text,
  min_price integer
)
language sql
stable
security definer
set search_path = ''
as $$
  with listed as (
    select e.*, o.name as org_name,
           (select min(c.indicative_price) from public.ticket_categories c
             where c.event_id = e.id and not c.is_invitation) as min_price,
           (select max(c.indicative_price) from public.ticket_categories c
             where c.event_id = e.id and not c.is_invitation) as max_price
    from public.events e
    join public.organizations o on o.id = e.organization_id
    where e.is_public
      and e.status in ('published', 'in_progress')
      and e.ends_at > now()
      and o.status = 'active'
  )
  select l.id, l.title, l.kind, l.starts_at, l.ends_at, l.timezone, l.venue, l.city,
         l.cover_path, l.org_name, l.min_price
  from listed l
  where (p_kinds is null or cardinality(p_kinds) = 0 or l.kind = any (p_kinds))
    and (nullif(btrim(p_city), '') is null or private.fold(l.city) = private.fold(btrim(p_city)))
    and (p_from is null or l.ends_at >= p_from)
    and (p_to is null or l.starts_at < p_to)
    and (not coalesce(p_free_only, false) or l.max_price = 0)
    and (nullif(btrim(p_search), '') is null
         or position(private.fold(btrim(p_search)) in
              private.fold(concat_ws(' ', l.title, l.venue, l.city, l.org_name))) > 0)
  order by l.starts_at, l.title, l.id
  limit least(greatest(coalesce(p_limit, 30), 1), 50)
  offset greatest(coalesce(p_offset, 0), 0)
$$;
revoke all on function public.public_events(text, public.event_kind[], text, timestamptz,
  timestamptz, boolean, integer, integer) from public;
grant execute on function public.public_events(text, public.event_kind[], text, timestamptz,
  timestamptz, boolean, integer, integer) to anon, authenticated;

create function public.public_event(p_event_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
  v_org public.organizations%rowtype;
begin
  select * into v_event from public.events e where e.id = p_event_id;
  if not found or not private.is_listed(v_event) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou non public.';
  end if;
  select * into v_org from public.organizations o where o.id = v_event.organization_id;
  return jsonb_build_object(
    'id', v_event.id,
    'title', v_event.title,
    'kind', v_event.kind,
    'description', v_event.description,
    'starts_at', v_event.starts_at,
    'ends_at', v_event.ends_at,
    'timezone', v_event.timezone,
    'venue', v_event.venue,
    'venue_address', v_event.venue_address,
    'city', v_event.city,
    'latitude', v_event.latitude,
    'longitude', v_event.longitude,
    'cover_path', v_event.cover_path,
    'status', v_event.status,
    'organization', jsonb_build_object(
      'name', v_org.name,
      'logo_path', v_org.logo_path,
      'public_phone', v_org.public_phone),
    'categories', coalesce((
      select jsonb_agg(jsonb_build_object('name', c.name, 'indicative_price', c.indicative_price)
                       order by c.created_at, c.name)
      from public.ticket_categories c
      where c.event_id = v_event.id and not c.is_invitation), '[]'::jsonb)
  );
end;
$$;
revoke all on function public.public_event(uuid) from public;
grant execute on function public.public_event(uuid) to anon, authenticated;
