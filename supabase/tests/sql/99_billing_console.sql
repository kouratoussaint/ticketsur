-- =============================================================================
-- Tikéo — Tests : console de facturation (migration 3700)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-3700-0000-0000-000000000001', 'promoteur-caisse@test.local'),
  ('aaaaaaaa-3700-0000-0000-000000000003', 'admin-caisse@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-3700-0000-0000-000000000003';

-- Un événement au forfait, figé au premier ticket.
set role authenticated;
select test.login('aaaaaaaa-3700-0000-0000-000000000001');
select (public.create_organization('Studio Console Qpv')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Console Qpv', now() + interval '1 day',
                            now() + interval '2 days')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select count(*) as n from public.issue_tickets(:'ev', :'cat', 1) \gset

-- Packs de la console.
select test.login('aaaaaaaa-3700-0000-0000-000000000003');
select public.admin_save_pack(null, $j${
  "name": "Console A Qpv", "system": "flat", "monthly_price": 4000,
  "durations": {"month": 4000},
  "options": [{"key": "members_per_structure", "included": 1, "addon_price": 500}]
  }$j$::jsonb) as pack_a \gset
select public.admin_save_pack(null, $j${
  "name": "Console B Qpv", "system": "flat", "monthly_price": 2000,
  "durations": {"month": 2000},
  "options": [{"key": "members_per_structure", "included": 2}]
  }$j$::jsonb) as pack_b \gset
select public.admin_save_pack(null, $j${
  "name": "Console U Qpv", "system": "usage", "entry_price": 50
  }$j$::jsonb) as pack_u \gset
select public.admin_grant_subscription('aaaaaaaa-3700-0000-0000-000000000001', :'pack_a', 'month',
                                       'Essai console', '{"members_per_structure": 1}') as sub \gset

select test.check('Console v2 : e-mail, pack et historique',
  (select (b->>'version') || ':' || (s->>'account_email') || ':' || (s->>'pack_id' = :'pack_a')::text
          || ':' || coalesce(s->>'pack_code', '-') || ':' || jsonb_typeof(b->'history')
          || ':' || ((select p->>'events' from jsonb_array_elements(b->'packs') p
                       where p->>'pack_id' = :'pack_u'))
     from (select public.admin_billing() as b) x,
          jsonb_array_elements(x.b->'subscriptions') s
    where s->>'id' = :'sub'),
  '2:promoteur-caisse@test.local:true:-:array:0');

-- Gestes réservés aux administrateurs.
select test.login('aaaaaaaa-3700-0000-0000-000000000001');
select test.expect_error('Prolonger : réservé aux administrateurs',
  format($q$select public.admin_extend_subscription(%L, now() + interval '1 year', 'Pirate')$q$, :'sub'),
  'forbidden');
select test.expect_error('Événements facturés : réservé aux administrateurs',
  $q$select public.admin_billing_events('qpv')$q$, 'forbidden');

-- Prolonger.
select test.login('aaaaaaaa-3700-0000-0000-000000000003');
select test.expect_error('Prolonger : motif obligatoire',
  format($q$select public.admin_extend_subscription(%L, now() + interval '2 months', '')$q$, :'sub'),
  'billing_note_required');
select test.expect_error('Prolonger : la fin suit le début',
  format($q$select public.admin_extend_subscription(%L, now() - interval '1 year', 'Erreur')$q$, :'sub'),
  'billing_subscription_invalid');
select public.admin_extend_subscription(:'sub', now() + interval '2 months', 'Geste commercial') \gset ignored_
reset role;
select test.check('Prolonger : nouvelle fin et rappel remis à zéro',
  (select (ends_at > now() + interval '59 days')::text || ':' || (reminded_at is null)::text
     from public.billing_subscriptions where id = :'sub'),
  'true:true');
set role authenticated;
select test.login('aaaaaaaa-3700-0000-0000-000000000003');

-- Changer de pack, régler les suppléments.
select test.expect_error('Changer de pack : supplément absent du nouveau pack',
  format($q$select public.admin_change_subscription_pack(%L, %L, 'Passage B')$q$, :'sub', :'pack_b'),
  'billing_addons_invalid');
select test.expect_error('Changer de pack : forfait seulement',
  format($q$select public.admin_change_subscription_pack(%L, %L, 'Passage U')$q$, :'sub', :'pack_u'),
  'billing_pack_invalid');
select public.admin_set_subscription_addons(:'sub', '{"members_per_structure": 0}', 'Retrait') \gset ignored_
select public.admin_change_subscription_pack(:'sub', :'pack_b', 'Passage B') \gset ignored_
select test.check('Changer de pack : copie du nouveau pack, sans supplément',
  (select (s->>'pack_name') || ':' || (s->>'addons')
     from jsonb_array_elements(public.admin_billing()->'subscriptions') s where s->>'id' = :'sub'),
  'Console B Qpv:{}');
select test.expect_error('Suppléments : option sans supplément refusée',
  format($q$select public.admin_set_subscription_addons(%L, '{"members_per_structure": 1}', 'Ajout')$q$, :'sub'),
  'billing_addons_invalid');

-- Facturation d'un événement figé.
select test.check('Événements facturés : recherche par titre, figé au forfait',
  (select (e->>'system') || ':' || (e->>'locked')
     from jsonb_array_elements(public.admin_billing_events('concert console')) e
    where e->>'id' = :'ev'),
  'flat:true');
select test.expect_error('Événement : pack à l''usage obligatoire',
  format($q$select public.admin_set_event_billing(%L, 'usage', %L, 'Passage usage')$q$, :'ev', :'pack_a'),
  'billing_choice_invalid');
select public.admin_set_event_billing(:'ev', 'usage', :'pack_u', 'Passage usage') \gset ignored_
select test.login('aaaaaaaa-3700-0000-0000-000000000001');
select test.check('Événement : passé à l''usage par l''administrateur',
  (select b->>'system' || ':' || (b->>'locked') from (select public.event_billing(:'ev') as b) x),
  'usage:true');
select test.login('aaaaaaaa-3700-0000-0000-000000000003');
select public.admin_issue_invoice(:'ev') \gset ignored_
select test.expect_error('Événement : facture déjà émise, changement refusé',
  format($q$select public.admin_set_event_billing(%L, 'flat', null, 'Retour forfait')$q$, :'ev'),
  'billing_invoice_exists');

reset role;
select test.check('Journal console : ni motif ni donnée personnelle',
  (select count(*) from public.audit_logs
    where action in ('admin.billing_subscription_extended', 'admin.billing_subscription_pack_changed',
                     'admin.billing_subscription_addons_set', 'admin.billing_event_set')
      and (details ? 'note' or details::text ~ '(Geste|Passage|Retrait|test\.local)'))::text,
  '0');
select test.check('Journal console : chaque geste tracé',
  (select count(distinct action) from public.audit_logs
    where action in ('admin.billing_subscription_extended', 'admin.billing_subscription_pack_changed',
                     'admin.billing_subscription_addons_set', 'admin.billing_event_set'))::text,
  '4');
