import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';

/// Réglage de la facturation d'un événement (P9).
enum EventBillingMode {
  /// Comme la structure.
  inherit('inherit'),
  flat('flat'),
  usage('usage');

  new(this.wireName);

  final String wireName;

  static EventBillingMode fromWire(Object? value) => switch (value) {
    'flat' => EventBillingMode.flat,
    'usage' => EventBillingMode.usage,
    _ => EventBillingMode.inherit,
  };
}

/// Calcul d'un montant à l'usage (`private.billing_usage_amount`).
@immutable
final class UsageAmount {
  const new({
    this.entries = 0,
    this.freeEntries = 0,
    this.billableEntries = 0,
    this.entriesAmount = 0,
    this.addonsAmount = 0,
    this.amount = 0,
  });

  factory fromJson(Map<String, Object?> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return UsageAmount(
      entries: read('entries'),
      freeEntries: read('free_entries'),
      billableEntries: read('billable_entries'),
      entriesAmount: read('entries_amount'),
      addonsAmount: read('addons_amount'),
      amount: read('amount'),
    );
  }

  final int entries;
  final int freeEntries;
  final int billableEntries;
  final int entriesAmount;
  final int addonsAmount;
  final int amount;
}

/// Facture émise pour l'événement.
typedef EventInvoice = ({String id, int amount, bool paid, DateTime dueAt});

/// `event_billing(événement)` : choix, verrou, droits, estimation, facture.
@immutable
final class EventBilling {
  const new({
    required this.mode,
    required this.system,
    this.usagePackId,
    this.locked = false,
    this.packName,
    this.addons = const {},
    this.limits = const {},
    this.features = const {},
    this.estimate,
    this.invoice,
  });

  factory fromJson(Map<String, Object?> json) {
    final invoice = (json['invoice'] as Map?)?.cast<String, Object?>();
    final estimate = (json['estimate'] as Map?)?.cast<String, Object?>();
    return EventBilling(
      mode: EventBillingMode.fromWire(json['mode']),
      system: BillingSystem.fromWire(json['system']),
      usagePackId: json['usage_pack_id'] as String?,
      locked: json['locked'] == true,
      packName: json['pack_name'] as String?,
      addons: {
        for (final MapEntry(:key, :value)
            in ((json['addons'] as Map?) ?? const {}).entries)
          ?BillingOption.byKey(key as String): (value as num).toInt(),
      },
      limits: {
        for (final MapEntry(:key, :value)
            in ((json['limits'] as Map?) ?? const {}).entries)
          ?BillingOption.byKey(key as String): (value as num?)?.toInt(),
      },
      features: {
        for (final MapEntry(:key, :value)
            in ((json['features'] as Map?) ?? const {}).entries)
          ?BillingOption.byKey(key as String): value == true,
      },
      estimate: estimate == null ? null : UsageAmount.fromJson(estimate),
      invoice: invoice == null
          ? null
          : (
              id: invoice['id']! as String,
              amount: (invoice['amount']! as num).toInt(),
              paid: invoice['status'] == 'paid',
              dueAt: DateTime.parse(invoice['due_at']! as String).toUtc(),
            ),
    );
  }

  final EventBillingMode mode;

  /// Système effectif (choix de l'événement ou de la structure).
  final BillingSystem system;
  final String? usagePackId;

  /// Figée dès le premier ticket émis.
  final bool locked;
  final String? packName;

  /// Suppléments confirmés (« Dépasser la limite »).
  final Map<BillingOption, int> addons;
  final Map<BillingOption, int?> limits;
  final Map<BillingOption, bool> features;

  /// Estimation en direct (à l'usage).
  final UsageAmount? estimate;
  final EventInvoice? invoice;

  /// Fonction comprise (option absente : comprise).
  bool allows(BillingOption option) => features[option] ?? true;
}
