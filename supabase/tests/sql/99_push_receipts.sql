-- =============================================================================
-- Tikéo — Tests : accusés de réception des notifications (migration 6400)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-6400-0000-0000-000000000001', 'recu-awa@test.local', now()),
  ('aaaaaaaa-6400-0000-0000-000000000002', 'recu-issa@test.local', now());
insert into public.push_devices (token, user_id) values
  ('jeton-de-test-awa-0001-rq', 'aaaaaaaa-6400-0000-0000-000000000001'),
  ('jeton-de-test-issa-0002-rq', 'aaaaaaaa-6400-0000-0000-000000000002');
insert into public.push_outbox (user_id, title, body) values
  ('aaaaaaaa-6400-0000-0000-000000000001', 'Pour Awa', 'Rq') returning id as mine \gset
insert into public.push_outbox (user_id, title, body) values
  ('aaaaaaaa-6400-0000-0000-000000000002', 'Pour Issa', 'Rq') returning id as theirs \gset
insert into public.push_outbox (topic_condition, title, body) values
  ('''tikeo_users'' in topics', 'Annonce', 'Rq') returning id as topic \gset

set role authenticated;
select test.login('aaaaaaaa-6400-0000-0000-000000000001');
select test.check('Accusés : son message et l''annonce, pas celui d''un autre',
  public.push_ack(array[:mine, :theirs, :topic]::bigint[], 'jeton-de-test-awa-0001-rq')::text, '2');
select test.check('Deuxième accusé : rien de nouveau',
  public.push_ack(array[:mine]::bigint[], 'jeton-de-test-awa-0001-rq')::text, '0');
select test.check('Jeton d''un autre compte : ignoré',
  public.push_ack(array[:mine]::bigint[], 'jeton-de-test-issa-0002-rq')::text, '0');
select test.check('Liste vide : ignorée',
  public.push_ack(array[]::bigint[], 'jeton-de-test-awa-0001-rq')::text, '0');
reset role;
select test.check('Appareil noté par l''empreinte du jeton seulement',
  (select string_agg(r.outbox_id::text || ':' || (r.device = md5('jeton-de-test-awa-0001-rq'))::text,
                     ',' order by r.outbox_id)
     from public.push_receipts r where r.outbox_id in (:mine, :theirs, :topic)),
  :mine || ':true,' || :topic || ':true');
select test.check('Fermé aux visiteurs et à l''API',
  has_function_privilege('anon', 'public.push_ack(bigint[], text)', 'execute')::text || '|'
  || has_table_privilege('authenticated', 'public.push_receipts', 'select')::text,
  'false|false');
