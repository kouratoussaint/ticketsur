-- =============================================================================
-- Tikéo — Tests : mentions légales (migration 2500)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-2500-0000-0000-000000000001', 'admin-legal@test.local'),
  ('aaaaaaaa-2500-0000-0000-000000000002', 'curieux-legal@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-2500-0000-0000-000000000001';

-- Lecture sans compte.
set role anon;
select (select title from public.legal_document('terms')) as anon_terms \gset
select (select count(*) from public.legal_document('inconnu')) as unknown_doc \gset
reset role;
select test.check('Sans compte : conditions lisibles', :'anon_terms', 'Conditions d''utilisation');
select test.check('Document inconnu : rien', :'unknown_doc', '0');
select (select version from public.legal_documents where slug = 'privacy' and locale = 'fr') as v0 \gset

-- Un compte ordinaire ne modifie pas.
set role authenticated;
select test.login('aaaaaaaa-2500-0000-0000-000000000002');
do $$
begin
  begin
    perform public.admin_save_legal_document('privacy', 'Titre', 'Un texte assez long pour passer.');
    raise exception 'ÉCHEC  texte modifié par un compte ordinaire';
  exception when insufficient_privilege then
    raise notice 'OK    Modification réservée aux administrateurs';
  end;
end $$;

-- L'administrateur enregistre une nouvelle version.
select test.login('aaaaaaaa-2500-0000-0000-000000000001');
select public.admin_save_legal_document('privacy', '  Confidentialité  ',
  'Nouveau texte de la politique, assez long.') as v1 \gset
select test.check('Nouvelle version numérotée', :'v1'::text, (:'v0'::int + 1)::text);
select test.check('Texte et titre nettoyés, lisibles par tous',
  (select title || '|' || body from public.legal_document('privacy')),
  'Confidentialité|Nouveau texte de la politique, assez long.');
do $$
begin
  begin
    perform public.admin_save_legal_document('terms', 'Ti', 'Un texte assez long pour passer.');
    raise exception 'ÉCHEC  titre trop court accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Titre trop court refusé';
  end;
  begin
    perform public.admin_save_legal_document('cgv', 'Titre', 'Un texte assez long pour passer.');
    raise exception 'ÉCHEC  document inconnu accepté';
  exception when no_data_found then
    raise notice 'OK    Document inconnu refusé';
  end;
end $$;
select test.check('Journal : document et version, sans texte',
  (select details::text from public.admin_audit_logs('admin.legal', 5, 0)
    where action = 'admin.legal_updated' limit 1),
  format('{"locale": "fr", "version": %s, "document": "privacy"}', :'v1'));
reset role;

-- Version anglaise ------------------------------------------------------------
set role anon;
select (select title from public.legal_document('terms', 'en')) as en_terms,
       (select title from public.legal_document('terms', 'de')) as de_terms \gset
reset role;
select test.check('Anglais : conditions en anglais, sans compte', :'en_terms', 'Terms of use');
select test.check('Langue inconnue : version française', :'de_terms', 'Conditions d''utilisation');
set role authenticated;
select test.login('aaaaaaaa-2500-0000-0000-000000000001');
select public.admin_save_legal_document('privacy', 'Privacy', 'A text long enough to pass the check.', 'en') as v_en \gset
reset role;
select test.check('Anglais modifié sans toucher au français',
  (select string_agg(locale || ':' || title, ',' order by locale)
     from public.legal_documents where slug = 'privacy'),
  'en:Privacy,fr:Confidentialité');

