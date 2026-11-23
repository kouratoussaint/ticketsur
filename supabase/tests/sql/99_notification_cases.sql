-- =============================================================================
-- Tikéo — Tests : cas de notification P3 à P11 (migration 6600)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

-- Déclencheurs différés : tout de suite (une seule transaction sur le staging).
set constraints public.tickets_notify_revoked immediate;

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-6600-0000-0000-000000000001', 'proprio-cas@test.local', now()),
  ('aaaaaaaa-6600-0000-0000-000000000002', 'controle-cas@test.local', now()),
  ('aaaaaaaa-6600-0000-0000-000000000003', 'spectateur-cas@test.local', now()),
  ('aaaaaaaa-6600-0000-0000-000000000004', 'admin-support-cas@test.local', now()),
  ('aaaaaaaa-6600-0000-0000-000000000005', 'admin-finance-cas@test.local', now()),
  ('aaaaaaaa-6600-0000-0000-000000000006', 'admin-moderation-cas@test.local', now()),
  ('aaaaaaaa-6600-0000-0000-000000000007', 'admin-super-cas@test.local', now());
update public.profiles set display_name = 'Issa Contrôle'
 where id = 'aaaaaaaa-6600-0000-0000-000000000002';
update public.profiles set is_platform_admin = true
 where id in ('aaaaaaaa-6600-0000-0000-000000000004', 'aaaaaaaa-6600-0000-0000-000000000005',
              'aaaaaaaa-6600-0000-0000-000000000006', 'aaaaaaaa-6600-0000-0000-000000000007');
insert into private.platform_admin_roles (user_id, role) values
  ('aaaaaaaa-6600-0000-0000-000000000004', 'support'),
  ('aaaaaaaa-6600-0000-0000-000000000005', 'finance'),
  ('aaaaaaaa-6600-0000-0000-000000000006', 'moderation');

-- P11 (« Prévenir » activé par défaut) : posé par la migration ; les tests de
-- la console le remettent à faux pour rester indépendants du réglage.

set role authenticated;
select test.login('aaaaaaaa-6600-0000-0000-000000000001');
select (public.create_organization('Cas Prod Nq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Nq', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as ev \gset
select (public.create_event(:'org', 'Quota Nq', now() + interval '5 days',
                            now() + interval '5 days 4 hours')).id as ev_q \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select (public.create_ticket_category(:'ev_q', 'Standard')).id as cat_q \gset
select test.complete_event(:'ev') \gset ignored_
select test.complete_event(:'ev_q') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select public.set_event_status(:'ev_q', 'published') \gset ignored_
select (public.create_checkpoint(:'ev', 'Entrée Nord')).id as door \gset
reset role;
-- Événements créés « avant » (sur le staging, tout est dans une transaction).
update public.events set created_at = now() - interval '1 hour' where id in (:'ev', :'ev_q');
select coalesce(max(id), 0) as base from public.push_outbox \gset

-- P5 : nouveau membre → propriétaire -----------------------------------------------
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-6600-0000-0000-000000000002', 'controller');
select test.check('P5 : propriétaire prévenu du nouveau membre',
  (select title || '|' || body || '|' || route from public.push_outbox
    where id > :base and user_id = 'aaaaaaaa-6600-0000-0000-000000000001'),
  'Nouveau membre|Issa Contrôle a rejoint « Cas Prod Nq » comme contrôleur.|/equipe');

-- P4 : affectation → contrôleur ----------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-6600-0000-0000-000000000001');
select public.assign_member(:'ev', 'aaaaaaaa-6600-0000-0000-000000000002', :'door') \gset ignored_
reset role;
select test.check('P4 : contrôleur prévenu de son affectation (porte)',
  (select title || '|' || (body like 'Vous contrôlez « Concert Nq » le % à %h% (porte : Entrée Nord).')::text || '|' || route
     from public.push_outbox
    where id > :base and user_id = 'aaaaaaaa-6600-0000-0000-000000000002'),
  'Nouvelle affectation|true|/postes');

-- P10 : signalement → modération -----------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-6600-0000-0000-000000000003');
select public.report_content('event', :'ev', 'scam') \gset ignored_
reset role;
select test.check('P10 : signalement aux administrateurs « catalogue » seulement',
  (select string_agg(right(user_id::text, 1) || ':' || title || ':' || body, ',' order by user_id)
     from public.push_outbox
    where id > :base and route = '/console/signalements'
      and user_id::text like 'aaaaaaaa-6600-%'),
  '6:Nouveau signalement:Événement « Concert Nq » · Arnaque ou faux événement,'
  || '7:Nouveau signalement:Événement « Concert Nq » · Arnaque ou faux événement');

-- P8 : support → administrateurs « support » -------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-6600-0000-0000-000000000003');
select public.create_support_request('Ticket perdu Nq', 'question', 'Bonjour') as req \gset
select public.reply_support_request(:'req', 'Encore moi') \gset ignored_
reset role;
select test.check('P8 : demande puis réponse aux administrateurs « support »',
  (select string_agg(right(user_id::text, 1) || ':' || title, ',' order by id)
     from public.push_outbox
    where id > :base and route = '/console/support/' || :'req'
      and user_id::text like 'aaaaaaaa-6600-%'),
  '4:Nouvelle demande de support,7:Nouvelle demande de support,'
  || '4:Nouvelle réponse au support,7:Nouvelle réponse au support');

-- P9 : paiement déclaré → administrateurs « facturation » -------------------------------
set role authenticated;
select test.login('aaaaaaaa-6600-0000-0000-000000000007');
select public.admin_save_pack(null, $j${
  "name": "Cas Nq", "system": "flat", "monthly_price": 3000,
  "durations": {"month": 3000},
  "options": [{"key": "tickets_per_event", "included": 5}]
  }$j$::jsonb) as pack \gset
select public.admin_set_pack_status(:'pack', 'published') \gset ignored_
select test.login('aaaaaaaa-6600-0000-0000-000000000003');
select (public.request_billing_pack(:'pack', 'month')->>'id') as request \gset
select public.declare_billing_payment(:'request', 'orange_money', 'TX-NQ-001') \gset ignored_
reset role;
select test.check('P9 : paiement aux administrateurs « facturation »',
  (select string_agg(right(user_id::text, 1) || ':' || title || ':' || route, ',' order by user_id)
     from public.push_outbox
    where id > :base and route like '/console/encaisser/%'
      and user_id::text like 'aaaaaaaa-6600-%'),
  '5:Paiement déclaré à valider:/console/encaisser/demande/' || :'request'
  || ',7:Paiement déclaré à valider:/console/encaisser/demande/' || :'request');

-- P3 : ticket annulé par la structure → détenteur ; par la console sans « prévenir » : rien
set role authenticated;
select test.login('aaaaaaaa-6600-0000-0000-000000000001');
select (array_agg(ticket_id))[1] as t1, (array_agg(ticket_id))[2] as t2
  from public.issue_tickets(:'ev', :'cat', 2) \gset
reset role;
update public.tickets set holder_user_id = 'aaaaaaaa-6600-0000-0000-000000000003'
 where id in (:'t1', :'t2');
set role authenticated;
select test.login('aaaaaaaa-6600-0000-0000-000000000001');
select public.revoke_ticket(:'t1') \gset ignored_
select test.login('aaaaaaaa-6600-0000-0000-000000000004');
select public.admin_revoke_ticket(:'t2', 'Doublon constaté', false) \gset ignored_
reset role;
select test.check('P3 : détenteur prévenu par la structure, pas par la console sans « prévenir »',
  (select string_agg(title || ':' || route, ',') from public.push_outbox
    where id > :base and user_id = 'aaaaaaaa-6600-0000-0000-000000000003'),
  'Ticket annulé:/portefeuille');

-- P7 : 80 % des tickets du pack → propriétaire, une fois ----------------------------------
set role authenticated;
select test.login('aaaaaaaa-6600-0000-0000-000000000007');
select public.admin_grant_subscription('aaaaaaaa-6600-0000-0000-000000000001', :'pack', 'month',
                                       'Pack de test Nq') \gset ignored_
select test.login('aaaaaaaa-6600-0000-0000-000000000001');
select count(*) from public.issue_tickets(:'ev_q', :'cat_q', 3) \gset ignored_
reset role;
select test.check('P7 : 3 sur 5 : pas encore',
  (select count(*)::text from public.push_outbox
    where id > :base and route = '/facturation'
      and user_id = 'aaaaaaaa-6600-0000-0000-000000000001'), '0');
set role authenticated;
select test.login('aaaaaaaa-6600-0000-0000-000000000001');
select count(*) from public.issue_tickets(:'ev_q', :'cat_q', 1) \gset ignored_
select count(*) from public.issue_tickets(:'ev_q', :'cat_q', 1) \gset ignored_
reset role;
select test.check('P7 : 4 sur 5 : une alerte, pas deux',
  (select string_agg(title || '|' || body, ',') from public.push_outbox
    where id > :base and route = '/facturation'
      and user_id = 'aaaaaaaa-6600-0000-0000-000000000001'),
  'Limite de tickets bientôt atteinte|« Quota Nq » : 4 tickets sur 5 permis par votre pack.');

-- P6 : retrait du catalogue, suspension, réactivation → propriétaire -----------------------
update public.events set public_blocked_at = now(), public_blocked_reason = 'Photo trompeuse'
 where id = :'ev';
update public.organizations set status = 'disabled', disabled_at = now(), disabled_reason = 'Vérification'
 where id = :'org';
update public.organizations set status = 'active', disabled_at = null, disabled_reason = null
 where id = :'org';
select test.check('P6 : retrait du catalogue, suspension et réactivation, avec le motif',
  (select string_agg(title || '|' || body, ' ## ' order by id) from public.push_outbox
    where id > :base and user_id = 'aaaaaaaa-6600-0000-0000-000000000001'
      and tag in ('blk-' || :'ev', 'org-' || :'org')),
  'Événement retiré du catalogue|« Concert Nq » n''est plus visible au catalogue public. Motif : Photo trompeuse'
  || ' ## Structure suspendue|« Cas Prod Nq » est suspendue par l''équipe Tikéo. Motif : Vérification'
  || ' ## Structure réactivée|« Cas Prod Nq » est de nouveau active.');

set constraints public.tickets_notify_revoked deferred;
