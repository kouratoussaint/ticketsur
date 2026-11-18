-- =============================================================================
-- TicketSûr — Tests : équipe (migration 0800, ORG-02, ORG-03, S16, S17)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('88888888-0000-0000-0000-000000000001', 'proprio-equipe@test.local'),
  ('88888888-0000-0000-0000-000000000002', 'gestion-equipe@test.local'),
  ('88888888-0000-0000-0000-000000000003', 'controle-equipe@test.local'),
  ('88888888-0000-0000-0000-000000000004', 'curieux-equipe@test.local'),
  ('88888888-0000-0000-0000-000000000005', 'devineur-equipe@test.local');

set role authenticated;
select test.login('88888888-0000-0000-0000-000000000001');
select (public.create_organization('Équipe Test')::jsonb)->>'id' as org \gset
select set_config('test.org', :'org', false) \gset ignored_

-- ------------------------------------------------------------ invitations
select public.create_invitation(:'org', 'manager') as inv_mgr \gset
select test.check('Code d''invitation au format TSI-XXXX-XXXX-XXXX',
  ((:'inv_mgr'::jsonb)->>'code' ~ '^TSI-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$')::text, 'true');
select test.check('Indice = 4 derniers caractères du code',
  (:'inv_mgr'::jsonb)->>'code_hint', right((:'inv_mgr'::jsonb)->>'code', 4));
select test.check('Aucun code en clair stocké',
  (select count(*) from public.organization_invitations_list(:'org')
   where code_hint = (:'inv_mgr'::jsonb)->>'code_hint')::text, '1');

-- Le gestionnaire rejoint avec un code saisi « à la main ».
select test.login('88888888-0000-0000-0000-000000000002');
select public.accept_invitation(lower(replace(substr((:'inv_mgr'::jsonb)->>'code', 5), '-', ' '))) as r \gset
select test.check('Code saisi en minuscules, espaces, sans préfixe : accepté',
  (:'r'::jsonb)->>'result', 'joined');
select test.check('Rôle de l''invitation attribué',
  (:'r'::jsonb)#>>'{organization,role}', 'manager');
select test.check('Code ressaisi par le nouveau membre : already_member',
  (public.accept_invitation((:'inv_mgr'::jsonb)->>'code'))->>'result', 'already_member');

do $$
begin
  perform public.create_invitation(current_setting('test.org')::uuid, 'manager');
  raise exception 'ÉCHEC  un gestionnaire a invité un gestionnaire';
exception when insufficient_privilege then
  raise notice 'OK    Gestionnaire : invitation de gestionnaire refusée';
end $$;
select public.create_invitation(:'org', 'controller', 3, 2) as inv_ctl \gset
select test.check('Gestionnaire : invitation de contrôleur (2 utilisations)',
  (:'inv_ctl'::jsonb)->>'max_uses', '2');

select test.login('88888888-0000-0000-0000-000000000003');
select test.check('Contrôleur : rejoint l''organisation',
  (public.accept_invitation((:'inv_ctl'::jsonb)->>'code'))->>'result', 'joined');
do $$
begin
  perform public.create_invitation(current_setting('test.org')::uuid, 'controller');
  raise exception 'ÉCHEC  un contrôleur a invité';
exception when insufficient_privilege then
  raise notice 'OK    Contrôleur : invitation refusée';
end $$;
do $$
begin
  perform * from public.organization_team(current_setting('test.org')::uuid);
  raise exception 'ÉCHEC  un contrôleur liste l''équipe';
exception when insufficient_privilege then
  raise notice 'OK    Contrôleur : liste de l''équipe refusée';
end $$;

-- Révocation, expiration, épuisement.
select test.login('88888888-0000-0000-0000-000000000001');
select public.create_invitation(:'org', 'controller') as inv_rev \gset
select public.revoke_invitation(((:'inv_rev'::jsonb)->>'id')::uuid) \gset ignored_
select public.create_invitation(:'org', 'controller') as inv_exp \gset
reset role;
update public.organization_invitations set expires_at = now() - interval '1 minute'
where id = ((:'inv_exp'::jsonb)->>'id')::uuid;
set role authenticated;
select test.check('Invitations utilisables : révoquée et expirée exclues',
  (select count(*) from public.organization_invitations_list(:'org'))::text, '1');

select test.login('88888888-0000-0000-0000-000000000004');
select test.check('Code révoqué → invalid',
  (public.accept_invitation((:'inv_rev'::jsonb)->>'code'))->>'result', 'invalid');
select test.check('Code expiré → expired',
  (public.accept_invitation((:'inv_exp'::jsonb)->>'code'))->>'result', 'expired');
select test.check('2e utilisation sur 2 → joined',
  (public.accept_invitation((:'inv_ctl'::jsonb)->>'code'))->>'result', 'joined');
select test.check('Code épuisé, ressaisi par celui qui l''a utilisé → already_member',
  (public.accept_invitation((:'inv_ctl'::jsonb)->>'code'))->>'result', 'already_member');

-- Limitation des essais : 10 échecs en 15 min bloquent même un code valide.
select test.login('88888888-0000-0000-0000-000000000001');
select public.create_invitation(:'org', 'controller') as inv_ok \gset
select test.login('88888888-0000-0000-0000-000000000005');
select test.check('Code épuisé (2/2) pour un nouveau venu → expired',
  (public.accept_invitation((:'inv_ctl'::jsonb)->>'code'))->>'result', 'expired');
select count(*) from (
  select public.accept_invitation('TSI-AAAA-AAAA-AAA' || n) from generate_series(1, 9) n
) x \gset ignored_
select test.check('Après 10 échecs : code valide refusé (rate_limited)',
  (public.accept_invitation((:'inv_ok'::jsonb)->>'code'))->>'result', 'rate_limited');
select test.login(null);
select test.check('Sans session : unauthorized',
  (public.accept_invitation((:'inv_ok'::jsonb)->>'code'))->>'result', 'unauthorized');

-- ------------------------------------------------------------ membres
select test.login('88888888-0000-0000-0000-000000000001');
select test.check('Équipe : 4 membres, propriétaire en tête, e-mails visibles',
  (select string_agg(role || ':' || email, ',' order by ord) from (
     select row_number() over () as ord, * from public.organization_team(:'org')) t),
  'owner:proprio-equipe@test.local,manager:gestion-equipe@test.local,controller:controle-equipe@test.local,controller:curieux-equipe@test.local');

select test.login('88888888-0000-0000-0000-000000000002');
do $$
declare v_org uuid := current_setting('test.org')::uuid;
begin
  begin
    perform public.update_member(v_org, '88888888-0000-0000-0000-000000000003', 'manager', true);
    raise exception 'ÉCHEC  un gestionnaire a promu un contrôleur';
  exception when insufficient_privilege then
    raise notice 'OK    Gestionnaire : promotion refusée';
  end;
  begin
    perform public.update_member(v_org, '88888888-0000-0000-0000-000000000001', 'controller', false);
    raise exception 'ÉCHEC  propriétaire modifié';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    Le propriétaire ne peut pas être modifié';
  end;
  begin
    perform public.update_member(v_org, '88888888-0000-0000-0000-000000000002', 'manager', false);
    raise exception 'ÉCHEC  auto-désactivation';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    Impossible de modifier son propre accès';
  end;
end $$;

-- ------------------------------------------------------------ affectations et ORG-03
select test.login('88888888-0000-0000-0000-000000000001');
select (public.create_event(:'org', 'Soirée équipe', now() + interval '1 hour',
                            now() + interval '6 hours')).id as evt \gset
select set_config('test.evt', :'evt', false) \gset ignored_
select (public.create_ticket_category(:'evt', 'Standard')).id as cat \gset
select (public.create_checkpoint(:'evt', 'Entrée')).id as cp \gset
select (public.create_checkpoint(:'evt', 'Coulisses')).id as cp2 \gset
select public.set_event_status(:'evt', 'published') \gset ignored_
create temp table team_tickets as select * from public.issue_tickets(:'evt', :'cat', 4);
select qr_token as t1 from team_tickets order by public_reference limit 1 offset 0 \gset
select qr_token as t2 from team_tickets order by public_reference limit 1 offset 1 \gset
select qr_token as t3 from team_tickets order by public_reference limit 1 offset 2 \gset
select qr_token as t4 from team_tickets order by public_reference limit 1 offset 3 \gset

do $$
declare v_evt uuid := current_setting('test.evt')::uuid;
begin
  begin
    perform public.assign_member(v_evt, '88888888-0000-0000-0000-000000000005');
    raise exception 'ÉCHEC  affectation d''un non-membre';
  exception when invalid_parameter_value then
    raise notice 'OK    Affectation d''un non-membre refusée';
  end;
  begin
    perform public.assign_member(v_evt, '88888888-0000-0000-0000-000000000003',
      'aaaaaaaa-0000-0000-0000-0000000000c1');
    raise exception 'ÉCHEC  porte d''un autre événement acceptée';
  exception when invalid_parameter_value then
    raise notice 'OK    Porte d''un autre événement refusée';
  end;
end $$;

select public.assign_member(:'evt', '88888888-0000-0000-0000-000000000003', :'cp') as asg \gset
select test.check('Affectation idempotente (même porte → même id)',
  (public.assign_member(:'evt', '88888888-0000-0000-0000-000000000003', :'cp'))::text, :'asg');
select test.check('event_team : contrôleur affecté à « Entrée »',
  (select email || '@' || checkpoint_name from public.event_team(:'evt')),
  'controle-equipe@test.local@Entrée');

select test.login('88888888-0000-0000-0000-000000000003');
select test.check('Contrôleur affecté : scan accepté à sa porte',
  (public.validate_scan('00000000-0000-4000-8000-0000000008a1', :'evt', :'cp', :'t1'))->>'result', 'accepted');
select test.check('Contrôleur affecté : autre porte refusée',
  (public.validate_scan('00000000-0000-4000-8000-0000000008a2', :'evt', :'cp2', :'t2'))->>'result', 'unauthorized');

-- ORG-03 : désactivation immédiate.
select test.login('88888888-0000-0000-0000-000000000002');
select public.update_member(:'org', '88888888-0000-0000-0000-000000000003', 'controller', false) \gset ignored_
select test.login('88888888-0000-0000-0000-000000000003');
select test.check('ORG-03 contrôleur désactivé : scan refusé au prochain appel',
  (public.validate_scan('00000000-0000-4000-8000-0000000008a3', :'evt', :'cp', :'t2'))->>'result', 'unauthorized');
select test.login('88888888-0000-0000-0000-000000000002');
select public.update_member(:'org', '88888888-0000-0000-0000-000000000003', 'controller', true) \gset ignored_
select test.login('88888888-0000-0000-0000-000000000003');
select test.check('Contrôleur réactivé : scan de nouveau accepté',
  (public.validate_scan('00000000-0000-4000-8000-0000000008a4', :'evt', :'cp', :'t2'))->>'result', 'accepted');

-- Retrait de l'affectation.
select test.login('88888888-0000-0000-0000-000000000001');
select public.unassign_member(:'asg') \gset ignored_
select test.check('Affectation retirée : plus listée',
  (select count(*) from public.event_team(:'evt'))::text, '0');
select test.login('88888888-0000-0000-0000-000000000003');
select test.check('Affectation retirée : scan refusé',
  (public.validate_scan('00000000-0000-4000-8000-0000000008a5', :'evt', :'cp', :'t3'))->>'result', 'unauthorized');

-- Toutes les portes.
select test.login('88888888-0000-0000-0000-000000000001');
select public.assign_member(:'evt', '88888888-0000-0000-0000-000000000003') \gset ignored_
select test.login('88888888-0000-0000-0000-000000000003');
select test.check('Affectation « toutes les portes » : Coulisses acceptée',
  (public.validate_scan('00000000-0000-4000-8000-0000000008a6', :'evt', :'cp2', :'t3'))->>'result', 'accepted');

-- Le propriétaire promeut, puis un ancien membre revient par invitation.
select test.login('88888888-0000-0000-0000-000000000001');
select public.update_member(:'org', '88888888-0000-0000-0000-000000000004', 'manager', false) \gset ignored_
select public.create_invitation(:'org', 'controller') as inv_back \gset
select test.login('88888888-0000-0000-0000-000000000004');
select test.check('Ancien membre désactivé : réintégré par invitation',
  (public.accept_invitation((:'inv_back'::jsonb)->>'code'))#>>'{organization,role}', 'controller');

-- Étranger : aucun accès.
select test.login('88888888-0000-0000-0000-000000000005');
do $$
begin
  perform * from public.event_team(current_setting('test.evt')::uuid);
  raise exception 'ÉCHEC  équipe d''événement lue par un étranger';
exception when insufficient_privilege then
  raise notice 'OK    Étranger : équipe de l''événement refusée';
end $$;
select test.check('Table des invitations inaccessible directement',
  (select has_table_privilege('authenticated', 'public.organization_invitations', 'select'))::text, 'false');

reset role;
drop table if exists team_tickets;
