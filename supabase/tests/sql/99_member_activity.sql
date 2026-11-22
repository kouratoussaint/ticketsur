-- =============================================================================
-- Tikéo — Tests : fiche d'un membre de l'équipe (migration 5800)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-5800-0000-0000-000000000001', 'proprio-membre@test.local', now()),
  ('aaaaaaaa-5800-0000-0000-000000000002', 'controle-membre@test.local', now()),
  ('aaaaaaaa-5800-0000-0000-000000000003', 'inconnu-membre@test.local', now());

set role authenticated;
select test.login('aaaaaaaa-5800-0000-0000-000000000001');
select (public.create_organization('Équipe Vq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Vq', now() + interval '1 hour',
                            now() + interval '5 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select (public.create_checkpoint(:'ev', 'Porte Nord')).id as cp \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
create temp table member_tickets as select * from public.issue_tickets(:'ev', :'cat', 2);
select qr_token as tok1 from member_tickets order by public_reference limit 1 \gset
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-5800-0000-0000-000000000002', 'controller');
set role authenticated;
select test.login('aaaaaaaa-5800-0000-0000-000000000001');
select public.assign_member(:'ev', 'aaaaaaaa-5800-0000-0000-000000000002', :'cp') \gset ignored_
select public.set_event_status(:'ev', 'in_progress') \gset ignored_

-- Le contrôleur valide une entrée, puis un refus (déjà utilisé).
select test.login('aaaaaaaa-5800-0000-0000-000000000002');
select public.validate_scan('00000000-0000-4000-8000-000000005801', :'ev', :'cp', :'tok1') \gset ignored_
select public.validate_scan('00000000-0000-4000-8000-000000005802', :'ev', :'cp', :'tok1') \gset ignored_

select test.login('aaaaaaaa-5800-0000-0000-000000000001');
select test.check('Fiche : entrées validées (refus non comptés), événements, dernière',
  (select (j->>'validated') || '|' || (j->>'validated_30d') || '|' || (j->>'events_worked')
          || '|' || ((j->>'last_validated_at') is not null)::text
     from (select public.member_activity(:'org', 'aaaaaaaa-5800-0000-0000-000000000002') j) s),
  '1|1|1|true');
select test.check('Fiche : affectation avec la porte',
  (select string_agg((x->>'event_title') || '@' || coalesce(x->>'checkpoint_name', '∅'), ',')
     from jsonb_array_elements(
       public.member_activity(:'org', 'aaaaaaaa-5800-0000-0000-000000000002')->'assignments') x),
  'Concert Vq@Porte Nord');
select test.check('Fiche du propriétaire : rien',
  (select (j->>'validated') || '|' || jsonb_array_length(j->'assignments')
     from (select public.member_activity(:'org', 'aaaaaaaa-5800-0000-0000-000000000001') j) s),
  '0|0');
select test.expect_error('Compte hors de la structure',
  format('select public.member_activity(%L, %L)', :'org', 'aaaaaaaa-5800-0000-0000-000000000003'),
  'member_not_found');
select test.login('aaaaaaaa-5800-0000-0000-000000000002');
select test.expect_error('Contrôleur : fiches réservées',
  format('select public.member_activity(%L, %L)', :'org', 'aaaaaaaa-5800-0000-0000-000000000002'),
  'org_forbidden');
reset role;
