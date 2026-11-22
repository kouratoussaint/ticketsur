-- =============================================================================
-- Tikéo — Structure fermée : consultation seule (décision de Toussaint du
-- 22/11/2026, ADR 0044)
-- =============================================================================
-- Une structure fermée par la console (`closed_at`, migration 5000) reste
-- inaccessible au quotidien (`has_org_role` exige une structure active).
-- Son propriétaire et ses gestionnaires peuvent seulement la consulter par
-- les fonctions ci-dessous : liste des structures fermées, événements avec
-- leurs chiffres, tableau de bord, bilan et liste des tickets (export).
--
-- Mécanisme : chaque fonction de consultation vérifie le droit, pose le
-- réglage local `tikeo.closed_read` (= identifiant de la structure) le temps
-- de lire avec les corps existants, puis le retire. `has_org_role` accepte
-- une structure fermée uniquement quand ce réglage la désigne : aucune
-- écriture n'est rouverte (les fonctions d'écriture ne posent jamais ce
-- réglage, et un client ne peut pas le poser).

-- -----------------------------------------------------------------------------
-- Habilitation : une structure fermée compte, le temps d'une consultation
-- -----------------------------------------------------------------------------
create or replace function private.has_org_role(p_org uuid, p_roles public.member_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_members m
    join public.profiles p on p.id = m.user_id
    join public.organizations o on o.id = m.organization_id
    where m.organization_id = p_org
      and m.user_id = auth.uid()
      and m.active
      and m.role = any (p_roles)
      and p.status = 'active'
      and (o.status = 'active'
           or (o.closed_at is not null and o.trashed_at is null and o.purged_at is null
               and current_setting('tikeo.closed_read', true) = o.id::text))
  )
$$;

-- Droit de consulter une structure fermée : propriétaire ou gestionnaire
-- encore membre, compte actif.
create function private.can_read_closed_org(p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_members m
    join public.profiles p on p.id = m.user_id
    join public.organizations o on o.id = m.organization_id
    where m.organization_id = p_org
      and m.user_id = auth.uid()
      and m.active
      and m.role in ('owner', 'manager')
      and p.status = 'active'
      and o.closed_at is not null and o.trashed_at is null and o.purged_at is null
  )
$$;
revoke all on function private.can_read_closed_org(uuid) from public, anon, authenticated;

-- Ouvre la consultation d'un événement d'une structure fermée ; renvoie la
-- structure. `event_not_found` sinon (même réponse qu'un événement inconnu).
create function private.open_closed_event_read(p_event_id uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_org uuid;
begin
  select e.organization_id into v_org
    from public.events e
   where e.id = p_event_id and e.trashed_at is null;
  if v_org is null or not private.can_read_closed_org(v_org) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  perform set_config('tikeo.closed_read', v_org::text, true);
  return v_org;
end;
$$;
revoke all on function private.open_closed_event_read(uuid) from public, anon, authenticated;

create function private.close_closed_read()
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  select set_config('tikeo.closed_read', '', true);
$$;
revoke all on function private.close_closed_read() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Liste des structures fermées du compte
-- -----------------------------------------------------------------------------
create function public.my_closed_organizations()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', o.id, 'name', o.name, 'city', o.city, 'logo_path', o.logo_path,
           'role', m.role, 'closed_at', o.closed_at,
           'events', (select count(*) from public.events e
                       where e.organization_id = o.id and e.trashed_at is null))
         order by o.closed_at desc, o.name), '[]'::jsonb)
    from public.organization_members m
    join public.profiles p on p.id = m.user_id
    join public.organizations o on o.id = m.organization_id
   where m.user_id = auth.uid()
     and m.active
     and m.role in ('owner', 'manager')
     and p.status = 'active'
     and o.closed_at is not null and o.trashed_at is null and o.purged_at is null
$$;
revoke all on function public.my_closed_organizations() from public, anon;
grant execute on function public.my_closed_organizations() to authenticated;

-- -----------------------------------------------------------------------------
-- Une structure fermée : identité et événements, avec leurs chiffres
-- -----------------------------------------------------------------------------
create function public.closed_organization_events(p_organization_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.can_read_closed_org(p_organization_id) then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable.';
  end if;
  return (
    select jsonb_build_object(
      'organization', jsonb_build_object(
        'id', o.id, 'name', o.name, 'city', o.city, 'logo_path', o.logo_path,
        'closed_at', o.closed_at,
        'role', (select m.role from public.organization_members m
                  where m.organization_id = o.id and m.user_id = auth.uid())),
      'events', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'id', e.id, 'organization_id', e.organization_id, 'title', e.title,
                 'venue', e.venue, 'city', e.city, 'timezone', e.timezone,
                 'starts_at', e.starts_at, 'ends_at', e.ends_at, 'status', e.status,
                 'kind', e.kind, 'cover_path', e.cover_path, 'capacity', e.capacity,
                 'issued', (select count(*) from public.tickets t
                             where t.event_id = e.id and t.status <> 'revoked'),
                 'admitted', (select count(*) from public.tickets t
                               where t.event_id = e.id and t.status <> 'revoked'
                                 and t.entries_used > 0),
                 'revoked', (select count(*) from public.tickets t
                              where t.event_id = e.id and t.status = 'revoked'))
               order by e.starts_at desc)
          from public.events e
         where e.organization_id = o.id and e.trashed_at is null), '[]'::jsonb))
    from public.organizations o
   where o.id = p_organization_id);
end;
$$;
revoke all on function public.closed_organization_events(uuid) from public, anon;
grant execute on function public.closed_organization_events(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Tableau de bord, bilan, liste des tickets d'un événement d'une structure
-- fermée (mêmes réponses que pour une structure ouverte ; pas de contrôle du
-- pack : ces données appartiennent déjà à la structure)
-- -----------------------------------------------------------------------------
create function public.closed_event_dashboard(p_event_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  perform private.open_closed_event_read(p_event_id);
  v_result := private.event_dashboard_core(p_event_id);
  perform private.close_closed_read();
  return v_result;
end;
$$;
revoke all on function public.closed_event_dashboard(uuid) from public, anon;
grant execute on function public.closed_event_dashboard(uuid) to authenticated;

create function public.closed_event_summary(p_event_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  perform private.open_closed_event_read(p_event_id);
  v_result := public.event_summary(p_event_id);
  perform private.close_closed_read();
  return v_result;
end;
$$;
revoke all on function public.closed_event_summary(uuid) from public, anon;
grant execute on function public.closed_event_summary(uuid) to authenticated;

create function public.closed_event_report_rows(p_event_id uuid)
returns table (
  public_reference text,
  category_name text,
  category_is_invitation boolean,
  status public.ticket_status,
  holder_name text,
  holder_phone text,
  holder_email text,
  issued_at timestamptz,
  redeemed_at timestamptz,
  redeemed_checkpoint_name text,
  revoked_at timestamptz,
  last_delivery_channel public.delivery_channel,
  last_delivery_at timestamptz
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.open_closed_event_read(p_event_id);
  -- `return query` exécute la requête tout de suite : le réglage peut être
  -- retiré juste après.
  return query select * from private.event_report_rows_core(p_event_id);
  perform private.close_closed_read();
end;
$$;
revoke all on function public.closed_event_report_rows(uuid) from public, anon;
grant execute on function public.closed_event_report_rows(uuid) to authenticated;
