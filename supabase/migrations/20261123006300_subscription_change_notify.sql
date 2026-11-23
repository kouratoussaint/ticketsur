-- ADR 0053 : le promoteur est prévenu quand la console change son
-- abonnement (demande de Toussaint, 23/11) : pack changé, date de fin
-- modifiée, suppléments réglés. Corps recopiés de la migration 3700 ;
-- `create or replace` retire les paramètres SET de la fonction : la
-- permission `billing` (migration 4900) est reposée ici.

create or replace function public.admin_change_subscription_pack(
  p_subscription_id uuid,
  p_pack_id uuid,
  p_note text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
set application_name = 'tikeo.perm:billing'
as $$
declare
  v_sub public.billing_subscriptions;
  v_snapshot jsonb;
  v_note text;
begin
  perform private.require_platform_admin();
  v_note := private.billing_require_note(p_note);
  v_sub := private.billing_active_subscription(p_subscription_id);
  select private.billing_pack_snapshot(p.id) into v_snapshot
    from public.billing_packs p where p.id = p_pack_id and p.system = 'flat';
  if v_snapshot is null then
    raise exception 'billing_pack_invalid' using errcode = '22023', detail = 'Choisissez un pack forfait.';
  end if;
  perform private.billing_addons_cost(v_snapshot, v_sub.addons, 1);
  update public.billing_subscriptions s
     set pack_id = p_pack_id, snapshot = v_snapshot, note = v_note
   where s.id = p_subscription_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_subscription_pack_changed', 'billing_subscription',
          p_subscription_id, '{}'::jsonb);
  if v_sub.pack_id is distinct from p_pack_id then
    perform private.billing_push(v_sub.account_id, 'Votre pack a changé', 'Your pack has changed',
      format('Votre pack est maintenant %s (au lieu de %s). Vos dates ne changent pas.',
             v_snapshot->>'name', v_sub.snapshot->>'name'),
      format('Your pack is now %s (instead of %s). Your dates do not change.',
             v_snapshot->>'name', v_sub.snapshot->>'name'),
      '/facturation');
  end if;
end;
$$;

create or replace function public.admin_extend_subscription(
  p_subscription_id uuid,
  p_ends_at timestamptz,
  p_note text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
set application_name = 'tikeo.perm:billing'
as $$
declare
  v_sub public.billing_subscriptions;
  v_note text;
begin
  perform private.require_platform_admin();
  v_note := private.billing_require_note(p_note);
  v_sub := private.billing_active_subscription(p_subscription_id);
  if p_ends_at is null or p_ends_at <= v_sub.starts_at then
    raise exception 'billing_subscription_invalid'
      using errcode = '22023', detail = 'La fin doit suivre le début de l''abonnement.';
  end if;
  update public.billing_subscriptions s
     set ends_at = p_ends_at, reminded_at = null, note = v_note
   where s.id = p_subscription_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_subscription_extended', 'billing_subscription',
          p_subscription_id, jsonb_build_object('later', p_ends_at > coalesce(v_sub.ends_at, p_ends_at)));
  if v_sub.ends_at is distinct from p_ends_at then
    perform private.billing_push(v_sub.account_id,
      'Date de fin de votre pack modifiée', 'Your pack end date has changed',
      format('Votre pack %s se termine maintenant le %s.', v_sub.snapshot->>'name',
             to_char(p_ends_at at time zone 'UTC', 'DD/MM/YYYY')),
      format('Your %s pack now ends on %s.', v_sub.snapshot->>'name',
             to_char(p_ends_at at time zone 'UTC', 'YYYY-MM-DD')),
      '/facturation');
  end if;
end;
$$;

create or replace function public.admin_set_subscription_addons(
  p_subscription_id uuid,
  p_addons jsonb,
  p_note text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
set application_name = 'tikeo.perm:billing'
as $$
declare
  v_sub public.billing_subscriptions;
  v_note text;
  v_addons jsonb;
begin
  perform private.require_platform_admin();
  v_note := private.billing_require_note(p_note);
  v_sub := private.billing_active_subscription(p_subscription_id);
  -- Zéro tranche : le supplément disparaît.
  select coalesce(jsonb_object_agg(a.key, a.value), '{}'::jsonb) into v_addons
    from jsonb_each(coalesce(p_addons, '{}'::jsonb)) a
   where jsonb_typeof(a.value) <> 'number' or (a.value::text)::numeric <> 0;
  perform private.billing_addons_cost(v_sub.snapshot, v_addons, 1);
  update public.billing_subscriptions s
     set addons = v_addons, note = v_note
   where s.id = p_subscription_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_subscription_addons_set', 'billing_subscription',
          p_subscription_id, jsonb_build_object('options', (select count(*) from jsonb_object_keys(v_addons))));
  if v_sub.addons is distinct from v_addons then
    perform private.billing_push(v_sub.account_id, 'Suppléments modifiés', 'Add-ons updated',
      format('Les suppléments de votre pack %s ont été mis à jour.', v_sub.snapshot->>'name'),
      format('The add-ons of your %s pack were updated.', v_sub.snapshot->>'name'),
      '/facturation');
  end if;
end;
$$;
