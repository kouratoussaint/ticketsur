-- =============================================================================
-- Tikéo — Notification de test (Paramètres › Notifications)
-- =============================================================================
-- Le compte connecté s'envoie une notification à ses propres appareils, pour
-- vérifier la réception sur son téléphone. 5 par heure au plus. Aucun
-- contenu personnel : titre et texte fixes.
-- =============================================================================

create function public.send_test_push()
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
begin
  if not exists (select 1 from public.push_devices d where d.user_id = v_actor) then
    raise exception 'push_no_device' using errcode = 'P0002',
      detail = 'Aucun téléphone enregistré pour ce compte.';
  end if;
  if (select count(*) from public.push_outbox o
       where o.user_id = v_actor and o.route = '/parametres'
         and o.created_at > now() - interval '1 hour') >= 5 then
    raise exception 'push_test_rate_limited' using errcode = '54000',
      detail = 'Trop d''essais : réessayez dans une heure.';
  end if;
  insert into public.push_outbox (user_id, title, body, route)
  values (v_actor, 'Tikéo', 'Les notifications fonctionnent sur ce téléphone.', '/parametres');
end;
$$;
revoke all on function public.send_test_push() from public, anon;
grant execute on function public.send_test_push() to authenticated;
