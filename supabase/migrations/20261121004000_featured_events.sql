-- Événements « À la une » choisis par l'administrateur (améliorations du 20/11,
-- #3, ADR 0028). Liste ordonnée, chaque mise en avant a une période (fin par
-- défaut : la fin de l'événement). Sans mise en avant en cours, Explorer montre
-- les 5 prochains événements publics. Seuls les événements publics à venir
-- (private.is_listed) peuvent être mis à la une ou affichés.

create table public.featured_events (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null unique references public.events (id) on delete cascade,
  position integer not null,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  added_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create index featured_events_position_idx on public.featured_events (position, created_at);
alter table public.featured_events enable row level security;
-- Lectures et écritures par les fonctions seulement.
revoke all on public.featured_events from anon, authenticated;

-- Lecture publique (Explorer) : mises en avant en cours, dans l'ordre ; à
-- défaut, les 5 prochains événements publics.
create function public.public_featured_events(p_limit integer default 10)
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
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  return query
  select e.id, e.title, e.kind, e.starts_at, e.ends_at, e.timezone, e.venue, e.city,
         e.cover_path, o.name,
         (select min(c.indicative_price) from public.ticket_categories c
           where c.event_id = e.id and not c.is_invitation)
    from public.featured_events f
    join public.events e on e.id = f.event_id
    join public.organizations o on o.id = e.organization_id
   where now() >= f.starts_at and now() < f.ends_at
     and private.is_listed(e)
   order by f.position, f.created_at
   limit least(greatest(coalesce(p_limit, 10), 1), 20);
  if not found then
    return query select * from public.public_events(p_limit => 5);
  end if;
end;
$$;
revoke all on function public.public_featured_events(integer) from public;
grant execute on function public.public_featured_events(integer) to anon, authenticated;

-- Console : liste complète, avec l'état de chaque mise en avant.
create function public.admin_featured_events()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', f.id,
             'event_id', e.id,
             'title', e.title,
             'kind', e.kind,
             'organization_name', o.name,
             'event_starts_at', e.starts_at,
             'event_ends_at', e.ends_at,
             'city', e.city,
             'cover_path', e.cover_path,
             'position', f.position,
             'starts_at', f.starts_at,
             'ends_at', f.ends_at,
             'listed', private.is_listed(e),
             'live', private.is_listed(e) and now() >= f.starts_at and now() < f.ends_at)
           order by f.position, f.created_at)
      from public.featured_events f
      join public.events e on e.id = f.event_id
      join public.organizations o on o.id = e.organization_id), '[]'::jsonb);
end;
$$;
revoke all on function public.admin_featured_events() from public, anon;
grant execute on function public.admin_featured_events() to authenticated;

create function public.admin_add_featured_event(
  p_event_id uuid,
  p_starts_at timestamptz default null,
  p_ends_at timestamptz default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events;
  v_id uuid;
  v_starts timestamptz := coalesce(p_starts_at, now());
begin
  perform private.require_platform_admin();
  select e.* into v_event from public.events e where e.id = p_event_id;
  if not found or not private.is_listed(v_event) then
    raise exception 'featured_event_invalid'
      using errcode = '22023', detail = 'Seul un événement public à venir peut être mis à la une.';
  end if;
  if coalesce(p_ends_at, v_event.ends_at) <= v_starts then
    raise exception 'featured_period_invalid'
      using errcode = '22023', detail = 'La fin de la mise en avant doit suivre son début.';
  end if;
  -- Ordre : à la suite des autres (verrou contre deux ajouts simultanés).
  perform pg_advisory_xact_lock(hashtext('featured_events'));
  begin
    insert into public.featured_events (event_id, position, starts_at, ends_at, added_by)
    values (p_event_id,
            coalesce((select max(f.position) from public.featured_events f), 0) + 1,
            v_starts, coalesce(p_ends_at, v_event.ends_at), auth.uid())
    returning id into v_id;
  exception when unique_violation then
    raise exception 'featured_exists'
      using errcode = '55000', detail = 'Cet événement est déjà à la une.';
  end;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'admin.featured_added', 'event', v_event.id, '{}'::jsonb);
  return v_id;
end;
$$;
revoke all on function public.admin_add_featured_event(uuid, timestamptz, timestamptz) from public, anon;
grant execute on function public.admin_add_featured_event(uuid, timestamptz, timestamptz) to authenticated;

create function public.admin_set_featured_period(
  p_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event_id uuid;
begin
  perform private.require_platform_admin();
  if p_starts_at is null or p_ends_at is null or p_ends_at <= p_starts_at then
    raise exception 'featured_period_invalid'
      using errcode = '22023', detail = 'La fin de la mise en avant doit suivre son début.';
  end if;
  update public.featured_events f
     set starts_at = p_starts_at, ends_at = p_ends_at
   where f.id = p_id
  returning f.event_id into v_event_id;
  if v_event_id is null then
    raise exception 'featured_not_found' using errcode = 'P0002', detail = 'Mise en avant introuvable.';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  select e.organization_id, auth.uid(), 'admin.featured_period_set', 'event', e.id, '{}'::jsonb
    from public.events e where e.id = v_event_id;
end;
$$;
revoke all on function public.admin_set_featured_period(uuid, timestamptz, timestamptz) from public, anon;
grant execute on function public.admin_set_featured_period(uuid, timestamptz, timestamptz) to authenticated;

-- Monter (-1) ou descendre (+1) d'un rang : échange avec le voisin.
create function public.admin_move_featured_event(p_id uuid, p_direction integer)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_row public.featured_events;
  v_next public.featured_events;
begin
  perform private.require_platform_admin();
  if p_direction not in (-1, 1) then
    raise exception 'featured_move_invalid' using errcode = '22023', detail = 'Monter ou descendre.';
  end if;
  perform pg_advisory_xact_lock(hashtext('featured_events'));
  -- Rangs remis à la suite (1, 2, 3…) avant l'échange.
  update public.featured_events f
     set position = r.rank
    from (select x.id, row_number() over (order by x.position, x.created_at) as rank
            from public.featured_events x) r
   where f.id = r.id and f.position <> r.rank;
  select f.* into v_row from public.featured_events f where f.id = p_id;
  if not found then
    raise exception 'featured_not_found' using errcode = 'P0002', detail = 'Mise en avant introuvable.';
  end if;
  select f.* into v_next from public.featured_events f
   where f.position = v_row.position + p_direction;
  if not found then
    return; -- Déjà en tête ou en dernier.
  end if;
  update public.featured_events f set position = v_next.position where f.id = v_row.id;
  update public.featured_events f set position = v_row.position where f.id = v_next.id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  select e.organization_id, auth.uid(), 'admin.featured_moved', 'event', e.id,
         jsonb_build_object('position', v_next.position)
    from public.events e where e.id = v_row.event_id;
end;
$$;
revoke all on function public.admin_move_featured_event(uuid, integer) from public, anon;
grant execute on function public.admin_move_featured_event(uuid, integer) to authenticated;

create function public.admin_remove_featured_event(p_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event_id uuid;
begin
  perform private.require_platform_admin();
  delete from public.featured_events f where f.id = p_id returning f.event_id into v_event_id;
  if v_event_id is null then
    raise exception 'featured_not_found' using errcode = 'P0002', detail = 'Mise en avant introuvable.';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  select e.organization_id, auth.uid(), 'admin.featured_removed', 'event', e.id, '{}'::jsonb
    from public.events e where e.id = v_event_id;
end;
$$;
revoke all on function public.admin_remove_featured_event(uuid) from public, anon;
grant execute on function public.admin_remove_featured_event(uuid) to authenticated;
