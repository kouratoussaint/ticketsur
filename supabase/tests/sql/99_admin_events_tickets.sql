-- =============================================================================
-- Tikéo — Tests : événements et tickets depuis la console (migration 5100)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-5100-0000-0000-000000000001', 'super-evconsole@test.local', now()),
  ('aaaaaaaa-5100-0000-0000-000000000002', 'support-evconsole@test.local', now()),
  ('aaaaaaaa-5100-0000-0000-000000000003', 'moderation-evconsole@test.local', now()),
  ('aaaaaaaa-5100-0000-0000-000000000004', 'awa-evconsole@test.local', now()),
  ('aaaaaaaa-5100-0000-0000-000000000005', 'public-evconsole@test.local', now()),
  ('aaaaaaaa-5100-0000-0000-000000000006', 'issa-evconsole@test.local', now());
update public.profiles set is_platform_admin = true
 where id in ('aaaaaaaa-5100-0000-0000-000000000001', 'aaaaaaaa-5100-0000-0000-000000000002',
              'aaaaaaaa-5100-0000-0000-000000000003');
insert into private.platform_admin_roles (user_id, role) values
  ('aaaaaaaa-5100-0000-0000-000000000002', 'support'),
  ('aaaaaaaa-5100-0000-0000-000000000003', 'moderation');
update private.console_settings s set value = 'false'::jsonb
 where s.key in ('notify_users', 'admin_issue_tickets');
select coalesce(max(id), 0) as base from public.push_outbox \gset

set role authenticated;
select test.login('aaaaaaaa-5100-0000-0000-000000000004');
select (public.create_organization('Studio Ev Xq')::jsonb)->>'id' as org_a \gset
select (public.create_event(:'org_a', 'Concert Ev Xq', now() + interval '5 days',
                            now() + interval '5 days 4 hours')).id as ev \gset
select (public.create_event(:'org_a', 'Brouillon Ev Xq', now() + interval '9 days',
                            now() + interval '9 days 4 hours')).id as ev_draft \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
create temp table issued as select * from public.issue_tickets(:'ev', :'cat', 4);
select test.login('aaaaaaaa-5100-0000-0000-000000000006');
select (public.create_organization('Faso Ev Xq')::jsonb)->>'id' as org_b \gset
reset role;
-- T1 entré ; T2 sans titulaire ; T3 et T4 dans « Mes tickets » du public.
select id as t1 from (select t.id, row_number() over (order by t.id) n from public.tickets t
                       where t.event_id = :'ev') x where n = 1 \gset
select id as t2 from (select t.id, row_number() over (order by t.id) n from public.tickets t
                       where t.event_id = :'ev') x where n = 2 \gset
select id as t3 from (select t.id, row_number() over (order by t.id) n from public.tickets t
                       where t.event_id = :'ev') x where n = 3 \gset
select public_reference as ref3 from public.tickets where id = :'t3' \gset
update public.tickets t set status = 'redeemed', redeemed_at = now(),
       redeemed_by = 'aaaaaaaa-5100-0000-0000-000000000004', entries_used = 1
 where t.id = :'t1';
update public.tickets t set holder_user_id = 'aaaaaaaa-5100-0000-0000-000000000005'
 where t.event_id = :'ev' and t.id not in (:'t1', :'t2');
update public.tickets t set holder_name = 'Aïcha Xqz', holder_phone = '+22670123456'
 where t.id = :'t3';
select starts_at as ev_starts, ends_at as ev_ends from public.events where id = :'ev' \gset
set role authenticated;

-- Liste et fiche (tout administrateur) -----------------------------------------------
select test.login('aaaaaaaa-5100-0000-0000-000000000003');
select test.check('Liste : les deux événements de la structure',
  (select count(*)::text from public.admin_events('Studio Ev Xq', p_limit => 10)), '2');
select test.check('Fiche : catégorie, tickets valables, entrés, à annuler',
  (select (d->'categories'->0->>'name') || ':' || (d->>'tickets_valid') || ':'
          || (d->>'tickets_admitted') || ':' || (d->>'tickets_to_cancel') || ':'
          || (d->>'holders_to_notify')
     from public.admin_event_detail(:'ev') d),
  'Standard:3:1:3:1');

-- Modifier (modération) -----------------------------------------------------------
select test.check('Modification : champs changés',
  (select (r->'fields')::text from public.admin_update_event(:'ev', 'Concert Ev Xq',
     :'ev_starts', :'ev_ends',
     'Africa/Ouagadougou', 'Maison du peuple', 'Ouagadougou', null, null,
     'Le grand soir', null, null, 'Faute de frappe') r),
  '["place", "tagline"]');
select test.expect_error('Modification : accroche trop longue',
  $q$select public.admin_update_event('$q$ || :'ev' || $q$', 'Concert Ev Xq', now() + interval '5 days', now() + interval '6 days', 'Africa/Ouagadougou', null, 'Ouagadougou', null, null, repeat('x', 61), null, null, 'Motif')$q$,
  'event_tagline_invalid');
select test.expect_error('Modification : capacité sous les tickets émis',
  $q$select public.admin_update_event('$q$ || :'ev' || $q$', 'Concert Ev Xq', now() + interval '5 days', now() + interval '6 days', 'Africa/Ouagadougou', null, 'Ouagadougou', null, null, null, 2, null, 'Motif')$q$,
  'event_capacity_below_issued');
select test.expect_error('Modération : émettre refusé',
  $q$select public.admin_issue_tickets('$q$ || :'ev' || $q$', '$q$ || :'cat' || $q$', 1, 'Motif')$q$,
  'admin_role_forbidden');

-- Tickets (support) ----------------------------------------------------------------
select test.login('aaaaaaaa-5100-0000-0000-000000000002');
select test.expect_error('Support : modifier un événement refusé',
  $q$select public.admin_set_event_status('$q$ || :'ev' || $q$', 'in_progress', 'Motif')$q$,
  'admin_role_forbidden');
select test.check('Recherche : par nom sans accent',
  (select string_agg(f.public_reference, ',') from public.admin_find_tickets('aicha xqz') f),
  :'ref3');
select test.check('Recherche : par chiffres du téléphone',
  (select count(*)::text from public.admin_find_tickets('70 12 34 56') f where f.id = :'t3'), '1');
select test.check('Recherche : par référence',
  (select count(*)::text from public.admin_find_tickets(lower(:'ref3')) f where f.id = :'t3'), '1');
select test.expect_error('Recherche : trop courte',
  $q$select * from public.admin_find_tickets('ab')$q$, 'search_query_invalid');
select test.check('Fiche du ticket : titulaire, « Mes tickets », jamais le QR',
  (select (d->>'holder_name') || ':' || (d->>'wallet_owner' is not null) || ':'
          || (d ? 'qr_token') || ':' || (d->'event'->>'title')
     from public.admin_ticket_detail(:'t3') d),
  'Aïcha Xqz:true:false:Concert Ev Xq');
select test.check('Titulaire changé, numéro au format international',
  (select (r->>'holder_name') || ':' || (r->>'holder_phone')
     from public.admin_set_ticket_holder(:'t3', 'Moussa Xqz', '70 99 88 77', null,
                                         'Erreur de saisie') r),
  'Moussa Xqz:+22670998877');
select public.admin_revoke_ticket(:'t2', 'Ticket vendu deux fois', true) \gset ignored_
select test.expect_error('Ticket déjà annulé',
  $q$select public.admin_revoke_ticket('$q$ || :'t2' || $q$', 'Motif')$q$, 'ticket_not_revocable');
select test.expect_error('Émission : réglage désactivé',
  $q$select public.admin_issue_tickets('$q$ || :'ev' || $q$', '$q$ || :'cat' || $q$', 2, 'Motif')$q$,
  'admin_issue_disabled');
reset role;
update private.console_settings s set value = 'true'::jsonb where s.key = 'admin_issue_tickets';
set role authenticated;
select test.login('aaaaaaaa-5100-0000-0000-000000000002');
select test.check('Émission par l''administrateur : un lot de 2',
  (public.admin_issue_tickets(:'ev', :'cat', 2, 'Promoteur sans réseau')->>'count'), '2');
reset role;
update private.console_settings s set value = 'false'::jsonb where s.key = 'admin_issue_tickets';
set role authenticated;

-- Changer l'état (modération) ------------------------------------------------------
select test.login('aaaaaaaa-5100-0000-0000-000000000003');
select public.admin_set_event_status(:'ev', 'in_progress', 'Contrôle oublié') \gset ignored_
select test.check('Annulation d''un événement en cours : tickets non entrés annulés',
  (select (r->>'tickets_cancelled') || ':' || (r->>'holders_notified')
     from public.admin_set_event_status(:'ev', 'cancelled', 'Salle fermée par la mairie') r),
  '4:1');
select test.expect_error('Transition interdite',
  $q$select public.admin_set_event_status('$q$ || :'ev' || $q$', 'published', 'Motif')$q$,
  'event_invalid_transition');
reset role;
select test.check('Annulation : ticket entré gardé, détenteur prévenu une fois',
  (select string_agg(t.status::text, ',' order by t.status) || ':'
          || (select count(*) from public.push_outbox o
               where o.id > :base and o.user_id = 'aaaaaaaa-5100-0000-0000-000000000005'
                 and o.title = 'Événement annulé')
     from public.tickets t where t.event_id = :'ev'),
  'redeemed,revoked,revoked,revoked,revoked,revoked:1');
set role authenticated;

-- Déplacer, corbeille --------------------------------------------------------------
select test.login('aaaaaaaa-5100-0000-0000-000000000003');
select public.admin_move_event(:'ev_draft', :'org_b', 'Créé dans la mauvaise structure') \gset ignored_
select test.expect_error('Déplacement vers la même structure',
  $q$select public.admin_move_event('$q$ || :'ev_draft' || $q$', '$q$ || :'org_b' || $q$', 'Motif')$q$,
  'event_same_organization');
select test.expect_error('Corbeille : événement avec tickets refusé',
  $q$select public.admin_trash_event('$q$ || :'ev' || $q$', 'Motif')$q$, 'event_not_trashable');
select public.admin_trash_event(:'ev_draft', 'Doublon') \gset ignored_
select test.check('Corbeille : l''événement y est, plus dans la liste',
  (select (exists (select 1 from jsonb_array_elements(public.admin_trash()) x
                    where x->>'id' = :'ev_draft' and x->>'kind' = 'event'))::text || ':'
          || (select count(*) from public.admin_events('Brouillon Ev Xq', p_limit => 10))),
  'true:0');
select test.login('aaaaaaaa-5100-0000-0000-000000000006');
select test.check('Promoteur : brouillon à la corbeille invisible',
  (select count(*)::text from public.events e where e.id = :'ev_draft'), '0');
select test.login('aaaaaaaa-5100-0000-0000-000000000003');
select public.admin_restore_event(:'ev_draft', 'Supprimé par erreur') \gset ignored_
select test.login('aaaaaaaa-5100-0000-0000-000000000006');
select test.check('Promoteur : brouillon restauré, dans sa nouvelle structure',
  (select (e.organization_id = :'org_b')::text from public.events e where e.id = :'ev_draft'),
  'true');
select test.login('aaaaaaaa-5100-0000-0000-000000000003');
select public.admin_trash_event(:'ev_draft', 'Doublon') \gset ignored_
reset role;
update public.events e set trashed_at = now() - interval '31 days' where e.id = :'ev_draft';
select (private.purge_due_events() >= 1) as purged_some \gset
select test.check('Tâche : brouillon de plus de 30 jours effacé',
  :'purged_some' || ':' || (select count(*) from public.events e where e.id = :'ev_draft'),
  't:0');

-- Journal ---------------------------------------------------------------------------
select test.check('Journal sans motif ; motifs à part',
  (select bool_and(a.details::text not like '%mairie%' and a.details::text not like '%Faute%'
                   and a.details::text not like '%Moussa%')::text
          || ':' || (select count(*) from private.admin_action_log l
                      where l.target_id in (:'ev', :'ev_draft', :'t2', :'t3'))
     from public.audit_logs a
    where a.organization_id in (:'org_a', :'org_b')),
  'true:10');
select test.check('Aucun paramètre personnalisé attaché à une fonction (migration 5100)',
  (select count(*)::text
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
     cross join lateral unnest(p.proconfig) as c(setting)
    where n.nspname in ('public', 'private')
      and split_part(c.setting, '=', 1) like '%.%'),
  '0');
