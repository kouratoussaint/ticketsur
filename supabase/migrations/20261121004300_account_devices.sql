-- =============================================================================
-- Tikéo — Lot 4-6a : appareils connectés et déconnexion à distance (ADR 0031)
-- =============================================================================
-- Une session Supabase Auth par appareil connecté (claim `session_id` du
-- jeton). L'app inscrit son appareil (modèle, système, version) ; le compte
-- voit ses appareils et peut en déconnecter un, ou tous les autres. La
-- session supprimée ne peut plus se renouveler ; l'app de l'appareil le
-- constate à sa prochaine inscription (`session_revoked`) et se déconnecte.
-- Aucune adresse IP n'est lue ni gardée.
-- =============================================================================

create table public.account_devices (
  session_id uuid primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  label text not null check (char_length(label) between 1 and 80),
  platform text not null check (platform in ('android', 'ios', 'other')),
  app_build integer check (app_build is null or app_build >= 0),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);
create index account_devices_user_idx on public.account_devices (user_id);
alter table public.account_devices enable row level security;
revoke all on public.account_devices from anon, authenticated;

-- Session du jeton en cours (null hors d'une requête authentifiée).
create function private.current_session_id()
returns uuid
language sql
stable
set search_path = ''
as $$
  select nullif(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'session_id',
    ''
  )::uuid
$$;
revoke all on function private.current_session_id() from public, anon, authenticated;

-- Inscrit (ou rafraîchit) l'appareil de la session en cours.
create function public.register_device(
  p_label text,
  p_platform text,
  p_app_build integer default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
  v_session uuid := private.current_session_id();
  v_label text := left(nullif(trim(coalesce(p_label, '')), ''), 80);
begin
  if v_session is null then
    raise exception 'session_unknown' using errcode = '22023', detail = 'Session inconnue.';
  end if;
  if not exists (select 1 from auth.sessions s
                  where s.id = v_session and s.user_id = v_actor) then
    raise exception 'session_revoked'
      using errcode = '28000', detail = 'Cet appareil a été déconnecté.';
  end if;
  insert into public.account_devices (session_id, user_id, label, platform, app_build)
  values (v_session, v_actor, coalesce(v_label, 'Appareil'),
          case when p_platform in ('android', 'ios') then p_platform else 'other' end,
          p_app_build)
  on conflict (session_id) do update
    set label = excluded.label,
        platform = excluded.platform,
        app_build = excluded.app_build,
        last_seen_at = now()
  where public.account_devices.user_id = v_actor;
  -- Appareils dont la session n'existe plus (déconnectés, expirés).
  delete from public.account_devices d
   where d.user_id = v_actor
     and not exists (select 1 from auth.sessions s where s.id = d.session_id);
  return jsonb_build_object('session_id', v_session);
end;
$$;
revoke all on function public.register_device(text, text, integer) from public, anon;
grant execute on function public.register_device(text, text, integer) to authenticated;

-- Appareils connectés du compte : la session en cours d'abord.
create function public.my_devices()
returns table (
  session_id uuid,
  label text,
  platform text,
  app_build integer,
  signed_in_at timestamptz,
  last_seen_at timestamptz,
  current boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
  v_session uuid := private.current_session_id();
begin
  return query
  select s.id, d.label, d.platform, d.app_build, s.created_at,
         greatest(coalesce(d.last_seen_at, s.created_at), s.updated_at),
         s.id = v_session
    from auth.sessions s
    left join public.account_devices d on d.session_id = s.id and d.user_id = v_actor
   where s.user_id = v_actor
     and (s.not_after is null or s.not_after > now())
   order by (s.id = v_session) desc,
            greatest(coalesce(d.last_seen_at, s.created_at), s.updated_at) desc;
end;
$$;
revoke all on function public.my_devices() from public, anon;
grant execute on function public.my_devices() to authenticated;

-- Déconnecte un autre appareil du compte.
create function public.revoke_device(p_session_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
begin
  if p_session_id is not distinct from private.current_session_id() then
    raise exception 'device_current'
      using errcode = '55000', detail = 'Pour cet appareil, utilisez « Se déconnecter ».';
  end if;
  delete from auth.sessions s where s.id = p_session_id and s.user_id = v_actor;
  if not found then
    raise exception 'device_not_found'
      using errcode = 'P0002', detail = 'Appareil introuvable ou déjà déconnecté.';
  end if;
  delete from public.account_devices d where d.session_id = p_session_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, v_actor, 'account.device_revoked', 'account', v_actor, '{}'::jsonb);
end;
$$;
revoke all on function public.revoke_device(uuid) from public, anon;
grant execute on function public.revoke_device(uuid) to authenticated;

-- Déconnecte tous les autres appareils ; renvoie leur nombre.
create function public.revoke_other_devices()
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
  v_session uuid := private.current_session_id();
  v_count integer;
begin
  if v_session is null then
    raise exception 'session_unknown' using errcode = '22023', detail = 'Session inconnue.';
  end if;
  delete from auth.sessions s where s.user_id = v_actor and s.id <> v_session;
  get diagnostics v_count = row_count;
  delete from public.account_devices d where d.user_id = v_actor and d.session_id <> v_session;
  if v_count > 0 then
    insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
    values (null, v_actor, 'account.devices_revoked', 'account', v_actor,
            jsonb_build_object('count', v_count));
  end if;
  return v_count;
end;
$$;
revoke all on function public.revoke_other_devices() from public, anon;
grant execute on function public.revoke_other_devices() to authenticated;
