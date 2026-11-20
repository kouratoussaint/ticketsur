-- =============================================================================
-- Tikéo — Tests : annulation groupée et duplication d'événement (migration 2600)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-2600-0000-0000-000000000001', 'proprio-dup@test.local'),
  ('aaaaaaaa-2600-0000-0000-000000000002', 'controleur-dup@test.local'),
  ('aaaaaaaa-2600-0000-0000-000000000003', 'autre-dup@test.local');

set role authenticated;
select test.login('aaaaaaaa-2600-0000-0000-000000000001');
select (public.create_organization('Studio Dup Qzv')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Culte Dup Qzv', now() + interval '2 days',
                            now() + interval '2 days 3 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select (public.create_ticket_category(:'ev', 'Invités')).id as inv \gset
select (public.create_checkpoint(:'ev', 'Porte Nord')).id as cp \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select array_agg(ticket_id)::text as tk from public.issue_tickets(:'ev', :'cat', 4) \gset
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-2600-0000-0000-000000000002', 'controller');
insert into public.event_assignments (event_id, user_id, checkpoint_id)
values (:'ev', 'aaaaaaaa-2600-0000-0000-000000000002', :'cp');
update public.ticket_categories set is_invitation = true, indicative_price = null where id = :'inv';
update public.ticket_categories set indicative_price = 2000 where id = :'cat';
-- Un ticket déjà utilisé reste tel quel.
update public.tickets set status = 'redeemed', redeemed_at = now(),
       redeemed_by = 'aaaaaaaa-2600-0000-0000-000000000002', redeemed_checkpoint_id = :'cp'
 where id = (:'tk'::uuid[])[1];
select set_config('test.tk', :'tk', false) \gset ignored_
select set_config('test.ev', :'ev', false) \gset ignored_
set role authenticated;

-- Annulation groupée ------------------------------------------------------------
select test.login('aaaaaaaa-2600-0000-0000-000000000003');
do $$
begin
  begin
    perform public.revoke_tickets(current_setting('test.tk')::uuid[], 'x');
    raise exception 'ÉCHEC  annulation par un compte étranger';
  exception when insufficient_privilege then
    raise notice 'OK    Annulation groupée réservée à la structure';
  end;
end $$;
select test.login('aaaaaaaa-2600-0000-0000-000000000001');
select public.revoke_tickets(:'tk'::uuid[], 'Doublons') as revoked \gset
select test.check('Annulation groupée : seuls les tickets valables changent', :'revoked', '3');
reset role;
select test.check('Statuts après annulation groupée',
  (select string_agg(status::text, ',' order by status::text)
     from public.tickets where id = any (:'tk'::uuid[])),
  'redeemed,revoked,revoked,revoked');
select test.check('Journal : une ligne par ticket annulé',
  (select count(*)::text from public.audit_logs
    where action = 'ticket.revoked' and resource_id = any (:'tk'::uuid[])
      and details->>'bulk' = 'true'),
  '3');
set role authenticated;
do $$
begin
  begin
    perform public.revoke_tickets('{}'::uuid[], null);
    raise exception 'ÉCHEC  sélection vide acceptée';
  exception when invalid_parameter_value then
    raise notice 'OK    Sélection vide refusée';
  end;
end $$;

-- Duplication -------------------------------------------------------------------
select public.duplicate_event(:'ev', 'Culte Dup Qzv (copie)', now() + interval '9 days',
                              now() + interval '9 days 3 hours') as dup \gset
reset role;
select test.check('Copie : brouillon, même structure, champs repris',
  (select status::text || '|' || (organization_id = :'org') || '|' || kind::text || '|' || title
     from public.events where id = :'dup'),
  (select 'draft|true|' || kind::text || '|Culte Dup Qzv (copie)' from public.events where id = :'ev'));
select test.check('Copie : catégories, invitation et prix gardés',
  (select string_agg(name || ':' || is_invitation || ':' || coalesce(indicative_price::text, '-'),
                     ',' order by name)
     from public.ticket_categories where event_id = :'dup'),
  'Invités:true:-,Standard:false:2000');
select test.check('Copie : porte et affectation du contrôleur',
  (select count(*)::text from public.event_assignments a
     join public.checkpoints c on c.id = a.checkpoint_id
    where a.event_id = :'dup' and c.name = 'Porte Nord'
      and a.user_id = 'aaaaaaaa-2600-0000-0000-000000000002'),
  '1');
select test.check('Copie : aucun ticket',
  (select count(*)::text from public.tickets where event_id = :'dup'), '0');
select test.check('Journal : duplication avec la source',
  (select details->>'source' from public.audit_logs
    where action = 'event.duplicated' and resource_id = :'dup'),
  :'ev');
set role authenticated;
select test.login('aaaaaaaa-2600-0000-0000-000000000002');
do $$
begin
  begin
    perform public.duplicate_event(current_setting('test.ev')::uuid, 'Pirate',
                                   now() + interval '3 days', now() + interval '3 days 1 hour');
    raise exception 'ÉCHEC  duplication par un contrôleur';
  exception when insufficient_privilege then
    raise notice 'OK    Duplication réservée aux gestionnaires';
  end;
end $$;
select test.login('aaaaaaaa-2600-0000-0000-000000000001');
do $$
begin
  begin
    perform public.duplicate_event(current_setting('test.ev')::uuid, 'Dates à l''envers',
                                   now() + interval '3 days', now() + interval '2 days');
    raise exception 'ÉCHEC  dates incohérentes acceptées';
  exception when others then
    raise notice 'OK    Dates incohérentes refusées';
  end;
end $$;
reset role;
