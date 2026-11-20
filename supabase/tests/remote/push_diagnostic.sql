-- Diagnostic des notifications (lecture seule) : compteurs, heures, codes
-- d'erreur et empreintes courtes (6 caractères de md5) des comptes et des
-- appareils — ni jeton, ni titre, ni texte, ni identifiant en clair.
\pset footer off
\echo '== Appareils enregistrés'
select left(md5(d.token), 6) as appareil, left(md5(d.user_id::text), 6) as compte,
       to_char(d.updated_at, 'MM-DD HH24:MI:SS') as enregistre
  from public.push_devices d order by d.updated_at desc;
\echo '== File des messages'
select case when topic_condition is null then 'compte' else 'annonce' end as type,
       count(*) as total,
       count(*) filter (where sent_at is not null) as envoyes,
       count(*) filter (where sent_at is null and attempts = 0) as jamais_pris,
       count(*) filter (where sent_at is null and attempts between 1 and 4) as en_echec,
       count(*) filter (where sent_at is null and attempts >= 5) as abandonnes
  from public.push_outbox group by 1 order by 1;
\echo '== 20 derniers messages'
select o.id, to_char(o.created_at, 'MM-DD HH24:MI:SS') as cree,
       to_char(o.sent_at, 'HH24:MI:SS') as envoye,
       case when o.topic_condition is null then left(md5(o.user_id::text), 6)
            else o.topic_condition end as destinataire,
       split_part(split_part(coalesce(o.route, ''), '/', 2), '?', 1) as page,
       (select string_agg(left(md5(d.token), 6), ',') from public.push_devices d
         where d.user_id = o.user_id) as appareils_actuels,
       o.attempts, o.last_error
  from public.push_outbox o order by o.id desc limit 20;
