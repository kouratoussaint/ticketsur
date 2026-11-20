-- =============================================================================
-- Tikéo — Migration 2800 : notifications push (lot 4-2, ADR 0020)
-- =============================================================================
-- Décision de Toussaint (19/11/2026) : notifications par Firebase Cloud
-- Messaging. La base prépare les messages dans une file (`push_outbox`) ;
-- la fonction Edge `push-dispatch` les envoie avec la clé du compte de
-- service Firebase (secret Supabase, jamais dans l'application ni le dépôt).
--
-- Messages :
-- * réponse du support → le demandeur ;
-- * annonce importante → les sujets Firebase des destinataires choisis ;
-- * contrôle démarré → les contrôleurs affectés à l'événement.
-- Le contenu ne passe jamais par `audit_logs` ; aucun jeton QR dans un message.
-- =============================================================================

-- Appareils des comptes connectés (jeton d'enregistrement Firebase).
create table public.push_devices (
  token text primary key check (char_length(token) between 20 and 4096),
  user_id uuid not null references public.profiles (id) on delete cascade,
  updated_at timestamptz not null default now()
);
create index push_devices_user_idx on public.push_devices (user_id);
alter table public.push_devices enable row level security;
revoke all on public.push_devices from anon, authenticated;

-- File des messages à envoyer.
create table public.push_outbox (
  id bigint generated always as identity primary key,
  user_id uuid references public.profiles (id) on delete cascade,
  -- Condition Firebase sur des sujets, ex. « 'tikeo_users' in topics ».
  topic_condition text,
  title text not null,
  body text not null,
  route text,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  attempts integer not null default 0,
  last_error text,
  check ((user_id is null) <> (topic_condition is null))
);
create index push_outbox_pending_idx on public.push_outbox (id) where sent_at is null;
alter table public.push_outbox enable row level security;
revoke all on public.push_outbox from anon, authenticated;
revoke all on sequence public.push_outbox_id_seq from anon, authenticated;

-- Enregistre l'appareil du compte connecté (un jeton = un compte).
create function public.register_push_device(p_token text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
begin
  if p_token is null or char_length(p_token) not between 20 and 4096 then
    raise exception 'push_token_invalid' using errcode = '22023', detail = 'Jeton invalide.';
  end if;
  insert into public.push_devices (token, user_id)
  values (p_token, v_actor)
  on conflict (token) do update set user_id = excluded.user_id, updated_at = now();
end;
$$;
revoke all on function public.register_push_device(text) from public, anon;
grant execute on function public.register_push_device(text) to authenticated;

-- Oublie l'appareil (déconnexion, notifications coupées).
create function public.unregister_push_device(p_token text)
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  delete from public.push_devices d where d.token = p_token and d.user_id = auth.uid()
$$;
revoke all on function public.unregister_push_device(text) from public, anon;
grant execute on function public.unregister_push_device(text) to authenticated;

-- Fonction Edge (rôle service_role) : prend un lot de messages en attente,
-- avec les jetons des destinataires. Chaque prise compte une tentative ;
-- au-delà de 5, un message est abandonné.
create function public.push_take_batch(p_limit integer default 50)
returns table (id bigint, tokens text[], topic_condition text, title text, body text, route text)
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
           t.topic_condition, t.title, t.body, t.route
      from taken t
     order by t.id;
end;
$$;
revoke all on function public.push_take_batch(integer) from public, anon, authenticated;
grant execute on function public.push_take_batch(integer) to service_role;

-- Fonction Edge : résultat de l'envoi ; jetons refusés par Firebase oubliés.
create function public.push_mark(p_sent bigint[], p_failed jsonb, p_dead_tokens text[])
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  update public.push_outbox o set sent_at = now(), last_error = null
   where o.id = any (coalesce(p_sent, '{}'));
  update public.push_outbox o set last_error = left(f.value, 300)
    from jsonb_each_text(coalesce(p_failed, '{}'::jsonb)) f
   where o.id = f.key::bigint;
  delete from public.push_devices d where d.token = any (coalesce(p_dead_tokens, '{}'));
  -- Ménage : messages envoyés depuis plus de 30 jours.
  delete from public.push_outbox o where o.sent_at < now() - interval '30 days';
end;
$$;
revoke all on function public.push_mark(bigint[], jsonb, text[]) from public, anon, authenticated;
grant execute on function public.push_mark(bigint[], jsonb, text[]) to service_role;

-- Réponse du support → le demandeur.
create function private.push_on_support_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.from_admin then
    insert into public.push_outbox (user_id, title, body, route)
    select r.user_id, 'Support Tikéo', 'Nouvelle réponse : ' || r.subject, '/support/' || r.id
      from public.support_requests r where r.id = new.request_id;
  end if;
  return new;
end;
$$;
create trigger support_messages_push
  after insert on public.support_messages
  for each row execute function private.push_on_support_message();

-- Annonce importante → sujets des destinataires choisis.
create function private.push_on_announcement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.level = 'important' then
    insert into public.push_outbox (topic_condition, title, body, route)
    values (
      (select string_agg(format('''tikeo_%s'' in topics', a), ' || ' order by a)
         from unnest(new.audiences) a),
      new.title, left(new.body, 240), '/');
  end if;
  return new;
end;
$$;
create trigger announcements_push
  after insert on public.announcements
  for each row execute function private.push_on_announcement();

-- Contrôle démarré → contrôleurs affectés (actifs) à l'événement.
create function private.push_on_control_started()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'in_progress' and old.status is distinct from 'in_progress' then
    insert into public.push_outbox (user_id, title, body, route)
    select distinct a.user_id, 'Contrôle ouvert', new.title || ' : vous pouvez scanner.',
           '/postes?evenement=' || new.id
      from public.event_assignments a
      join public.organization_members m
        on m.user_id = a.user_id and m.organization_id = new.organization_id and m.active
     where a.event_id = new.id and a.active and m.role = 'controller';
  end if;
  return new;
end;
$$;
create trigger events_control_push
  after update of status on public.events
  for each row execute function private.push_on_control_started();
