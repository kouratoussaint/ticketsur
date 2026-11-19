-- =============================================================================
-- Tikéo — Tests : console d'administration (migration 1900)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-1900-0000-0000-000000000001', 'proprio-console@test.local'),
  ('aaaaaaaa-1900-0000-0000-000000000002', 'admin-console@test.local');

set role authenticated;
select test.login('aaaaaaaa-1900-0000-0000-000000000001');
select (public.create_organization('Kwabo Événements Console')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Festival Kwabo Console', now() + interval '2 days',
                            now() + interval '2 days 5 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select public.set_event_public(:'ev', true) \gset ignored_
select count(*) from public.issue_tickets(:'ev', :'cat', 3) \gset ignored_

-- Un compte ordinaire n'a aucun accès -----------------------------------------
select test.login('aaaaaaaa-1900-0000-0000-000000000002');
select test.check('Compte ordinaire : pas administrateur',
  public.is_platform_admin()::text, 'false');
do $$
begin
  begin
    perform public.admin_overview();
    raise exception 'ÉCHEC  vue d''ensemble lue sans être administrateur';
  exception when insufficient_privilege then
    raise notice 'OK    Vue d''ensemble réservée aux administrateurs';
  end;
  begin
    perform public.admin_set_organization_status(
      (select id from public.organizations where name = 'Kwabo Événements Console'),
      'disabled', 'test');
    raise exception 'ÉCHEC  organisation suspendue sans être administrateur';
  exception when insufficient_privilege then
    raise notice 'OK    Suspension réservée aux administrateurs';
  end;
end $$;

-- Sans compte : rien non plus.
reset role;
select test.login(null);
set role anon;
do $$
begin
  begin
    perform public.admin_overview();
    raise exception 'ÉCHEC  console ouverte sans compte';
  exception when insufficient_privilege then
    raise notice 'OK    Console fermée sans compte';
  end;
end $$;

-- Le rôle s'attribue en SQL seulement -------------------------------------------
reset role;
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-1900-0000-0000-000000000002';
set role authenticated;
select test.login('aaaaaaaa-1900-0000-0000-000000000002');
select test.check('Administrateur reconnu', public.is_platform_admin()::text, 'true');

select public.admin_overview()::text as overview \gset
select test.check('Vue d''ensemble : sections',
  (select string_agg(k, ',' order by k) from jsonb_object_keys(:'overview'::jsonb) k),
  'accounts,events,organizations,scans_24h,server_time,tickets,version');
select test.check('Vue d''ensemble : nos tickets comptés',
  (((:'overview'::jsonb)->'tickets'->>'issued')::int >= 3)::text, 'true');
select test.check('Vue d''ensemble : notre événement listé',
  (((:'overview'::jsonb)->'events'->>'listed')::int >= 1)::text, 'true');

select test.check('Organisations : recherche sans accents, chiffres',
  (select name || '|' || (owner_name is not null) || '|' || members || '|' || events || '|' || tickets
   from public.admin_organizations('kwabo evenements console')),
  'Kwabo Événements Console|true|1|1|3');

-- Suspension d'une organisation ---------------------------------------------------
do $$
begin
  begin
    perform public.admin_set_organization_status(
      (select id from public.organizations where name = 'Kwabo Événements Console'), 'disabled', '  ');
    raise exception 'ÉCHEC  suspension sans motif';
  exception when invalid_parameter_value then
    raise notice 'OK    Suspension : motif obligatoire';
  end;
end $$;
select (public.admin_set_organization_status(:'org', 'disabled', 'Fraude signalée')).status::text as st \gset
select test.check('Organisation suspendue', :'st', 'disabled');
select test.check('Suspension : motif sur l''organisation, pas dans le journal',
  (select details::text from public.admin_audit_logs('admin.organization_status_changed', 100)
   where resource_id = :'org'),
  '{"status": "disabled"}');
select test.check('Filtre des suspendues',
  (select count(*)::text from public.admin_organizations('kwabo', 'disabled')), '1');

-- L'organisateur d'une organisation suspendue perd ses droits.
select test.login('aaaaaaaa-1900-0000-0000-000000000001');
do $$
begin
  begin
    perform public.issue_tickets(
      (select id from public.events where title = 'Festival Kwabo Console'),
      (select c.id from public.ticket_categories c join public.events e on e.id = c.event_id
        where e.title = 'Festival Kwabo Console'), 1);
    raise exception 'ÉCHEC  émission dans une organisation suspendue';
  exception when insufficient_privilege then
    raise notice 'OK    Organisation suspendue : plus d''émission';
  end;
end $$;
reset role;
select test.login(null);
set role anon;
select coalesce(string_agg(title, ','), '∅') as anon_suspended
  from public.public_events('kwabo console') \gset
reset role;
select test.check('Organisation suspendue : hors du catalogue', :'anon_suspended', '∅');

set role authenticated;
select test.login('aaaaaaaa-1900-0000-0000-000000000002');
select (public.admin_set_organization_status(:'org', 'active')).disabled_reason is null as cleared \gset
select test.check('Réactivation : motif effacé', :'cleared', 't');

-- Modération du catalogue -------------------------------------------------------
select test.check('Catalogue : événement public visible de la console',
  (select title || '|' || organization_name || '|' || listed
   from public.admin_public_events('festival kwabo')),
  'Festival Kwabo Console|Kwabo Événements Console|true');
do $$
begin
  begin
    perform public.admin_set_event_blocked(
      (select id from public.events where title = 'Festival Kwabo Console'), true, null);
    raise exception 'ÉCHEC  retrait sans motif';
  exception when invalid_parameter_value then
    raise notice 'OK    Retrait : motif obligatoire';
  end;
end $$;
select (public.admin_set_event_blocked(:'ev', true, 'Contenu trompeur')).is_public::text as after_block \gset
select test.check('Retrait : l''événement n''est plus public', :'after_block', 'false');
select test.check('Retrait : visible dans « retirés »',
  (select blocked_reason || '|' || listed from public.admin_public_events('kwabo', true)),
  'Contenu trompeur|false');
select test.check('Retrait journalisé sans motif',
  (select details::text from public.admin_audit_logs('admin.event_moderated', 100)
   where resource_id = :'ev'),
  '{"blocked": true}');

reset role;
select test.login(null);
set role anon;
select coalesce(string_agg(title, ','), '∅') as anon_blocked
  from public.public_events('kwabo console') \gset
reset role;
select test.check('Retrait : hors du catalogue', :'anon_blocked', '∅');

-- L'organisateur ne peut pas republier ; il voit le motif.
set role authenticated;
select test.login('aaaaaaaa-1900-0000-0000-000000000001');
do $$
begin
  begin
    perform public.set_event_public(
      (select id from public.events where title = 'Festival Kwabo Console'), true);
    raise exception 'ÉCHEC  événement retiré republié';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    Événement retiré : l''organisateur ne peut pas le republier';
  end;
end $$;
select test.check('Organisateur : motif du retrait lisible',
  (select public_blocked_reason from public.events where id = :'ev'), 'Contenu trompeur');

-- Rétablissement : l'organisateur peut republier.
select test.login('aaaaaaaa-1900-0000-0000-000000000002');
select (public.admin_set_event_blocked(:'ev', false)).is_public::text as after_unblock \gset
select test.check('Rétablissement : pas de republication automatique', :'after_unblock', 'false');
select test.login('aaaaaaaa-1900-0000-0000-000000000001');
select (public.set_event_public(:'ev', true)).is_public::text as republished \gset
select test.check('Rétablissement : l''organisateur republie', :'republished', 'true');

-- Journal -------------------------------------------------------------------------
reset role;
select string_agg(action || ':' || (details::text), ',' order by created_at desc, id) as expected_log
  from public.audit_logs where organization_id = :'org' and action like 'admin.%' \gset
set role authenticated;
select test.login('aaaaaaaa-1900-0000-0000-000000000002');
select test.check('Journal : les quatre actions de la console, les plus récentes d''abord',
  (select count(*)::text || '|' || string_agg(action || ':' || (details::text), ',' order by created_at desc, id)
   from (select * from public.admin_audit_logs('admin.', 100)
          where organization_id = :'org') j),
  '4|' || :'expected_log');
select test.check('Journal : nom de l''organisation et de l''auteur',
  (select organization_name || '|' || (actor_name is not null)
   from public.admin_audit_logs('admin.event_moderated', 100)
   where resource_id = :'ev' limit 1),
  'Kwabo Événements Console|true');
do $$
begin
  begin
    perform public.admin_audit_logs(null, 500);
    raise exception 'ÉCHEC  page de journal trop longue';
  exception when invalid_parameter_value then
    raise notice 'OK    Journal : 100 lignes par page au plus';
  end;
end $$;

-- Un administrateur désactivé perd la console.
reset role;
update public.profiles set status = 'disabled'
 where id = 'aaaaaaaa-1900-0000-0000-000000000002';
set role authenticated;
select test.login('aaaaaaaa-1900-0000-0000-000000000002');
select test.check('Administrateur désactivé : plus de console',
  public.is_platform_admin()::text, 'false');
reset role;
