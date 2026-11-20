import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/billing/domain/billing_option.dart';

/// Système de facturation d'un pack (ADR 0027).
enum BillingSystem {
  flat('flat'),
  usage('usage');

  new(this.wireName);

  final String wireName;

  static BillingSystem fromWire(Object? value) =>
      value == 'usage' ? BillingSystem.usage : BillingSystem.flat;
}

/// État d'un pack dans la console.
enum PackStatus {
  draft('draft'),
  published('published'),
  archived('archived');

  new(this.wireName);

  final String wireName;

  static PackStatus fromWire(Object? value) => switch (value) {
    'published' => PackStatus.published,
    'archived' => PackStatus.archived,
    _ => PackStatus.draft,
  };
}

/// Durées d'un forfait. `unlimited` : packs du système (Découverte).
enum BillingDuration {
  month('month', 1),
  quarter('quarter', 3),
  semester('semester', 6),
  year('year', 12),
  event('event', 1),
  unlimited('unlimited', 0);

  new(this.wireName, this.months);

  final String wireName;

  /// Mois couverts (prix calculé par défaut : prix mensuel × mois).
  final int months;

  /// Durées proposées à l'achat.
  static const List<BillingDuration> offered = [
    month,
    quarter,
    semester,
    year,
    event,
  ];

  static BillingDuration? fromWire(Object? value) {
    for (final duration in values) {
      if (duration.wireName == value) return duration;
    }
    return null;
  }

  /// Fin d'un abonnement qui commence à [start] (comme `billing_end`) ;
  /// null : sans fin.
  DateTime? endFrom(DateTime start) => switch (this) {
    unlimited => null,
    event => DateTime.utc(
      start.year + 1,
      start.month,
      start.day,
      start.hour,
      start.minute,
    ),
    _ => DateTime.utc(
      start.year,
      start.month + months,
      start.day,
      start.hour,
      start.minute,
    ),
  };
}

/// État d'une option oui / non dans un pack.
enum FeatureState {
  included('included'),
  addon('addon'),
  unavailable('unavailable');

  new(this.wireName);

  final String wireName;

  static FeatureState fromWire(Object? value) => switch (value) {
    'addon' => FeatureState.addon,
    'unavailable' => FeatureState.unavailable,
    _ => FeatureState.included,
  };
}

/// Réglage d'une option dans un pack. Option absente du pack : illimitée ou
/// comprise.
@immutable
final class PackOptionSetting {
  const new({
    required this.option,
    this.included,
    this.state = FeatureState.included,
    this.addonPrice,
    this.addonStep = 1,
    this.addonCap,
  });

  factory fromJson(BillingOption option, Map<String, Object?> json) =>
      PackOptionSetting(
        option: option,
        included: (json['included'] as num?)?.toInt(),
        state: FeatureState.fromWire(json['state']),
        addonPrice: (json['addon_price'] as num?)?.toInt(),
        addonStep: (json['addon_step'] as num?)?.toInt() ?? 1,
        addonCap: (json['addon_cap'] as num?)?.toInt(),
      );

  final BillingOption option;

  /// Option chiffrée : valeur incluse, null = illimitée.
  final int? included;

  /// Option oui / non.
  final FeatureState state;

  /// Prix d'une tranche de supplément ; null : pas de supplément possible.
  final int? addonPrice;
  final int addonStep;
  final int? addonCap;

  bool get addonAllowed => addonPrice != null;

  Map<String, Object?> toJson() => {
    'key': option.key,
    if (option.numeric) 'included': included else 'state': state.wireName,
    'addon_price': addonPrice,
    'addon_step': addonStep,
    'addon_cap': addonCap,
  };
}

/// Palier d'un pack à l'usage : prix par entrée jusqu'à `upTo` entrées
/// (null : au-delà).
typedef UsageTier = ({int? upTo, int price});

/// Pack de la console.
@immutable
final class BillingPack {
  const new({
    required this.id,
    required this.name,
    required this.system,
    this.code,
    this.description,
    this.status = PackStatus.draft,
    this.sortOrder = 0,
    this.featured = false,
    this.monthlyPrice,
    this.durations = const {},
    this.trialDays = 0,
    this.entryPrice,
    this.freeEntries = 0,
    this.tiers = const [],
    this.paymentDays,
    this.options = const {},
    this.subscriptions = 0,
    this.events = 0,
  });

  factory fromJson(Map<String, Object?> json) {
    final options = <BillingOption, PackOptionSetting>{};
    for (final MapEntry(:key, :value)
        in ((json['options'] as Map?) ?? const {}).entries) {
      if (BillingOption.byKey(key as String) case final option?) {
        options[option] = PackOptionSetting.fromJson(
          option,
          Map<String, Object?>.from(value as Map),
        );
      }
    }
    return BillingPack(
      id: json['pack_id']! as String,
      code: json['code'] as String?,
      name: json['name']! as String,
      description: json['description'] as String?,
      system: BillingSystem.fromWire(json['system']),
      status: PackStatus.fromWire(json['status']),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      featured: json['featured'] == true,
      monthlyPrice: (json['monthly_price'] as num?)?.toInt(),
      durations: {
        for (final MapEntry(:key, :value)
            in ((json['durations'] as Map?) ?? const {}).entries)
          ?BillingDuration.fromWire(key): (value as num).toInt(),
      },
      trialDays: (json['trial_days'] as num?)?.toInt() ?? 0,
      entryPrice: (json['entry_price'] as num?)?.toInt(),
      freeEntries: (json['free_entries'] as num?)?.toInt() ?? 0,
      tiers: [
        for (final tier in (json['tiers'] as List?) ?? const [])
          (
            upTo: ((tier as Map)['up_to'] as num?)?.toInt(),
            price: (tier['price'] as num).toInt(),
          ),
      ],
      paymentDays: (json['payment_days'] as num?)?.toInt(),
      options: options,
      subscriptions: (json['subscriptions'] as num?)?.toInt() ?? 0,
      events: (json['events'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;

  /// Packs du système : « decouverte », « lancement ».
  final String? code;
  final String name;
  final String? description;
  final BillingSystem system;
  final PackStatus status;
  final int sortOrder;
  final bool featured;
  final int? monthlyPrice;
  final Map<BillingDuration, int> durations;
  final int trialDays;
  final int? entryPrice;
  final int freeEntries;
  final List<UsageTier> tiers;
  final int? paymentDays;
  final Map<BillingOption, PackOptionSetting> options;

  /// Abonnements actifs (forfait) ou événements facturés (usage).
  final int subscriptions;
  final int events;

  bool get isSystem => code != null;
  bool get isFree => code == 'decouverte';

  /// Corps envoyé à `admin_save_pack`.
  Map<String, Object?> toSaveJson() => {
    'name': name,
    'description': description,
    'system': system.wireName,
    'sort_order': sortOrder,
    'featured': featured,
    'monthly_price': system == BillingSystem.flat ? monthlyPrice : null,
    'durations': system == BillingSystem.flat
        ? {for (final e in durations.entries) e.key.wireName: e.value}
        : <String, Object?>{},
    'trial_days': trialDays,
    'entry_price': system == BillingSystem.usage ? entryPrice : null,
    'free_entries': system == BillingSystem.usage ? freeEntries : 0,
    'tiers': system == BillingSystem.usage
        ? [
            for (final tier in tiers) {'up_to': tier.upTo, 'price': tier.price},
          ]
        : const <Object?>[],
    'payment_days': system == BillingSystem.usage ? paymentDays : null,
    'options': [for (final setting in options.values) setting.toJson()],
  };
}

/// Réglages de paiement (C6).
@immutable
final class BillingSettings {
  const new({
    this.orangeMoneyNumber,
    this.moovMoneyNumber,
    this.beneficiary,
    this.instructions,
    this.usagePaymentDays = 7,
    this.invoiceDelayHours = 24,
    this.reminderDays = 7,
    this.graceDays = 7,
  });

  factory fromJson(Map<String, Object?> json) => BillingSettings(
    orangeMoneyNumber: json['orange_money_number'] as String?,
    moovMoneyNumber: json['moov_money_number'] as String?,
    beneficiary: json['beneficiary'] as String?,
    instructions: json['instructions'] as String?,
    usagePaymentDays: (json['usage_payment_days'] as num?)?.toInt() ?? 7,
    invoiceDelayHours: (json['invoice_delay_hours'] as num?)?.toInt() ?? 24,
    reminderDays: (json['reminder_days'] as num?)?.toInt() ?? 7,
    graceDays: (json['grace_days'] as num?)?.toInt() ?? 7,
  );

  final String? orangeMoneyNumber;
  final String? moovMoneyNumber;
  final String? beneficiary;
  final String? instructions;
  final int usagePaymentDays;
  final int invoiceDelayHours;
  final int reminderDays;
  final int graceDays;

  Map<String, Object?> toJson() => {
    'orange_money_number': orangeMoneyNumber,
    'moov_money_number': moovMoneyNumber,
    'beneficiary': beneficiary,
    'instructions': instructions,
    'usage_payment_days': usagePaymentDays,
    'invoice_delay_hours': invoiceDelayHours,
    'reminder_days': reminderDays,
    'grace_days': graceDays,
  };
}

/// Canal d'un paiement reçu.
enum PaymentChannel {
  orangeMoney('orange_money'),
  moovMoney('moov_money'),
  other('other');

  new(this.wireName);

  final String wireName;

  static PaymentChannel? fromWire(Object? value) {
    for (final channel in values) {
      if (channel.wireName == value) return channel;
    }
    return null;
  }
}

Map<String, int> _units(Object? value) => {
  for (final MapEntry(:key, :value) in ((value as Map?) ?? const {}).entries)
    key as String: (value as num).toInt(),
};

DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value).toUtc() : null;

/// Demande d'activation en attente (C3, C4).
@immutable
final class BillingRequest {
  const new({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.addonsOnly,
    required this.amount,
    required this.reference,
    required this.createdAt,
    this.accountEmail,
    this.packId,
    this.packName,
    this.duration,
    this.subscriptionId,
    this.addons = const {},
    this.declaredChannel,
    this.declaredTransaction,
  });

  factory fromJson(Map<String, Object?> json) => BillingRequest(
    id: json['id']! as String,
    accountId: json['account_id']! as String,
    accountName: json['account_name']! as String,
    accountEmail: json['account_email'] as String?,
    addonsOnly: json['kind'] == 'addons',
    packId: json['pack_id'] as String?,
    packName: json['pack_name'] as String?,
    duration: BillingDuration.fromWire(json['duration']),
    subscriptionId: json['subscription_id'] as String?,
    addons: _units(json['addons']),
    amount: (json['amount']! as num).toInt(),
    reference: json['reference']! as String,
    declaredChannel: PaymentChannel.fromWire(json['declared_channel']),
    declaredTransaction: json['declared_transaction'] as String?,
    createdAt: DateTime.parse(json['created_at']! as String).toUtc(),
  );

  final String id;
  final String accountId;
  final String accountName;
  final String? accountEmail;

  /// Suppléments en cours d'abonnement (sinon : abonnement à un pack).
  final bool addonsOnly;
  final String? packId;
  final String? packName;
  final BillingDuration? duration;
  final String? subscriptionId;
  final Map<String, int> addons;
  final int amount;
  final String reference;
  final PaymentChannel? declaredChannel;
  final String? declaredTransaction;
  final DateTime createdAt;
}

/// Abonnement actif (C5).
@immutable
final class AdminSubscription {
  const new({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.packName,
    required this.duration,
    required this.startsAt,
    this.accountEmail,
    this.packId,
    this.packCode,
    this.addons = const {},
    this.endsAt,
    this.note,
  });

  factory fromJson(Map<String, Object?> json) => AdminSubscription(
    id: json['id']! as String,
    accountId: json['account_id']! as String,
    accountName: json['account_name']! as String,
    accountEmail: json['account_email'] as String?,
    packId: json['pack_id'] as String?,
    packCode: json['pack_code'] as String?,
    packName: json['pack_name']! as String,
    duration:
        BillingDuration.fromWire(json['duration']) ?? BillingDuration.month,
    addons: _units(json['addons']),
    startsAt: DateTime.parse(json['starts_at']! as String).toUtc(),
    endsAt: _date(json['ends_at']),
    note: json['note'] as String?,
  );

  final String id;
  final String accountId;
  final String accountName;
  final String? accountEmail;
  final String? packId;
  final String? packCode;
  final String packName;
  final BillingDuration duration;
  final Map<String, int> addons;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? note;

  /// État à [now], période de grâce de [graceDays] jours comprise.
  SubscriptionState stateAt(DateTime now, {required int graceDays}) {
    final end = endsAt;
    if (end == null) return SubscriptionState.active;
    if (now.isBefore(end)) {
      return end.difference(now).inDays < 7
          ? SubscriptionState.endingSoon
          : SubscriptionState.active;
    }
    return now.isBefore(end.add(Duration(days: graceDays)))
        ? SubscriptionState.grace
        : SubscriptionState.ended;
  }
}

/// État d'un abonnement vu par la console.
enum SubscriptionState { active, endingSoon, grace, ended }

/// Facture à l'usage à encaisser (C3, C4).
@immutable
final class DueInvoice {
  const new({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.eventId,
    required this.eventTitle,
    required this.entries,
    required this.amount,
    required this.issuedAt,
    required this.dueAt,
    required this.overdue,
    this.accountEmail,
    this.freeEntries = 0,
    this.entriesAmount = 0,
    this.addonsAmount = 0,
  });

  factory fromJson(Map<String, Object?> json) => DueInvoice(
    id: json['id']! as String,
    accountId: json['account_id']! as String,
    accountName: json['account_name']! as String,
    accountEmail: json['account_email'] as String?,
    eventId: json['event_id']! as String,
    eventTitle: json['event_title']! as String,
    entries: (json['entries'] as num?)?.toInt() ?? 0,
    freeEntries: (json['free_entries'] as num?)?.toInt() ?? 0,
    entriesAmount: (json['entries_amount'] as num?)?.toInt() ?? 0,
    addonsAmount: (json['addons_amount'] as num?)?.toInt() ?? 0,
    amount: (json['amount']! as num).toInt(),
    issuedAt: DateTime.parse(json['issued_at']! as String).toUtc(),
    dueAt: DateTime.parse(json['due_at']! as String).toUtc(),
    overdue: json['overdue'] == true,
  );

  final String id;
  final String accountId;
  final String accountName;
  final String? accountEmail;
  final String eventId;
  final String eventTitle;
  final int entries;
  final int freeEntries;
  final int entriesAmount;
  final int addonsAmount;
  final int amount;
  final DateTime issuedAt;
  final DateTime dueAt;
  final bool overdue;
}

/// Demande traitée ou facture payée (onglet « Traitées »).
@immutable
final class BillingHistoryItem {
  const new({
    required this.id,
    required this.invoice,
    required this.accountName,
    required this.amount,
    required this.status,
    this.label,
    this.reference,
    this.decidedAt,
    this.channel,
  });

  factory fromJson(Map<String, Object?> json) => BillingHistoryItem(
    id: json['id']! as String,
    invoice: json['type'] == 'invoice',
    accountName: json['account_name']! as String,
    label: (json['event_title'] ?? json['pack_name']) as String?,
    amount: (json['amount']! as num).toInt(),
    status: json['status']! as String,
    reference: json['reference'] as String?,
    decidedAt: _date(json['decided_at']),
    channel: PaymentChannel.fromWire(json['channel']),
  );

  final String id;

  /// Facture à l'usage payée (sinon : demande d'activation).
  final bool invoice;
  final String accountName;

  /// Pack demandé ou événement facturé.
  final String? label;
  final int amount;

  /// `activated`, `refused`, `cancelled` (demande) ou `paid` (facture).
  final String status;
  final String? reference;
  final DateTime? decidedAt;
  final PaymentChannel? channel;
}

/// Tout ce que montre la console de facturation.
@immutable
final class AdminBilling {
  const new({
    required this.settings,
    this.packs = const [],
    this.requests = const [],
    this.subscriptions = const [],
    this.invoices = const [],
    this.history = const [],
  });

  factory fromJson(Map<String, Object?> json) {
    List<T> list<T>(String key, T Function(Map<String, Object?>) read) => [
      for (final row in (json[key] as List?) ?? const [])
        read(Map<String, Object?>.from(row as Map)),
    ];
    return AdminBilling(
      settings: BillingSettings.fromJson(
        Map<String, Object?>.from((json['settings'] as Map?) ?? const {}),
      ),
      packs: list('packs', BillingPack.fromJson),
      requests: list('requests', BillingRequest.fromJson),
      subscriptions: list('subscriptions', AdminSubscription.fromJson),
      invoices: list('invoices', DueInvoice.fromJson),
      history: list('history', BillingHistoryItem.fromJson),
    );
  }

  final BillingSettings settings;
  final List<BillingPack> packs;
  final List<BillingRequest> requests;
  final List<AdminSubscription> subscriptions;
  final List<DueInvoice> invoices;
  final List<BillingHistoryItem> history;

  /// Paiements à vérifier : demandes et factures dues.
  int get toCollect => requests.length + invoices.length;

  BillingPack? packById(String? id) {
    for (final pack in packs) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}

/// Événement dont la facturation est réglée (changement par l'admin).
@immutable
final class BillingEventRow {
  const new({
    required this.id,
    required this.title,
    required this.organizationName,
    required this.system,
    required this.locked,
    required this.startsAt,
    this.ownerName,
    this.packName,
    this.invoiceStatus,
  });

  factory fromJson(Map<String, Object?> json) => BillingEventRow(
    id: json['id']! as String,
    title: json['title']! as String,
    organizationName: json['organization_name']! as String,
    ownerName: json['owner_name'] as String?,
    system: BillingSystem.fromWire(json['system']),
    locked: json['locked'] == true,
    startsAt: DateTime.parse(json['starts_at']! as String).toUtc(),
    packName: json['pack_name'] as String?,
    invoiceStatus: json['invoice_status'] as String?,
  );

  final String id;
  final String title;
  final String organizationName;
  final String? ownerName;
  final BillingSystem system;
  final bool locked;
  final DateTime startsAt;
  final String? packName;

  /// Facture émise (`due`, `paid`) : le changement est refusé.
  final String? invoiceStatus;
}

/// Erreurs de la console de facturation.
enum BillingAdminFailure implements Exception {
  forbidden,
  noteRequired,
  packInvalid,
  packProtected,
  addonsInvalid,
  settingsInvalid,
  paymentInvalid,
  alreadyProcessed,
  subscriptionInvalid,
  choiceInvalid,
  invoiceExists,
  network,
  unknown,
}

/// Paiement reçu saisi par l'administrateur (C4).
typedef ReceivedPayment = ({
  PaymentChannel channel,
  String? operatorReference,
  DateTime? paidAt,
  String? note,
});

/// Console de facturation (RPC `admin_*`, migrations 3600 et 3700).
abstract interface class BillingAdminRepository {
  Future<AdminBilling> load();

  /// Crée ([id] null) ou modifie un pack ; renvoie son identifiant.
  Future<String> savePack(String? id, BillingPack pack);
  Future<void> setPackStatus(String id, PackStatus status);
  Future<void> saveSettings(BillingSettings settings);

  Future<void> activateRequest(String id, ReceivedPayment payment);
  Future<void> refuseRequest(String id, String? note);
  Future<void> markInvoicePaid(String id, ReceivedPayment payment);
  Future<void> issueInvoice(String eventId);

  Future<void> grantSubscription({
    required String accountId,
    required String packId,
    required BillingDuration duration,
    required String note,
  });
  Future<void> cancelSubscription(String id, String note);
  Future<void> extendSubscription(String id, DateTime endsAt, String note);
  Future<void> changeSubscriptionPack(String id, String packId, String note);
  Future<void> setSubscriptionAddons(
    String id,
    Map<String, int> addons,
    String note,
  );

  Future<List<BillingEventRow>> events(String search);
  Future<void> setEventBilling(
    String eventId,
    BillingSystem system,
    String? usagePackId,
    String note,
  );
}
