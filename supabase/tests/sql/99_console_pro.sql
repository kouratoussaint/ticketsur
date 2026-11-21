-- =============================================================================
-- Tikéo — Tests : console pro (migration 4700)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-4700-0000-0000-000000000001', 'admin-console-pro@test.local'),
  ('aaaaaaaa-4700-0000-0000-000000000002', 'promoteur-console-pro@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-4700-0000-0000-000000000001';
select coalesce(max(id), 0) as base from public.push_outbox \gset

-- Annonces programmées ----------------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-4700-0000-0000-000000000001');
select public.admin_publish_announcement('Alerte Prog Qzv', 'Demain.', array['promoters'],
  'important', null, now() + interval '1 day') as prog \gset
select public.admin_publish_announcement('Tout de suite Prog Qzv', 'Maintenant.', array['users'],
  'important') \gset ignored_

reset role;
select test.check('Programmée : pas de notification à la publication ; immédiate : une',
  (select string_agg(o.title, ',') from public.push_outbox o
    where o.id > :base and o.title like '%Prog Qzv'),
  'Tout de suite Prog Qzv');
set role authenticated;
select test.check('Console : état « programmée »',
  (select a.scheduled || ':' || a.active from public.admin_announcements(100, 0) a
    where a.id = :'prog'),
  'true:false');

select test.expect_error('Début dans plus de 90 jours',
  $q$select public.admin_publish_announcement('Trop loin Qzv', 'x', array['users'], 'info', null,
       now() + interval '91 days')$q$, 'announcement_dates_invalid');
select test.expect_error('Fin avant le début',
  $q$select public.admin_publish_announcement('Fin Qzv', 'x', array['users'], 'info',
       now() + interval '1 day', now() + interval '2 days')$q$, 'announcement_dates_invalid');

-- Modification avant le début.
select public.admin_update_announcement(:'prog', 'Alerte Prog Qzv', 'Après-demain.',
  array['promoters', 'controllers'], 'important', now() + interval '2 days', null) \gset ignored_
select test.check('Programmée modifiée',
  (select a.body || ':' || array_to_string(a.audiences, '+') from public.admin_announcements(100, 0) a
    where a.id = :'prog'),
  'Après-demain.:controllers+promoters');

-- Arrivée au début : notification une seule fois.
reset role;
select private.push_due_announcements(now() + interval '3 days') \gset ignored_
select private.push_due_announcements(now() + interval '3 days') \gset ignored_
select test.check('Notification au début, une seule fois, vers les nouveaux destinataires',
  (select count(*) || ':' || min(o.topic_condition) from public.push_outbox o
    where o.id > :base and o.title = 'Alerte Prog Qzv'),
  '1:''tikeo_controllers'' in topics || ''tikeo_promoters'' in topics');
set role authenticated;
select test.expect_error('Diffusée : ne se modifie plus',
  format($q$select public.admin_update_announcement(%L, 'Alerte Prog Qzv', 'x', array['users'],
           'info', null, null)$q$, :'prog'), 'announcement_started');

-- Réponses types ------------------------------------------------------------------
select public.admin_save_support_template(null, 'Mot de passe Qzv',
  'Bonjour, utilisez « Mot de passe oublié » sur l''écran de connexion.') as tpl \gset
select public.admin_save_support_template(:'tpl', 'Mot de passe oublié Qzv',
  'Bonjour, touchez « Mot de passe oublié ».') \gset ignored_
select test.check('Réponse type enregistrée puis modifiée',
  (select t.title || '|' || t.body from public.admin_support_templates() t where t.id = :'tpl'),
  'Mot de passe oublié Qzv|Bonjour, touchez « Mot de passe oublié ».');
select test.expect_error('Titre trop court',
  $q$select public.admin_save_support_template(null, 'x', 'Corps')$q$,
  'support_template_title_invalid');
select public.admin_delete_support_template(:'tpl') \gset ignored_
select test.expect_error('Supprimée : introuvable',
  format($q$select public.admin_delete_support_template(%L)$q$, :'tpl'),
  'support_template_not_found');

-- Courbes ---------------------------------------------------------------------------
select test.check('30 jours, du plus ancien à aujourd''hui',
  (select count(*) || ':' || (max(s.day) = (now() at time zone 'UTC')::date)
          || ':' || (min(s.day) = (now() at time zone 'UTC')::date - 29)
     from public.admin_daily_stats(30) s),
  '30:true:true');
select test.check('Comptes créés aujourd''hui comptés',
  (select (s.accounts >= 2)::text from public.admin_daily_stats(30) s
    where s.day = (now() at time zone 'UTC')::date),
  'true');
select test.expect_error('Période invalide',
  $q$select * from public.admin_daily_stats(400)$q$, 'days_invalid');

-- Hors administrateurs : refusé -----------------------------------------------------
select test.login('aaaaaaaa-4700-0000-0000-000000000002');
select test.expect_error('Promoteur : réponses types refusées',
  $q$select * from public.admin_support_templates()$q$, 'forbidden');
select test.expect_error('Promoteur : courbes refusées',
  $q$select * from public.admin_daily_stats(30)$q$, 'forbidden');

-- Journal sans texte ----------------------------------------------------------------
reset role;
select test.check('Journal : jamais le texte des annonces ni des modèles',
  (select bool_and(a.details::text not like '%Bonjour%' and a.details::text not like '%demain%')::text
     from public.audit_logs a
    where a.actor_id = 'aaaaaaaa-4700-0000-0000-000000000001'),
  'true');
select test.check('Réponses types fermées à l''API',
  (has_table_privilege('authenticated', 'public.support_reply_templates', 'select'))::text, 'false');
