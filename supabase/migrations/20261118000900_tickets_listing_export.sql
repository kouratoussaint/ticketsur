-- =============================================================================
-- TicketSûr — Migration 0900 : liste des billets et ré-export audité
-- (S13, S14, S15 ; décision du 2026-11-18 : re-téléchargement autorisé)
-- =============================================================================
-- * event_tickets : billets d'un événement pour les organisateurs, filtrés
--   (statut, référence ou catégorie) et paginés, sans aucun secret.
-- * export_tickets : relit les jetons QR (copie chiffrée AES-256, ADR 0003)
--   de billets déjà émis, pour les ré-afficher, les partager ou les imprimer.
--   - organisateurs (propriétaire, gestionnaire) uniquement ;
--   - 200 billets au plus par appel ; billets annulés exclus ;
--   - CHAQUE appel est journalisé (« tickets.exported », identifiants et
--     nombre, jamais les jetons).
--
-- Erreurs (MESSAGE = code stable) :
--   42501 event_not_found | ticket_not_found
--   22023 export_params_invalid
-- =============================================================================

create or replace function public.event_tickets(
  p_event_id uuid,
  p_status public.ticket_status default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  id uuid,
  public_reference text,
  category_id uuid,
  category_name text,
  status public.ticket_status,
  issued_at timestamptz,
  redeemed_at timestamptz,
  redeemed_checkpoint_name text,
  revoked_at timestamptz,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_search text := nullif(upper(trim(coalesce(p_search, ''))), '');
begin
  if not exists (
    select 1 from public.events e
    where e.id = p_event_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  ) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  return query
    select t.id, t.public_reference, t.category_id, c.name, t.status, t.issued_at,
           t.redeemed_at, cp.name, t.revoked_at,
           count(*) over ()
    from public.tickets t
    join public.ticket_categories c on c.id = t.category_id
    left join public.checkpoints cp on cp.id = t.redeemed_checkpoint_id
    where t.event_id = p_event_id
      and (p_status is null or t.status = p_status)
      and (v_search is null
           or t.public_reference like '%' || v_search || '%'
           or upper(c.name) like '%' || v_search || '%')
    order by t.issued_at desc, t.public_reference
    limit least(greatest(coalesce(p_limit, 50), 1), 200)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;
revoke all on function public.event_tickets(uuid, public.ticket_status, text, integer, integer)
  from public, anon;
grant execute on function public.event_tickets(uuid, public.ticket_status, text, integer, integer)
  to authenticated;

create or replace function public.export_tickets(p_ticket_ids uuid[])
returns table (
  ticket_id uuid,
  public_reference text,
  qr_token text,
  status public.ticket_status,
  category_name text,
  event_id uuid
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_enc_key text;
  v_count integer;
  v_events uuid[];
  v_orgs uuid[];
begin
  if p_ticket_ids is null or cardinality(p_ticket_ids) not between 1 and 200 then
    raise exception 'export_params_invalid'
      using errcode = '22023', detail = 'De 1 à 200 billets par export.';
  end if;

  -- Tous les billets demandés doivent exister et être gérés par l'appelant.
  select count(*), array_agg(distinct t.event_id), array_agg(distinct e.organization_id)
    into v_count, v_events, v_orgs
  from public.tickets t
  join public.events e on e.id = t.event_id
  where t.id = any (p_ticket_ids)
    and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[]);
  if v_actor is null or v_count <> (select count(distinct x) from unnest(p_ticket_ids) x) then
    raise exception 'ticket_not_found'
      using errcode = '42501', detail = 'Billet introuvable ou droits insuffisants.';
  end if;

  v_enc_key := private.vault_secret('ticketsur_qr_encryption_key');

  -- Journal : un enregistrement par organisation concernée (en pratique une).
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  select o, v_actor, 'tickets.exported', 'event',
         case when cardinality(v_events) = 1 then v_events[1] end,
         jsonb_build_object('count', v_count, 'ticket_ids', to_jsonb(p_ticket_ids))
  from unnest(v_orgs) o;

  return query
    select t.id, t.public_reference,
           extensions.pgp_sym_decrypt(s.token_ciphertext, v_enc_key),
           t.status, c.name, t.event_id
    from public.tickets t
    join private.ticket_secrets s on s.ticket_id = t.id
    join public.ticket_categories c on c.id = t.category_id
    where t.id = any (p_ticket_ids)
      and t.status <> 'revoked'
    order by t.public_reference;
end;
$$;
revoke all on function public.export_tickets(uuid[]) from public, anon;
grant execute on function public.export_tickets(uuid[]) to authenticated;
