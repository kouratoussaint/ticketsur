-- =============================================================================
-- Tikéo — Mon ticket : fiche publique de l'événement et page de la structure
-- (amélioration n° 8 validée par Toussaint le 22/11/2026, ADR 0046)
-- =============================================================================
-- `my_tickets` renvoie aussi l'identifiant de la structure et si l'événement
-- est visible au catalogue (`private.is_listed`) : l'app rend alors
-- l'événement et la structure touchables. Corps recopié de la migration 3200.

drop function public.my_tickets();
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
  organization_name text,
  event_number integer,
  tagline text,
  organization_logo_path text,
  template jsonb,
  organization_id uuid,
  event_listed boolean
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
           e.kind, e.cover_path, o.name,
           t.event_number, e.tagline, o.logo_path, private.template_json(c.id),
           o.id, private.is_listed(e)
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
