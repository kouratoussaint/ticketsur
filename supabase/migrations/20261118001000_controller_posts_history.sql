-- =============================================================================
-- TicketSûr — Migration 1000 : postes du contrôleur et historique personnel
-- (S20, S21, S27)
-- =============================================================================
-- * my_scan_posts : couples (événement, porte) où l'appelant peut scanner :
--   affectation active, adhésion active, compte actif, organisation active,
--   événement publié ou en cours, porte active. Une affectation « toutes les
--   portes » est dépliée en portes actives. La fenêtre de contrôle est
--   renvoyée pour l'affichage ; validate_scan reste seul juge.
-- * my_recent_scans : les tentatives de l'appelant sur 7 jours, 100 au plus,
--   avec la référence publique du billet (jamais le jeton).
-- =============================================================================

create or replace function public.my_scan_posts()
returns table (
  event_id uuid,
  event_title text,
  event_status public.event_status,
  venue text,
  timezone text,
  starts_at timestamptz,
  ends_at timestamptz,
  scan_opens_at timestamptz,
  scan_closes_at timestamptz,
  organization_id uuid,
  organization_name text,
  checkpoint_id uuid,
  checkpoint_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct on (e.id, cp.id)
         e.id, e.title, e.status, e.venue, e.timezone, e.starts_at, e.ends_at,
         e.starts_at - e.scan_opens_before, e.ends_at + e.scan_closes_after,
         o.id, o.name, cp.id, cp.name
  from public.event_assignments a
  join public.events e on e.id = a.event_id
  join public.organizations o on o.id = e.organization_id
  join public.organization_members m
    on m.organization_id = e.organization_id and m.user_id = a.user_id
  join public.profiles p on p.id = a.user_id
  join public.checkpoints cp
    on cp.event_id = e.id and (a.checkpoint_id is null or cp.id = a.checkpoint_id)
  where a.user_id = auth.uid()
    and a.active and m.active and p.status = 'active' and o.status = 'active'
    and e.status in ('published', 'in_progress')
    and cp.active
    and e.ends_at + e.scan_closes_after > now()
  order by e.id, cp.id
$$;
revoke all on function public.my_scan_posts() from public, anon;
grant execute on function public.my_scan_posts() to authenticated;

create or replace function public.my_recent_scans(p_limit integer default 50)
returns table (
  id uuid,
  server_time timestamptz,
  outcome public.scan_result,
  event_id uuid,
  event_title text,
  checkpoint_name text,
  public_reference text,
  category_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select sa.id, sa.server_time, sa.outcome, sa.event_id, e.title, cp.name,
         t.public_reference, c.name
  from public.scan_attempts sa
  left join public.events e on e.id = sa.event_id
  left join public.checkpoints cp on cp.id = sa.checkpoint_id
  left join public.tickets t on t.id = sa.ticket_id
  left join public.ticket_categories c on c.id = t.category_id
  where sa.actor_id = auth.uid()
    and sa.server_time > now() - interval '7 days'
  order by sa.server_time desc, sa.id
  limit least(greatest(coalesce(p_limit, 50), 1), 100)
$$;
revoke all on function public.my_recent_scans(integer) from public, anon;
grant execute on function public.my_recent_scans(integer) to authenticated;
