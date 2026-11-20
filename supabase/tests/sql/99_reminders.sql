-- =============================================================================
-- Tikéo — Tests : rappels avant l'événement et bilan (migration 3500)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-3500-0000-0000-000000000001', 'promoteur-rappel@test.local'),
  ('aaaaaaaa-3500-0000-0000-000000000002', 'spectatrice-rappel@test.local'),
  ('aaaaaaaa-3500-0000-0000-000000000003', 'spectator-reminder@test.local'),
  ('aaaaaaaa-3500-0000-0000-000000000004', 'sans-rappel@test.local'),
  ('aaaaaaaa-3500-0000-0000-000000000005', 'sans-telephone@test.local'),
  ('aaaaaaaa-3500-0000-0000-000000000006', 'controleur-rappel@test.local');
update public.profiles set locale = 'en' where id = 'aaaaaaaa-3500-0000-0000-000000000003';

set role authenticated;
select test.login('aaaaaaaa-3500-0000-0000-000000000001');
select (public.create_organization('Studio Rappel Qzk')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Gala Rappel Qzk', now() + interval '2 days',
                            now() + interval '2 days 4 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Salle')).id as cat \gset
select (public.create_checkpoint(:'ev', 'Porte')).id as cp \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
create temporary table rq (n int, ticket_id uuid, qr text);
grant all on rq to authenticated;
insert into rq select row_number() over (), ticket_id, qr_token
  from public.issue_tickets(:'ev', :'cat', 6);

-- Chaque spectateur ajoute ses tickets à « Mes tickets ».
select test.login('aaaaaaaa-3500-0000-0000-000000000002');
select count(public.claim_ticket(qr)) from rq where n in (1, 2) \gset ignored_
select public.register_push_device('jeton-rappel-fr-' || repeat('f', 20)) \gset ignored_
select test.login('aaaaaaaa-3500-0000-0000-000000000003');
select public.claim_ticket(qr) as claimed_en from rq where n = 3 \gset
select public.register_push_device('jeton-rappel-en-' || repeat('e', 20)) \gset ignored_
select test.login('aaaaaaaa-3500-0000-0000-000000000004');
select public.claim_ticket(qr) from rq where n = 4 \gset ignored_
select public.register_push_device('jeton-rappel-off-' || repeat('o', 20)) \gset ignored_
select public.set_event_reminders(false) \gset ignored_
select test.check('Rappels désactivés par le spectateur',
  (select event_reminders::text from public.my_profile()), 'false');
select test.login('aaaaaaaa-3500-0000-0000-000000000005');
select public.claim_ticket(qr) from rq where n = 5 \gset ignored_
select test.check('Rappels activés par défaut',
  (select event_reminders::text from public.my_profile()), 'true');
set role anon;
do $$
begin
  begin
    perform public.set_event_reminders(false);
    raise exception 'ÉCHEC  rappels réglés sans compte';
  exception when insufficient_privilege then
    raise notice 'OK    Rappels : réservé aux comptes';
  end;
end $$;

-- Rappels ------------------------------------------------------------------------
reset role;
select e.starts_at as starts, to_char(e.starts_at at time zone e.timezone, 'HH24:MI') as hhmi,
       coalesce(' · ' || nullif(concat_ws(', ', e.venue, e.city), ''), '') as place
  from public.events e where e.id = :'ev' \gset
create or replace function pg_temp.mine() returns setof public.push_outbox language sql as $$
  select o.* from public.push_outbox o
   where o.user_id in ('aaaaaaaa-3500-0000-0000-000000000002', 'aaaaaaaa-3500-0000-0000-000000000003',
                       'aaaaaaaa-3500-0000-0000-000000000004', 'aaaaaaaa-3500-0000-0000-000000000005')
$$;

select private.enqueue_event_reminders(:'starts'::timestamptz - interval '30 hours') \gset ignored_
select test.check('Plus de 24 h avant : aucun rappel', (select count(*)::text from pg_temp.mine()), '0');

select private.enqueue_event_reminders(:'starts'::timestamptz - interval '20 hours') \gset ignored_
select test.check('La veille : un rappel par personne avec un téléphone et les rappels actifs',
  (select string_agg(right(user_id::text, 1) || ':' || route, ',' order by user_id)
     from pg_temp.mine()),
  '2:/portefeuille,3:/mon-ticket/' || :'claimed_en');
select test.check('La veille : texte en français, heure de l''événement',
  (select (title = 'Rappel : Gala Rappel Qzk')::text || '|'
          || (body ~ ('^(Demain|Aujourd''hui) à ' || :'hhmi' || '.*Votre ticket est dans Tikéo\.$'))::text
     from pg_temp.mine() where user_id = 'aaaaaaaa-3500-0000-0000-000000000002'),
  'true|true');
select test.check('La veille : texte en anglais pour un compte anglais',
  (select (title = 'Reminder: Gala Rappel Qzk')::text || '|'
          || (body ~ ('^(Tomorrow|Today) at ' || :'hhmi' || '.*Your ticket is in Tikéo\.$'))::text
     from pg_temp.mine() where user_id = 'aaaaaaaa-3500-0000-0000-000000000003'),
  'true|true');

select private.enqueue_event_reminders(:'starts'::timestamptz - interval '10 hours') \gset ignored_
select private.enqueue_event_reminders(:'starts'::timestamptz - interval '150 minutes') \gset ignored_
select test.check('Pas de second rappel la veille ; rien entre 3 h et 2 h avant',
  (select count(*)::text from pg_temp.mine()), '2');

select private.enqueue_event_reminders(:'starts'::timestamptz - interval '90 minutes') \gset ignored_
select private.enqueue_event_reminders(:'starts'::timestamptz - interval '60 minutes') \gset ignored_
select test.check('2 h avant : « Bientôt », une seule fois',
  (select string_agg(right(user_id::text, 1) || ':' || title, ',' order by user_id)
     from pg_temp.mine() where title like 'Bientôt%' or title like 'Starting soon%'),
  '2:Bientôt : Gala Rappel Qzk,3:Starting soon: Gala Rappel Qzk');
select test.check('« Bientôt » : heure de début',
  (select body from pg_temp.mine()
    where user_id = 'aaaaaaaa-3500-0000-0000-000000000002' and title like 'Bientôt%'),
  'Début à ' || :'hhmi' || :'place' || '. Préparez votre ticket.');

select test.check('Tâche planifiée : s''exécute sans erreur',
  (select private.push_tick()::text), '');

-- Bilan ----------------------------------------------------------------------------
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-3500-0000-0000-000000000006', 'controller');
insert into public.event_assignments (event_id, user_id, checkpoint_id)
values (:'ev', 'aaaaaaaa-3500-0000-0000-000000000006', :'cp');
set role authenticated;
select test.login('aaaaaaaa-3500-0000-0000-000000000001');
select public.set_event_status(:'ev', 'in_progress') \gset ignored_
select test.login('aaaaaaaa-3500-0000-0000-000000000006');
select count(public.validate_scan(gen_random_uuid(), :'ev', :'cp', qr)) from rq where n in (1, 2, 3) \gset ignored_
select public.validate_scan(gen_random_uuid(), :'ev', :'cp', qr) from rq where n = 1 \gset ignored_

-- Un ancien événement de la structure, pour la comparaison.
select test.login('aaaaaaaa-3500-0000-0000-000000000001');
select (public.create_event(:'org', 'Ancien Gala Qzk', now() + interval '1 day',
                            now() + interval '1 day 3 hours')).id as old \gset
select (public.create_ticket_category(:'old', 'Salle')).id as oldcat \gset
select test.complete_event(:'old') \gset ignored_
select public.set_event_status(:'old', 'published') \gset ignored_
select count(*) from public.issue_tickets(:'old', :'oldcat', 4) \gset ignored_
reset role;
update public.events set starts_at = now() - interval '30 days', ends_at = now() - interval '29 days',
       status = 'closed' where id = :'old';
set role authenticated;
select test.login('aaaaaaaa-3500-0000-0000-000000000001');
select public.event_summary(:'ev') as s \gset
select test.check('Bilan : une heure d''affluence, 3 entrées, pointe identique',
  jsonb_array_length((:'s'::jsonb)->'hours')::text || '|'
  || ((:'s'::jsonb)->'hours'->0->>'entries') || '|'
  || ((:'s'::jsonb)->'peak'->>'entries') || '|'
  || (((:'s'::jsonb)->'peak'->>'at') = ((:'s'::jsonb)->'hours'->0->>'at'))::text,
  '1|3|3|true');
select test.check('Bilan : par jour, personnes et entrées ; aucun pass',
  ((:'s'::jsonb)->'days'->0->>'people') || '|' || ((:'s'::jsonb)->'days'->0->>'entries') || '|'
  || ((:'s'::jsonb)->'passes'->>'tickets'),
  '3|3|0');
select test.check('Bilan : comparaison avec l''ancien événement',
  (select string_agg((c->>'title') || ':' || (c->>'issued') || ':' || (c->>'admitted') || ':'
                     || (c->>'current'), ',' order by c->>'title')
     from jsonb_array_elements((:'s'::jsonb)->'comparison') c),
  'Ancien Gala Qzk:4:0:false,Gala Rappel Qzk:6:3:true');
select test.login('aaaaaaaa-3500-0000-0000-000000000006');
select set_config('test.ev', :'ev', false) \gset ignored_
do $$
begin
  begin
    perform public.event_summary(current_setting('test.ev')::uuid);
    raise exception 'ÉCHEC  bilan lu par un contrôleur';
  exception when insufficient_privilege then
    raise notice 'OK    Bilan réservé aux propriétaires et gestionnaires';
  end;
end $$;

-- Tâche planifiée (staging seulement) ------------------------------------------------
reset role;
create or replace function pg_temp.cron_job() returns text language plpgsql as $$
declare v integer;
begin
  if to_regclass('cron.job') is null then return 'ok'; end if;
  execute 'select count(*) from cron.job where jobname = ''tikeo-push-tick''
             and schedule = ''*/5 * * * *'' and command = ''select private.push_tick()'''
    into v;
  return case when v = 1 then 'ok' else 'absente' end;
end $$;
select test.check('Tâche planifiée : toutes les 5 minutes là où pg_cron existe',
  pg_temp.cron_job(), 'ok');
drop table rq;
