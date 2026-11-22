-- Lot 4-12c (ADR 0051) : mesures d'audience pour le promoteur.
-- 1. Vues de la fiche publique d'un événement : un compteur par jour, sans
--    compte, sans adresse IP, sans identifiant d'appareil (l'app compte une
--    vue par appareil, par événement et par jour). Indicatif.
-- 2. Abonnés d'une structure (ADR 0047) : nombre et arrivées par jour.
-- Jours en heure UTC (heure du Burkina Faso).

create table public.event_page_views (
  event_id uuid not null references public.events (id) on delete cascade,
  day date not null,
  views integer not null default 0 check (views >= 0),
  primary key (event_id, day)
);
alter table public.event_page_views enable row level security;
revoke all on public.event_page_views from anon, authenticated;

-- Une vue de la fiche publique. Sans effet (et sans erreur, pour ne rien
-- révéler) si l'événement n'est pas au catalogue.
create function public.record_event_view(p_event_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  if exists (select 1 from public.events e
              where e.id = p_event_id and private.is_listed(e)) then
    insert into public.event_page_views as v (event_id, day, views)
    values (p_event_id, (now() at time zone 'UTC')::date, 1)
    on conflict (event_id, day) do update set views = v.views + 1;
  end if;
end;
$$;
revoke all on function public.record_event_view(uuid) from public;
grant execute on function public.record_event_view(uuid) to anon, authenticated;

-- Promoteur (propriétaire ou gestionnaire) : `{total, last_7, days}`,
-- `days` = les 30 derniers jours, aujourd'hui compris, du plus ancien au
-- plus récent.
create function public.event_page_views(p_event_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org uuid;
  v_today date := (now() at time zone 'UTC')::date;
begin
  select e.organization_id into v_org from public.events e where e.id = p_event_id;
  if v_org is null
     or not private.has_org_role(v_org, array['owner', 'manager']::public.member_role[]) then
    raise exception 'event_not_found'
      using errcode = 'P0002', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  return jsonb_build_object(
    'total', (select coalesce(sum(v.views), 0) from public.event_page_views v
               where v.event_id = p_event_id),
    'last_7', (select coalesce(sum(v.views), 0) from public.event_page_views v
                where v.event_id = p_event_id and v.day > v_today - 7),
    'days', (select jsonb_agg(jsonb_build_object('day', d.day::date, 'count', coalesce(v.views, 0))
                              order by d.day)
               from generate_series(v_today - 29, v_today, interval '1 day') as d(day)
               left join public.event_page_views v
                 on v.event_id = p_event_id and v.day = d.day::date));
end;
$$;
revoke all on function public.event_page_views(uuid) from public, anon;
grant execute on function public.event_page_views(uuid) to authenticated;

-- Promoteur : `{followers, new_30d, days}` ; les arrivées comptent les
-- abonnés encore abonnés (un désabonnement efface la ligne).
create function public.organization_followers_stats(p_organization_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'UTC')::date;
begin
  if not private.has_org_role(p_organization_id,
                              array['owner', 'manager']::public.member_role[]) then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable ou droits insuffisants.';
  end if;
  return jsonb_build_object(
    'followers', (select count(*) from public.organization_followers f
                   where f.organization_id = p_organization_id),
    'new_30d', (select count(*) from public.organization_followers f
                 where f.organization_id = p_organization_id
                   and (f.created_at at time zone 'UTC')::date > v_today - 30),
    'days', (select jsonb_agg(jsonb_build_object('day', d.day::date, 'count',
                                (select count(*) from public.organization_followers f
                                  where f.organization_id = p_organization_id
                                    and (f.created_at at time zone 'UTC')::date = d.day::date))
                              order by d.day)
               from generate_series(v_today - 29, v_today, interval '1 day') as d(day)));
end;
$$;
revoke all on function public.organization_followers_stats(uuid) from public, anon;
grant execute on function public.organization_followers_stats(uuid) to authenticated;
