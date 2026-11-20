-- Diagnostic des notifications (lecture seule) : compteurs et codes
-- d'erreur seulement — ni jeton, ni titre, ni texte, ni compte.
\pset footer off
\echo '== Appareils enregistrés'
select count(*) as appareils, count(distinct user_id) as comptes,
       to_char(max(updated_at), 'YYYY-MM-DD HH24:MI') as dernier_enregistrement
  from public.push_devices;
\echo '== File des messages'
select case when topic_condition is null then 'compte' else 'annonce' end as type,
       count(*) as total,
       count(*) filter (where sent_at is not null) as envoyes,
       count(*) filter (where sent_at is null and attempts = 0) as jamais_pris,
       count(*) filter (where sent_at is null and attempts between 1 and 4) as en_echec,
       count(*) filter (where sent_at is null and attempts >= 5) as abandonnes
  from public.push_outbox group by 1 order by 1;
\echo '== 15 derniers messages'
select o.id, to_char(o.created_at, 'MM-DD HH24:MI') as cree,
       case when o.topic_condition is null then 'compte' else 'annonce' end as type,
       split_part(coalesce(o.route, ''), '/', 2) as route,
       (select count(*) from public.push_devices d where d.user_id = o.user_id) as appareils_du_compte,
       o.attempts, o.sent_at is not null as envoye, o.last_error
  from public.push_outbox o order by o.id desc limit 15;
