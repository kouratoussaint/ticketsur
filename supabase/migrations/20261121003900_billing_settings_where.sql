-- Correction (améliorations du 20/11, #21) : l'enregistrement des réglages de
-- paiement échouait sur Supabase. L'extension « safeupdate », chargée pour les
-- requêtes de l'API, refuse tout UPDATE sans clause WHERE (« UPDATE requires a
-- WHERE clause ») ; la table billing_settings n'a qu'une ligne, la fonction
-- n'en avait pas. Même corps, avec « where s.id » (clé booléenne, toujours vraie).

create or replace function public.admin_save_billing_settings(p_data jsonb)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  begin
    update public.billing_settings s
       set orange_money_number = nullif(trim(p_data->>'orange_money_number'), ''),
           moov_money_number = nullif(trim(p_data->>'moov_money_number'), ''),
           beneficiary = nullif(trim(p_data->>'beneficiary'), ''),
           instructions = nullif(trim(p_data->>'instructions'), ''),
           usage_payment_days = coalesce((p_data->>'usage_payment_days')::integer, s.usage_payment_days),
           invoice_delay_hours = coalesce((p_data->>'invoice_delay_hours')::integer, s.invoice_delay_hours),
           reminder_days = coalesce((p_data->>'reminder_days')::integer, s.reminder_days),
           grace_days = coalesce((p_data->>'grace_days')::integer, s.grace_days),
           updated_at = now()
     where s.id;
  exception
    when check_violation or invalid_text_representation or numeric_value_out_of_range then
      raise exception 'billing_settings_invalid' using errcode = '22023', detail = 'Réglages invalides.';
  end;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_settings_saved', 'billing_settings', null, '{}'::jsonb);
end;
$$;
revoke all on function public.admin_save_billing_settings(jsonb) from public, anon;
grant execute on function public.admin_save_billing_settings(jsonb) to authenticated;
