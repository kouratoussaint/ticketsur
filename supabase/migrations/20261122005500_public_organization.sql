-- =============================================================================
-- Tikéo — Page publique d'une structure (demande de Toussaint du 22/11/2026,
-- ADR 0045)
-- =============================================================================
-- Sur la fiche publique d'un événement, le bloc « Organisé par » ouvre la
-- page publique de la structure : logo, nom, ville, numéro WhatsApp public,
-- ses événements visibles au catalogue et le nombre de ses événements publics
-- passés. Mêmes règles que le catalogue (`private.is_listed`) ; rien d'autre
-- n'est exposé (ni membres, ni chiffres, ni coordonnées privées).

-- `public_event` : l'identifiant de la structure s'ajoute à `organization`.
create or replace function public.public_event(p_event_id uuid)
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
      'id', v_org.id,
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

create function public.public_organization(p_organization_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org public.organizations%rowtype;
begin
  select * into v_org from public.organizations o
   where o.id = p_organization_id and o.status = 'active';
  if not found then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable.';
  end if;
  return jsonb_build_object(
    'id', v_org.id,
    'name', v_org.name,
    'city', v_org.city,
    'logo_path', v_org.logo_path,
    'public_phone', v_org.public_phone,
    'created_at', v_org.created_at,
    'past_events', (
      select count(*) from public.events e
       where e.organization_id = v_org.id
         and e.is_public and e.public_blocked_at is null
         and e.status in ('published', 'in_progress', 'closed', 'archived')
         and e.ends_at <= now()),
    'events', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', e.id, 'title', e.title, 'kind', e.kind,
               'starts_at', e.starts_at, 'ends_at', e.ends_at, 'timezone', e.timezone,
               'venue', e.venue, 'city', e.city, 'cover_path', e.cover_path,
               'organization_name', v_org.name,
               'min_price', (select min(c.indicative_price) from public.ticket_categories c
                              where c.event_id = e.id and not c.is_invitation))
             order by e.starts_at, e.title, e.id)
        from (select * from public.events e
               where e.organization_id = v_org.id and private.is_listed(e)
               order by e.starts_at, e.title, e.id
               limit 50) e), '[]'::jsonb));
end;
$$;
revoke all on function public.public_organization(uuid) from public;
grant execute on function public.public_organization(uuid) to anon, authenticated;
