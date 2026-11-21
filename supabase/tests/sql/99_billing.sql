-- =============================================================================
-- Tikéo — Tests : packs, quotas et facturation (migration 3600)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-3600-0000-0000-000000000001', 'promoteur-packs@test.local'),
  ('aaaaaaaa-3600-0000-0000-000000000002', 'controleur-packs@test.local'),
  ('aaaaaaaa-3600-0000-0000-000000000003', 'admin-packs@test.local'),
  ('aaaaaaaa-3600-0000-0000-000000000004', 'membre-packs@test.local'),
  ('aaaaaaaa-3600-0000-0000-000000000005', 'membre2-packs@test.local'),
  ('aaaaaaaa-3600-0000-0000-000000000006', 'controleur2-packs@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-3600-0000-0000-000000000003';

select test.check('Packs : tables fermées à l''API',
  (select bool_or(has_table_privilege('authenticated', t, 'select'))
       or bool_or(has_table_privilege('anon', t, 'select'))
     from unnest(array['public.billing_packs', 'public.billing_pack_options',
                       'public.billing_subscriptions', 'public.billing_requests',
                       'public.billing_payments', 'public.billing_invoices',
                       'public.billing_settings']) t)::text,
  'false');
select test.check('Packs du système : Découverte publié, Lancement archivé',
  (select string_agg(code || ':' || status, ',' order by code) from public.billing_packs
    where code is not null),
  'decouverte:published,lancement:archived');

set role authenticated;
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select (public.create_organization('Studio Packs Qpv')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Packs Qpv', now() + interval '1 day',
                            now() + interval '2 days')).id as ev1 \gset
select (public.create_ticket_category(:'ev1', 'Standard')).id as cat1 \gset
select test.complete_event(:'ev1') \gset ignored_

select test.check('Sans abonnement : pack Découverte, rien de limité',
  (select (b->'plan'->'snapshot'->>'code') || ':' || (b->'plan'->>'subscription_id' is null)::text
          || ':' || (select count(*) from jsonb_each(b->'limits') l where l.value <> 'null')
          || ':' || (select count(*) from jsonb_each(b->'features') f where f.value <> 'true')
     from (select public.my_billing() as b) x),
  'decouverte:true:0:0');
-- Par le code, jamais par le nom : l'administrateur peut renommer les packs
-- du système depuis la console (le staging a « DECOUVERTE » depuis le 21/11).
select test.check('Catalogue : packs publiés seulement',
  (select string_agg(p->>'code', ',') from jsonb_array_elements(public.billing_catalog()) p
    where p->>'code' is not null),
  'decouverte');

-- Console : packs -------------------------------------------------------------
select test.expect_error('Packs : console réservée aux administrateurs',
  $q$select public.admin_save_pack(null, '{"name": "Pirate", "system": "flat"}')$q$, 'forbidden');

select test.login('aaaaaaaa-3600-0000-0000-000000000003');
select public.admin_save_pack(null, $j${
  "name": "Pro Qpv", "system": "flat", "monthly_price": 5000,
  "durations": {"month": 5000, "quarter": 13500},
  "options": [
    {"key": "structures", "included": 1},
    {"key": "active_events", "included": 1},
    {"key": "tickets_per_period", "included": 3, "addon_price": 1000, "addon_step": 2, "addon_cap": 5},
    {"key": "members_per_structure", "included": 1},
    {"key": "assisted_send", "state": "unavailable"},
    {"key": "export", "state": "addon", "addon_price": 500},
    {"key": "live_dashboard", "state": "unavailable"},
    {"key": "public_catalog", "state": "unavailable"}
  ]}$j$::jsonb) as pro \gset
select public.admin_set_pack_status(:'pro', 'published') \gset ignored_
select public.admin_save_pack(null, $j${
  "name": "Soirée Qpv", "system": "usage", "entry_price": 100, "free_entries": 2,
  "options": [{"key": "controllers_per_event", "included": 1, "addon_price": 1000}]
  }$j$::jsonb) as soiree \gset
select public.admin_set_pack_status(:'soiree', 'published') \gset ignored_
select test.expect_error('Pack : paliers dans le désordre refusés',
  $q$select public.admin_save_pack(null, '{"name": "Mauvais", "system": "usage", "entry_price": 1,
     "tiers": [{"up_to": 500, "price": 150}, {"up_to": 100, "price": 100}]}')$q$,
  'billing_pack_invalid');
select test.expect_error('Pack : option inconnue refusée',
  $q$select public.admin_save_pack(null, '{"name": "Mauvais", "system": "flat",
     "options": [{"key": "teleportation", "included": 1}]}')$q$,
  'billing_pack_invalid');
select set_config('test.decouverte', (select p->>'pack_id' from jsonb_array_elements(public.billing_catalog()) p where p->>'code' = 'decouverte'), false)
  \gset ignored_
select test.expect_error('Découverte : reste publié',
  format($q$select public.admin_set_pack_status(%L, 'archived')$q$, current_setting('test.decouverte')),
  'billing_pack_protected');
select test.expect_error('Abonnement offert : motif obligatoire',
  format($q$select public.admin_grant_subscription('aaaaaaaa-3600-0000-0000-000000000001', %L, 'month', '')$q$,
         :'pro'),
  'billing_note_required');

-- Demande d'activation --------------------------------------------------------
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select test.expect_error('Demande : supplément d''une fonction indisponible refusé',
  format($q$select public.request_billing_pack(%L, 'month', '{"assisted_send": 1}')$q$, :'pro'),
  'billing_addons_invalid');
select test.expect_error('Demande : au-delà du plafond refusée',
  format($q$select public.request_billing_pack(%L, 'month', '{"tickets_per_period": 6}')$q$, :'pro'),
  'billing_addons_invalid');
select test.expect_error('Demande : durée non proposée refusée',
  format($q$select public.request_billing_pack(%L, 'year')$q$, :'pro'),
  'billing_pack_invalid');
select r->>'id' as req1, r->>'reference' as ref1, r->>'amount' as amount1
  from (select public.request_billing_pack(:'pro', 'month', '{"tickets_per_period": 1}') as r) x \gset
select test.check('Demande : montant = durée + suppléments, référence TK-XXXX',
  :'amount1' || ':' || (:'ref1' ~ '^TK-[A-Z0-9]{4}$')::text, '6000:true');
select public.declare_billing_payment(:'req1', 'orange_money', 'PP2611.1234.A12345') \gset ignored_

select test.login('aaaaaaaa-3600-0000-0000-000000000003');
select test.check('Console : demande en attente avec le moyen déclaré',
  (select r->>'declared_channel' from jsonb_array_elements(public.admin_billing()->'requests') r
    where r->>'id' = :'req1'),
  'orange_money');
select public.admin_activate_request(:'req1', 'orange_money', 'PP2611.1234.A12345') as sub1 \gset
select test.expect_error('Demande : validée une seule fois',
  format($q$select public.admin_activate_request(%L, 'orange_money')$q$, :'req1'),
  'billing_request_not_found');
reset role;
select test.check('Paiement reçu : montant et canal, aucun nom ni numéro de payeur',
  (select amount || ':' || channel || ':'
          || (select count(*) from information_schema.columns
               where table_schema = 'public' and table_name = 'billing_payments'
                 and column_name ~ '(phone|name|email|payer)')
     from public.billing_payments where request_id = :'req1'),
  '6000:orange_money:0');
set role authenticated;

-- Quotas et options -----------------------------------------------------------
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select test.check('Pack actif : limite des tickets avec le supplément (3 + 1 × 2)',
  (select (b->'plan'->'snapshot'->>'name') || ':' || (b->'limits'->>'tickets_per_period') || ':'
          || (b->'features'->>'assisted_send') || ':' || (b->'features'->>'export')
     from (select public.my_billing() as b) x),
  'Pro Qpv:5:false:false');
select test.check('Événement créé avant le pack : visibilité inchangée',
  (select is_public::text from public.events where id = :'ev1'), 'true');
select (public.create_event(:'org', 'Masqué Packs Qpv', now() + interval '1 day',
                            now() + interval '2 days')).id as ev4 \gset
reset role;
select test.check('Catalogue public indisponible : nouvel événement masqué',
  (select is_public::text from public.events where id = :'ev4'), 'false');
set role authenticated;
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select test.expect_error('Catalogue public : refusé par le pack',
  format($q$select public.set_event_public(%L, true)$q$, :'ev4'),
  'billing_option_public_catalog');

select public.set_event_status(:'ev1', 'published') \gset ignored_
select test.complete_event(:'ev4') \gset ignored_
select test.expect_error('Événements actifs : 1 au plus',
  format($q$select public.set_event_status(%L, 'published')$q$, :'ev4'),
  'billing_limit_active_events', 'Votre pack permet 1 événements actifs en même temps.');
select test.expect_error('Structures : 1 au plus',
  $q$select public.create_organization('Deuxième Packs Qpv')$q$, 'billing_limit_structures');

select count(*) as n from public.issue_tickets(:'ev1', :'cat1', 4) \gset
select ticket_id as t1 from public.issue_tickets(:'ev1', :'cat1', 1) \gset
select test.expect_error('Tickets de la période : 5 au plus, rien d''émis au-delà',
  format($q$select * from public.issue_tickets(%L, %L, 1)$q$, :'ev1', :'cat1'),
  'billing_limit_tickets_per_period', null, :'ev1');
select test.check('Événement au forfait figé au premier ticket',
  (select b->>'system' || ':' || (b->>'locked') from (select public.event_billing(:'ev1') as b) x),
  'flat:true');
select test.expect_error('Tableau de bord en direct : refusé par le pack',
  format($q$select public.event_dashboard(%L)$q$, :'ev1'), 'billing_option_live_dashboard');
select test.expect_error('Export : supplément non pris',
  format($q$select * from public.event_report_rows(%L)$q$, :'ev1'), 'billing_option_export');
select test.expect_error('Envoi assisté : indisponible dans le pack',
  format($q$select public.record_ticket_delivery(%L, 'whatsapp')$q$, :'t1'),
  'billing_option_assisted_send');

reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-3600-0000-0000-000000000004', 'manager');
do $$
begin
  begin
    insert into public.organization_members (organization_id, user_id, role)
    select o.id, 'aaaaaaaa-3600-0000-0000-000000000005', 'manager'
      from public.organizations o where o.name = 'Studio Packs Qpv';
    raise exception 'ÉCHEC  deuxième membre accepté';
  exception when program_limit_exceeded then
    if sqlerrm <> 'billing_limit_members_per_structure' then raise; end if;
    raise notice 'OK    Membres de l''équipe : 1 au plus (propriétaire non compté)';
  end;
end $$;
set role authenticated;

-- Suppléments en cours d'abonnement (prorata) -----------------------------------
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select r->>'id' as req2, r->>'amount' as amount2
  from (select public.request_billing_addons('{"tickets_per_period": 1}') as r) x \gset
select test.check('Suppléments en cours : au prorata des jours restants',
  (:'amount2'::integer between 900 and 1050)::text, 'true');
select test.login('aaaaaaaa-3600-0000-0000-000000000003');
select public.admin_activate_request(:'req2', 'moov_money') \gset ignored_
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select count(*) as n from public.issue_tickets(:'ev1', :'cat1', 2) \gset
select test.check('Suppléments ajoutés : 7 tickets sur la période',
  (select count(*) from public.tickets where event_id = :'ev1')::text, '7');

-- Renouvellement : commence à la fin de l'abonnement en cours.
select r->>'id' as req3 from (select public.request_billing_pack(:'pro', 'quarter') as r) x \gset
select test.login('aaaaaaaa-3600-0000-0000-000000000003');
select public.admin_activate_request(:'req3', 'orange_money') as sub3 \gset
reset role;
select test.check('Renouvellement : départ à la fin de l''abonnement en cours',
  (select (s3.starts_at = s1.ends_at)::text || ':' || (s3.ends_at = s1.ends_at + interval '3 months')::text
     from public.billing_subscriptions s1, public.billing_subscriptions s3
    where s1.id = :'sub1' and s3.id = :'sub3'),
  'true:true');
set role authenticated;

-- Événement à l'usage -----------------------------------------------------------
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select (public.create_event(:'org', 'Soirée Packs Qpv', now() + interval '1 day',
                            now() + interval '2 days')).id as ev2 \gset
select (public.create_ticket_category(:'ev2', 'Entrée')).id as single2 \gset
select (public.create_ticket_category(:'ev2', 'Pass 3 sessions')).id as pass2 \gset
select (public.create_ticket_category(:'ev2', 'Invités', null, true)).id as invit2 \gset
select (public.create_checkpoint(:'ev2', 'Porte')).id as cp2 \gset
select public.set_category_entry_policy(:'pass2', 'limited', 3) \gset ignored_
select test.complete_event(:'ev2') \gset ignored_
select test.expect_error('Usage : pack à l''usage publié obligatoire',
  format($q$select public.set_event_billing(%L, 'usage', %L)$q$, :'ev2', :'pro'),
  'billing_choice_invalid');
select public.set_event_billing(:'ev2', 'usage', :'soiree') \gset ignored_
select public.set_event_status(:'ev2', 'published') \gset ignored_
select ticket_id as a1, qr_token as qa1 from public.issue_tickets(:'ev2', :'single2', 1) \gset
select ticket_id as a2, qr_token as qa2 from public.issue_tickets(:'ev2', :'single2', 1) \gset
select ticket_id as a3, qr_token as qa3 from public.issue_tickets(:'ev2', :'single2', 1) \gset
select ticket_id as p1, qr_token as qp1 from public.issue_tickets(:'ev2', :'pass2', 1) \gset
select ticket_id as i1, qr_token as qi1 from public.issue_tickets(:'ev2', :'invit2', 1) \gset
select test.check('Usage : hors du quota de tickets du forfait',
  (select count(*) from public.tickets where event_id = :'ev2')::text, '5');
select test.check('Usage : pack figé au premier ticket',
  (select b->>'system' || ':' || (b->>'locked') || ':' || (b->>'pack_name')
     from (select public.event_billing(:'ev2') as b) x),
  'usage:true:Soirée Qpv');
select test.expect_error('Usage : choix figé dès le premier ticket',
  format($q$select public.set_event_billing(%L, 'flat')$q$, :'ev2'), 'billing_locked');

reset role;
-- Membres portés à 5 dans la copie du pack (une modification du pack, elle,
-- ne change pas un abonnement en cours).
update public.billing_subscriptions set snapshot = jsonb_set(snapshot, '{options,members_per_structure,included}', '5')
 where account_id = 'aaaaaaaa-3600-0000-0000-000000000001' and status = 'active';
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', 'aaaaaaaa-3600-0000-0000-000000000002', 'controller'),
  (:'org', 'aaaaaaaa-3600-0000-0000-000000000006', 'controller');
insert into public.event_assignments (event_id, user_id, checkpoint_id)
values (:'ev2', 'aaaaaaaa-3600-0000-0000-000000000002', :'cp2');
do $$
begin
  begin
    insert into public.event_assignments (event_id, user_id, checkpoint_id)
    select e.id, 'aaaaaaaa-3600-0000-0000-000000000006', c.id
      from public.events e join public.checkpoints c on c.event_id = e.id
     where e.title = 'Soirée Packs Qpv';
    raise exception 'ÉCHEC  deuxième contrôleur accepté';
  exception when program_limit_exceeded then
    if sqlerrm <> 'billing_limit_controllers_per_event' then raise; end if;
    raise notice 'OK    Contrôleurs par événement : 1 inclus';
  end;
end $$;
set role authenticated;
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select public.add_event_billing_addon(:'ev2', 'controllers_per_event', 1) \gset ignored_
reset role;
insert into public.event_assignments (event_id, user_id, checkpoint_id)
values (:'ev2', 'aaaaaaaa-3600-0000-0000-000000000006', :'cp2');
set role authenticated;
select test.check('Dépasser la limite : +1 contrôleur ajouté à la facture',
  (select count(distinct user_id) from public.event_assignments where event_id = :'ev2')::text, '2');

-- Entrées réelles : 3 tickets simples, un pass entré 2 fois, une invitation.
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select public.set_event_status(:'ev2', 'in_progress') \gset ignored_
select test.login('aaaaaaaa-3600-0000-0000-000000000002');
select public.validate_scan(gen_random_uuid(), :'ev2', :'cp2', :'qa1') \gset ignored_
select public.validate_scan(gen_random_uuid(), :'ev2', :'cp2', :'qa2') \gset ignored_
select public.validate_scan(gen_random_uuid(), :'ev2', :'cp2', :'qa3') \gset ignored_
select public.validate_scan(gen_random_uuid(), :'ev2', :'cp2', :'qa3') \gset ignored_
select public.validate_scan(gen_random_uuid(), :'ev2', :'cp2', :'qp1') \gset ignored_
select public.validate_scan(gen_random_uuid(), :'ev2', :'cp2', :'qp1') \gset ignored_
select public.validate_scan(gen_random_uuid(), :'ev2', :'cp2', :'qi1') \gset ignored_
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select test.check('Estimation en direct : 6 entrées (pass 2, invitation comprise), 2 offertes',
  (select (e->>'entries') || ':' || (e->>'free_entries') || ':' || (e->>'billable_entries') || ':'
          || (e->>'entries_amount') || ':' || (e->>'addons_amount') || ':' || (e->>'amount')
     from (select public.event_billing(:'ev2')->'estimate' as e) x),
  '6:2:4:400:1000:1400');
select public.set_event_status(:'ev2', 'closed') \gset ignored_
select test.check('Clôture du contrôle : facture émise, due',
  (select i->>'amount' || ':' || (i->>'status') from (select public.event_billing(:'ev2')->'invoice' as i) x),
  '1400:due');
reset role;
select test.check('Facture : lignes entrées et supplément',
  (select string_agg(l->>'kind' || ':' || (l->>'amount'), ',' order by l->>'kind')
     from public.billing_invoices i, jsonb_array_elements(i.lines) l where i.event_id = :'ev2'),
  'addon:1000,entries:400');
select test.check('Journal : aucune donnée personnelle dans les actions de facturation',
  (select count(*) from public.audit_logs
    where (action like 'billing.%' or action like 'admin.billing_%')
      and (details ?| array['holder_name', 'holder_phone', 'holder_email', 'operator_reference',
                            'declared_transaction', 'reference', 'note']
           or details::text ~ '(PP2611|test\.local)'))::text,
  '0');

-- Facture en retard : bloque un nouvel événement à l'usage.
update public.billing_invoices set due_at = now() - interval '1 day' where event_id = :'ev2';
set role authenticated;
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select (public.create_event(:'org', 'Retard Packs Qpv', now() + interval '1 day',
                            now() + interval '2 days')).id as ev3 \gset
select (public.create_ticket_category(:'ev3', 'Entrée')).id as cat3 \gset
select public.set_event_billing(:'ev3', 'usage', :'soiree') \gset ignored_
select test.complete_event(:'ev3') \gset ignored_
select public.set_event_status(:'ev3', 'published') \gset ignored_
select test.expect_error('Facture en retard : nouvel événement à l''usage bloqué',
  format($q$select * from public.issue_tickets(%L, %L, 1)$q$, :'ev3', :'cat3'),
  'billing_overdue', null, :'ev3');
select test.check('Mon pack : facture en retard signalée',
  (select i->>'overdue' from jsonb_array_elements(public.my_billing()->'invoices') i
    where i->>'event_id' = :'ev2'),
  'true');
select test.login('aaaaaaaa-3600-0000-0000-000000000003');
select public.admin_mark_invoice_paid(
  (select (i->>'id')::uuid from jsonb_array_elements(public.admin_billing()->'invoices') i
    where i->>'event_id' = :'ev2'), 'orange_money', 'PP2611.9999.B1') \gset ignored_
select test.login('aaaaaaaa-3600-0000-0000-000000000001');
select count(*) as n from public.issue_tickets(:'ev3', :'cat3', 1) \gset
select test.check('Facture réglée : émission de nouveau possible',
  (select count(*) from public.tickets where event_id = :'ev3')::text, '1');

-- Tâche planifiée : N heures après la fin, facture (montant nul réglé d'office).
reset role;
select private.billing_tick(now()) \gset ignored_
select test.check('Tâche planifiée : rien avant la fin + délai',
  (select count(*) from public.billing_invoices where event_id = :'ev3')::text, '0');
select private.billing_tick(now() + interval '2 days' + interval '25 hours') \gset ignored_
select test.check('Facture sans entrée facturable : réglée d''office',
  (select amount || ':' || status from public.billing_invoices where event_id = :'ev3'),
  '0:paid');

-- Paliers marginaux : 500 à 150, au-delà à 100.
select test.check('Paliers : 700 entrées = 500 × 150 + 200 × 100',
  (private.billing_usage_amount(
     '{"entry_price": 0, "free_entries": 0,
       "tiers": [{"up_to": null, "price": 100}, {"up_to": 500, "price": 150}]}'::jsonb,
     '{}'::jsonb, 700)->>'amount'),
  '95000');
