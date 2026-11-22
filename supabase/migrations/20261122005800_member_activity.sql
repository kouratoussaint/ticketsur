-- =============================================================================
-- Tikéo — Fiche d'un membre de l'équipe (amélioration n° 10 validée par
-- Toussaint le 22/11/2026, ADR 0048)
-- =============================================================================
-- Propriétaire et gestionnaires : pour un membre de la structure, ses entrées
-- validées (au total, sur 30 jours, la dernière), le nombre d'événements où
-- il a validé des entrées, et ses affectations aux événements à venir ou en
-- cours (porte comprise). Aucune donnée de spectateur.

create function public.member_activity(p_organization_id uuid, p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.has_org_role(p_organization_id, array['owner','manager']::public.member_role[]) then
    raise exception 'org_forbidden'
      using errcode = '42501', detail = 'Droits insuffisants.';
  end if;
  if not exists (select 1 from public.organization_members m
                  where m.organization_id = p_organization_id and m.user_id = p_user_id) then
    raise exception 'member_not_found'
      using errcode = 'P0002', detail = 'Ce compte n''est pas membre de la structure.';
  end if;
  return (
    with accepted as (
      select a.server_time, a.event_id
        from public.scan_attempts a
        join public.events e on e.id = a.event_id
       where a.actor_id = p_user_id
         and a.outcome = 'accepted'
         and e.organization_id = p_organization_id
    )
    select jsonb_build_object(
      'validated', (select count(*) from accepted),
      'validated_30d', (select count(*) from accepted
                         where server_time > now() - interval '30 days'),
      'last_validated_at', (select max(server_time) from accepted),
      'events_worked', (select count(distinct event_id) from accepted),
      'assignments', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'event_id', e.id, 'event_title', e.title, 'status', e.status,
                 'starts_at', e.starts_at, 'ends_at', e.ends_at, 'timezone', e.timezone,
                 'checkpoint_name', c.name)
               order by e.starts_at, e.title, e.id)
          from public.event_assignments ea
          join public.events e on e.id = ea.event_id
          left join public.checkpoints c on c.id = ea.checkpoint_id
         where ea.user_id = p_user_id
           and ea.active
           and e.organization_id = p_organization_id
           and e.status in ('draft', 'published', 'in_progress')
           and e.ends_at > now()), '[]'::jsonb))
  );
end;
$$;
revoke all on function public.member_activity(uuid, uuid) from public, anon;
grant execute on function public.member_activity(uuid, uuid) to authenticated;
