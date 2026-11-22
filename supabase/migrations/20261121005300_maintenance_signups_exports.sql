-- =============================================================================
-- Tikéo — Migration 5300 : maintenance, inscriptions, exports
-- (lot 4-11d-2, ADR 0042)
-- =============================================================================
-- 1. Mode maintenance (réglage de la console) : bandeau pour tous, avec un
--    message ; au besoin, modifications bloquées pour tout compte qui n'est
--    pas administrateur. Le contrôle à l'entrée (validation des tickets,
--    démarrage et arrêt du contrôle) n'est jamais bloqué ; « Mes tickets »,
--    le support et le profil non plus.
-- 2. Inscriptions ouvertes ou fermées : fermées, un compte ne se crée
--    qu'avec un code d'invitation valable (passé à l'inscription), ou par un
--    administrateur depuis la console.
-- 3. Exports pour Excel : comptes, structures, événements, factures, journal
--    (50 000 lignes au plus, les plus récentes). Chaque export est journalisé
--    avec son type et son nombre de lignes, jamais son contenu.
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   55000 maintenance
--   42501 signups_closed | admin_role_forbidden
--   22023 maintenance_message_invalid | export_kind_invalid
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Réglages
-- -----------------------------------------------------------------------------
alter table private.console_settings drop constraint console_settings_key_check;
alter table private.console_settings add constraint console_settings_key_check check (
  key in ('notify_users', 'admin_issue_tickets', 'maintenance', 'maintenance_message',
          'maintenance_writes', 'signups_open')
);
insert into private.console_settings (key, value) values
  ('maintenance', 'false'::jsonb),
  ('maintenance_message', '""'::jsonb),
  ('maintenance_writes', 'false'::jsonb),
  ('signups_open', 'true'::jsonb)
on conflict (key) do nothing;

-- État public de la plateforme (avec ou sans compte).
create function public.platform_status()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'maintenance', private.console_setting_bool('maintenance'),
    'message', case when private.console_setting_bool('maintenance')
                    then nullif((select s.value #>> '{}' from private.console_settings s
                                  where s.key = 'maintenance_message'), '') end,
    'writes_blocked', private.console_setting_bool('maintenance')
                      and private.console_setting_bool('maintenance_writes'),
    'signups_open', private.console_setting_bool('signups_open'))
$$;
revoke all on function public.platform_status() from public;
grant execute on function public.platform_status() to anon, authenticated;

create function public.admin_save_platform_status(
  p_maintenance boolean,
  p_message text,
  p_block_writes boolean,
  p_signups_open boolean
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_message text := nullif(trim(coalesce(p_message, '')), '');
  v_maintenance boolean := coalesce(p_maintenance, false);
  v_writes boolean := v_maintenance and coalesce(p_block_writes, false);
  v_signups boolean := coalesce(p_signups_open, true);
begin
  perform private.require_admin('settings');
  if char_length(coalesce(v_message, '')) > 300 then
    raise exception 'maintenance_message_invalid'
      using errcode = '22023', detail = 'Message de 300 caractères au plus.';
  end if;
  update private.console_settings s
     set value = case s.key
                   when 'maintenance' then to_jsonb(v_maintenance)
                   when 'maintenance_message' then to_jsonb(coalesce(v_message, ''))
                   when 'maintenance_writes' then to_jsonb(v_writes)
                   when 'signups_open' then to_jsonb(v_signups)
                 end,
         updated_by = auth.uid(),
         updated_at = now()
   where s.key in ('maintenance', 'maintenance_message', 'maintenance_writes', 'signups_open');
  perform private.log_admin_action('admin.platform_status_updated', 'platform', null, 'settings',
    jsonb_build_object('maintenance', v_maintenance, 'block_writes', v_writes,
                       'signups_open', v_signups));
  return public.platform_status();
end;
$$;
revoke all on function public.admin_save_platform_status(boolean, text, boolean, boolean)
  from public, anon;
grant execute on function public.admin_save_platform_status(boolean, text, boolean, boolean)
  to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Modifications bloquées pendant la maintenance
-- -----------------------------------------------------------------------------
create function private.maintenance_blocks_writes()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.console_setting_bool('maintenance')
     and private.console_setting_bool('maintenance_writes')
$$;
revoke all on function private.maintenance_blocks_writes() from public, anon, authenticated;

-- Les tâches planifiées (sans compte) et les administrateurs passent.
create function private.maintenance_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null
     and private.maintenance_blocks_writes()
     and not private.is_admin_account() then
    raise exception 'maintenance'
      using errcode = '55000',
            detail = 'Tikéo est en maintenance : les modifications reprendront bientôt.';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;
revoke all on function private.maintenance_guard() from public, anon, authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['organizations', 'organization_members', 'organization_invitations',
                           'organization_settings', 'ticket_categories', 'checkpoints',
                           'event_assignments', 'ticket_category_templates']
  loop
    execute format(
      'create trigger maintenance_guard before insert or update or delete on public.%I
         for each row execute function private.maintenance_guard()', t);
  end loop;
end;
$$;

-- Événements : création, suppression, modification ; jamais un changement
-- d'état (démarrer ou arrêter le contrôle reste possible).
create trigger maintenance_guard before insert or delete on public.events
  for each row execute function private.maintenance_guard();
create trigger maintenance_guard_update before update on public.events
  for each row when (old.status is not distinct from new.status)
  execute function private.maintenance_guard();

-- Tickets : émission, annulation, titulaire ; jamais une validation à
-- l'entrée ni l'ajout à « Mes tickets ».
create trigger maintenance_guard before insert on public.tickets
  for each row execute function private.maintenance_guard();
create trigger maintenance_guard_update before update on public.tickets
  for each row when (
    (new.status = 'revoked' and old.status <> 'revoked')
    or new.holder_name is distinct from old.holder_name
    or new.holder_phone is distinct from old.holder_phone
    or new.holder_email is distinct from old.holder_email)
  execute function private.maintenance_guard();

create trigger maintenance_guard before insert on public.billing_requests
  for each row execute function private.maintenance_guard();

-- -----------------------------------------------------------------------------
-- 3. Inscriptions (corps de 0400) : fermées, un code d'invitation valable ou
--    un compte créé par un administrateur (app_metadata posé par la fonction
--    serveur, jamais par l'app).
-- -----------------------------------------------------------------------------
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code text := nullif(trim(new.raw_user_meta_data ->> 'invitation_code'), '');
begin
  if not private.console_setting_bool('signups_open')
     and coalesce(new.raw_app_meta_data ->> 'tikeo_admin_created', '') <> 'true'
     and not exists (
       select 1
         from public.organization_invitations i
         join public.organizations o on o.id = i.organization_id and o.status = 'active'
        where v_code is not null
          and i.code_hash = private.invitation_code_hash(v_code)
          and private.invitation_state(i) = 'active')
  then
    raise exception 'signups_closed'
      using errcode = '42501', detail = 'Inscriptions fermées : il faut un code d''invitation.';
  end if;
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Utilisateur'
    ), 120)
  )
  on conflict (id) do nothing;
  -- Le code ne reste pas dans les métadonnées du compte.
  if v_code is not null then
    update auth.users u
       set raw_user_meta_data = u.raw_user_meta_data - 'invitation_code'
     where u.id = new.id;
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 4. Exports
-- -----------------------------------------------------------------------------
create function private.export_time(p_at timestamptz)
returns text
language sql
immutable
set search_path = ''
as $$
  select to_char(p_at at time zone 'UTC', 'YYYY-MM-DD HH24:MI')
$$;
revoke all on function private.export_time(timestamptz) from public, anon, authenticated;

create function public.admin_export(p_kind text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  c_max constant integer := 50000;
  v_columns text[];
  v_rows jsonb;
  v_count integer;
  v_total bigint;
begin
  perform private.require_platform_admin();
  if p_kind not in ('accounts', 'organizations', 'events', 'invoices', 'journal') then
    raise exception 'export_kind_invalid' using errcode = '22023', detail = 'Export inconnu.';
  end if;
  if not private.admin_can(case p_kind
                             when 'accounts' then 'accounts'
                             when 'organizations' then 'organizations'
                             when 'events' then 'events'
                             when 'invoices' then 'billing'
                             else null end) then
    raise exception 'admin_role_forbidden'
      using errcode = '42501', detail = 'Votre rôle d''administration ne permet pas cette action.';
  end if;

  if p_kind = 'accounts' then
    v_columns := array['id', 'name', 'email', 'phone', 'status', 'admin_role', 'created_at',
                       'last_sign_in_at', 'deletion_requested_at', 'deleted', 'organizations'];
    select count(*) into v_total from public.profiles;
    select coalesce(jsonb_agg(jsonb_build_array(
             x.id, x.display_name, x.email, x.phone, x.status, x.admin_role,
             private.export_time(x.created_at), private.export_time(x.last_sign_in_at),
             private.export_time(x.deletion_requested_at), x.deleted, x.organizations)
             order by x.created_at desc), '[]'::jsonb)
      into v_rows
      from (select p.id, p.display_name,
                   case when p.deleted_at is null then u.email end as email,
                   p.phone, p.status::text as status,
                   case when p.is_platform_admin then private.admin_role_of(p.id) end as admin_role,
                   p.created_at, u.last_sign_in_at, p.deletion_requested_at,
                   p.deleted_at is not null as deleted,
                   (select count(*) from public.organization_members m
                     where m.user_id = p.id and m.active) as organizations
              from public.profiles p
              left join auth.users u on u.id = p.id
             order by p.created_at desc
             limit c_max) x;
  elsif p_kind = 'organizations' then
    v_columns := array['id', 'name', 'city', 'status', 'closed_at', 'trashed_at', 'owner_name',
                       'owner_email', 'created_at', 'members', 'events', 'tickets'];
    select count(*) into v_total from public.organizations;
    select coalesce(jsonb_agg(jsonb_build_array(
             x.id, x.name, x.city, x.status, private.export_time(x.closed_at),
             private.export_time(x.trashed_at), x.owner_name, x.owner_email,
             private.export_time(x.created_at), x.members, x.events, x.tickets)
             order by x.created_at desc), '[]'::jsonb)
      into v_rows
      from (select o.id, o.name, o.city, o.status::text as status, o.closed_at, o.trashed_at,
                   pr.display_name as owner_name,
                   case when pr.deleted_at is null then u.email end as owner_email,
                   o.created_at,
                   (select count(*) from public.organization_members m
                     where m.organization_id = o.id and m.active) as members,
                   (select count(*) from public.events e where e.organization_id = o.id) as events,
                   (select count(*) from public.tickets t
                      join public.events e on e.id = t.event_id
                     where e.organization_id = o.id) as tickets
              from public.organizations o
              left join public.profiles pr on pr.id = o.owner_id
              left join auth.users u on u.id = o.owner_id
             order by o.created_at desc
             limit c_max) x;
  elsif p_kind = 'events' then
    v_columns := array['id', 'title', 'organization_name', 'city', 'status', 'starts_at',
                       'ends_at', 'public', 'tickets', 'admitted', 'trashed_at'];
    select count(*) into v_total from public.events;
    select coalesce(jsonb_agg(jsonb_build_array(
             x.id, x.title, x.organization_name, x.city, x.status,
             private.export_time(x.starts_at), private.export_time(x.ends_at), x.is_public,
             x.tickets, x.admitted, private.export_time(x.trashed_at))
             order by x.starts_at desc), '[]'::jsonb)
      into v_rows
      from (select e.id, e.title, o.name as organization_name, e.city, e.status::text as status,
                   e.starts_at, e.ends_at, e.is_public, e.trashed_at,
                   (select count(*) from public.tickets t where t.event_id = e.id) as tickets,
                   (select count(*) from public.tickets t
                     where t.event_id = e.id and t.status <> 'revoked' and t.entries_used > 0)
                     as admitted
              from public.events e
              join public.organizations o on o.id = e.organization_id
             order by e.starts_at desc
             limit c_max) x;
  elsif p_kind = 'invoices' then
    v_columns := array['id', 'issued_at', 'due_at', 'status', 'amount', 'entries',
                       'billable_entries', 'account_name', 'account_email', 'event_title',
                       'organization_name', 'paid_at'];
    select count(*) into v_total from public.billing_invoices;
    select coalesce(jsonb_agg(jsonb_build_array(
             x.id, private.export_time(x.issued_at), private.export_time(x.due_at), x.status,
             x.amount, x.entries, x.billable_entries, x.account_name, x.account_email,
             x.event_title, x.organization_name, private.export_time(x.paid_at))
             order by x.issued_at desc), '[]'::jsonb)
      into v_rows
      from (select i.id, i.issued_at, i.due_at, i.status, i.amount, i.entries,
                   i.billable_entries, pr.display_name as account_name,
                   case when pr.deleted_at is null then u.email end as account_email,
                   e.title as event_title, o.name as organization_name, i.paid_at
              from public.billing_invoices i
              join public.profiles pr on pr.id = i.account_id
              left join auth.users u on u.id = i.account_id
              join public.events e on e.id = i.event_id
              join public.organizations o on o.id = e.organization_id
             order by i.issued_at desc
             limit c_max) x;
  else
    v_columns := array['created_at', 'action', 'organization_name', 'actor_name',
                       'resource_type', 'resource_id', 'details'];
    select count(*) into v_total from public.audit_logs;
    select coalesce(jsonb_agg(jsonb_build_array(
             private.export_time(x.created_at), x.action, x.organization_name, x.actor_name,
             x.resource_type, x.resource_id, x.details::text)
             order by x.created_at desc, x.id), '[]'::jsonb)
      into v_rows
      from (select a.id, a.created_at, a.action, o.name as organization_name,
                   pr.display_name as actor_name, a.resource_type, a.resource_id, a.details
              from public.audit_logs a
              left join public.organizations o on o.id = a.organization_id
              left join public.profiles pr on pr.id = a.actor_id
             order by a.created_at desc, a.id
             limit c_max) x;
  end if;

  v_count := jsonb_array_length(v_rows);
  perform private.log_admin_action('admin.export', 'platform', null, 'export',
    jsonb_build_object('export', p_kind, 'rows', v_count));
  return jsonb_build_object('kind', p_kind, 'columns', to_jsonb(v_columns), 'rows', v_rows,
                            'truncated', v_total > v_count);
end;
$$;
revoke all on function public.admin_export(text) from public, anon;
grant execute on function public.admin_export(text) to authenticated;
