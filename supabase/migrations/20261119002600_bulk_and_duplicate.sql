-- =============================================================================
-- Tikéo — Migration 2600 : annulation groupée, duplication d'événement
-- (lot 3c-C)
-- =============================================================================
-- * `revoke_tickets` : annule d'un coup une sélection de tickets (500 au plus),
--   tout ou rien sur les droits ; seuls les tickets encore valables changent.
--   Une ligne de journal par ticket, comme `revoke_ticket`.
-- * `duplicate_event` : copie un événement en brouillon, avec ses catégories,
--   ses portes et les affectations actives de l'équipe. Jamais les tickets.
--   La photo est recopiée par l'application (fichier distinct, pour que
--   remplacer la photo de l'un n'efface pas celle de l'autre).
-- =============================================================================

create function public.revoke_tickets(p_ticket_ids uuid[], p_reason text default null)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_ids uuid[];
  v_found integer;
  v_count integer;
begin
  select array_agg(distinct id) into v_ids from unnest(p_ticket_ids) id where id is not null;
  if v_ids is null or cardinality(v_ids) = 0 or cardinality(v_ids) > 500 then
    raise exception 'selection_invalid'
      using errcode = '22023', detail = 'Choisissez de 1 à 500 tickets.';
  end if;
  -- Chaque ticket doit appartenir à une structure où l'appelant gère.
  select count(*) into v_found
    from public.tickets t
    join public.events e on e.id = t.event_id
   where t.id = any (v_ids)
     and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[]);
  if v_actor is null or v_found <> cardinality(v_ids) then
    raise exception 'ticket_not_found'
      using errcode = '42501', detail = 'Ticket introuvable ou droits insuffisants.';
  end if;

  with revoked as (
    update public.tickets t
       set status = 'revoked', revoked_at = now(), revoked_by = v_actor
     where t.id = any (v_ids) and t.status = 'issued'
    returning t.id, t.event_id
  ), logged as (
    insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
    select e.organization_id, v_actor, 'ticket.revoked', 'ticket', r.id,
           jsonb_build_object('reason', left(coalesce(p_reason, ''), 200), 'bulk', true)
      from revoked r join public.events e on e.id = r.event_id
    returning 1
  )
  select count(*) into v_count from logged;
  return v_count;
end;
$$;
revoke all on function public.revoke_tickets(uuid[], text) from public, anon;
grant execute on function public.revoke_tickets(uuid[], text) to authenticated;

create function public.duplicate_event(
  p_event_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_source public.events%rowtype;
  v_title text := private.normalize_text(p_title);
  v_id uuid;
begin
  select * into v_source from public.events e where e.id = p_event_id;
  if v_actor is null or not found
     or not private.has_org_role(v_source.organization_id,
                                 array['owner','manager']::public.member_role[]) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  perform private.check_event_fields(v_title, v_source.venue, v_source.timezone,
                                     p_starts_at, p_ends_at, v_source.capacity);

  insert into public.events (organization_id, title, venue, timezone, starts_at, ends_at,
                             capacity, status, created_by, city, country_code, venue_address,
                             latitude, longitude, description, kind, is_public)
  values (v_source.organization_id, v_title, v_source.venue, v_source.timezone, p_starts_at,
          p_ends_at, v_source.capacity, 'draft', v_actor, v_source.city, v_source.country_code,
          v_source.venue_address, v_source.latitude, v_source.longitude, v_source.description,
          v_source.kind, v_source.is_public and v_source.public_blocked_at is null)
  returning id into v_id;

  insert into public.ticket_categories (event_id, name, capacity, is_invitation, indicative_price)
  select v_id, c.name, c.capacity, c.is_invitation, c.indicative_price
    from public.ticket_categories c where c.event_id = p_event_id;

  insert into public.checkpoints (event_id, name, active)
  select v_id, c.name, c.active from public.checkpoints c where c.event_id = p_event_id;

  -- Affectations actives, porte retrouvée par son nom.
  insert into public.event_assignments (event_id, user_id, checkpoint_id, active)
  select v_id, a.user_id, n.id, true
    from public.event_assignments a
    left join public.checkpoints o on o.id = a.checkpoint_id
    left join public.checkpoints n on n.event_id = v_id and n.name = o.name
   where a.event_id = p_event_id and a.active
  on conflict do nothing;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_source.organization_id, v_actor, 'event.duplicated', 'event', v_id,
          jsonb_build_object('source', p_event_id));
  return v_id;
end;
$$;
revoke all on function public.duplicate_event(uuid, text, timestamptz, timestamptz) from public, anon;
grant execute on function public.duplicate_event(uuid, text, timestamptz, timestamptz) to authenticated;
