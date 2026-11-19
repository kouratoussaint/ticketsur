-- =============================================================================
-- Tikéo — Tests : catalogue public (migration 1800)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-1800-0000-0000-000000000001', 'proprio-catalogue@test.local'),
  ('aaaaaaaa-1800-0000-0000-000000000002', 'curieux-catalogue@test.local');

set role authenticated;
select test.login('aaaaaaaa-1800-0000-0000-000000000001');
select (public.create_organization('Zébra Productions')::jsonb)->>'id' as org \gset

-- Trois événements, mot-clé commun « Qwyz » pour ne voir que les nôtres sur
-- le staging (d'autres événements publics peuvent y exister).
select (public.create_event(:'org', 'Concert Qwyz à Bobo', now() + interval '2 days',
                            now() + interval '2 days 4 hours')).id as e_pub \gset
select (public.create_event(:'org', 'Séminaire Qwyz privé', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as e_priv \gset
select (public.create_event(:'org', 'Brouillon Qwyz public', now() + interval '4 days',
                            now() + interval '4 days 4 hours')).id as e_draft \gset
reset role;
update public.events set kind = 'concert', city = 'Bobo-Dioulasso',
       description = 'Une soirée en plein air.' where id = :'e_pub';
update public.events set kind = 'conference' where id = :'e_priv';
set role authenticated;
select test.login('aaaaaaaa-1800-0000-0000-000000000001');

select (public.create_ticket_category(:'e_pub', 'Standard')).id as c_std \gset
select (public.create_ticket_category(:'e_pub', 'VIP')).id as c_vip \gset
select (public.create_ticket_category(:'e_pub', 'Invités', null, true)).id as c_inv \gset
select test.complete_event(:'e_pub') \gset ignored_
select test.complete_event(:'e_priv') \gset ignored_
select public.set_event_status(:'e_pub', 'published') \gset ignored_
select public.set_event_status(:'e_priv', 'published') \gset ignored_

select test.check('Visibilité : privé par défaut',
  (select is_public::text from public.events where id = :'e_pub'), 'false');
select (public.set_event_public(:'e_pub', true)).is_public::text as pub \gset
select test.check('Visibilité : rendu public', :'pub', 'true');
select public.set_event_public(:'e_draft', true) \gset ignored_
select test.check('Visibilité journalisée sans contenu',
  (select details::text from public.audit_logs
   where resource_id = :'e_pub' and action = 'event.visibility_changed'),
  '{"public": true}');

select (public.set_category_price(:'c_std', 2000)).indicative_price::text as p1 \gset
select public.set_category_price(:'c_vip', 10000) \gset ignored_
select test.check('Prix indicatif enregistré', :'p1', '2000');
select test.check('Prix visible dans la liste des catégories',
  (select string_agg(name || ':' || coalesce(indicative_price::text, '∅'), ',' order by name)
   from public.event_categories(:'e_pub')),
  'Invités:∅,Standard:2000,VIP:10000');

select (public.set_organization_public_phone(:'org', '70 11 22 33')).public_phone as ph \gset
select test.check('Numéro public normalisé', :'ph', '+22670112233');
select test.check('Numéro public absent du journal',
  (select details::text from public.audit_logs
   where resource_id = :'org' and action = 'organization.public_phone_changed'),
  '{"removed": false}');
select test.check('Numéro public dans mes organisations',
  (select public_phone from public.my_organizations() where id = :'org'), '+22670112233');

do $$
begin
  begin
    perform public.set_category_price(
      (select id from public.ticket_categories where name = 'Standard'
         and event_id in (select id from public.events where title like 'Concert Qwyz%')), -5);
    raise exception 'ÉCHEC  prix négatif accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Prix négatif refusé (category_price_invalid)';
  end;
end $$;

-- Un autre compte ne peut rien changer.
select test.login('aaaaaaaa-1800-0000-0000-000000000002');
do $$
begin
  begin
    perform public.set_event_public(
      (select id from public.events where title = 'Concert Qwyz à Bobo'), false);
    raise exception 'ÉCHEC  visibilité modifiée par un inconnu';
  exception when insufficient_privilege then
    raise notice 'OK    Visibilité réservée aux organisateurs';
  end;
end $$;

-- Lecture sans compte -----------------------------------------------------------
reset role;
select test.login(null);
set role anon;
select coalesce(string_agg(title, ',' order by starts_at), '∅') as anon_all
  from public.public_events('qwyz') \gset
select coalesce(string_agg(title, ',' order by starts_at), '∅') as anon_accent
  from public.public_events('CONCERT QWYZ A BOBO') \gset
select coalesce(string_agg(title, ','), '∅') as anon_kind
  from public.public_events('qwyz', array['conference']::public.event_kind[]) \gset
select coalesce(string_agg(title, ','), '∅') as anon_city
  from public.public_events('qwyz', null, 'bobo-dioulasso') \gset
select coalesce(string_agg(title, ','), '∅') as anon_other_city
  from public.public_events('qwyz', null, 'Ouagadougou') \gset
select coalesce(string_agg(title, ','), '∅') as anon_free
  from public.public_events('qwyz', null, null, null, null, true) \gset
select coalesce(string_agg(title, ','), '∅') as anon_late
  from public.public_events('qwyz', null, null, now() + interval '10 days') \gset
select string_agg(organization_name || '|' || city || '|' || min_price, ',') as anon_fields
  from public.public_events('qwyz') \gset
select public.public_event(:'e_pub')::text as anon_detail \gset
do $$
begin
  begin
    perform public.public_event((select id from public.events where title = 'Séminaire Qwyz privé'));
    raise exception 'ÉCHEC  événement privé visible';
  exception when insufficient_privilege then
    raise notice 'OK    Fiche d''un événement privé refusée sans compte';
  end;
end $$;
do $$
begin
  begin
    perform 1 from public.event_categories((select id from public.events where title = 'Concert Qwyz à Bobo'));
    raise exception 'ÉCHEC  catégories organisateur lues sans compte';
  exception when insufficient_privilege then
    raise notice 'OK    Lectures organisateur fermées sans compte';
  end;
end $$;
reset role;

select test.check('Sans compte : seul l''événement public et publié', :'anon_all', 'Concert Qwyz à Bobo');
select test.check('Recherche sans casse ni accents', :'anon_accent', 'Concert Qwyz à Bobo');
select test.check('Filtre de catégorie (privé jamais listé)', :'anon_kind', '∅');
select test.check('Filtre de ville sans casse', :'anon_city', 'Concert Qwyz à Bobo');
select test.check('Autre ville : rien', :'anon_other_city', '∅');
select test.check('Entrée gratuite : rien (prix 2000 et 10000)', :'anon_free', '∅');
select test.check('Après la date de l''événement : rien', :'anon_late', '∅');
select test.check('Champs de vitrine', :'anon_fields', 'Zébra Productions|Bobo-Dioulasso|2000');
select test.check('Fiche : catégories sans les invitations, avec prix',
  (select (:'anon_detail'::jsonb)->'categories')::text,
  '[{"name": "Standard", "indicative_price": 2000}, {"name": "VIP", "indicative_price": 10000}]');
select test.check('Fiche : numéro public de l''organisation',
  (:'anon_detail'::jsonb)->'organization'->>'public_phone', '+22670112233');
select test.check('Fiche : aucun champ de ticket ni de chiffre',
  (select count(*)::text from jsonb_object_keys(:'anon_detail'::jsonb) k
   where k in ('tickets', 'issued', 'redeemed', 'capacity', 'organization_id', 'created_by')), '0');

-- Retiré du public : disparaît du catalogue.
set role authenticated;
select test.login('aaaaaaaa-1800-0000-0000-000000000001');
select public.set_event_public(:'e_pub', false) \gset ignored_
reset role;
select test.login(null);
set role anon;
select coalesce(string_agg(title, ','), '∅') as anon_after from public.public_events('qwyz') \gset
reset role;
select test.check('Retiré du public : plus listé', :'anon_after', '∅');
