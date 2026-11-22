-- Lot 4-12a (ADR 0049) : l'Explorer montre les prochains événements publics
-- des structures que le compte suit (ADR 0047). Mêmes champs de vitrine que
-- `public_events` : jamais de ticket, de titulaire ni de chiffre.

create function public.my_followed_events(p_limit integer default 10)
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
  select e.id, e.title, e.kind, e.starts_at, e.ends_at, e.timezone, e.venue,
         e.city, e.cover_path, o.name,
         (select min(c.indicative_price) from public.ticket_categories c
           where c.event_id = e.id and not c.is_invitation)
    from public.organization_followers f
    join public.organizations o on o.id = f.organization_id
    join public.events e on e.organization_id = o.id
   where f.user_id = auth.uid()
     and private.is_listed(e)
   order by e.starts_at, e.title, e.id
   limit least(greatest(coalesce(p_limit, 10), 1), 20)
$$;
revoke all on function public.my_followed_events(integer) from public, anon;
grant execute on function public.my_followed_events(integer) to authenticated;
