import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';

/// Pack de test.
BillingPack testPack({
  String id = 'pk1',
  String name = 'Pro',
  BillingSystem system = BillingSystem.flat,
  PackStatus status = PackStatus.published,
  String? code,
  int subscriptions = 0,
  Map<BillingOption, PackOptionSetting> options = const {},
}) => BillingPack(
  id: id,
  code: code,
  name: name,
  system: system,
  status: status,
  monthlyPrice: system == BillingSystem.flat ? 9000 : null,
  durations: system == BillingSystem.flat
      ? const {BillingDuration.month: 9000, BillingDuration.quarter: 24000}
      : const {},
  entryPrice: system == BillingSystem.usage ? 150 : null,
  subscriptions: subscriptions,
  options: options,
);

/// Console de facturation en mémoire : enregistre les appels.
class FakeBillingAdminRepository implements BillingAdminRepository {
  new({AdminBilling? billing, this.eventRows = const []})
    : billing =
          billing ??
          AdminBilling(
            settings: const BillingSettings(orangeMoneyNumber: '70 00 00 00'),
            packs: [
              testPack(code: 'decouverte', id: 'free', name: 'Découverte'),
              testPack(),
            ],
          );

  AdminBilling billing;
  final List<BillingEventRow> eventRows;
  final List<String> calls = [];
  final List<BillingPack> savedPacks = [];
  ReceivedPayment? lastPayment;
  BillingSettings? savedSettings;
  String? lastNote;
  BillingAdminFailure? nextFailure;

  Future<void> _maybeFail() async {
    if (nextFailure case final failure?) {
      nextFailure = null;
      throw failure;
    }
  }

  @override
  Future<AdminBilling> load() async {
    calls.add('load');
    await _maybeFail();
    return billing;
  }

  @override
  Future<String> savePack(String? id, BillingPack pack) async {
    calls.add('savePack ${id ?? 'new'}');
    await _maybeFail();
    savedPacks.add(pack);
    return id ?? 'new-${savedPacks.length}';
  }

  @override
  Future<void> setPackStatus(String id, PackStatus status) async {
    calls.add('status $id ${status.wireName}');
    await _maybeFail();
  }

  @override
  Future<void> saveSettings(BillingSettings settings) async {
    calls.add('settings');
    await _maybeFail();
    savedSettings = settings;
  }

  @override
  Future<void> activateRequest(String id, ReceivedPayment payment) async {
    calls.add('activate $id');
    await _maybeFail();
    lastPayment = payment;
  }

  @override
  Future<void> refuseRequest(String id, String? note) async {
    calls.add('refuse $id');
    await _maybeFail();
    lastNote = note;
  }

  @override
  Future<void> markInvoicePaid(String id, ReceivedPayment payment) async {
    calls.add('paid $id');
    await _maybeFail();
    lastPayment = payment;
  }

  @override
  Future<void> issueInvoice(String eventId) async {
    calls.add('issue $eventId');
    await _maybeFail();
  }

  @override
  Future<void> grantSubscription({
    required String accountId,
    required String packId,
    required BillingDuration duration,
    required String note,
  }) async {
    calls.add('grant $accountId $packId ${duration.wireName}');
    await _maybeFail();
    lastNote = note;
  }

  @override
  Future<void> cancelSubscription(String id, String note) async {
    calls.add('cancel $id');
    await _maybeFail();
    lastNote = note;
  }

  @override
  Future<void> extendSubscription(
    String id,
    DateTime endsAt,
    String note,
  ) async {
    calls.add('extend $id');
    await _maybeFail();
    lastNote = note;
  }

  @override
  Future<void> changeSubscriptionPack(
    String id,
    String packId,
    String note,
  ) async {
    calls.add('pack $id $packId');
    await _maybeFail();
    lastNote = note;
  }

  @override
  Future<void> setSubscriptionAddons(
    String id,
    Map<String, int> addons,
    String note,
  ) async {
    calls.add('addons $id $addons');
    await _maybeFail();
    lastNote = note;
  }

  @override
  Future<List<BillingEventRow>> events(String search) async {
    calls.add('events $search');
    await _maybeFail();
    return eventRows;
  }

  @override
  Future<void> setEventBilling(
    String eventId,
    BillingSystem system,
    String? usagePackId,
    String note,
  ) async {
    calls.add('event $eventId ${system.wireName} $usagePackId');
    await _maybeFail();
    lastNote = note;
  }
}

/// Console remplie : demande, abonnement, facture en retard, historique.
AdminBilling sampleAdminBilling({DateTime? now}) {
  final at = now ?? DateTime.now().toUtc();
  return AdminBilling(
    settings: const BillingSettings(
      orangeMoneyNumber: '70 00 00 00',
      moovMoneyNumber: '60 00 00 00',
      beneficiary: 'Tikéo SARL',
    ),
    packs: [
      testPack(code: 'decouverte', id: 'free', name: 'Découverte'),
      testPack(
        subscriptions: 3,
        options: {
          BillingOption.membersPerStructure: const PackOptionSetting(
            option: BillingOption.membersPerStructure,
            included: 2,
            addonPrice: 1000,
          ),
          BillingOption.export: const PackOptionSetting(
            option: BillingOption.export,
            state: FeatureState.addon,
            addonPrice: 2000,
          ),
        },
      ),
      testPack(id: 'pk2', name: 'Business', status: PackStatus.draft),
      testPack(id: 'pu', name: 'Soirée', system: BillingSystem.usage),
    ],
    requests: [
      BillingRequest(
        id: 'r1',
        accountId: 'u2',
        accountName: 'Awa Ouédraogo',
        accountEmail: 'awa@faso.bf',
        addonsOnly: false,
        packId: 'pk1',
        packName: 'Pro',
        duration: BillingDuration.quarter,
        amount: 24000,
        reference: 'TK-AB12',
        declaredChannel: PaymentChannel.orangeMoney,
        declaredTransaction: 'PP2611.1234',
        createdAt: at,
      ),
    ],
    subscriptions: [
      AdminSubscription(
        id: 's1',
        accountId: 'u2',
        accountName: 'Awa Ouédraogo',
        accountEmail: 'awa@faso.bf',
        packId: 'pk1',
        packName: 'Pro',
        duration: BillingDuration.month,
        addons: const {'members_per_structure': 1},
        startsAt: at.subtract(const Duration(days: 25)),
        endsAt: at.add(const Duration(days: 5)),
      ),
      AdminSubscription(
        id: 's2',
        accountId: 'u3',
        accountName: 'Kwabo Events',
        packName: 'Pro',
        duration: BillingDuration.year,
        startsAt: at.subtract(const Duration(days: 30)),
        endsAt: at.add(const Duration(days: 335)),
      ),
    ],
    invoices: [
      DueInvoice(
        id: 'i1',
        accountId: 'u3',
        accountName: 'Kwabo Events',
        eventId: 'e2',
        eventTitle: 'Gala',
        entries: 120,
        freeEntries: 20,
        entriesAmount: 15000,
        addonsAmount: 1000,
        amount: 16000,
        issuedAt: at.subtract(const Duration(days: 10)),
        dueAt: at.subtract(const Duration(days: 3)),
        overdue: true,
      ),
    ],
    history: [
      BillingHistoryItem(
        id: 'h1',
        invoice: false,
        accountName: 'Awa Ouédraogo',
        label: 'Pro',
        amount: 9000,
        status: 'activated',
        reference: 'TK-ZZ99',
        decidedAt: at.subtract(const Duration(days: 25)),
        channel: PaymentChannel.moovMoney,
      ),
    ],
  );
}
