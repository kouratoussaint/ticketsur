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
\echo '== Tâche planifiée (rappels et nouvel essai, migration 3500)'
select to_regclass('cron.job_run_details') is not null as has_cron,
       to_regclass('net._http_response') is not null as has_net \gset
\if :has_cron
select j.jobname, j.schedule, j.active from cron.job j where j.jobname = 'tikeo-push-tick';
select to_char(r.start_time, 'MM-DD HH24:MI:SS') as debut, r.status, left(r.return_message, 80) as message
  from cron.job_run_details r join cron.job j on j.jobid = r.jobid
 where j.jobname = 'tikeo-push-tick' order by r.start_time desc limit 5;
\else
\echo 'pg_cron absent'
\endif
\if :has_net
select to_char(h.created, 'MM-DD HH24:MI:SS') as appel, h.status_code, left(h.content, 60) as reponse,
       left(h.error_msg, 60) as erreur
  from net._http_response h order by h.created desc limit 5;
\endif
select (select count(*) from private.app_settings where key in ('push_dispatch_url', 'publishable_key'))
         as reglages_envoi,
       (select count(*) from private.event_reminders) as rappels_prepares;
