-- =============================================================================
-- Tikéo — Tests : double authentification des administrateurs (migration 4800)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-4800-0000-0000-000000000001', 'admin-mfa@test.local'),
  ('aaaaaaaa-4800-0000-0000-000000000002', 'promoteur-mfa@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-4800-0000-0000-000000000001';

-- Sans facteur : console ouverte comme avant.
set role authenticated;
select test.login('aaaaaaaa-4800-0000-0000-000000000001');
select test.check('Sans facteur : console ouverte, état lu',
  (select (public.admin_overview() is not null)::text || ':' || (s->>'enrolled') || ':' || (s->>'aal')
     from public.admin_mfa_status() s),
  'true:false:aal1');
select test.expect_error('Codes sans facteur : refusés',
  $q$select public.admin_generate_recovery_codes()$q$, 'mfa_not_enrolled');

-- Facteur vérifié : la console exige une session aal2.
reset role;
insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at)
values ('bbbbbbbb-4800-0000-0000-000000000001', 'aaaaaaaa-4800-0000-0000-000000000001',
        'Tikéo test', 'totp', 'verified', now(), now());
set role authenticated;
select test.login('aaaaaaaa-4800-0000-0000-000000000001');
select test.expect_error('Facteur sans code (aal1) : console refusée',
  $q$select public.admin_overview()$q$, 'mfa_required');
select test.check('aal1 : entrée « Console » toujours visible, état enrôlé',
  (select public.is_platform_admin()::text || ':' || (s->>'enrolled') from public.admin_mfa_status() s),
  'true:true');

-- Session aal2 : console et codes de secours.
select set_config('request.jwt.claims',
  jsonb_build_object('sub', 'aaaaaaaa-4800-0000-0000-000000000001', 'role', 'authenticated',
                     'aal', 'aal2')::text, false) \gset ignored_
select test.check('aal2 : console ouverte',
  (public.admin_overview() is not null)::text, 'true');
create temp table codes as select unnest(public.admin_generate_recovery_codes()) as code;
select test.check('8 codes XXXXX-XXXXX, gardés en empreinte seulement',
  (select count(*) || ':' || bool_and(c.code ~ '^[A-HJ-KM-NP-Z2-9]{5}-[A-HJ-KM-NP-Z2-9]{5}$')
     from codes c),
  '8:true');
select test.check('Codes restants',
  (select s->>'recovery_codes_left' from public.admin_mfa_status() s), '8');
select min(code) as one_code from codes \gset

-- Retour à aal1 : un mauvais code, puis un bon code (minuscules, sans tiret).
select test.login('aaaaaaaa-4800-0000-0000-000000000001');
select test.check('Mauvais code de secours : refusé, facteur gardé',
  (select public.admin_use_recovery_code('AAAAA-AAAAA')::text || ':'
          || (s->>'enrolled') from public.admin_mfa_status() s),
  'false:true');
select test.check('Bon code (minuscules, sans tiret) accepté',
  public.admin_use_recovery_code(lower(replace(:'one_code', '-', '')))::text, 'true');
select test.check('Code de secours : facteur retiré, console rouverte à aal1',
  (select (s->>'enrolled') || ':' || (s->>'recovery_codes_left') || ':'
          || (public.admin_overview() is not null)::text
     from public.admin_mfa_status() s),
  'false:0:true');

-- Trop d'essais.
reset role;
insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at)
values ('bbbbbbbb-4800-0000-0000-000000000002', 'aaaaaaaa-4800-0000-0000-000000000001',
        'Tikéo test 2', 'totp', 'verified', now(), now());
insert into private.admin_recovery_attempts (user_id)
select 'aaaaaaaa-4800-0000-0000-000000000001' from generate_series(1, 2);
set role authenticated;
select test.login('aaaaaaaa-4800-0000-0000-000000000001');
-- Déjà 4 essais dans l'heure (2 ci-dessus, 2 posés) : un cinquième, puis refus.
select test.check('Cinquième essai encore permis (code faux)',
  public.admin_use_recovery_code('BBBBB-BBBBB')::text, 'false');
select test.expect_error('Sixième essai dans l''heure : refusé',
  $q$select public.admin_use_recovery_code('BBBBB-BBBBB')$q$, 'recovery_rate_limited');

-- Autres comptes.
select test.login('aaaaaaaa-4800-0000-0000-000000000002');
select test.expect_error('Promoteur : état refusé',
  $q$select public.admin_mfa_status()$q$, 'forbidden');

reset role;
select test.check('Journal : codes générés et secours, sans code',
  (select string_agg(a.action || ':' || a.details::text, ',' order by a.action)
     from public.audit_logs a
    where a.actor_id = 'aaaaaaaa-4800-0000-0000-000000000001' and a.action like 'admin.mfa_%'),
  'admin.mfa_codes_generated:{"count": 8},admin.mfa_recovered:{}');
select test.check('Codes de secours inaccessibles à l''API',
  (has_table_privilege('authenticated', 'private.admin_recovery_codes', 'select'))::text, 'false');
