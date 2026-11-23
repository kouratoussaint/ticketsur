-- =============================================================================
-- Tikéo — Tests : recherche globale, messages ciblés, journal filtrable
-- (migration 5200)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-5200-0000-0000-000000000001', 'super-msg@test.local', now()),
  ('aaaaaaaa-5200-0000-0000-000000000002', 'support-msg@test.local', now()),
  ('aaaaaaaa-5200-0000-0000-000000000003', 'moderation-msg@test.local', now()),
  ('aaaaaaaa-5200-0000-0000-000000000004', 'finance-msg@test.local', now()),
  ('aaaaaaaa-5200-0000-0000-000000000005', 'awa-msg@test.local', now()),
  ('aaaaaaaa-5200-0000-0000-000000000006', 'issa-msg@test.local', now()),
  ('aaaaaaaa-5200-0000-0000-000000000007', 'public-msg@test.local', now());
update public.profiles set is_platform_admin = true
 where id in ('aaaaaaaa-5200-0000-0000-000000000001', 'aaaaaaaa-5200-0000-0000-000000000002',
              'aaaaaaaa-5200-0000-0000-000000000003', 'aaaaaaaa-5200-0000-0000-000000000004');
update public.profiles set display_name = 'Zebulon Awa'
 where id = 'aaaaaaaa-5200-0000-0000-000000000005';
insert into private.platform_admin_roles (user_id, role) values
  ('aaaaaaaa-5200-0000-0000-000000000002', 'support'),
  ('aaaaaaaa-5200-0000-0000-000000000003', 'moderation'),
  ('aaaaaaaa-5200-0000-0000-000000000004', 'finance');
select coalesce(max(id), 0) as base from public.push_outbox \gset

set role authenticated;
select test.login('aaaaaaaa-5200-0000-0000-000000000005');
select (public.create_organization('Zebulon Studio')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Zebulon Fest', now() + interval '5 days',
                            now() + interval '5 days 4 hours')).id as ev \gset
select (public.create_event(:'org', 'Zebulon Vide', now() + interval '9 days',
                            now() + interval '9 days 4 hours')).id as ev_empty \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
create temp table issued_5200 as select * from public.issue_tickets(:'ev', :'cat', 2);
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-5200-0000-0000-000000000006', 'controller');
select min(t.id::text) as ticket from public.tickets t where t.event_id = :'ev' \gset
update public.tickets t set holder_user_id = 'aaaaaaaa-5200-0000-0000-000000000007',
       holder_name = 'Zebulon Public'
 where t.id = :'ticket';
set role authenticated;

-- Recherche globale (tout administrateur) -------------------------------------------
select test.login('aaaaaaaa-5200-0000-0000-000000000004');
select public.admin_global_search('zebulon', 10) as found \gset
select test.check('Recherche : compte, structure, événement et ticket trouvés',
  ((:'found'::jsonb)->'accounts' @> jsonb_build_array(jsonb_build_object('id', 'aaaaaaaa-5200-0000-0000-000000000005'))
   and (:'found'::jsonb)->'organizations' @> jsonb_build_array(jsonb_build_object('id', :'org'))
   and (:'found'::jsonb)->'events' @> jsonb_build_array(jsonb_build_object('id', :'ev'))
   and (:'found'::jsonb)->'tickets' @> jsonb_build_array(jsonb_build_object('id', :'ticket')))::text,
  'true');
select test.check('Recherche : moins de 3 caractères, pas de tickets',
  jsonb_array_length(public.admin_global_search('ze')->'tickets')::text, '0');
select test.expect_error('Recherche : trop courte',
  $q$select public.admin_global_search('z')$q$, 'search_query_invalid');

-- Message à un compte (support) ------------------------------------------------------
select test.expect_error('Finance : message refusé',
  $q$select public.admin_send_message('account', 'aaaaaaaa-5200-0000-0000-000000000005', 'Bonjour', 'Texte')$q$,
  'admin_role_forbidden');
select test.login('aaaaaaaa-5200-0000-0000-000000000002');
select test.check('Compte : un destinataire',
  (public.admin_send_message('account', 'aaaaaaaa-5200-0000-0000-000000000005',
     'Votre structure', 'Merci de compléter votre numéro WhatsApp.')->>'recipients'), '1');
select test.expect_error('Compte : soi-même refusé',
  $q$select public.admin_send_message('account', 'aaaaaaaa-5200-0000-0000-000000000002', 'Bonjour', 'Texte')$q$,
  'self_forbidden');
select test.expect_error('Durée invalide',
  $q$select public.admin_send_message('organization', '$q$ || :'org' || $q$', 'Bonjour', 'Texte', 45)$q$,
  'message_days_invalid');
reset role;
select test.check('Compte : conversation ouverte par l''équipe, non lue, notification',
  (select r.status || ':' || r.user_unread || ':' || r.admin_unread || ':'
          || (select count(*) from public.push_outbox o
               where o.id > :base and o.user_id = r.user_id and o.route = '/support/' || r.id)
     from public.support_requests r
    where r.user_id = 'aaaaaaaa-5200-0000-0000-000000000005' and r.subject = 'Votre structure'),
  'answered:true:false:1');
set role authenticated;

-- Message aux membres d'une structure (modération) -----------------------------------
select test.login('aaaaaaaa-5200-0000-0000-000000000003');
select test.check('Structure : deux membres actifs',
  (public.admin_send_message('organization', :'org', 'Maintenance du soir',
     'Les tickets restent valables.', 3)->>'recipients'), '2');
select test.expect_error('Événement sans détenteur relié',
  $q$select public.admin_send_message('event', '$q$ || :'ev_empty' || $q$', 'Bonjour', 'Texte')$q$,
  'message_no_recipients');
select test.check('Événement : un détenteur relié',
  (public.admin_send_message('event', :'ev', 'Changement de porte',
     'Entrée par la porte Nord.')->>'recipients'), '1');
select test.check('Liste : messages réservés avec leur destinataire',
  (select string_agg(a.target_kind || ':' || a.target_name || ':' || cardinality(a.audiences),
                     ',' order by a.target_kind)
     from public.admin_announcements(10) a where a.target_id in (:'org', :'ev')),
  'event:Zebulon Fest:0,organization:Zebulon Studio:0');
select id as msg_org from public.admin_announcements(10) a where a.target_id = :'org' \gset
select test.expect_error('Message réservé : non modifiable',
  $q$select public.admin_update_announcement('$q$ || :'msg_org' || $q$', 'Titre', 'Texte', array['users'], 'info', null, null)$q$,
  'announcement_targeted');

-- Bandeaux ---------------------------------------------------------------------------
select test.login('aaaaaaaa-5200-0000-0000-000000000006');
select test.check('Membre : message de la structure',
  (select string_agg(m.title, ',') from public.my_announcements() m
    where m.title in ('Maintenance du soir', 'Changement de porte')), 'Maintenance du soir');
select test.login('aaaaaaaa-5200-0000-0000-000000000007');
select test.check('Détenteur : message de l''événement',
  (select string_agg(m.title, ',') from public.my_announcements() m
    where m.title in ('Maintenance du soir', 'Changement de porte')), 'Changement de porte');
reset role;
select test.check('Notifications : par compte, aucune sur un sujet',
  (select count(*) filter (where o.user_id is not null and o.route = '/') || ':'
          || count(*) filter (where o.user_id is not null and o.route = '/portefeuille') || ':'
          -- (hors annonce du nouvel événement à sa ville, migration 6500)
          || count(*) filter (where o.topic_condition is not null
                                and o.route not like '/evenement/%')
     from public.push_outbox o where o.id > :base),
  '2:1:0');
set role authenticated;

-- Journal filtrable -------------------------------------------------------------------
select test.login('aaaaaaaa-5200-0000-0000-000000000004');
select test.check('Journal : par compte',
  (select count(*)::text from public.admin_audit_logs('admin.message', 50, 0,
     p_account_id => 'aaaaaaaa-5200-0000-0000-000000000005')), '1');
select test.check('Journal : par administrateur',
  (select string_agg(distinct l.details->>'audience', ',') from public.admin_audit_logs('admin.message', 50, 0,
     p_actor_id => 'aaaaaaaa-5200-0000-0000-000000000003') l), 'holders,members');
select test.check('Journal : par structure (messages structure et événement)',
  (select count(*)::text from public.admin_audit_logs('admin.message', 50, 0,
     p_organization_id => :'org')), '2');
select test.check('Journal : par événement',
  (select string_agg(l.details->>'recipients', ',') from public.admin_audit_logs('admin.message', 50, 0,
     p_event_id => :'ev') l), '1');
select test.check('Journal : jamais le texte d''un message',
  (select bool_or(l.details::text like '%Maintenance%' or l.details::text like '%porte%')::text
     from public.admin_audit_logs('admin.message', 50, 0,
       p_organization_id => :'org') l), 'false');
select test.check('Journal : appel des anciennes versions (3 paramètres)',
  (select (count(*) > 0)::text from public.admin_audit_logs('admin.', 5, 0)), 'true');
reset role;
