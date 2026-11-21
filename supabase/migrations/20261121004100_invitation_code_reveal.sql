-- Code d'invitation affichable (améliorations du 20/11, #5, ADR 0029).
-- Jusqu'ici, seule l'empreinte du code (code_hash) et ses 4 derniers
-- caractères étaient gardés : le code ne pouvait plus être réaffiché. On garde
-- désormais une copie chiffrée (même méthode que les jetons QR, ADR 0003 :
-- pgp_sym_encrypt avec la clé du coffre). code_hash reste seul utilisé pour
-- vérifier un code. L'affichage est réservé au propriétaire et aux
-- gestionnaires (selon le rôle de l'invitation), pour une invitation active,
-- inscrit au journal (sans le code) et limité à 30 par heure.

alter table public.organization_invitations add column code_ciphertext bytea;

create or replace function public.create_invitation(
  p_organization_id uuid,
  p_role public.member_role,
  p_valid_days integer default 7,
  p_max_uses integer default 1
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_code text;
  v_invitation public.organization_invitations%rowtype;
begin
  if not private.has_org_role(p_organization_id, array['owner','manager']::public.member_role[]) then
    raise exception 'org_forbidden'
      using errcode = '42501', detail = 'Organisation introuvable ou droits insuffisants.';
  end if;
  if p_role is null or p_role = 'owner' then
    raise exception 'invitation_role_invalid'
      using errcode = '22023', detail = 'Rôle : gestionnaire ou contrôleur.';
  end if;
  if not private.can_manage_role(p_organization_id, p_role) then
    raise exception 'org_forbidden'
      using errcode = '42501', detail = 'Seul le propriétaire invite des gestionnaires.';
  end if;
  if p_valid_days is null or p_valid_days not between 1 and 30
     or p_max_uses is null or p_max_uses not between 1 and 100 then
    raise exception 'invitation_params_invalid'
      using errcode = '22023', detail = 'Validité de 1 à 30 jours, 1 à 100 utilisations.';
  end if;

  loop
    v_code := private.new_invitation_code();
    begin
      insert into public.organization_invitations
        (organization_id, role, code_hash, code_hint, created_by, expires_at, max_uses,
         code_ciphertext)
      values
        (p_organization_id, p_role, private.invitation_code_hash(v_code), right(v_code, 4),
         auth.uid(), now() + make_interval(days => p_valid_days), p_max_uses,
         extensions.pgp_sym_encrypt(v_code,
                                    private.vault_secret('ticketsur_qr_encryption_key'),
                                    'cipher-algo=aes256'))
      returning * into v_invitation;
      exit;
    exception when unique_violation then
      null; -- collision (≈ 2^-60) : nouveau tirage
    end;
  end loop;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, auth.uid(), 'invitation.created', 'invitation', v_invitation.id,
          jsonb_build_object('role', p_role, 'expires_at', v_invitation.expires_at,
                             'max_uses', p_max_uses));

  -- Code en clair dans la réponse ; ensuite, seulement par
  -- reveal_invitation_code (copie chiffrée, accès limité et journalisé).
  return jsonb_build_object(
    'id', v_invitation.id,
    'code', v_code,
    'role', v_invitation.role,
    'code_hint', v_invitation.code_hint,
    'expires_at', v_invitation.expires_at,
    'max_uses', v_invitation.max_uses,
    'uses', 0
  );
end;
$$;
revoke all on function public.create_invitation(uuid, public.member_role, integer, integer) from public, anon;
grant execute on function public.create_invitation(uuid, public.member_role, integer, integer) to authenticated;

-- État d'une invitation.
create function private.invitation_state(p_invitation public.organization_invitations)
returns text
language sql
stable
set search_path = ''
as $$
  select case
    when p_invitation.revoked_at is not null then 'revoked'
    when p_invitation.uses >= p_invitation.max_uses then 'exhausted'
    when p_invitation.expires_at <= now() then 'expired'
    else 'active'
  end
$$;
revoke all on function private.invitation_state(public.organization_invitations) from public, anon, authenticated;

-- Détails d'une invitation (feuille de l'équipe).
create function public.invitation_details(p_invitation_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_invitation public.organization_invitations%rowtype;
begin
  select * into v_invitation from public.organization_invitations i where i.id = p_invitation_id;
  if not found or not private.can_manage_role(v_invitation.organization_id, v_invitation.role) then
    raise exception 'invitation_not_found'
      using errcode = '42501', detail = 'Invitation introuvable ou droits insuffisants.';
  end if;
  return jsonb_build_object(
    'id', v_invitation.id,
    'organization_id', v_invitation.organization_id,
    'organization_name', (select o.name from public.organizations o
                           where o.id = v_invitation.organization_id),
    'role', v_invitation.role,
    'state', private.invitation_state(v_invitation),
    'code_hint', v_invitation.code_hint,
    'code_available', v_invitation.code_ciphertext is not null,
    'created_by_name', (select p.display_name from public.profiles p
                         where p.id = v_invitation.created_by),
    'created_at', v_invitation.created_at,
    'expires_at', v_invitation.expires_at,
    'revoked_at', v_invitation.revoked_at,
    'uses', v_invitation.uses,
    'max_uses', v_invitation.max_uses,
    'used_by', coalesce((
      select jsonb_agg(jsonb_build_object('name', p.display_name, 'at', a.created_at)
                       order by a.created_at)
        from public.audit_logs a
        join public.profiles p on p.id = a.actor_id
       where a.action = 'invitation.accepted' and a.resource_id = v_invitation.id),
      '[]'::jsonb));
end;
$$;
revoke all on function public.invitation_details(uuid) from public, anon;
grant execute on function public.invitation_details(uuid) to authenticated;

-- Afficher le code d'une invitation active.
create function public.reveal_invitation_code(p_invitation_id uuid)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_invitation public.organization_invitations%rowtype;
  v_actor uuid := auth.uid();
begin
  select * into v_invitation from public.organization_invitations i where i.id = p_invitation_id;
  if not found or not private.can_manage_role(v_invitation.organization_id, v_invitation.role) then
    raise exception 'invitation_not_found'
      using errcode = '42501', detail = 'Invitation introuvable ou droits insuffisants.';
  end if;
  if private.invitation_state(v_invitation) <> 'active' then
    raise exception 'invitation_inactive'
      using errcode = '55000', detail = 'Invitation expirée, révoquée ou épuisée.';
  end if;
  if v_invitation.code_ciphertext is null then
    raise exception 'invitation_code_unavailable'
      using errcode = '55000', detail = 'Code non récupérable : créez une nouvelle invitation.';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('reveal_invitation:' || v_actor::text, 0));
  if (select count(*) from public.audit_logs a
       where a.actor_id = v_actor and a.action = 'invitation.code_revealed'
         and a.created_at > now() - interval '1 hour') >= 30 then
    raise exception 'invitation_reveal_limited'
      using errcode = '54000', detail = 'Trop d''affichages : réessayez dans une heure.';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_invitation.organization_id, v_actor, 'invitation.code_revealed', 'invitation',
          v_invitation.id, '{}'::jsonb);
  return extensions.pgp_sym_decrypt(v_invitation.code_ciphertext,
                                    private.vault_secret('ticketsur_qr_encryption_key'));
end;
$$;
revoke all on function public.reveal_invitation_code(uuid) from public, anon;
grant execute on function public.reveal_invitation_code(uuid) to authenticated;
