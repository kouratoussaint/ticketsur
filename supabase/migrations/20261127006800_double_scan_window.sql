-- =============================================================================
-- 6800 — Délai des doubles scans réglable depuis la console (ADR 0057)
--
-- Un refus « déjà utilisé » arrivé dans les N secondes qui suivent l'entrée du
-- même ticket est un double scan : il n'entre pas dans les pertes évitées.
-- N = réglage `double_scan_seconds` (15 par défaut, 0 à 300), permission
-- « settings ». Le tableau de bord renvoie aussi le nombre de refus écartés.
--
--   22023 double_scan_invalid
-- =============================================================================

alter table private.console_settings drop constraint console_settings_key_check;
alter table private.console_settings add constraint console_settings_key_check check (
  key in ('notify_users', 'admin_issue_tickets', 'maintenance', 'maintenance_message',
          'maintenance_writes', 'signups_open', 'double_scan_seconds')
);
insert into private.console_settings (key, value) values ('double_scan_seconds', '15'::jsonb)
on conflict (key) do nothing;

create function private.double_scan_seconds()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select (s.value #>> '{}')::integer from private.console_settings s
                    where s.key = 'double_scan_seconds'), 15)
$$;
revoke all on function private.double_scan_seconds() from public, anon, authenticated;

-- Réglages lus par la console (corps de 4900 + délai des doubles scans).
create or replace function public.admin_me()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role text := private.admin_role_of(auth.uid());
begin
  if v_role is null then
    raise exception 'forbidden'
      using errcode = '42501', detail = 'Réservé aux administrateurs de Tikéo.';
  end if;
  return jsonb_build_object(
    'role', v_role,
    'permissions', to_jsonb(private.role_permissions(v_role)),
    'mfa_enrolled', private.has_verified_factor(auth.uid()),
    'notify_users', private.console_setting_bool('notify_users'),
    'admin_issue_tickets', private.console_setting_bool('admin_issue_tickets'),
    'double_scan_seconds', private.double_scan_seconds());
end;
$$;

create or replace function public.admin_console_settings()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return jsonb_build_object(
    'notify_users', private.console_setting_bool('notify_users'),
    'admin_issue_tickets', private.console_setting_bool('admin_issue_tickets'),
    'double_scan_seconds', private.double_scan_seconds());
end;
$$;

create function public.admin_save_double_scan_seconds(p_seconds integer)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.require_admin('settings');
  if p_seconds is null or p_seconds < 0 or p_seconds > 300 then
    raise exception 'double_scan_invalid'
      using errcode = '22023', detail = 'Délai de 0 à 300 secondes.';
  end if;
  update private.console_settings s
     set value = to_jsonb(p_seconds), updated_by = auth.uid(), updated_at = now()
   where s.key = 'double_scan_seconds';
  perform private.log_admin_action('admin.double_scan_updated', 'platform', null, 'settings',
    jsonb_build_object('seconds', p_seconds));
  return public.admin_me();
end;
$$;
revoke all on function public.admin_save_double_scan_seconds(integer) from public, anon;
grant execute on function public.admin_save_double_scan_seconds(integer) to authenticated;

-- Pertes évitées : délai réglable, refus écartés comptés (corps de 6700).
create or replace function private.event_money(p_event_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with cats as (
    select c.id, c.name, c.indicative_price as price, c.is_invitation, c.created_at
      from public.ticket_categories c where c.event_id = p_event_id
  ), admitted as (
    select t.category_id, count(*) as n
      from public.tickets t
     where t.event_id = p_event_id and t.status <> 'revoked' and t.entries_used > 0
     group by t.category_id
  ), win as (
    select private.double_scan_seconds() as seconds
  ), attempts as (
    -- Refus d'un ticket de l'événement ; un « déjà utilisé » dans les N secondes
    -- qui suivent l'entrée de ce ticket est un double scan (réglage de la console).
    select t.id, t.category_id,
           (sa.outcome = 'already_used' and t.last_entry_at is not null
            and sa.server_time >= t.last_entry_at
            and sa.server_time < t.last_entry_at + make_interval(secs => w.seconds)) as double_scan
      from public.scan_attempts sa
      join public.tickets t on t.id = sa.ticket_id and t.event_id = p_event_id
      cross join win w
     where sa.event_id = p_event_id
       and sa.outcome in ('already_used', 'revoked', 'expired')
  ), refused as (
    select a.category_id, count(distinct a.id) as n
      from attempts a where not a.double_scan
     group by a.category_id
  ), rows as (
    select c.id, c.name, c.price, c.is_invitation, c.created_at,
           coalesce(a.n, 0) as admitted, coalesce(r.n, 0) as refused
      from cats c
      left join admitted a on a.category_id = c.id
      left join refused r on r.category_id = c.id
  )
  select jsonb_build_object(
    'currency', 'XOF',
    'revenue', coalesce(sum(r.admitted * r.price) filter (where not r.is_invitation), 0),
    'revenue_tickets', coalesce(sum(r.admitted) filter (where not r.is_invitation and r.price is not null), 0),
    'revenue_unpriced', coalesce(sum(r.admitted) filter (where not r.is_invitation and r.price is null), 0),
    'avoided', coalesce(sum(r.refused * r.price) filter (where not r.is_invitation), 0),
    'avoided_tickets', coalesce(sum(r.refused) filter (where not r.is_invitation and r.price is not null), 0),
    'avoided_unpriced', coalesce(sum(r.refused) filter (where not r.is_invitation and r.price is null), 0),
    'double_scans', (select count(*) from attempts a where a.double_scan),
    'double_scan_seconds', (select w.seconds from win w),
    'unknown_refusals', (select count(*) from public.scan_attempts sa
                          where sa.event_id = p_event_id
                            and sa.outcome in ('not_found', 'wrong_event')),
    'categories', coalesce(jsonb_agg(jsonb_build_object(
        'id', r.id, 'name', r.name, 'price', r.price, 'invitation', r.is_invitation,
        'admitted', r.admitted, 'refused', r.refused,
        'revenue', case when r.is_invitation then 0 else r.admitted * r.price end,
        'avoided', case when r.is_invitation then 0 else r.refused * r.price end)
      order by r.created_at, r.name) filter (where r.id is not null), '[]'::jsonb))
  from rows r
$$;
revoke all on function private.event_money(uuid) from public, anon, authenticated;
