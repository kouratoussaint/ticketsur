-- =============================================================================
-- Tikéo — Lot 4-6b : recherche globale du promoteur (ADR 0032)
-- =============================================================================
-- Une seule recherche sur la structure : événements (titre, lieu, ville) et
-- tickets de tous ses événements (référence, nom du titulaire, téléphone par
-- ses chiffres). Propriétaire et gestionnaires seulement, comme la liste des
-- tickets. Le texte cherché n'est jamais enregistré.
-- =============================================================================

create function public.promoter_search(
  p_organization_id uuid,
  p_query text,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_query text := trim(coalesce(p_query, ''));
  v_folded text;
  v_digits text;
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_events jsonb;
  v_tickets jsonb;
begin
  if auth.uid() is null
     or not private.has_org_role(p_organization_id, array['owner', 'manager']::public.member_role[]) then
    raise exception 'forbidden'
      using errcode = '42501', detail = 'Recherche réservée au propriétaire et aux gestionnaires.';
  end if;
  if char_length(v_query) < 2 or char_length(v_query) > 60 then
    raise exception 'search_query_invalid'
      using errcode = '22023', detail = 'Entre 2 et 60 caractères.';
  end if;
  v_folded := private.fold(v_query);
  v_digits := regexp_replace(v_query, '[^0-9]', '', 'g');

  select coalesce(jsonb_agg(x.j order by x.rank, x.starts_at desc), '[]'::jsonb) into v_events
    from (
      select jsonb_build_object(
               'id', e.id, 'title', e.title, 'status', e.status, 'kind', e.kind,
               'starts_at', e.starts_at, 'ends_at', e.ends_at,
               'venue', e.venue, 'city', e.city) as j,
             -- Titre qui commence par la recherche d'abord.
             case when private.fold(e.title) like v_folded || '%' then 0 else 1 end as rank,
             e.starts_at
        from public.events e
       where e.organization_id = p_organization_id
         and (private.fold(e.title) like '%' || v_folded || '%'
              or private.fold(coalesce(e.venue, '')) like '%' || v_folded || '%'
              or private.fold(coalesce(e.city, '')) like '%' || v_folded || '%')
       order by rank, e.starts_at desc
       limit v_limit
    ) x;

  select coalesce(jsonb_agg(x.j order by x.rank, x.issued_at desc), '[]'::jsonb) into v_tickets
    from (
      select jsonb_build_object(
               'id', t.id, 'event_id', t.event_id, 'event_title', e.title,
               'event_starts_at', e.starts_at,
               'public_reference', t.public_reference, 'event_number', t.event_number,
               'holder_name', t.holder_name, 'holder_phone', t.holder_phone,
               'category', c.name, 'is_invitation', c.is_invitation,
               'status', t.status) as j,
             case when upper(t.public_reference) = upper(v_query) then 0 else 1 end as rank,
             t.issued_at
        from public.tickets t
        join public.events e on e.id = t.event_id
        join public.ticket_categories c on c.id = t.category_id
       where e.organization_id = p_organization_id
         and (
           upper(t.public_reference) like '%' || upper(v_query) || '%'
           or (t.holder_name is not null
               and private.fold(t.holder_name) like '%' || v_folded || '%')
           or (char_length(v_digits) >= 4 and t.holder_phone is not null
               and regexp_replace(t.holder_phone, '[^0-9]', '', 'g') like '%' || v_digits || '%')
         )
       order by rank, t.issued_at desc
       limit v_limit
    ) x;

  return jsonb_build_object('events', v_events, 'tickets', v_tickets);
end;
$$;
revoke all on function public.promoter_search(uuid, text, integer) from public, anon;
grant execute on function public.promoter_search(uuid, text, integer) to authenticated;
