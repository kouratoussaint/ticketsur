-- =============================================================================
-- TicketSûr — Tests : organisations en libre-service (migration 0500, ADR 0007)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('55555555-0000-0000-0000-000000000001', 'createur@test.local'),
  ('55555555-0000-0000-0000-000000000002', 'voisin@test.local'),
  ('55555555-0000-0000-0000-000000000003', 'desactive@test.local');
update public.profiles set status = 'disabled' where id = '55555555-0000-0000-0000-000000000003';

set role authenticated;
select test.login('55555555-0000-0000-0000-000000000001');

select test.check('Nouvel utilisateur : aucune organisation',
  (select count(*) from public.my_organizations())::text, '0');

select public.create_organization('  Nuits   Sacrées 2026 ') as org1 \gset
select test.check('Création : nom nettoyé', (:'org1'::jsonb)->>'name', 'Nuits Sacrées 2026');
select test.check('Création : slug sans accent', (:'org1'::jsonb)->>'slug', 'nuits-sacrees-2026');
select test.check('Création : rôle propriétaire', (:'org1'::jsonb)->>'role', 'owner');
select test.check('my_organizations renvoie l''organisation et le rôle',
  (select name || '|' || role from public.my_organizations()), 'Nuits Sacrées 2026|owner');

select public.create_organization('Nuits Sacrées 2026') as org2 \gset
select test.check('Même nom : slug distinct',
  ((:'org2'::jsonb)->>'slug' <> (:'org1'::jsonb)->>'slug'
   and (:'org2'::jsonb)->>'slug' like 'nuits-sacrees-2026-%')::text, 'true');

select test.check('Le propriétaire voit l''événementiel de son organisation (vide)',
  (select count(*) from public.events where organization_id = ((:'org1'::jsonb)->>'id')::uuid)::text, '0');

do $$
begin
  perform public.create_organization('A');
  raise exception 'ÉCHEC  nom d''un caractère accepté';
exception when invalid_parameter_value then
  raise notice 'OK    Nom trop court refusé';
end $$;

select public.create_organization('Org 3'), public.create_organization('Org 4'),
       public.create_organization('Org 5') \gset
do $$
begin
  perform public.create_organization('Org 6');
  raise exception 'ÉCHEC  6e organisation acceptée';
exception when configuration_limit_exceeded then
  raise notice 'OK    Limite de 5 organisations par propriétaire';
end $$;

-- Isolation : un autre utilisateur ne voit rien.
select test.login('55555555-0000-0000-0000-000000000002');
select test.check('Voisin : aucune organisation visible',
  (select count(*) from public.organizations where slug like 'nuits-sacrees-2026%')::text, '0');
select test.check('Voisin : my_organizations vide',
  (select count(*) from public.my_organizations())::text, '0');

-- Profil désactivé et visiteur anonyme : refus.
select test.login('55555555-0000-0000-0000-000000000003');
do $$
begin
  perform public.create_organization('Interdite');
  raise exception 'ÉCHEC  profil désactivé a créé une organisation';
exception when insufficient_privilege then
  raise notice 'OK    Profil désactivé : création refusée';
end $$;
select test.login(null);
do $$
begin
  perform public.create_organization('Anonyme');
  raise exception 'ÉCHEC  création sans session';
exception when insufficient_privilege then
  raise notice 'OK    Sans session : création refusée';
end $$;

reset role;
select test.check('Journal d''audit : 5 créations',
  (select count(*) from public.audit_logs a join public.organizations o on o.id = a.organization_id
   where a.action = 'organization.created' and o.owner_id = '55555555-0000-0000-0000-000000000001')::text, '5');
select test.check('Une seule ligne propriétaire par organisation créée',
  (select count(*) from public.organization_members m join public.organizations o on o.id = m.organization_id
   where o.owner_id = '55555555-0000-0000-0000-000000000001' and m.role = 'owner')::text, '5');

\echo 'OK    Tests des organisations verts.'
