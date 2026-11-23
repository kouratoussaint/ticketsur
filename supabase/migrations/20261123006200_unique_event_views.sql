-- ADR 0052 : vues de la fiche publique comptées par le serveur, sans
-- gonflement possible par appels répétés (décision de Toussaint, 23/11).
-- 1. Une vue par visiteur, par événement et par jour : le visiteur est le
--    compte connecté, sinon le numéro d'installation envoyé par l'app,
--    sinon (anciennes APK) l'adresse internet.
-- 2. Au plus 20 vues comptées par adresse internet, par événement et par
--    jour (opérateurs mobiles et cybercafés partagent une même adresse).
-- 3. Les membres de la structure ne comptent pas.
-- 4. Ni compte, ni numéro, ni adresse en clair : seulement une empreinte
--    HMAC avec une clé tirée au hasard chaque jour ; clés et empreintes
--    effacées à la première vue du jour suivant et chaque nuit
--    (`private.purge_trash`, tâche `tikeo-trash-purge`).

create table private.view_salts (
  day date primary key,
  salt bytea not null
);
create table private.event_view_seen (
  event_id uuid not null references public.events (id) on delete cascade,
  day date not null,
  viewer bytea not null,
  primary key (event_id, day, viewer)
);
create table private.event_view_networks (
  event_id uuid not null references public.events (id) on delete cascade,
  day date not null,
  network bytea not null,
  views integer not null default 0,
  primary key (event_id, day, network)
);
create index event_view_seen_day on private.event_view_seen (day);
create index event_view_networks_day on private.event_view_networks (day);

-- Efface les clés et empreintes d'avant aujourd'hui (UTC).
create function private.purge_view_keys()
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'UTC')::date;
begin
  delete from private.event_view_seen where day < v_today;
  delete from private.event_view_networks where day < v_today;
  delete from private.view_salts where day < v_today;
  return 0;
end;
$$;
revoke all on function private.purge_view_keys() from public, anon, authenticated;

create or replace function private.purge_trash()
returns integer
language sql
volatile
security definer
set search_path = ''
as $$
  select private.purge_due_organizations() + private.purge_due_events()
         + private.purge_view_keys()
$$;
revoke all on function private.purge_trash() from public, anon, authenticated;

-- Adresse internet de l'appel (premier élément de X-Forwarded-For), ou
-- « inconnue » hors de l'API.
create function private.request_network()
returns text
language sql
stable
set search_path = ''
as $$
  select coalesce(
    nullif(btrim(split_part(
      coalesce(nullif(current_setting('request.headers', true), '')::json ->> 'x-forwarded-for', ''),
      ',', 1)), ''),
    nullif(btrim(coalesce(nullif(current_setting('request.headers', true), '')::json ->> 'cf-connecting-ip', '')), ''),
    'inconnue')
$$;
revoke all on function private.request_network() from public, anon, authenticated;

drop function public.record_event_view(uuid);

-- Une vue de la fiche publique. Sans effet (et sans erreur, pour ne rien
-- révéler) si l'événement n'est pas au catalogue, si la vue est déjà
-- comptée aujourd'hui, ou au-delà de 20 vues pour cette adresse.
create function public.record_event_view(p_event_id uuid, p_device text default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'UTC')::date;
  v_user uuid := auth.uid();
  v_org uuid;
  v_salt bytea;
  v_network text := private.request_network();
  v_key text;
  v_inserted integer;
begin
  select e.organization_id into v_org
    from public.events e where e.id = p_event_id and private.is_listed(e);
  if v_org is null then return; end if;
  if v_user is not null and private.has_org_role(
       v_org, array['owner', 'manager', 'controller']::public.member_role[]) then
    return;
  end if;

  select s.salt into v_salt from private.view_salts s where s.day = v_today;
  if v_salt is null then
    insert into private.view_salts (day, salt)
    values (v_today, extensions.gen_random_bytes(32))
    on conflict (day) do nothing;
    select s.salt into v_salt from private.view_salts s where s.day = v_today;
    perform private.purge_view_keys();
  end if;

  v_key := case
    when v_user is not null then 'compte:' || v_user::text
    when p_device ~ '^[A-Za-z0-9-]{16,64}$' then 'appareil:' || p_device
    else 'adresse:' || v_network
  end;
  insert into private.event_view_seen (event_id, day, viewer)
  values (p_event_id, v_today, extensions.hmac(convert_to(v_key, 'UTF8'), v_salt, 'sha256'))
  on conflict do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then return; end if;

  insert into private.event_view_networks as n (event_id, day, network, views)
  values (p_event_id, v_today,
          extensions.hmac(convert_to('adresse:' || v_network, 'UTF8'), v_salt, 'sha256'), 1)
  on conflict (event_id, day, network) do update set views = n.views + 1
    where n.views < 20;
  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then return; end if;

  insert into public.event_page_views as v (event_id, day, views)
  values (p_event_id, v_today, 1)
  on conflict (event_id, day) do update set views = v.views + 1;
end;
$$;
revoke all on function public.record_event_view(uuid, text) from public;
grant execute on function public.record_event_view(uuid, text) to anon, authenticated;
