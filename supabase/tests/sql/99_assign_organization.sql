-- =============================================================================
-- Tikéo — Tests : attribuer une structure à un compte (migration 4200)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-4200-0000-0000-000000000001', 'admin-attribution@test.local'),
  ('aaaaaaaa-4200-0000-0000-000000000002', 'proprio-attribution@test.local'),
  ('aaaaaaaa-4200-0000-0000-000000000003', 'nouveau-attribution@test.local'),
  ('aaaaaaaa-4200-0000-0000-000000000004', 'equipe-attribution@test.local'),
  ('aaaaaaaa-4200-0000-0000-000000000005', 'inactif-attribution@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-4200-0000-0000-000000000001';
update public.profiles set locale = 'en'
 where id = 'aaaaaaaa-4200-0000-0000-000000000003';
update public.profiles set status = 'disabled', disabled_at = now(), disabled_reason = 'test'
 where id = 'aaaaaaaa-4200-0000-0000-000000000005';

set role authenticated;
select test.login('aaaaaaaa-4200-0000-0000-000000000002');
select (public.create_organization('Studio Attribution Kpw')::jsonb)->>'id' as org \gset

-- Seul un administrateur de la plateforme attribue.
select test.expect_error('Un promoteur ne peut pas attribuer',
  format($q$select public.admin_assign_organization(%L, %L, 'manager', 'Essai')$q$,
         'aaaaaaaa-4200-0000-0000-000000000004', :'org'), 'forbidden');

select test.login('aaaaaaaa-4200-0000-0000-000000000001');
select test.expect_error('Motif obligatoire',
  format($q$select public.admin_assign_organization(%L, %L, 'manager', '  ')$q$,
         'aaaaaaaa-4200-0000-0000-000000000004', :'org'), 'reason_required');
select test.expect_error('Compte désactivé refusé',
  format($q$select public.admin_assign_organization(%L, %L, 'manager', 'Aide')$q$,
         'aaaaaaaa-4200-0000-0000-000000000005', :'org'), 'account_inactive');
select test.expect_error('Structure inconnue',
  format($q$select public.admin_assign_organization(%L, %L, 'manager', 'Aide')$q$,
         'aaaaaaaa-4200-0000-0000-000000000004', gen_random_uuid()), 'organization_not_found');
select test.expect_error('Le propriétaire ne peut pas être rétrogradé sans transfert',
  format($q$select public.admin_assign_organization(%L, %L, 'controller', 'Aide')$q$,
         'aaaaaaaa-4200-0000-0000-000000000002', :'org'), 'owner_role_locked');
select test.expect_error('Déjà propriétaire',
  format($q$select public.admin_assign_organization(%L, %L, 'owner', 'Aide')$q$,
         'aaaaaaaa-4200-0000-0000-000000000002', :'org'), 'already_owner');

-- Gestionnaire, puis contrôleur : même ligne, rôle changé.
select public.admin_assign_organization('aaaaaaaa-4200-0000-0000-000000000004', :'org',
  'manager', 'Demande du promoteur par téléphone') \gset ignored_
select public.admin_assign_organization('aaaaaaaa-4200-0000-0000-000000000004', :'org',
  'controller', 'Correction') \gset ignored_
select test.check('Rôle changé sur la même appartenance',
  (select string_agg(role::text || ':' || active::text, ',')
     from public.admin_account_structures('aaaaaaaa-4200-0000-0000-000000000004')),
  'controller:true');

-- Transfert : nouveau propriétaire, l'ancien devient gestionnaire.
select public.admin_assign_organization('aaaaaaaa-4200-0000-0000-000000000003', :'org',
  'owner', 'Cession de la structure') as res \gset
select test.check('Transfert : ancien propriétaire renvoyé',
  (:'res'::jsonb)->>'previous_owner_id', 'aaaaaaaa-4200-0000-0000-000000000002');
reset role;
select test.check('Transfert : propriétaire de la structure changé',
  (select owner_id::text from public.organizations where id = :'org'),
  'aaaaaaaa-4200-0000-0000-000000000003');
select test.check('Transfert : rôles de l''équipe',
  (select string_agg(right(user_id::text, 1) || '=' || role::text, ',' order by user_id)
     from public.organization_members where organization_id = :'org' and active),
  '2=manager,3=owner,4=controller');
select test.check('Motif gardé à part, pas dans le journal',
  (select count(*)::text from private.organization_assignments where organization_id = :'org')
  || ':' ||
  (select count(*)::text from public.audit_logs
    where organization_id = :'org' and action = 'admin.organization_assigned'
      and details::text not like '%Cession%' and details ? 'role' and details ? 'transfer'),
  '3:3');
select test.check('Notifications : nouveau propriétaire (anglais) et ancien',
  (select string_agg(title, ' | ' order by id) from public.push_outbox
    where user_id in ('aaaaaaaa-4200-0000-0000-000000000003', 'aaaaaaaa-4200-0000-0000-000000000002')
      and route = '/profil'),
  'New organization | Structure transférée');
set role authenticated;

-- Le nouveau propriétaire gère la structure.
select test.login('aaaaaaaa-4200-0000-0000-000000000003');
select test.check('Le nouveau propriétaire voit son rôle',
  (select role::text from public.organization_members
    where organization_id = :'org' and user_id = auth.uid()), 'owner');

-- Quota du pack : transfert refusé au-delà du nombre de structures.
select test.login('aaaaaaaa-4200-0000-0000-000000000004');
select (public.create_organization('Seconde Attribution Kpw')::jsonb)->>'id' as org2 \gset
reset role;
insert into public.billing_pack_options (pack_id, option_key, included)
select p.id, 'structures', 1 from public.billing_packs p where p.code = 'decouverte';
set role authenticated;
select test.login('aaaaaaaa-4200-0000-0000-000000000001');
select test.expect_error('Transfert refusé au-delà du quota de structures du pack',
  format($q$select public.admin_assign_organization(%L, %L, 'owner', 'Cession')$q$,
         'aaaaaaaa-4200-0000-0000-000000000003', :'org2'), 'billing_limit_structures');
select test.check('Transfert refusé : rien n''a changé',
  (select string_agg(organization_id::text || role::text, ',')
     from public.admin_account_structures('aaaaaaaa-4200-0000-0000-000000000003')
    where organization_id = :'org2'), null);
reset role;
delete from public.billing_pack_options o
 using public.billing_packs p
 where o.pack_id = p.id and p.code = 'decouverte' and o.option_key = 'structures';
set role authenticated;
select test.login('aaaaaaaa-4200-0000-0000-000000000001');
select test.check('Structures d''un compte : liste lisible par l''administrateur',
  (select count(*)::text from public.admin_account_structures('aaaaaaaa-4200-0000-0000-000000000002')),
  '1');
select test.login('aaaaaaaa-4200-0000-0000-000000000004');
select test.expect_error('Liste réservée à l''administrateur',
  $q$select * from public.admin_account_structures('aaaaaaaa-4200-0000-0000-000000000002')$q$,
  'forbidden');
reset role;
