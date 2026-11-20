import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/domain/event_billing.dart';

export 'package:ticketsur/features/billing/domain/event_billing.dart';

DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value).toUtc() : null;

Map<String, int> _units(Object? value) => {
  for (final MapEntry(:key, :value) in ((value as Map?) ?? const {}).entries)
    key as String: (value as num).toInt(),
};

/// Numéros de paiement de Tikéo (réglages de la console).
@immutable
final class PaymentInfo {
  const new({
    this.orangeMoneyNumber,
    this.moovMoneyNumber,
    this.beneficiary,
    this.instructions,
  });

  factory fromJson(Map<String, Object?>? json) => PaymentInfo(
    orangeMoneyNumber: json?['orange_money_number'] as String?,
    moovMoneyNumber: json?['moov_money_number'] as String?,
    beneficiary: json?['beneficiary'] as String?,
    instructions: json?['instructions'] as String?,
  );

  final String? orangeMoneyNumber;
  final String? moovMoneyNumber;
  final String? beneficiary;
  final String? instructions;
}

/// Droits forfait du compte : abonnement en vigueur, sinon pack gratuit.
@immutable
final class BillingPlan {
  const new({
    required this.pack,
    required this.duration,
    this.subscriptionId,
    this.addons = const {},
    this.periodStart,
    this.periodEnd,
    this.grace = false,
  });

  factory fromJson(Map<String, Object?> json) => BillingPlan(
    pack: BillingPack.fromJson(
      Map<String, Object?>.from(json['snapshot']! as Map),
    ),
    subscriptionId: json['subscription_id'] as String?,
    duration:
        BillingDuration.fromWire(json['duration']) ?? BillingDuration.unlimited,
    addons: _units(json['addons']),
    periodStart: _date(json['period_start']),
    periodEnd: _date(json['period_end']),
    grace: json['grace'] == true,
  );

  /// Copie du pack au moment de l'activation.
  final BillingPack pack;
  final String? subscriptionId;
  final BillingDuration duration;
  final Map<String, int> addons;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// Abonnement terminé, dans sa période de grâce.
  final bool grace;

  /// Pack gratuit (aucun abonnement en vigueur).
  bool get isFree => subscriptionId == null;

  /// Essai gratuit en cours.
  bool get isTrial => duration == BillingDuration.trial;

  /// Abonnement payant (suppléments possibles en cours de route).
  bool get isPaid =>
      subscriptionId != null &&
      pack.code == null &&
      duration != BillingDuration.unlimited &&
      duration != BillingDuration.trial;
}

/// Structure du compte et sa facturation par défaut.
@immutable
final class BillingOrganization {
  const new({
    required this.id,
    required this.name,
    required this.system,
    this.usagePackId,
  });

  factory fromJson(Map<String, Object?> json) => BillingOrganization(
    id: json['id']! as String,
    name: json['name']! as String,
    system: BillingSystem.fromWire(json['billing_default']),
    usagePackId: json['usage_pack_id'] as String?,
  );

  final String id;
  final String name;
  final BillingSystem system;
  final String? usagePackId;
}

/// État d'une demande d'activation.
enum RequestStatus {
  pending('pending'),
  activated('activated'),
  refused('refused'),
  cancelled('cancelled');

  new(this.wireName);

  final String wireName;

  static RequestStatus fromWire(Object? value) => switch (value) {
    'activated' => RequestStatus.activated,
    'refused' => RequestStatus.refused,
    'cancelled' => RequestStatus.cancelled,
    _ => RequestStatus.pending,
  };
}

/// Demande d'activation du promoteur (P5, P6).
@immutable
final class MyBillingRequest {
  const new({
    required this.id,
    required this.addonsOnly,
    required this.amount,
    required this.reference,
    required this.status,
    required this.createdAt,
    this.packId,
    this.duration,
    this.addons = const {},
    this.declaredChannel,
  });

  factory fromJson(Map<String, Object?> json) => MyBillingRequest(
    id: json['id']! as String,
    addonsOnly: json['kind'] == 'addons',
    packId: json['pack_id'] as String?,
    duration: BillingDuration.fromWire(json['duration']),
    addons: _units(json['addons']),
    amount: (json['amount']! as num).toInt(),
    reference: json['reference']! as String,
    declaredChannel: PaymentChannel.fromWire(json['declared_channel']),
    status: RequestStatus.fromWire(json['status']),
    createdAt: DateTime.parse(json['created_at']! as String).toUtc(),
  );

  final String id;
  final bool addonsOnly;
  final String? packId;
  final BillingDuration? duration;
  final Map<String, int> addons;
  final int amount;
  final String reference;
  final PaymentChannel? declaredChannel;
  final RequestStatus status;
  final DateTime createdAt;

  bool get declared => declaredChannel != null;
}

/// Ligne d'une facture à l'usage (entrées, palier, supplément).
@immutable
final class InvoiceLine {
  const new({
    required this.kind,
    required this.amount,
    this.count = 0,
    this.price = 0,
    this.from,
    this.to,
    this.option,
  });

  factory fromJson(Map<String, Object?> json) => InvoiceLine(
    kind: json['kind']! as String,
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    count: ((json['count'] ?? json['units']) as num?)?.toInt() ?? 0,
    price: (json['price'] as num?)?.toInt() ?? 0,
    from: (json['from'] as num?)?.toInt(),
    to: (json['to'] as num?)?.toInt(),
    option: BillingOption.byKey((json['option'] as String?) ?? ''),
  );

  /// `entries`, `tier` ou `addon`.
  final String kind;
  final int amount;
  final int count;
  final int price;
  final int? from;
  final int? to;
  final BillingOption? option;
}

/// Facture à l'usage du promoteur (P7).
@immutable
final class MyInvoice {
  const new({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.entries,
    required this.amount,
    required this.paid,
    required this.overdue,
    required this.issuedAt,
    required this.dueAt,
    this.lines = const [],
    this.paidAt,
    this.freeEntries = 0,
    this.billableEntries = 0,
    this.entriesAmount = 0,
    this.addonsAmount = 0,
    this.packName,
  });

  factory fromJson(Map<String, Object?> json) => MyInvoice(
    id: json['id']! as String,
    eventId: json['event_id']! as String,
    eventTitle: json['event_title']! as String,
    entries: (json['entries'] as num?)?.toInt() ?? 0,
    amount: (json['amount']! as num).toInt(),
    lines: [
      for (final line in (json['lines'] as List?) ?? const [])
        InvoiceLine.fromJson(Map<String, Object?>.from(line as Map)),
    ],
    paid: json['status'] == 'paid',
    overdue: json['overdue'] == true,
    issuedAt: DateTime.parse(json['issued_at']! as String).toUtc(),
    dueAt: DateTime.parse(json['due_at']! as String).toUtc(),
    paidAt: _date(json['paid_at']),
    freeEntries: (json['free_entries'] as num?)?.toInt() ?? 0,
    billableEntries: (json['billable_entries'] as num?)?.toInt() ?? 0,
    entriesAmount: (json['entries_amount'] as num?)?.toInt() ?? 0,
    addonsAmount: (json['addons_amount'] as num?)?.toInt() ?? 0,
    packName: json['pack_name'] as String?,
  );

  final String id;
  final String eventId;
  final String eventTitle;
  final int entries;
  final int amount;
  final List<InvoiceLine> lines;
  final bool paid;
  final bool overdue;
  final DateTime issuedAt;
  final DateTime dueAt;
  final DateTime? paidAt;
  final int freeEntries;
  final int billableEntries;
  final int entriesAmount;
  final int addonsAmount;
  final String? packName;

  /// Référence à indiquer avec le paiement d'une facture.
  String get reference => 'F-${id.substring(0, 6).toUpperCase()}';
}

/// Consommation du compte (jauges de « Mon pack »).
typedef BillingUsage = ({
  int structures,
  int activeEvents,
  int ticketsPeriod,
  int membersMax,
});

/// « Mon pack » : droits, consommation, structures, demandes, factures.
@immutable
final class MyBilling {
  const new({
    required this.plan,
    this.limits = const {},
    this.features = const {},
    this.usage = (
      structures: 0,
      activeEvents: 0,
      ticketsPeriod: 0,
      membersMax: 0,
    ),
    this.organizations = const [],
    this.requests = const [],
    this.invoices = const [],
    this.payment = const PaymentInfo(),
    this.trialUsed = false,
  });

  factory fromJson(Map<String, Object?> json) {
    final usage = Map<String, Object?>.from(
      (json['usage'] as Map?) ?? const {},
    );
    int count(String key) => (usage[key] as num?)?.toInt() ?? 0;
    List<T> list<T>(String key, T Function(Map<String, Object?>) read) => [
      for (final row in (json[key] as List?) ?? const [])
        read(Map<String, Object?>.from(row as Map)),
    ];
    return MyBilling(
      plan: BillingPlan.fromJson(
        Map<String, Object?>.from(json['plan']! as Map),
      ),
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
      usage: (
        structures: count('structures'),
        activeEvents: count('active_events'),
        ticketsPeriod: count('tickets_period'),
        membersMax: count('members_max'),
      ),
      organizations: list('organizations', BillingOrganization.fromJson),
      requests: list('requests', MyBillingRequest.fromJson),
      invoices: list('invoices', MyInvoice.fromJson),
      payment: PaymentInfo.fromJson(
        (json['payment'] as Map?)?.cast<String, Object?>(),
      ),
      trialUsed: json['trial_used'] == true,
    );
  }

  final BillingPlan plan;

  /// Limites des options chiffrées (null : illimité), suppléments compris.
  final Map<BillingOption, int?> limits;

  /// Fonctions comprises.
  final Map<BillingOption, bool> features;
  final BillingUsage usage;
  final List<BillingOrganization> organizations;
  final List<MyBillingRequest> requests;
  final List<MyInvoice> invoices;
  final PaymentInfo payment;

  /// Essai gratuit déjà utilisé par ce compte (une fois au plus).
  final bool trialUsed;

  /// Demande en attente (une seule à la fois).
  MyBillingRequest? get pending {
    for (final request in requests) {
      if (request.status == RequestStatus.pending) return request;
    }
    return null;
  }

  /// Factures à payer (dues), en retard d'abord.
  List<MyInvoice> get dueInvoices => [
    for (final invoice in invoices)
      if (!invoice.paid && invoice.overdue) invoice,
    for (final invoice in invoices)
      if (!invoice.paid && !invoice.overdue) invoice,
  ];

  MyInvoice? invoiceById(String id) {
    for (final invoice in invoices) {
      if (invoice.id == id) return invoice;
    }
    return null;
  }

  MyBillingRequest? requestById(String id) {
    for (final request in requests) {
      if (request.id == id) return request;
    }
    return null;
  }
}

/// Demande créée : montant, référence et numéros de paiement (P5).
typedef CreatedRequest = ({String id, String reference, int amount});

/// Erreurs de la facturation côté promoteur.
enum BillingFailure implements Exception {
  /// Pack ou durée indisponible.
  packInvalid,

  /// Supplément impossible (option, tranche, plafond).
  addonsInvalid,

  /// Canal ou identifiant de transaction invalide.
  paymentInvalid,

  /// Demande introuvable ou déjà traitée.
  requestProcessed,

  /// Aucun abonnement payant en cours (suppléments).
  noSubscription,

  /// Choix de facturation invalide (structure, événement).
  choiceInvalid,

  /// Facturation d'un événement figée au premier ticket.
  locked,

  /// Essai gratuit déjà utilisé.
  trialUsed,

  /// Essai impossible pendant un abonnement payant.
  trialUnavailable,

  /// Événement introuvable ou droits insuffisants.
  forbidden,

  network,
  unknown,
}

/// Facturation du promoteur (RPC de la migration 3600).
abstract interface class BillingRepository {
  Future<MyBilling> myBilling();

  /// Packs publiés.
  Future<List<BillingPack>> catalog();

  Future<CreatedRequest> requestPack(
    String packId,
    BillingDuration duration,
    Map<String, int> addons,
  );

  Future<CreatedRequest> requestAddons(Map<String, int> addons);

  Future<void> declarePayment(
    String requestId,
    PaymentChannel channel,
    String? transaction,
  );

  Future<void> cancelRequest(String requestId);

  Future<void> setOrganizationBilling(
    String organizationId,
    BillingSystem system,
    String? usagePackId,
  );

  /// Essai gratuit d'un pack forfait (une fois par compte).
  Future<void> startTrial(String packId);

  /// Facturation d'un événement (P9) : choix, verrou, droits, estimation.
  Future<EventBilling> eventBilling(String eventId);

  Future<EventBilling> setEventBilling(
    String eventId,
    EventBillingMode mode,
    String? usagePackId,
  );

  /// « Dépasser la limite » : supplément d'un événement à l'usage.
  Future<EventBilling> addEventAddon(
    String eventId,
    BillingOption option,
    int units,
  );
}

/// Estimation d'une facture à l'usage pour [entries] entrées réelles
/// (même calcul que `private.billing_usage_amount`, sans suppléments) :
/// entrées offertes d'abord, puis paliers marginaux du plus bas au plus haut.
({int billable, int amount, List<({int from, int to, int price})> tiers})
usageEstimate(BillingPack pack, int entries) {
  final billable = (entries - pack.freeEntries).clamp(0, entries);
  if (pack.tiers.isEmpty) {
    final price = pack.entryPrice ?? 0;
    return (
      billable: billable,
      amount: billable * price,
      tiers: [if (billable > 0) (from: 1, to: billable, price: price)],
    );
  }
  final tiers = [...pack.tiers]
    ..sort((a, b) => (a.upTo ?? 1 << 30).compareTo(b.upTo ?? 1 << 30));
  var from = 0;
  var amount = 0;
  final lines = <({int from, int to, int price})>[];
  for (final tier in tiers) {
    if (from >= billable) break;
    final count = ((tier.upTo ?? billable).clamp(0, billable)) - from;
    if (count <= 0) continue;
    amount += count * tier.price;
    lines.add((from: from + 1, to: from + count, price: tier.price));
    from += count;
  }
  return (billable: billable, amount: amount, tiers: lines);
}
