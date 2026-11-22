-- =============================================================================
-- Tikéo — Tests : signaler un contenu, traitement dans la console (migration 6000)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-6000-0000-0000-000000000001', 'proprio-signal@test.local', now()),
  ('aaaaaaaa-6000-0000-0000-000000000002', 'awa-signal@test.local', now()),
  ('aaaaaaaa-6000-0000-0000-000000000003', 'issa-signal@test.local', now()),
  ('aaaaaaaa-6000-0000-0000-000000000004', 'moderation-signal@test.local', now()),
  ('aaaaaaaa-6000-0000-0000-000000000005', 'finance-signal@test.local', now());
update public.profiles set is_platform_admin = true
 where id in ('aaaaaaaa-6000-0000-0000-000000000004', 'aaaaaaaa-6000-0000-0000-000000000005');
insert into private.platform_admin_roles (user_id, role) values
  ('aaaaaaaa-6000-0000-0000-000000000004', 'moderation'),
  ('aaaaaaaa-6000-0000-0000-000000000005', 'finance');

set role authenticated;
select test.login('aaaaaaaa-6000-0000-0000-000000000001');
select (public.create_organization('Signal Prod Vq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Vq', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as ev \gset
select (public.create_event(:'org', 'Brouillon Vq', now() + interval '4 days',
                            now() + interval '4 days 4 hours')).id as ev_draft \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_

-- Signaler -----------------------------------------------------------------------
select test.login('aaaaaaaa-6000-0000-0000-000000000002');
select test.check('Signalement d''un événement',
  public.report_content('event', :'ev', 'scam', '  Faux concert, numéro injoignable.  ')->>'already',
  'false');
select test.check('Deuxième signalement du même compte : sans effet',
  public.report_content('event', :'ev', 'misleading')->>'already', 'true');
select test.check('Structure signalée',
  public.report_content('organization', :'org', 'other')->>'already', 'false');
select test.expect_error('Motif inconnu refusé',
  format('select public.report_content(''event'', %L, ''boring'')', :'ev'), 'report_reason_invalid');
select test.expect_error('Commentaire trop long refusé',
  format('select public.report_content(''event'', %L, ''other'', %L)', :'ev', repeat('a', 301)),
  'report_comment_invalid');
select test.expect_error('Brouillon : introuvable',
  format('select public.report_content(''event'', %L, ''other'')', :'ev_draft'),
  'report_target_not_found');
select test.login('aaaaaaaa-6000-0000-0000-000000000003');
select public.report_content('event', :'ev', 'misleading') \gset ignored_
reset role;
select test.check('Commentaire nettoyé, jamais dans le journal',
  (select comment from public.content_reports
    where event_id = :'ev' and reporter_id = 'aaaaaaaa-6000-0000-0000-000000000002')
  || '|' || (select count(*)::text from public.audit_logs where details::text like '%injoignable%'),
  'Faux concert, numéro injoignable.|0');
-- Limite : 10 par jour et par compte.
insert into public.content_reports (kind, organization_id, reporter_id, reason, status)
select 'organization', :'org', 'aaaaaaaa-6000-0000-0000-000000000003', 'other', 'dismissed'
  from generate_series(1, 9);
set role authenticated;
select test.login('aaaaaaaa-6000-0000-0000-000000000003');
select test.expect_error('Plus de 10 signalements par jour refusés',
  format('select public.report_content(''organization'', %L, ''other'')', :'org'),
  'report_rate_limited');
reset role;
select test.check('Fermé aux visiteurs',
  has_function_privilege('anon', 'public.report_content(text, uuid, text, text)', 'execute')::text,
  'false');

-- Console -------------------------------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-6000-0000-0000-000000000005');
select test.expect_error('Rôle finance : signalements interdits',
  'select public.admin_content_reports()', 'admin_role_forbidden');
select test.login('aaaaaaaa-6000-0000-0000-000000000004');
select test.check('À traiter : événement (2 signalements, motifs, commentaire)',
  (select (i->>'count') || '|' || (i->'reasons'->>'scam') || '|' || (i->'reasons'->>'misleading')
          || '|' || (i->'comments'->0->>'comment') || '|' || (i->>'title') || '|' || (i->>'removed')
     from jsonb_array_elements(public.admin_content_reports()->'items') i
    where i->>'id' = :'ev'),
  '2|1|1|Faux concert, numéro injoignable.|Concert Vq|false');
select test.check('Les plus signalés d''abord',
  (select string_agg(i->>'kind', ',' order by o)
     from jsonb_array_elements(public.admin_content_reports()->'items') with ordinality t(i, o)
    where i->>'organization_id' = :'org'),
  'event,organization');
select test.expect_error('Motif obligatoire',
  format('select public.admin_resolve_reports(''event'', %L, ''remove'', '' '')', :'ev'),
  'reason_required');
select test.check('Retirer du catalogue : 2 signalements traités',
  public.admin_resolve_reports('event', :'ev', 'remove', 'Arnaque confirmée')->>'resolved', '2');
select test.check('Classer sans suite la structure',
  public.admin_resolve_reports('organization', :'org', 'dismiss', 'Rien d''anormal')->>'resolved', '1');
select test.expect_error('Plus rien à traiter',
  format('select public.admin_resolve_reports(''event'', %L, ''dismiss'', ''Encore'')', :'ev'),
  'report_not_found');
select test.check('Traités : état et retrait',
  (select (i->>'status') || '|' || (i->>'removed')
     from jsonb_array_elements(public.admin_content_reports(false)->'items') i
    where i->>'id' = :'ev'),
  'actioned|true');
reset role;
select test.check('Événement retiré du catalogue',
  (select (public_blocked_at is not null)::text || '|' || public_blocked_reason
     from public.events where id = :'ev'),
  'true|Arnaque confirmée');
select test.check('Structure toujours active',
  (select status::text from public.organizations where id = :'org'), 'active');
select test.check('Journal : action sans structure ni commentaire, motif à part',
  (select string_agg(action || ':' || coalesce(organization_id::text, '∅') || ':' || (details->>'reports'),
                     ',' order by action)
     from public.audit_logs
    where actor_id = 'aaaaaaaa-6000-0000-0000-000000000004' and action like 'admin.reports_%')
  || '|' || (select count(*)::text from private.admin_action_log
              where actor_id = 'aaaaaaaa-6000-0000-0000-000000000004'
                and action like 'admin.reports_%'),
  'admin.reports_actioned:∅:2,admin.reports_dismissed:∅:1|2');
select test.check('Table fermée à l''API',
  has_table_privilege('authenticated', 'public.content_reports', 'select')::text, 'false');
