-- =============================================================================
-- Tikéo — Tests : notifications d'événements (migration 6500)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

-- Le déclencheur des modifications est différé à la fin de la transaction :
-- sur le staging (une seule transaction), on le fait passer tout de suite.
set constraints public.events_notify_changes immediate;

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-6500-0000-0000-000000000001', 'proprio-diffusion@test.local', now()),
  ('aaaaaaaa-6500-0000-0000-000000000002', 'abonne-diffusion@test.local', now()),
  ('aaaaaaaa-6500-0000-0000-000000000003', 'detenteur-diffusion@test.local', now());
update public.profiles set locale = 'en' where id = 'aaaaaaaa-6500-0000-0000-000000000003';

select test.check('Sujets des villes',
  private.city_topic('Bobo-Dioulasso') || ' ' || private.city_topic('Fada N''Gourma')
  || ' ' || private.city_topic('Pô') || ' ' || private.city_topic(' Dédougou '),
  'tikeo_city_bobo_dioulasso tikeo_city_fada_n_gourma tikeo_city_po tikeo_city_dedougou');

set role authenticated;
select test.login('aaaaaaaa-6500-0000-0000-000000000001');
select (public.create_organization('Diffusion Prod Pq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Pq', '2031-06-20 21:00+00',
                            '2031-06-21 01:00+00')).id as ev \gset
select (public.create_event(:'org', 'Privé Pq', '2031-07-20 21:00+00',
                            '2031-07-21 01:00+00')).id as ev_priv \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select (public.create_ticket_category(:'ev_priv', 'Standard')).id as cat_priv \gset
select test.complete_event(:'ev') \gset ignored_
select test.complete_event(:'ev_priv') \gset ignored_
reset role;
update public.events set city = 'Bobo-Dioulasso', venue = 'Stade Pq',
       timezone = 'Africa/Ouagadougou' where id in (:'ev', :'ev_priv');
set role authenticated;
select public.set_event_public(:'ev_priv', false) \gset ignored_
select test.login('aaaaaaaa-6500-0000-0000-000000000002');
select public.follow_organization(:'org', true) \gset ignored_
reset role;
select coalesce(max(id), 0) as base from public.push_outbox \gset

-- Publication : abonnés (personnel) et ville (sujets) -------------------------------
set role authenticated;
select test.login('aaaaaaaa-6500-0000-0000-000000000001');
select public.set_event_status(:'ev', 'published') \gset ignored_
select public.set_event_status(:'ev_priv', 'published') \gset ignored_
select count(*) from public.issue_tickets(:'ev', :'cat', 1) \gset ignored_
select count(*) from public.issue_tickets(:'ev_priv', :'cat_priv', 1) \gset ignored_
reset role;
update public.tickets set holder_user_id = 'aaaaaaaa-6500-0000-0000-000000000003'
 where event_id in (:'ev', :'ev_priv');
select test.check('Nouvel événement : à sa ville et à « toutes les villes », groupé par étiquette',
  (select topic_condition || '|' || title || '|' || body || '|' || route || '|' || tag
     from public.push_outbox where id > :base and topic_condition is not null),
  '''tikeo_city_bobo_dioulasso'' in topics || ''tikeo_city_all'' in topics|Nouvel événement à Bobo-Dioulasso'
  || '|Concert Pq · 20/06 à 21h00 · Diffusion Prod Pq|/evenement/' || :'ev' || '|evt-' || :'ev');
select test.check('Abonné : message personnel, même étiquette ; rien pour l''événement privé',
  (select string_agg(right(user_id::text, 1) || ':' || tag, ',') from public.push_outbox
    where id > :base and user_id is not null),
  '2:evt-' || :'ev');
select coalesce(max(id), 0) as base from public.push_outbox \gset

-- Modification sans importance : rien ---------------------------------------------
update public.events set description = 'Nouvelle affiche.', title = 'Concert Pq'
 where id = :'ev';
select test.check('Description changée : aucune notification',
  (select count(*)::text from public.push_outbox where id > :base), '0');

-- Date et lieu : détenteur (sa langue), abonné, favoris -------------------------------
update public.events set starts_at = '2031-06-27 20:30+00', ends_at = '2031-06-28 01:00+00',
       venue = 'Palais Pq' where id = :'ev';
select test.check('Date et lieu changés : détenteur, abonné, favoris',
  (select string_agg(coalesce(right(user_id::text, 1), topic_condition) || '|' || title || '|' || body
                     || '|' || route, ' ## ' order by id)
     from public.push_outbox where id > :base),
  '3|Event updated|“Concert Pq”: new date 2031-06-27 20:30 · new place: Palais Pq, Bobo-Dioulasso.|/portefeuille'
  || ' ## 2|Événement modifié|« Concert Pq » : nouvelle date le 27/06 à 20h30 · nouveau lieu : Palais Pq, Bobo-Dioulasso.|/evenement/' || :'ev'
  || ' ## ''tikeo_event_' || :'ev' || ''' in topics|Événement modifié|« Concert Pq » : nouvelle date le 27/06 à 20h30 · nouveau lieu : Palais Pq, Bobo-Dioulasso.|/evenement/' || :'ev');
select coalesce(max(id), 0) as base from public.push_outbox \gset

-- Événement privé : seulement le détenteur ------------------------------------------
update public.events set city = 'Koudougou' where id = :'ev_priv';
select test.check('Événement privé : détenteur seulement',
  (select string_agg(right(user_id::text, 1) || '|' || body, ',') from public.push_outbox where id > :base),
  '3|“Privé Pq”: new place: Stade Pq, Koudougou.');
select coalesce(max(id), 0) as base from public.push_outbox \gset

-- Annulation par le promoteur ------------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-6500-0000-0000-000000000001');
select public.set_event_status(:'ev', 'cancelled') \gset ignored_
reset role;
select test.check('Annulé par le promoteur : détenteur, abonné, favoris',
  (select string_agg(coalesce(right(user_id::text, 1), 'favoris') || ':' || title, ',' order by id)
     from public.push_outbox where id > :base),
  '3:Event cancelled,2:Événement annulé,favoris:Événement annulé');
select coalesce(max(id), 0) as base from public.push_outbox \gset

-- Brouillon : rien -------------------------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-6500-0000-0000-000000000001');
select (public.create_event(:'org', 'Brouillon Pq', '2031-08-20 21:00+00',
                            '2031-08-21 01:00+00')).id as ev_draft \gset
reset role;
update public.events set venue = 'Ailleurs Pq' where id = :'ev_draft';
select test.check('Brouillon modifié : rien',
  (select count(*)::text from public.push_outbox where id > :base), '0');

set constraints public.events_notify_changes deferred;
