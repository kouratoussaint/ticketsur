-- Lot 4-12b (ADR 0050) : signaler un événement public ou une structure ;
-- traitement dans la console (rôles super et modération, permission
-- `catalog`). Le commentaire du signalement n'est lu que par la console :
-- jamais dans `audit_logs`, jamais montré à la structure signalée.

create table public.content_reports (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('event', 'organization')),
  event_id uuid references public.events (id) on delete cascade,
  organization_id uuid not null references public.organizations (id) on delete cascade,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason text not null
    check (reason in ('misleading', 'scam', 'offensive', 'duplicate', 'other')),
  comment text check (comment is null or char_length(comment) between 1 and 300),
  status text not null default 'open' check (status in ('open', 'dismissed', 'actioned')),
  created_at timestamptz not null default now(),
  handled_at timestamptz,
  handled_by uuid references auth.users (id) on delete set null,
  check ((kind = 'event') = (event_id is not null))
);
alter table public.content_reports enable row level security;
revoke all on public.content_reports from anon, authenticated;

-- Un seul signalement ouvert par compte et par contenu.
create unique index content_reports_one_open_event
  on public.content_reports (reporter_id, event_id)
  where status = 'open' and kind = 'event';
create unique index content_reports_one_open_org
  on public.content_reports (reporter_id, organization_id)
  where status = 'open' and kind = 'organization';
create index content_reports_open on public.content_reports (status, created_at desc);
create index content_reports_reporter on public.content_reports (reporter_id, created_at desc);

-- Signaler (compte connecté) : `{id, already}`.
create function public.report_content(
  p_kind text,
  p_id uuid,
  p_reason text,
  p_comment text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
  v_comment text := nullif(btrim(coalesce(p_comment, '')), '');
  v_org uuid;
  v_event uuid;
  v_existing uuid;
  v_id uuid;
begin
  if p_reason is null
     or p_reason not in ('misleading', 'scam', 'offensive', 'duplicate', 'other') then
    raise exception 'report_reason_invalid' using errcode = '22023', detail = 'Choisissez un motif.';
  end if;
  if char_length(v_comment) > 300 then
    raise exception 'report_comment_invalid'
      using errcode = '22023', detail = 'Commentaire trop long (300 caractères au plus).';
  end if;
  if p_kind = 'event' then
    select e.id, e.organization_id into v_event, v_org
      from public.events e where e.id = p_id and private.is_listed(e);
  elsif p_kind = 'organization' then
    select o.id into v_org from public.organizations o
     where o.id = p_id and o.status = 'active';
  end if;
  if v_org is null then
    raise exception 'report_target_not_found'
      using errcode = 'P0002', detail = 'Contenu introuvable.';
  end if;
  select r.id into v_existing from public.content_reports r
   where r.reporter_id = v_actor and r.status = 'open' and r.kind = p_kind
     and (case when p_kind = 'event' then r.event_id = v_event
               else r.organization_id = v_org end);
  if v_existing is not null then
    return jsonb_build_object('id', v_existing, 'already', true);
  end if;
  if (select count(*) from public.content_reports r
       where r.reporter_id = v_actor and r.created_at > now() - interval '1 day') >= 10 then
    raise exception 'report_rate_limited'
      using errcode = '54000', detail = 'Trop de signalements aujourd''hui. Réessayez demain.';
  end if;
  insert into public.content_reports (kind, event_id, organization_id, reporter_id, reason, comment)
  values (p_kind, v_event, v_org, v_actor, p_reason, v_comment)
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'already', false);
end;
$$;
revoke all on function public.report_content(text, uuid, text, text) from public, anon;
grant execute on function public.report_content(text, uuid, text, text) to authenticated;

-- Console : signalements regroupés par contenu. `p_open` vrai : à traiter
-- (les plus signalés d'abord) ; faux : traités (les plus récents d'abord).
create function public.admin_content_reports(
  p_open boolean default true,
  p_limit integer default 30,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin('catalog');
  return jsonb_build_object(
    'open', (select count(distinct (r.kind, coalesce(r.event_id, r.organization_id)))
               from public.content_reports r where r.status = 'open'),
    'items', coalesce((
      with base as (
        select r.*, coalesce(r.event_id, r.organization_id) as target
          from public.content_reports r
         where (r.status = 'open') = p_open
      )
      select jsonb_agg(to_jsonb(g) - 'sort_count' - 'sort_at'
                       order by g.sort_count desc, g.sort_at desc, g.id)
        from (
          select b.kind,
                 b.target as id,
                 b.organization_id,
                 max(o.name) as organization_name,
                 case when b.kind = 'event' then max(e.title) else max(o.name) end as title,
                 case when b.kind = 'event' then max(e.starts_at) end as starts_at,
                 count(*) as count,
                 (select jsonb_object_agg(x.reason, x.n) from (
                    select b2.reason, count(*) as n from base b2
                     where b2.kind = b.kind and b2.target = b.target
                     group by b2.reason) x) as reasons,
                 (select coalesce(jsonb_agg(jsonb_build_object('comment', c.comment, 'at', c.created_at)
                                            order by c.created_at desc), '[]'::jsonb)
                    from (select b3.comment, b3.created_at from base b3
                           where b3.kind = b.kind and b3.target = b.target
                             and b3.comment is not null
                           order by b3.created_at desc limit 5) c) as comments,
                 min(b.created_at) as first_at,
                 max(b.created_at) as last_at,
                 max(b.handled_at) as handled_at,
                 case when bool_or(b.status = 'actioned') then 'actioned'
                      when bool_or(b.status = 'dismissed') then 'dismissed'
                      else 'open' end as status,
                 case when b.kind = 'event' then bool_or(e.public_blocked_at is not null)
                      else bool_or(o.status = 'disabled') end as removed,
                 case when p_open then count(*) else 0 end as sort_count,
                 case when p_open then max(b.created_at) else max(b.handled_at) end as sort_at
            from base b
            join public.organizations o on o.id = b.organization_id
            left join public.events e on e.id = b.event_id
           group by b.kind, b.target, b.organization_id
           order by case when p_open then count(*) else 0 end desc,
                    case when p_open then max(b.created_at) else max(b.handled_at) end desc,
                    b.target
           limit least(greatest(coalesce(p_limit, 30), 1), 50)
           offset greatest(coalesce(p_offset, 0), 0)
        ) g), '[]'::jsonb));
end;
$$;
revoke all on function public.admin_content_reports(boolean, integer, integer) from public, anon;
grant execute on function public.admin_content_reports(boolean, integer, integer) to authenticated;

-- Console : traiter les signalements ouverts d'un contenu. `remove` retire
-- l'événement du catalogue ou suspend la structure (fonctions existantes,
-- mêmes droits et même journal), `dismiss` classe sans suite. Motif
-- obligatoire. Renvoie `{resolved}`.
create function public.admin_resolve_reports(
  p_kind text,
  p_id uuid,
  p_action text,
  p_reason text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text;
  v_count integer;
begin
  perform private.require_admin('catalog');
  if p_action is null or p_action not in ('remove', 'dismiss') then
    raise exception 'status_invalid' using errcode = '22023', detail = 'Action inconnue.';
  end if;
  v_reason := private.clean_admin_reason(p_reason);
  if not exists (select 1 from public.content_reports r
                  where r.status = 'open' and r.kind = p_kind
                    and coalesce(r.event_id, r.organization_id) = p_id) then
    raise exception 'report_not_found'
      using errcode = 'P0002', detail = 'Aucun signalement à traiter.';
  end if;
  if p_action = 'remove' then
    if p_kind = 'event' then
      perform public.admin_set_event_blocked(p_id, true, v_reason);
    else
      perform public.admin_set_organization_status(p_id, 'disabled', v_reason);
    end if;
  end if;
  with done as (
    update public.content_reports r
       set status = case when p_action = 'remove' then 'actioned' else 'dismissed' end,
           handled_at = now(),
           handled_by = auth.uid()
     where r.status = 'open' and r.kind = p_kind
       and coalesce(r.event_id, r.organization_id) = p_id
    returning 1)
  select count(*) into v_count from done;
  -- Sans structure : la structure signalée ne voit pas ce traitement.
  perform private.log_admin_action(
    case when p_action = 'remove' then 'admin.reports_actioned' else 'admin.reports_dismissed' end,
    p_kind, p_id, v_reason, jsonb_build_object('reports', v_count));
  return jsonb_build_object('resolved', v_count);
end;
$$;
revoke all on function public.admin_resolve_reports(text, uuid, text, text) from public, anon;
grant execute on function public.admin_resolve_reports(text, uuid, text, text) to authenticated;
