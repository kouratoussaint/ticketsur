-- ADR 0054 : notifications d'événements (décision de Toussaint, 23/11) et
-- notifications groupées par événement.
-- 1. Nouvel événement au catalogue : tous les téléphones qui ont choisi sa
--    ville dans l'Explorer, et ceux en « Toutes les villes » (sujets
--    Firebase `tikeo_city_<ville>` et `tikeo_city_all`, gérés par l'app ;
--    chacun peut les couper dans Paramètres › Notifications). Abonnés de la
--    structure : message personnel, comme avant.
-- 2. Modification importante d'un événement publié (date, heure, lieu,
--    ville, annulation) : détenteurs de tickets (« Mes tickets »), abonnés
--    de la structure, et téléphones qui l'ont en favori (sujet
--    `tikeo_event_<id>`).
-- 3. `push_outbox.tag` : les notifications d'un même événement se
--    remplacent dans la barre du téléphone au lieu de s'empiler.
-- Messages à des sujets : en français (comme les annonces).

alter table public.push_outbox add column tag text
  check (tag is null or tag ~ '^[A-Za-z0-9_.-]{1,64}$');

drop function public.push_take_batch(integer);
create function public.push_take_batch(p_limit integer default 50)
returns table (id bigint, tokens text[], topic_condition text, title text, body text,
               route text, tag text)
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  return query
    with batch as (
      select o.id from public.push_outbox o
       where o.sent_at is null and o.attempts < 5
       order by o.id
       limit least(greatest(coalesce(p_limit, 50), 1), 200)
       for update skip locked
    ), taken as (
      update public.push_outbox o set attempts = o.attempts + 1
        from batch b where o.id = b.id
      returning o.*
    )
    select t.id,
           case when t.user_id is null then null
                else coalesce((select array_agg(d.token) from public.push_devices d
                                where d.user_id = t.user_id), '{}') end,
           t.topic_condition, t.title, t.body, t.route, t.tag
      from taken t
     order by t.id;
end;
$$;
revoke all on function public.push_take_batch(integer) from public, anon, authenticated;
grant execute on function public.push_take_batch(integer) to service_role;

-- Sujet Firebase d'une ville (même calcul que `cityTopic` dans l'app).
create function private.city_topic(p_city text)
returns text
language sql
immutable
set search_path = ''
as $$
  select 'tikeo_city_' || btrim(regexp_replace(private.fold(p_city), '[^a-z0-9]+', '_', 'g'), '_')
$$;
revoke all on function private.city_topic(text) from public, anon, authenticated;

-- « 20/06 à 21h00 », dans le fuseau de l'événement.
create function private.event_when(p_event public.events)
returns text
language sql
stable
set search_path = ''
as $$
  select to_char(p_event.starts_at at time zone coalesce(p_event.timezone, 'UTC'),
                 'DD/MM "à" HH24"h"MI')
$$;
revoke all on function private.event_when(public.events) from public, anon, authenticated;

-- Message personnel (langue du compte) avec étiquette.
create function private.notify_user_tagged(
  p_user uuid, p_title_fr text, p_title_en text, p_body_fr text, p_body_en text,
  p_route text, p_tag text
)
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  insert into public.push_outbox (user_id, title, body, route, tag)
  select p.id,
         left(case when p.locale = 'en' then p_title_en else p_title_fr end, 120),
         left(case when p.locale = 'en' then p_body_en else p_body_fr end, 240),
         p_route, p_tag
    from public.profiles p
   where p.id = p_user and p.deleted_at is null
$$;
revoke all on function private.notify_user_tagged(uuid, text, text, text, text, text, text)
  from public, anon, authenticated;

-- 1. Première mise au catalogue : abonnés (personnel) et ville (sujets).
create or replace function private.notify_followers()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org text;
  v_tag text := 'evt-' || new.id;
  r record;
begin
  if new.followers_notified_at is null and private.is_listed(new) then
    new.followers_notified_at := now();
    select o.name into v_org from public.organizations o where o.id = new.organization_id;
    for r in
      select f.user_id from public.organization_followers f
       where f.organization_id = new.organization_id
         and not exists (select 1 from public.organization_members m
                          where m.organization_id = new.organization_id
                            and m.user_id = f.user_id and m.active)
    loop
      perform private.notify_user_tagged(
        r.user_id,
        'Nouvel événement : ' || new.title,
        'New event: ' || new.title,
        v_org || ' vient de publier un événement. Touchez pour voir la fiche.',
        v_org || ' just published an event. Tap to see it.',
        '/evenement/' || new.id, v_tag);
    end loop;
    insert into public.push_outbox (topic_condition, title, body, route, tag)
    values (
      case when nullif(btrim(coalesce(new.city, '')), '') is null
           then '''tikeo_city_all'' in topics'
           else format('%L in topics || ''tikeo_city_all'' in topics', private.city_topic(new.city))
      end,
      left(case when nullif(btrim(coalesce(new.city, '')), '') is null then 'Nouvel événement'
                else 'Nouvel événement à ' || new.city end, 120),
      left(new.title || ' · ' || private.event_when(new) || ' · ' || v_org, 240),
      '/evenement/' || new.id, v_tag);
  end if;
  return new;
end;
$$;

-- 2. Modifications importantes d'un événement déjà publié.
create function private.notify_event_changes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cancelled boolean := new.status = 'cancelled' and old.status <> 'cancelled';
  v_date boolean := new.starts_at is distinct from old.starts_at
                    or new.ends_at is distinct from old.ends_at;
  v_place boolean := new.venue is distinct from old.venue or new.city is distinct from old.city;
  v_listed boolean := private.is_listed(old);
  v_tag text := 'evt-' || new.id;
  v_title_fr text;
  v_title_en text;
  v_body_fr text;
  v_body_en text;
  v_place_text text;
  r record;
begin
  if old.status not in ('published', 'in_progress') then return null; end if;
  if not v_cancelled
     and (new.status not in ('published', 'in_progress') or not (v_date or v_place)) then
    return null;
  end if;
  v_place_text := concat_ws(', ', nullif(btrim(coalesce(new.venue, '')), ''),
                                  nullif(btrim(coalesce(new.city, '')), ''));
  if v_cancelled then
    v_title_fr := 'Événement annulé';
    v_title_en := 'Event cancelled';
    v_body_fr := '« ' || new.title || ' » est annulé.';
    v_body_en := '“' || new.title || '” is cancelled.';
  else
    v_title_fr := 'Événement modifié';
    v_title_en := 'Event updated';
    v_body_fr := '« ' || new.title || ' » : ' || concat_ws(' · ',
      case when v_date then 'nouvelle date le ' || private.event_when(new) end,
      case when v_place then 'nouveau lieu : ' || coalesce(nullif(v_place_text, ''), 'à préciser') end) || '.';
    v_body_en := '“' || new.title || '”: ' || concat_ws(' · ',
      case when v_date then 'new date ' || to_char(new.starts_at at time zone coalesce(new.timezone, 'UTC'),
                                                   'YYYY-MM-DD HH24:MI') end,
      case when v_place then 'new place: ' || coalesce(nullif(v_place_text, ''), 'to be confirmed') end) || '.';
  end if;

  -- Détenteurs de tickets ajoutés à « Mes tickets ».
  for r in
    select distinct t.holder_user_id as user_id from public.tickets t
     where t.event_id = new.id and t.holder_user_id is not null and t.status <> 'revoked'
  loop
    perform private.notify_user_tagged(r.user_id, v_title_fr, v_title_en, v_body_fr, v_body_en,
                                       '/portefeuille', v_tag);
  end loop;

  if v_listed then
    -- Abonnés de la structure (hors membres et détenteurs déjà prévenus).
    for r in
      select f.user_id from public.organization_followers f
       where f.organization_id = new.organization_id
         and not exists (select 1 from public.organization_members m
                          where m.organization_id = new.organization_id
                            and m.user_id = f.user_id and m.active)
         and not exists (select 1 from public.tickets t
                          where t.event_id = new.id and t.holder_user_id = f.user_id
                            and t.status <> 'revoked')
    loop
      perform private.notify_user_tagged(r.user_id, v_title_fr, v_title_en, v_body_fr, v_body_en,
                                         '/evenement/' || new.id, v_tag);
    end loop;
    -- Téléphones qui l'ont en favori.
    insert into public.push_outbox (topic_condition, title, body, route, tag)
    values (format('%L in topics', 'tikeo_event_' || new.id), v_title_fr, left(v_body_fr, 240),
            '/evenement/' || new.id, v_tag);
  end if;
  return null;
end;
$$;
revoke all on function private.notify_event_changes() from public, anon, authenticated;

-- Différé à la fin de la transaction : une annulation par la console a déjà
-- annulé les tickets non entrés (leurs détenteurs sont prévenus par
-- `private.cancel_event_tickets`), ils ne reçoivent pas un second message.
create constraint trigger events_notify_changes
  after update of status, starts_at, ends_at, venue, city on public.events
  deferrable initially deferred
  for each row execute function private.notify_event_changes();
