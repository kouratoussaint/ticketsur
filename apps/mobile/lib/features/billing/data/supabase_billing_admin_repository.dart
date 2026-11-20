import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/billing/domain/billing_admin.dart';

/// Console de facturation sur Supabase (RPC `admin_*`).
class SupabaseBillingAdminRepository implements BillingAdminRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  Future<T> _call<T>(String function, [Map<String, Object?>? params]) =>
      _guard(() => _client.rpc<T>(function, params: params).timeout(_timeout));

  Map<String, Object?> _payment(ReceivedPayment payment) => {
    'p_channel': payment.channel.wireName,
    'p_operator_reference': payment.operatorReference,
    'p_paid_at': payment.paidAt?.toUtc().toIso8601String(),
    'p_note': payment.note,
  };

  @override
  Future<AdminBilling> load() async {
    final json = await _call<Map<String, dynamic>>('admin_billing');
    return AdminBilling.fromJson(json);
  }

  @override
  Future<String> savePack(String? id, BillingPack pack) async =>
      await _call<String>('admin_save_pack', {
        'p_pack_id': id,
        'p_data': pack.toSaveJson(),
      });

  @override
  Future<void> setPackStatus(String id, PackStatus status) => _call<void>(
    'admin_set_pack_status',
    {'p_pack_id': id, 'p_status': status.wireName},
  );

  @override
  Future<void> saveSettings(BillingSettings settings) =>
      _call<void>('admin_save_billing_settings', {'p_data': settings.toJson()});

  @override
  Future<void> activateRequest(String id, ReceivedPayment payment) =>
      _call<String>('admin_activate_request', {
        'p_request_id': id,
        ..._payment(payment),
      });

  @override
  Future<void> refuseRequest(String id, String? note) =>
      _call<void>('admin_refuse_request', {'p_request_id': id, 'p_note': note});

  @override
  Future<void> markInvoicePaid(String id, ReceivedPayment payment) =>
      _call<void>('admin_mark_invoice_paid', {
        'p_invoice_id': id,
        ..._payment(payment),
      });

  @override
  Future<void> issueInvoice(String eventId) =>
      _call<String>('admin_issue_invoice', {'p_event_id': eventId});

  @override
  Future<void> grantSubscription({
    required String accountId,
    required String packId,
    required BillingDuration duration,
    required String note,
  }) => _call<String>('admin_grant_subscription', {
    'p_account_id': accountId,
    'p_pack_id': packId,
    'p_duration': duration.wireName,
    'p_note': note,
  });

  @override
  Future<void> cancelSubscription(String id, String note) => _call<void>(
    'admin_cancel_subscription',
    {'p_subscription_id': id, 'p_note': note},
  );

  @override
  Future<void> extendSubscription(String id, DateTime endsAt, String note) =>
      _call<void>('admin_extend_subscription', {
        'p_subscription_id': id,
        'p_ends_at': endsAt.toUtc().toIso8601String(),
        'p_note': note,
      });

  @override
  Future<void> changeSubscriptionPack(String id, String packId, String note) =>
      _call<void>('admin_change_subscription_pack', {
        'p_subscription_id': id,
        'p_pack_id': packId,
        'p_note': note,
      });

  @override
  Future<void> setSubscriptionAddons(
    String id,
    Map<String, int> addons,
    String note,
  ) => _call<void>('admin_set_subscription_addons', {
    'p_subscription_id': id,
    'p_addons': addons,
    'p_note': note,
  });

  @override
  Future<List<BillingEventRow>> events(String search) async {
    final rows = await _call<List<dynamic>>('admin_billing_events', {
      'p_search': search,
      'p_limit': 30,
    });
    return [
      for (final row in rows)
        BillingEventRow.fromJson(Map<String, Object?>.from(row as Map)),
    ];
  }

  @override
  Future<void> setEventBilling(
    String eventId,
    BillingSystem system,
    String? usagePackId,
    String note,
  ) => _call<void>('admin_set_event_billing', {
    'p_event_id': eventId,
    'p_system': system.wireName,
    'p_usage_pack_id': usagePackId,
    'p_note': note,
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapBillingAdminError(error);
    }
  }
}

/// Traduit une erreur réseau ou PostgREST en [BillingAdminFailure].
BillingAdminFailure mapBillingAdminError(Object error) {
  if (error is BillingAdminFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return BillingAdminFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return switch (error.message) {
      'forbidden' => BillingAdminFailure.forbidden,
      'billing_note_required' => BillingAdminFailure.noteRequired,
      'billing_pack_invalid' ||
      'billing_pack_not_found' => BillingAdminFailure.packInvalid,
      'billing_pack_protected' => BillingAdminFailure.packProtected,
      'billing_addons_invalid' => BillingAdminFailure.addonsInvalid,
      'billing_settings_invalid' => BillingAdminFailure.settingsInvalid,
      'billing_payment_invalid' => BillingAdminFailure.paymentInvalid,
      'billing_request_not_found' ||
      'billing_invoice_not_found' ||
      'billing_subscription_missing' => BillingAdminFailure.alreadyProcessed,
      'billing_subscription_invalid' => BillingAdminFailure.subscriptionInvalid,
      'billing_choice_invalid' => BillingAdminFailure.choiceInvalid,
      'billing_invoice_exists' => BillingAdminFailure.invoiceExists,
      _ when error.code == '42501' => BillingAdminFailure.forbidden,
      _ => BillingAdminFailure.unknown,
    };
  }
  return BillingAdminFailure.unknown;
}
