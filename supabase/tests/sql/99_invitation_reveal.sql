-- =============================================================================
-- Tikéo — Tests : code d'invitation affichable (migration 4100)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-4100-0000-0000-000000000001', 'proprio-code@test.local'),
  ('aaaaaaaa-4100-0000-0000-000000000002', 'gestion-code@test.local'),
  ('aaaaaaaa-4100-0000-0000-000000000003', 'controle-code@test.local'),
  ('aaaaaaaa-4100-0000-0000-000000000004', 'curieux-code@test.local');
update public.profiles set display_name = 'Awa Proprio'
 where id = 'aaaaaaaa-4100-0000-0000-000000000001';
update public.profiles set display_name = 'Issa Contrôle'
 where id = 'aaaaaaaa-4100-0000-0000-000000000003';

set role authenticated;
select test.login('aaaaaaaa-4100-0000-0000-000000000001');
select (public.create_organization('Studio Code Qzv')::jsonb)->>'id' as org \gset
select public.create_invitation(:'org', 'controller', 7, 2) as inv \gset
select (:'inv'::jsonb)->>'id' as inv_id \gset
select (:'inv'::jsonb)->>'code' as inv_code \gset

reset role;
select test.check('Copie chiffrée gardée, jamais le code en clair',
  (select (code_ciphertext is not null)::text || ':'
          || (position(:'inv_code' in encode(code_ciphertext, 'escape')) = 0)::text
     from public.organization_invitations where id = :'inv_id'),
  'true:true');
set role authenticated;
select test.login('aaaaaaaa-4100-0000-0000-000000000001');

select test.check('Propriétaire : code réaffiché à l''identique',
  public.reveal_invitation_code(:'inv_id'), :'inv_code');

select test.check('Détails : état, structure, auteur, utilisations',
  (select (d->>'state') || ':' || (d->>'organization_name') || ':' || (d->>'created_by_name')
          || ':' || (d->>'uses') || '/' || (d->>'max_uses') || ':' || (d->>'code_available')
     from (select public.invitation_details(:'inv_id') as d) x),
  'active:Studio Code Qzv:Awa Proprio:0/2:true');

-- Un contrôleur rejoint : il apparaît dans les détails.
select test.login('aaaaaaaa-4100-0000-0000-000000000003');
select (public.accept_invitation(:'inv_code'))->>'result' as r \gset
select test.check('Code réaffiché toujours valable', :'r', 'joined');
select test.expect_error('Un contrôleur ne voit pas le code',
  format($q$select public.reveal_invitation_code(%L)$q$, :'inv_id'), 'invitation_not_found');
select test.login('aaaaaaaa-4100-0000-0000-000000000004');
select test.expect_error('Un étranger ne voit pas les détails',
  format($q$select public.invitation_details(%L)$q$, :'inv_id'), 'invitation_not_found');

select test.login('aaaaaaaa-4100-0000-0000-000000000001');
select test.check('Détails : personnes qui l''ont utilisée',
  (select (d->'used_by'->0->>'name') || ':' || (d->>'uses')
     from (select public.invitation_details(:'inv_id') as d) x),
  'Issa Contrôle:1');

-- Révoquée : plus de code.
select public.revoke_invitation(:'inv_id') \gset ignored_
select test.expect_error('Invitation révoquée : code non affiché',
  format($q$select public.reveal_invitation_code(%L)$q$, :'inv_id'), 'invitation_inactive');
select test.check('Invitation révoquée : état',
  (public.invitation_details(:'inv_id'))->>'state', 'revoked');

-- Invitation créée avant ce changement : pas de copie chiffrée.
select public.create_invitation(:'org', 'manager') as inv_old \gset
select (:'inv_old'::jsonb)->>'id' as old_id \gset
reset role;
update public.organization_invitations set code_ciphertext = null where id = :'old_id';
set role authenticated;
select test.login('aaaaaaaa-4100-0000-0000-000000000001');
select test.expect_error('Ancienne invitation : code non récupérable',
  format($q$select public.reveal_invitation_code(%L)$q$, :'old_id'), 'invitation_code_unavailable');
select test.check('Ancienne invitation : signalée dans les détails',
  (public.invitation_details(:'old_id'))->>'code_available', 'false');

reset role;
select test.check('Journal : affichage inscrit, sans le code',
  (select count(*)::text || ':' || bool_and(details = '{}'::jsonb)::text
     from public.audit_logs
    where action = 'invitation.code_revealed' and resource_id = :'inv_id'),
  '1:true');

-- Limite : 30 affichages par heure.
insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id)
select :'org', 'aaaaaaaa-4100-0000-0000-000000000001', 'invitation.code_revealed', 'invitation',
       :'inv_id'
  from generate_series(1, 30);
set role authenticated;
select test.login('aaaaaaaa-4100-0000-0000-000000000001');
select public.create_invitation(:'org', 'controller') as inv_new \gset
select test.expect_error('Trop d''affichages : limité',
  format($q$select public.reveal_invitation_code(%L)$q$, (:'inv_new'::jsonb)->>'id'),
  'invitation_reveal_limited');
