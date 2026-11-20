-- =============================================================================
-- Tikéo — Migration 2700 : « Mes tickets » du spectateur (lot 4-1, ADR 0019)
-- =============================================================================
-- Décision de Toussaint (19/11/2026) : le spectateur retrouve ses tickets
-- dans son compte. Pour ne jamais livrer un ticket à la mauvaise personne
-- (adresses et numéros ne sont pas vérifiés), un ticket entre dans un compte
-- par la preuve de sa possession : son QR (scanné, lu dans une image ou
-- collé). Le premier compte qui l'ajoute le garde ; un autre compte est
-- refusé. Le format du QR ne change pas.
-- =============================================================================

alter table public.tickets
  add column holder_user_id uuid references public.profiles (id) on delete set null;
create index tickets_holder_user_idx on public.tickets (holder_user_id)
  where holder_user_id is not null;

create function private.require_wallet_user()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null or not exists (
    select 1 from public.profiles p where p.id = v_actor and p.deleted_at is null
  ) then
    raise exception 'forbidden' using errcode = '42501', detail = 'Connectez-vous.';
  end if;
  return v_actor;
end;
$$;
revoke all on function private.require_wallet_user() from public, anon, authenticated;

-- Ajoute un ticket à « Mes tickets » à partir de son QR ; renvoie son id.
create function public.claim_ticket(p_qr_token text)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
  v_ticket public.tickets%rowtype;
  v_org uuid;
begin
  if p_qr_token is null or p_qr_token !~ '^TS1\.[A-Za-z0-9_-]{43}$' then
    raise exception 'qr_invalid'
      using errcode = '22023', detail = 'Ce code n''est pas un ticket Tikéo.';
  end if;
  select t.* into v_ticket
    from private.ticket_secrets s
    join public.tickets t on t.id = s.ticket_id
   where s.token_hmac = private.token_hmac(p_qr_token)
   for update of t;
  if not found then
    raise exception 'ticket_unknown'
      using errcode = 'P0002', detail = 'Ticket inconnu.';
  end if;
  if v_ticket.status = 'revoked' then
    raise exception 'ticket_revoked'
      using errcode = '55000', detail = 'Ce ticket a été annulé par l''organisateur.';
  end if;
  if v_ticket.holder_user_id is not null and v_ticket.holder_user_id <> v_actor then
    raise exception 'ticket_claimed'
      using errcode = '55000', detail = 'Ce ticket est déjà dans le compte d''une autre personne.';
  end if;
  if v_ticket.holder_user_id is null then
    update public.tickets t set holder_user_id = v_actor where t.id = v_ticket.id;
    select e.organization_id into v_org from public.events e where e.id = v_ticket.event_id;
    insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
    values (v_org, v_actor, 'ticket.claimed', 'ticket', v_ticket.id, '{}'::jsonb);
  end if;
  return v_ticket.id;
end;
$$;
revoke all on function public.claim_ticket(text) from public, anon;
grant execute on function public.claim_ticket(text) to authenticated;

-- Tickets du compte, à venir d'abord. Le QR n'est renvoyé que pour un
-- ticket encore valable (le compte en a déjà prouvé la possession).
create function public.my_tickets()
returns table (
  ticket_id uuid,
  public_reference text,
  status public.ticket_status,
  redeemed_at timestamptz,
  category_name text,
  is_invitation boolean,
  holder_name text,
  qr_token text,
  event_id uuid,
  event_title text,
  event_status public.event_status,
  starts_at timestamptz,
  ends_at timestamptz,
  timezone text,
  venue text,
  city text,
  kind public.event_kind,
  cover_path text,
  organization_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
  v_key text := private.vault_secret('ticketsur_qr_encryption_key');
begin
  return query
    select t.id, t.public_reference, t.status, t.redeemed_at, c.name, c.is_invitation,
           t.holder_name,
           case when t.status = 'issued'
                then extensions.pgp_sym_decrypt(s.token_ciphertext, v_key) end,
           e.id, e.title, e.status, e.starts_at, e.ends_at, e.timezone, e.venue, e.city,
           e.kind, e.cover_path, o.name
      from public.tickets t
      join public.events e on e.id = t.event_id
      join public.organizations o on o.id = e.organization_id
      join public.ticket_categories c on c.id = t.category_id
      join private.ticket_secrets s on s.ticket_id = t.id
     where t.holder_user_id = v_actor
     order by (e.ends_at < now()), e.starts_at, t.public_reference
     limit 200;
end;
$$;
revoke all on function public.my_tickets() from public, anon;
grant execute on function public.my_tickets() to authenticated;

-- Retire un ticket de « Mes tickets » (il redevient ajoutable).
create function public.release_ticket(p_ticket_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
  v_org uuid;
begin
  update public.tickets t set holder_user_id = null
   where t.id = p_ticket_id and t.holder_user_id = v_actor
  returning (select e.organization_id from public.events e where e.id = t.event_id) into v_org;
  if not found then
    raise exception 'ticket_not_found' using errcode = 'P0002', detail = 'Ticket introuvable.';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org, v_actor, 'ticket.released', 'ticket', p_ticket_id, '{}'::jsonb);
end;
$$;
revoke all on function public.release_ticket(uuid) from public, anon;
grant execute on function public.release_ticket(uuid) to authenticated;
