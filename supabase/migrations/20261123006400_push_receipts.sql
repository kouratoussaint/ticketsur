-- ADR 0053 : accusés de réception des notifications. Firebase dit seulement
-- qu'il a accepté un message ; le téléphone confirme maintenant qu'il l'a
-- reçu (au premier plan tout de suite, en arrière-plan à la prochaine
-- ouverture de l'app). Le diagnostic (`push-diagnostic`) montre ainsi si un
-- message accepté est arrivé sur le téléphone.
-- Ni jeton ni contenu : l'appareil est noté par l'empreinte md5 de son jeton
-- (comme dans le diagnostic).

create table public.push_receipts (
  outbox_id bigint not null references public.push_outbox (id) on delete cascade,
  device text not null check (char_length(device) = 32),
  received_at timestamptz not null default now(),
  primary key (outbox_id, device)
);
alter table public.push_receipts enable row level security;
revoke all on public.push_receipts from anon, authenticated;

-- Le téléphone (compte connecté, jeton enregistré pour ce compte) confirme
-- la réception de messages : ceux de son compte et les annonces. Renvoie le
-- nombre d'accusés nouveaux ; ignore le reste sans erreur.
create function public.push_ack(p_ids bigint[], p_token text)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_count integer;
begin
  if v_user is null or p_ids is null or cardinality(p_ids) = 0 then
    return 0;
  end if;
  if not exists (select 1 from public.push_devices d
                  where d.token = p_token and d.user_id = v_user) then
    return 0;
  end if;
  insert into public.push_receipts (outbox_id, device)
  select o.id, md5(p_token)
    from public.push_outbox o
   where o.id = any (p_ids[1:100])
     and (o.user_id = v_user or o.topic_condition is not null)
  on conflict do nothing;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke all on function public.push_ack(bigint[], text) from public, anon;
grant execute on function public.push_ack(bigint[], text) to authenticated;
