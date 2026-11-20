-- =============================================================================
-- Tikéo — Tests : notifications push (migration 2800)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-2800-0000-0000-000000000001', 'promoteur-push@test.local'),
  ('aaaaaaaa-2800-0000-0000-000000000002', 'controleur-push@test.local'),
  ('aaaaaaaa-2800-0000-0000-000000000003', 'admin-push@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-2800-0000-0000-000000000003';
-- File vide pour ces tests (sur le staging, d'autres messages peuvent exister).
select coalesce(max(id), 0) as base from public.push_outbox \gset

set role authenticated;
select test.login('aaaaaaaa-2800-0000-0000-000000000002');
select public.register_push_device('jeton-controleur-' || repeat('x', 20)) \gset ignored_
do $$
begin
  begin
    perform public.register_push_device('court');
    raise exception 'ÉCHEC  jeton trop court accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Jeton invalide refusé';
  end;
end $$;
set role anon;
do $$
begin
  begin
    perform public.register_push_device('jeton-anonyme-' || repeat('x', 20));
    raise exception 'ÉCHEC  appareil enregistré sans compte';
  exception when insufficient_privilege then
    raise notice 'OK    Sans compte : pas d''appareil enregistré';
  end;
end $$;
set role authenticated;

-- Contrôle démarré → contrôleur affecté ------------------------------------------
select test.login('aaaaaaaa-2800-0000-0000-000000000001');
select (public.create_organization('Studio Push Qxp')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Match Push Qxp', now() + interval '1 day',
                            now() + interval '1 day 2 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Tribune')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-2800-0000-0000-000000000002', 'controller');
insert into public.event_assignments (event_id, user_id)
values (:'ev', 'aaaaaaaa-2800-0000-0000-000000000002');
set role authenticated;
select test.login('aaaaaaaa-2800-0000-0000-000000000001');
select public.set_event_status(:'ev', 'in_progress') \gset ignored_
reset role;
select test.check('Contrôle démarré : message au contrôleur',
  (select count(*)::text || '|' || min(title) || '|' || min(route)
     from public.push_outbox
    where id > :base and user_id = 'aaaaaaaa-2800-0000-0000-000000000002'),
  '1|Contrôle ouvert|/postes?evenement=' || :'ev');

-- Réponse du support → demandeur ---------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-2800-0000-0000-000000000002');
select public.create_support_request('Question Push Qxp', 'question', 'Bonjour') as req \gset
reset role;
select test.check('Message de l''utilisateur : pas de notification',
  (select count(*)::text from public.push_outbox where id > :base and route like '/support/%'), '0');
set role authenticated;
select test.login('aaaaaaaa-2800-0000-0000-000000000003');
select public.reply_support_request(:'req', 'Voici la réponse.') \gset ignored_
reset role;
select test.check('Réponse du support : message au demandeur, sans le texte',
  (select title || '|' || body || '|' || route from public.push_outbox
    where id > :base and route = '/support/' || :'req'),
  'Support Tikéo|Nouvelle réponse : Question Push Qxp|/support/' || :'req');

-- Annonce importante → sujets ; annonce simple → rien -------------------------------
set role authenticated;
select test.login('aaaaaaaa-2800-0000-0000-000000000003');
select public.admin_publish_announcement('Info Push Qxp', 'Simple.', array['users']) \gset ignored_
select public.admin_publish_announcement('Alerte Push Qxp', 'Important.',
  array['visitors', 'promoters'], 'important') \gset ignored_
reset role;
select test.check('Annonce importante seulement, vers ses sujets',
  (select string_agg(topic_condition, ',') from public.push_outbox
    where id > :base and title like '%Push Qxp'),
  '''tikeo_promoters'' in topics || ''tikeo_visitors'' in topics');

-- Fonction Edge : prise d'un lot, jetons, marquage --------------------------------
set role authenticated;
do $$
begin
  begin
    perform public.push_take_batch(10);
    raise exception 'ÉCHEC  file lue par un compte';
  exception when insufficient_privilege then
    raise notice 'OK    File réservée à la fonction d''envoi';
  end;
end $$;
set role service_role;
create temporary table taken as
  select * from public.push_take_batch(200) b where b.id > :base;
select tokens[1] as controller_token from taken where route like '/postes%' \gset
reset role;
select test.check('Lot : jeton du contrôleur joint à son message',
  :'controller_token', 'jeton-controleur-' || repeat('x', 20));
set role service_role;
select public.push_mark(
  (select array_agg(id) from taken where route like '/postes%'),
  (select jsonb_object_agg(id::text, 'UNAVAILABLE') from taken where route not like '/postes%'),
  array['jeton-controleur-' || repeat('x', 20)]) \gset ignored_
reset role;
select test.check('Envoyé marqué ; échecs gardés pour un nouvel essai',
  (select count(*) filter (where sent_at is not null) || '|'
          || count(*) filter (where sent_at is null and last_error = 'UNAVAILABLE')
     from public.push_outbox where id > :base),
  '1|2');
select test.check('Jeton refusé par Firebase oublié',
  (select count(*)::text from public.push_devices
    where user_id = 'aaaaaaaa-2800-0000-0000-000000000002'), '0');
drop table taken;

-- Notification de test -----------------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-2800-0000-0000-000000000001');
do $$
begin
  begin
    perform public.send_test_push();
    raise exception 'ÉCHEC  test sans appareil accepté';
  exception when sqlstate 'P0002' then
    if sqlerrm <> 'push_no_device' then raise; end if;
    raise notice 'OK    Test refusé sans téléphone enregistré';
  end;
end $$;
select public.register_push_device('jeton-test-' || repeat('t', 20)) \gset ignored_
select public.send_test_push() \gset ignored_
reset role;
select test.check('Test : un message vers le compte, page Paramètres',
  (select count(*)::text from public.push_outbox
    where user_id = 'aaaaaaaa-2800-0000-0000-000000000001' and route = '/parametres'), '1');
set role authenticated;
select test.login('aaaaaaaa-2800-0000-0000-000000000001');
select public.send_test_push(), public.send_test_push(), public.send_test_push(),
       public.send_test_push() \gset ignored_
do $$
begin
  begin
    perform public.send_test_push();
    raise exception 'ÉCHEC  sixième test accepté';
  exception when sqlstate '54000' then
    if sqlerrm <> 'push_test_rate_limited' then raise; end if;
    raise notice 'OK    5 tests par heure au plus';
  end;
end $$;
reset role;

-- Notifications dans la langue du destinataire --------------------------------
update public.profiles set locale = 'en' where id = 'aaaaaaaa-2800-0000-0000-000000000002';
set role authenticated;
select test.login('aaaaaaaa-2800-0000-0000-000000000002');
select public.register_push_device('jeton-anglais-' || repeat('e', 20)) \gset ignored_
select public.send_test_push() \gset ignored_
reset role;
select test.check('Notification de test en anglais pour un compte anglais',
  (select body from public.push_outbox
    where user_id = 'aaaaaaaa-2800-0000-0000-000000000002' and route = '/parametres'),
  'Notifications work on this phone.');
