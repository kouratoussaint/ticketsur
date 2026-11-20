import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_block.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';

/// Facturation du promoteur sur Supabase.
class SupabaseBillingRepository implements BillingRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  Future<T> _call<T>(String function, [Map<String, Object?>? params]) async {
    try {
      return await _client.rpc<T>(function, params: params).timeout(_timeout);
    } on Object catch (error) {
      throw mapBillingError(error);
    }
  }

  CreatedRequest _created(Map<String, dynamic> json) => (
    id: json['id']! as String,
    reference: json['reference']! as String,
    amount: (json['amount']! as num).toInt(),
  );

  @override
  Future<MyBilling> myBilling() async =>
      MyBilling.fromJson(await _call<Map<String, dynamic>>('my_billing'));

  @override
  Future<List<BillingPack>> catalog() async {
    final rows = await _call<List<dynamic>>('billing_catalog');
    return [
      for (final row in rows)
        BillingPack.fromJson(Map<String, Object?>.from(row as Map)),
    ];
  }

  @override
  Future<CreatedRequest> requestPack(
    String packId,
    BillingDuration duration,
    Map<String, int> addons,
  ) async => _created(
    await _call<Map<String, dynamic>>('request_billing_pack', {
      'p_pack_id': packId,
      'p_duration': duration.wireName,
      'p_addons': addons,
    }),
  );

  @override
  Future<CreatedRequest> requestAddons(Map<String, int> addons) async =>
      _created(
        await _call<Map<String, dynamic>>('request_billing_addons', {
          'p_addons': addons,
        }),
      );

  @override
  Future<void> declarePayment(
    String requestId,
    PaymentChannel channel,
    String? transaction,
  ) => _call<void>('declare_billing_payment', {
    'p_request_id': requestId,
    'p_channel': channel.wireName,
    'p_transaction': transaction,
  });

  @override
  Future<void> cancelRequest(String requestId) =>
      _call<void>('cancel_billing_request', {'p_request_id': requestId});

  @override
  Future<void> setOrganizationBilling(
    String organizationId,
    BillingSystem system,
    String? usagePackId,
  ) => _call<Map<String, dynamic>>('set_organization_billing', {
    'p_organization_id': organizationId,
    'p_default': system.wireName,
    'p_usage_pack_id': usagePackId,
  });

  @override
  Future<void> startTrial(String packId) =>
      _call<Map<String, dynamic>>('start_billing_trial', {'p_pack_id': packId});

  @override
  Future<EventBilling> eventBilling(String eventId) async =>
      EventBilling.fromJson(
        await _call<Map<String, dynamic>>('event_billing', {
          'p_event_id': eventId,
        }),
      );

  @override
  Future<EventBilling> setEventBilling(
    String eventId,
    EventBillingMode mode,
    String? usagePackId,
  ) async => EventBilling.fromJson(
    await _call<Map<String, dynamic>>('set_event_billing', {
      'p_event_id': eventId,
      'p_mode': mode.wireName,
      'p_usage_pack_id': usagePackId,
    }),
  );

  @override
  Future<EventBilling> addEventAddon(
    String eventId,
    BillingOption option,
    int units,
  ) async => EventBilling.fromJson(
    await _call<Map<String, dynamic>>('add_event_billing_addon', {
      'p_event_id': eventId,
      'p_option': option.key,
      'p_units': units,
    }),
  );
}

/// Traduit une erreur réseau ou PostgREST en [BillingFailure].
BillingFailure mapBillingError(Object error) {
  if (error is BillingFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return BillingFailure.network;
  }
  if (error is supabase.PostgrestException) {
    captureBillingBlock(error);
    return switch (error.message) {
      'billing_pack_invalid' => BillingFailure.packInvalid,
      'billing_addons_invalid' => BillingFailure.addonsInvalid,
      'billing_payment_invalid' => BillingFailure.paymentInvalid,
      'billing_request_not_found' => BillingFailure.requestProcessed,
      'billing_subscription_missing' => BillingFailure.noSubscription,
      'billing_choice_invalid' => BillingFailure.choiceInvalid,
      'billing_locked' => BillingFailure.locked,
      'billing_trial_used' => BillingFailure.trialUsed,
      'billing_trial_unavailable' => BillingFailure.trialUnavailable,
      'event_not_found' => BillingFailure.forbidden,
      _ => BillingFailure.unknown,
    };
  }
  return BillingFailure.unknown;
}
