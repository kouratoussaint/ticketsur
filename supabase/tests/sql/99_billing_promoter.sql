-- =============================================================================
-- Tikéo — Tests : facturation côté promoteur (migration 3800)
-- Essai, notifications, erreurs de limite lisibles par l'app, my_billing v2.
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-3800-0000-0000-000000000001', 'promoteur-essai@test.local'),
  ('aaaaaaaa-3800-0000-0000-000000000003', 'admin-essai@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-3800-0000-0000-000000000003';
update public.profiles set locale = 'fr'
 where id = 'aaaaaaaa-3800-0000-0000-000000000001';

set role authenticated;
select test.login('aaaaaaaa-3800-0000-0000-000000000003');
select public.admin_save_pack(null, $j${
  "name": "Essai Qpw", "system": "flat", "monthly_price": 3000, "trial_days": 14,
  "durations": {"month": 3000},
  "options": [{"key": "members_per_structure", "included": 1, "addon_price": 500}]
  }$j$::jsonb) as trial_pack \gset
select public.admin_set_pack_status(:'trial_pack', 'published') \gset ignored_
select public.admin_save_pack(null, $j${
  "name": "Sans essai Qpw", "system": "flat", "monthly_price": 2000,
  "durations": {"month": 2000}
  }$j$::jsonb) as plain_pack \gset
select public.admin_set_pack_status(:'plain_pack', 'published') \gset ignored_
select public.admin_save_pack(null, $j${
  "name": "Soirée Qpw", "system": "usage", "entry_price": 100,
  "options": [{"key": "tickets_per_event", "included": 1},
              {"key": "controllers_per_event", "included": 1, "addon_price": 1000}]
  }$j$::jsonb) as usage_pack \gset
select public.admin_set_pack_status(:'usage_pack', 'published') \gset ignored_

-- Essai --------------------------------------------------------------------------
select test.login('aaaaaaaa-3800-0000-0000-000000000001');
select test.check('my_billing v2 : essai pas encore utilisé',
  (select (b->>'version') || ':' || (b->>'trial_used') from (select public.my_billing() as b) x),
  '2:false');
select test.expect_error('Essai : pack sans jours d''essai refusé',
  format($q$select public.start_billing_trial(%L)$q$, :'plain_pack'), 'billing_pack_invalid');
select public.start_billing_trial(:'trial_pack')->>'subscription_id' as trial_sub \gset
select test.check('Essai : pack actif 14 jours, essai utilisé',
  (select (b->'plan'->>'duration') || ':' || (b->'plan'->'snapshot'->>'name') || ':'
          || (b->>'trial_used') || ':'
          || ((b->'plan'->>'period_end')::timestamptz > now() + interval '13 days')::text
     from (select public.my_billing() as b) x),
  'trial:Essai Qpw:true:true');
select test.expect_error('Essai : une seule fois par compte',
  format($q$select public.start_billing_trial(%L)$q$, :'trial_pack'), 'billing_trial_used');
select test.expect_error('Essai : pas de suppléments payants pendant l''essai',
  $q$select public.request_billing_addons('{"members_per_structure": 1}')$q$,
  'billing_subscription_missing');

-- Un pack payé remplace l'essai et démarre tout de suite.
select public.request_billing_pack(:'trial_pack', 'month')->>'id' as req \gset
select test.login('aaaaaaaa-3800-0000-0000-000000000003');
select public.admin_activate_request(:'req', 'orange_money', 'OM-QPW-1') as paid_sub \gset
reset role;
select test.check('Activation : essai arrêté, pack payé dès maintenant',
  (select (select status from public.billing_subscriptions where id = :'trial_sub') || ':'
          || (starts_at < now() + interval '1 minute')::text
     from public.billing_subscriptions where id = :'paid_sub'),
  'cancelled:true');
select test.check('Notification : pack activé',
  (select title || ' | ' || body || ' | ' || route from public.push_outbox
    where user_id = 'aaaaaaaa-3800-0000-0000-000000000001' order by id desc limit 1),
  'Pack activé | Votre pack Essai Qpw est actif. | /facturation');

-- Demande refusée.
set role authenticated;
select test.login('aaaaaaaa-3800-0000-0000-000000000001');
select public.request_billing_pack(:'plain_pack', 'month')->>'id' as req_cancelled \gset
select public.request_billing_pack(:'plain_pack', 'month')->>'id' as req2 \gset
select test.login('aaaaaaaa-3800-0000-0000-000000000003');
select public.admin_refuse_request(:'req2', 'Paiement introuvable') \gset ignored_
reset role;
select test.check('Notification : demande refusée, vers la demande',
  (select title || ' | ' || route from public.push_outbox
    where user_id = 'aaaaaaaa-3800-0000-0000-000000000001' order by id desc limit 1),
  'Demande refusée | /facturation/demande/' || :'req2');
select test.check('Notification : une demande annulée ne notifie pas',
  (select count(*) from public.push_outbox
    where user_id = 'aaaaaaaa-3800-0000-0000-000000000001')::text,
  '2');

-- Rappel avant la fin, une seule fois.
update public.billing_subscriptions set ends_at = now() + interval '3 days' where id = :'paid_sub';
select private.billing_notify(now()) as n1 \gset
select private.billing_notify(now()) as n2 \gset
select test.check('Rappel : envoyé une fois, avec la date de fin',
  (select (select count(*) from public.push_outbox
            where user_id = 'aaaaaaaa-3800-0000-0000-000000000001' and title = 'Fin de votre pack')::text
          || ':' || (body like 'Essai Qpw se termine le ' || to_char(now() + interval '3 days', 'DD/MM/YYYY') || '%')::text
     from public.push_outbox
    where user_id = 'aaaaaaaa-3800-0000-0000-000000000001' and title = 'Fin de votre pack'),
  '1:true');
select test.check('Rappel : marqué sur l''abonnement',
  (select (reminded_at is not null)::text from public.billing_subscriptions where id = :'paid_sub'),
  'true');

-- Événement à l'usage : limite lisible, facture, retard -----------------------------
set role authenticated;
select test.login('aaaaaaaa-3800-0000-0000-000000000001');
select (public.create_organization('Studio Essai Qpw')::jsonb)->>'id' as org \gset
select public.set_organization_billing(:'org', 'usage', :'usage_pack') \gset ignored_
select (public.create_event(:'org', 'Soirée Essai Qpw', now() + interval '1 day',
                            now() + interval '2 days')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Entrée')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select count(*) as n from public.issue_tickets(:'ev', :'cat', 1) \gset
select set_config('test.billing_ev', :'ev', false) \gset ignored_
select set_config('test.billing_cat', :'cat', false) \gset ignored_
do $$
declare
  v_hint text;
begin
  perform public.issue_tickets(current_setting('test.billing_ev')::uuid,
                               current_setting('test.billing_cat')::uuid, 1);
  raise exception 'ÉCHEC  deuxième ticket accepté';
exception when program_limit_exceeded then
  get stacked diagnostics v_hint = pg_exception_hint;
  perform set_config('test.billing_hint', sqlerrm || ' ' || v_hint, false);
end $$;
select test.check('Limite : HINT en JSON (limite, système, événement)',
  current_setting('test.billing_hint'),
  'billing_limit_tickets_per_event '
    || jsonb_build_object('limit', 1, 'system', 'usage', 'event', :'ev')::text);

select public.add_event_billing_addon(:'ev', 'controllers_per_event', 1) \gset ignored_
select test.login('aaaaaaaa-3800-0000-0000-000000000003');
select public.admin_issue_invoice(:'ev') as inv \gset
reset role;
select test.check('Notification : facture à payer, montant et échéance',
  (select title || ' | ' || body || ' | ' || route from public.push_outbox
    where user_id = 'aaaaaaaa-3800-0000-0000-000000000001' order by id desc limit 1),
  'Facture à payer | Soirée Essai Qpw : 1 000 FCFA, avant le '
    || (select to_char(due_at, 'DD/MM/YYYY') from public.billing_invoices where id = :'inv')
    || '. | /facturation/factures/' || :'inv');

set role authenticated;
select test.login('aaaaaaaa-3800-0000-0000-000000000001');
select test.check('my_billing v2 : détail de la facture',
  (select (i->>'billable_entries') || ':' || (i->>'addons_amount') || ':' || (i->>'pack_name')
          || ':' || (i->>'free_entries')
     from (select public.my_billing() as b) x, jsonb_array_elements(x.b->'invoices') i
    where i->>'id' = :'inv'),
  '0:1000:Soirée Qpw:0');

reset role;
update public.billing_invoices set due_at = now() - interval '1 day' where id = :'inv';
select private.billing_notify(now()) as n3 \gset
select private.billing_notify(now()) as n4 \gset
select test.check('Retard : notifié une seule fois',
  (select count(*) from public.push_outbox
    where user_id = 'aaaaaaaa-3800-0000-0000-000000000001' and title = 'Facture en retard')::text
   || ':' || (select route from public.push_outbox
               where user_id = 'aaaaaaaa-3800-0000-0000-000000000001' and title = 'Facture en retard'),
  '1:/facturation/factures/' || :'inv');

-- Anglais.
update public.profiles set locale = 'en' where id = 'aaaaaaaa-3800-0000-0000-000000000001';
select private.billing_push('aaaaaaaa-3800-0000-0000-000000000001', 'Titre', 'Title', 'Corps',
                            'Body', '/facturation') \gset ignored_
select test.check('Notification : langue du compte',
  (select title || ':' || body from public.push_outbox
    where user_id = 'aaaaaaaa-3800-0000-0000-000000000001' order by id desc limit 1),
  'Title:Body');
select test.check('Montant en anglais',
  private.billing_money(1234567, 'en') || ' / ' || private.billing_money(1234567, 'fr'),
  '1,234,567 FCFA / 1 234 567 FCFA');
set role authenticated;
