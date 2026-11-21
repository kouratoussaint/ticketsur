-- =============================================================================
-- Tikéo — Tests : structures depuis la console, fermeture et corbeille
-- (migration 5000)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-5000-0000-0000-000000000001', 'super-structures@test.local', now()),
  ('aaaaaaaa-5000-0000-0000-000000000002', 'support-structures@test.local', now()),
  ('aaaaaaaa-5000-0000-0000-000000000003', 'moderation-structures@test.local', now()),
  ('aaaaaaaa-5000-0000-0000-000000000004', 'awa-structures@test.local', now()),
  ('aaaaaaaa-5000-0000-0000-000000000005', 'issa-structures@test.local', now()),
  ('aaaaaaaa-5000-0000-0000-000000000006', 'public-structures@test.local', now()),
  ('aaaaaaaa-5000-0000-0000-000000000007', 'nouveau-structures@test.local', now());
update public.profiles set is_platform_admin = true
 where id in ('aaaaaaaa-5000-0000-0000-000000000001', 'aaaaaaaa-5000-0000-0000-000000000002',
              'aaaaaaaa-5000-0000-0000-000000000003');
insert into private.platform_admin_roles (user_id, role) values
  ('aaaaaaaa-5000-0000-0000-000000000002', 'support'),
  ('aaaaaaaa-5000-0000-0000-000000000003', 'moderation');
insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at)
values ('bbbbbbbb-5000-0000-0000-000000000001', 'aaaaaaaa-5000-0000-0000-000000000001',
        'Tikéo structures', 'totp', 'verified', now(), now());
update private.console_settings s set value = 'false'::jsonb where s.key = 'notify_users';
select coalesce(max(id), 0) as base from public.push_outbox \gset

-- Une structure qui a servi (événement à venir avec tickets, événement passé)
-- et une structure vide, créées par Awa.
set role authenticated;
select test.login('aaaaaaaa-5000-0000-0000-000000000004');
select (public.create_organization('Kwabo Ferme Xq')::jsonb)->>'id' as org_close \gset
select (public.create_organization('Kwabo Vide Xq')::jsonb)->>'id' as org_empty \gset
select (public.create_event(:'org_close', 'Concert annulé Xq', now() + interval '5 days',
                            now() + interval '5 days 4 hours')).id as ev_next \gset
select (public.create_event(:'org_close', 'Gala passé Xq', now() + interval '6 days',
                            now() + interval '6 days 4 hours')).id as ev_past \gset
select (public.create_ticket_category(:'ev_next', 'Standard')).id as cat \gset
select test.complete_event(:'ev_next') \gset ignored_
select public.set_event_status(:'ev_next', 'published') \gset ignored_
select count(*) from public.issue_tickets(:'ev_next', :'cat', 3) \gset ignored_
select public.create_invitation(:'org_close', 'controller') \gset ignored_
reset role;
-- Événement passé ; un ticket entré ; deux tickets dans « Mes tickets ».
update public.events e set starts_at = now() - interval '10 days',
                           ends_at = now() - interval '9 days'
 where e.id = :'ev_past';
with picked as (select t.id from public.tickets t where t.event_id = :'ev_next' order by t.id limit 1)
update public.tickets t set status = 'redeemed', redeemed_at = now(),
       redeemed_by = 'aaaaaaaa-5000-0000-0000-000000000004', entries_used = 1
 where t.id in (select id from picked);
update public.tickets t set holder_user_id = 'aaaaaaaa-5000-0000-0000-000000000006'
 where t.event_id = :'ev_next' and t.status = 'issued';
insert into public.organization_members (organization_id, user_id, role) values
  (:'org_close', 'aaaaaaaa-5000-0000-0000-000000000005', 'manager');
set role authenticated;

-- Permissions ---------------------------------------------------------------------
select test.login('aaaaaaaa-5000-0000-0000-000000000003');
select test.expect_error('Modération : créer une structure refusé',
  $q$select public.admin_create_organization('aaaaaaaa-5000-0000-0000-000000000007', 'Xq', null, 'Motif')$q$,
  'admin_role_forbidden');
select test.check('Modération : fiche lisible',
  (public.admin_organization_detail(:'org_close')->>'name'), 'Kwabo Ferme Xq');

-- Création, modification, membres (support) ----------------------------------------
select test.login('aaaaaaaa-5000-0000-0000-000000000002');
select public.admin_create_organization('aaaaaaaa-5000-0000-0000-000000000007',
  '  Nouvelle   Structure Xq ', 'Bobo-Dioulasso', 'Contrat signé') as org_new \gset
reset role;
select test.check('Structure créée : propriétaire membre, ville',
  (select o.name || ':' || o.city || ':' || m.role
     from public.organizations o
     join public.organization_members m on m.organization_id = o.id and m.user_id = o.owner_id
    where o.id = :'org_new'),
  'Nouvelle Structure Xq:Bobo-Dioulasso:owner');
set role authenticated;
select test.login('aaaaaaaa-5000-0000-0000-000000000002');
select test.expect_error('Création : propriétaire inconnu',
  $q$select public.admin_create_organization('aaaaaaaa-5000-0000-0000-0000000000ff', 'Xq Xq', null, 'Motif')$q$,
  'account_not_found');
select test.expect_error('Création : motif obligatoire',
  $q$select public.admin_create_organization('aaaaaaaa-5000-0000-0000-000000000007', 'Xq Xq', null, '')$q$,
  'reason_required');

select test.check('Modification : champs changés',
  (public.admin_update_organization(:'org_close', 'Kwabo Ferme Xq', 'Ouagadougou',
     '70 11 22 33', null, '70 44 55 66', 'Demande au support')->'fields')::text,
  '["city", "phone", "public_phone"]');
select test.check('Modification : numéros au format international',
  (select (d->>'phone') || ':' || (d->>'public_phone')
     from public.admin_organization_detail(:'org_close') d),
  '+22670112233:+22670445566');
select test.expect_error('Modification : téléphone invalide',
  $q$select public.admin_update_organization('$q$ || :'org_close' || $q$', 'Kwabo Ferme Xq', null, '12', null, null, 'Motif')$q$,
  'org_phone_invalid');

select test.expect_error('Membre : le propriétaire ne se modifie pas',
  $q$select public.admin_set_member_role('$q$ || :'org_close' || $q$', 'aaaaaaaa-5000-0000-0000-000000000004', 'manager', 'Motif')$q$,
  'member_is_owner');
select public.admin_set_member_role(:'org_close', 'aaaaaaaa-5000-0000-0000-000000000005',
  'controller', 'Changement d''équipe', true) \gset ignored_
reset role;
select test.check('Membre : rôle changé, personne prévenue à sa demande',
  (select m.role::text || ':' ||
          (select count(*) from public.push_outbox o
            where o.id > :base and o.user_id = 'aaaaaaaa-5000-0000-0000-000000000005'
              and o.title = 'Rôle modifié')
     from public.organization_members m
    where m.organization_id = :'org_close' and m.user_id = 'aaaaaaaa-5000-0000-0000-000000000005'),
  'controller:1');
set role authenticated;
select test.login('aaaaaaaa-5000-0000-0000-000000000002');
select public.admin_remove_member(:'org_close', 'aaaaaaaa-5000-0000-0000-000000000005',
  'Départ') \gset ignored_
select test.expect_error('Membre retiré : plus modifiable',
  $q$select public.admin_set_member_role('$q$ || :'org_close' || $q$', 'aaaaaaaa-5000-0000-0000-000000000005', 'manager', 'Motif')$q$,
  'member_not_found');
select (public.admin_organization_detail(:'org_close')->'invitations'->0->>'id') as inv \gset
select public.admin_revoke_invitation(:'inv', 'Code diffusé par erreur') \gset ignored_

select test.check('Fiche : membres, invitations, événements, tickets, historique',
  (select (d->'members'->0->>'role') || ':' || jsonb_array_length(d->'members') || ':'
          || jsonb_array_length(d->'invitations') || ':' || (d->>'events_total') || ':'
          || (d->>'events_upcoming') || ':' || (d->>'tickets_issued') || ':'
          || (d->>'tickets_admitted') || ':' || jsonb_array_length(d->'actions')
     from public.admin_organization_detail(:'org_close') d),
  'owner:2:0:2:1:3:1:1');

-- Supprimer : réservé au super administrateur avec double authentification --------
select test.expect_error('Support : supprimer refusé',
  $q$select public.admin_delete_organization('$q$ || :'org_close' || $q$', 'Kwabo Ferme Xq', 'Motif')$q$,
  'admin_role_forbidden');
select set_config('request.jwt.claims',
  jsonb_build_object('sub', 'aaaaaaaa-5000-0000-0000-000000000001', 'role', 'authenticated',
                     'aal', 'aal2')::text, false) \gset ignored_
select test.check('Aperçu : fermeture, 1 événement, 2 tickets, 1 détenteur',
  (select (p->>'mode') || ':' || (p->>'events_to_cancel') || ':' || (p->>'tickets_to_cancel')
          || ':' || (p->>'holders_to_notify')
     from public.admin_organization_delete_preview(:'org_close') p),
  'close:1:2:1');
select test.expect_error('Suppression : nom à recopier',
  $q$select public.admin_delete_organization('$q$ || :'org_close' || $q$', 'Kwabo', 'Motif')$q$,
  'confirmation_mismatch');
select test.check('Fermeture : événements annulés et archivés, tickets annulés, détenteur prévenu',
  (select (r->>'mode') || ':' || (r->>'events_cancelled') || ':' || (r->>'events_archived')
          || ':' || (r->>'tickets_cancelled') || ':' || (r->>'holders_notified')
     from public.admin_delete_organization(:'org_close', ' kwabo ferme xq ',
                                           'Fraude avérée, dossier 12') r),
  'close:1:1:2:1');
reset role;
select test.check('Fermeture : structure suspendue pour toujours, états des événements',
  (select o.status || ':' || (o.closed_at is not null) || ':'
          || (select string_agg(e.status::text, ',' order by e.title)
                from public.events e where e.organization_id = o.id)
     from public.organizations o where o.id = :'org_close'),
  'disabled:true:cancelled,archived');
select test.check('Fermeture : ticket entré gardé, les autres annulés',
  (select string_agg(t.status::text, ',' order by t.status)
     from public.tickets t where t.event_id = :'ev_next'),
  'redeemed,revoked,revoked');
select test.check('Fermeture : un message au détenteur, dans sa langue',
  (select count(*)::text from public.push_outbox o
    where o.id > :base and o.user_id = 'aaaaaaaa-5000-0000-0000-000000000006'
      and o.title = 'Événement annulé' and o.body like '%Concert annulé Xq%'),
  '1');
set role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub', 'aaaaaaaa-5000-0000-0000-000000000001', 'role', 'authenticated',
                     'aal', 'aal2')::text, false) \gset ignored_
select test.expect_error('Structure fermée : réactivation refusée',
  $q$select public.admin_set_organization_status('$q$ || :'org_close' || $q$', 'active')$q$,
  'organization_closed');
select test.expect_error('Structure fermée : aucun nouveau membre',
  $q$select public.admin_assign_organization('aaaaaaaa-5000-0000-0000-000000000005', '$q$ || :'org_close' || $q$', 'manager', 'Motif')$q$,
  'organization_closed');
select test.expect_error('Structure fermée : modification refusée',
  $q$select public.admin_update_organization('$q$ || :'org_close' || $q$', 'Autre nom', null, null, null, null, 'Motif')$q$,
  'organization_closed');

-- Corbeille ------------------------------------------------------------------------
select test.check('Structure vide : à la corbeille',
  (public.admin_delete_organization(:'org_empty', 'Kwabo Vide Xq', 'Doublon')->>'mode'), 'trash');
select test.check('Corbeille : la structure y est, plus dans la liste',
  (select (exists (select 1 from jsonb_array_elements(public.admin_trash()) x
                    where x->>'id' = :'org_empty'))::text || ':'
          || (select count(*) from public.admin_organizations('Kwabo Vide Xq', null, 10, 0))),
  'true:0');
select test.login('aaaaaaaa-5000-0000-0000-000000000002');
select public.admin_restore_organization(:'org_empty', 'Supprimée par erreur') \gset ignored_
reset role;
select test.check('Restaurée par le support : active, hors de la corbeille',
  (select o.status || ':' || (o.trashed_at is null) from public.organizations o
    where o.id = :'org_empty'),
  'active:true');
set role authenticated;
select test.login('aaaaaaaa-5000-0000-0000-000000000002');
select test.expect_error('Restaurer une structure hors corbeille',
  $q$select public.admin_restore_organization('$q$ || :'org_empty' || $q$', 'Motif')$q$,
  'organization_not_trashed');
select set_config('request.jwt.claims',
  jsonb_build_object('sub', 'aaaaaaaa-5000-0000-0000-000000000001', 'role', 'authenticated',
                     'aal', 'aal2')::text, false) \gset ignored_
select public.admin_delete_organization(:'org_empty', 'Kwabo Vide Xq', 'Doublon') \gset ignored_
select public.admin_purge_organization_now(:'org_empty', 'Kwabo Vide Xq', 'Demande du propriétaire')
  \gset ignored_
reset role;
select test.check('Effacée : anonymisée, sans membre',
  (select o.name || ':' || (o.purged_at is not null) || ':'
          || (select count(*) from public.organization_members m where m.organization_id = o.id)
     from public.organizations o where o.id = :'org_empty'),
  'Structure supprimée:true:0');

-- Effacement automatique après 30 jours.
set role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub', 'aaaaaaaa-5000-0000-0000-000000000001', 'role', 'authenticated',
                     'aal', 'aal2')::text, false) \gset ignored_
select public.admin_delete_organization(:'org_new', 'Nouvelle Structure Xq', 'Jamais utilisée')
  \gset ignored_
reset role;
update public.organizations o set trashed_at = now() - interval '31 days' where o.id = :'org_new';
select (private.purge_due_organizations() >= 1) as purged_some \gset
select test.check('Tâche : corbeille de plus de 30 jours effacée',
  :'purged_some' || ':' || (select (o.purged_at is not null)::text from public.organizations o
                              where o.id = :'org_new'),
  't:true');

-- Journal ---------------------------------------------------------------------------
select test.check('Journal sans motif ; motifs à part',
  (select bool_and(a.details::text not like '%Fraude%' and a.details::text not like '%Doublon%')::text
          || ':' || (select count(*) from private.admin_action_log l
                      where l.target_id in (:'org_close', :'org_empty', :'org_new'))
     from public.audit_logs a
    where a.organization_id in (:'org_close', :'org_empty', :'org_new')),
  'true:9');
select test.check('Aucun paramètre personnalisé attaché à une fonction (migration 5000)',
  (select count(*)::text
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
     cross join lateral unnest(p.proconfig) as c(setting)
    where n.nspname in ('public', 'private')
      and split_part(c.setting, '=', 1) like '%.%'),
  '0');
