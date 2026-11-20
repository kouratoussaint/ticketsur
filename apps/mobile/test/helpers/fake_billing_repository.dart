import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';

import 'fake_billing_admin_repository.dart';

/// Pack gratuit tel que le renvoie `my_billing` (sans abonnement).
MyBilling freeBilling({
  List<MyBillingRequest> requests = const [],
  bool trialUsed = false,
  List<MyInvoice> invoices = const [],
  Map<BillingOption, int?> limits = const {},
  BillingUsage usage = (
    structures: 1,
    activeEvents: 0,
    ticketsPeriod: 0,
    membersMax: 0,
  ),
}) => MyBilling(
  plan: BillingPlan(
    pack: testPack(code: 'decouverte', id: 'free', name: 'Découverte'),
    duration: BillingDuration.unlimited,
  ),
  limits: limits,
  features: {
    for (final option in BillingOption.values)
      if (!option.numeric) option: true,
  },
  usage: usage,
  organizations: const [
    BillingOrganization(id: 'o1', name: 'Kwabo', system: BillingSystem.flat),
  ],
  requests: requests,
  invoices: invoices,
  payment: const PaymentInfo(
    orangeMoneyNumber: '70 00 00 00',
    moovMoneyNumber: '60 00 00 00',
    beneficiary: 'Tikéo SARL',
  ),
  trialUsed: trialUsed,
);

/// Exemple riche pour les captures : deux demandes et des jauges.
MyBilling sampleMyBilling() => freeBilling(
  limits: const {
    BillingOption.structures: 1,
    BillingOption.activeEvents: 2,
    BillingOption.membersPerStructure: 3,
  },
  usage: (structures: 1, activeEvents: 2, ticketsPeriod: 140, membersMax: 1),
  invoices: [
    sampleInvoice(overdue: true),
    sampleInvoice(id: 'aaaaaaaa-0000-0000-0000-00000000f002', paid: true),
  ],
  requests: [
    MyBillingRequest(
      id: 'rq-wait',
      addonsOnly: false,
      packId: 'pk1',
      duration: BillingDuration.quarter,
      amount: 24000,
      reference: 'TK-WA17',
      status: RequestStatus.pending,
      createdAt: DateTime.utc(2030, 6, 3),
      declaredChannel: PaymentChannel.orangeMoney,
    ),
    MyBillingRequest(
      id: 'rq-new',
      addonsOnly: false,
      packId: 'pk1',
      duration: BillingDuration.month,
      amount: 9000,
      reference: 'TK-NE05',
      status: RequestStatus.pending,
      createdAt: DateTime.utc(2030, 6, 2),
    ),
    MyBillingRequest(
      id: 'rq-pay',
      addonsOnly: false,
      packId: 'pk1',
      duration: BillingDuration.month,
      amount: 9000,
      reference: 'TK-PA42',
      status: RequestStatus.refused,
      createdAt: DateTime.utc(2030, 5, 4),
    ),
  ],
);

/// Facture à l'usage d'exemple (paliers, supplément).
MyInvoice sampleInvoice({
  String id = 'aaaaaaaa-0000-0000-0000-00000000f001',
  bool paid = false,
  bool overdue = false,
}) => MyInvoice(
  id: id,
  eventId: 'e1',
  eventTitle: 'Soirée Afro-Jazz',
  entries: 650,
  freeEntries: 50,
  billableEntries: 600,
  entriesAmount: 85000,
  addonsAmount: 1000,
  amount: 86000,
  packName: 'Soirée',
  lines: const [
    InvoiceLine(
      kind: 'tier',
      from: 1,
      to: 500,
      count: 500,
      price: 150,
      amount: 75000,
    ),
    InvoiceLine(
      kind: 'tier',
      from: 501,
      to: 600,
      count: 100,
      price: 100,
      amount: 10000,
    ),
    InvoiceLine(
      kind: 'addon',
      option: BillingOption.controllersPerEvent,
      count: 1,
      price: 1000,
      amount: 1000,
    ),
  ],
  paid: paid,
  overdue: overdue,
  issuedAt: DateTime.utc(2030, 6, 3),
  dueAt: DateTime.utc(2030, 6, 10),
  paidAt: paid ? DateTime.utc(2030, 6, 5) : null,
);

/// Facturation du promoteur en mémoire : enregistre les appels.
class FakeBillingRepository implements BillingRepository {
  new({MyBilling? billing, List<BillingPack>? catalog})
    : billing = billing ?? freeBilling(),
      catalogPacks =
          catalog ??
          [
            testPack(
              options: {
                BillingOption.membersPerStructure: const PackOptionSetting(
                  option: BillingOption.membersPerStructure,
                  included: 2,
                  addonPrice: 1000,
                  addonCap: 5,
                ),
                BillingOption.export: const PackOptionSetting(
                  option: BillingOption.export,
                  state: FeatureState.addon,
                  addonPrice: 2000,
                ),
                BillingOption.liveDashboard: const PackOptionSetting(
                  option: BillingOption.liveDashboard,
                  state: FeatureState.unavailable,
                ),
              },
            ),
            testPack(id: 'pk2', name: 'Business'),
            const BillingPack(
              id: 'pu',
              name: 'Soirée',
              system: BillingSystem.usage,
              status: PackStatus.published,
              entryPrice: 150,
              freeEntries: 50,
              tiers: [(upTo: 500, price: 150), (upTo: null, price: 100)],
            ),
          ];

  MyBilling billing;
  final List<BillingPack> catalogPacks;
  final List<String> calls = [];
  Map<String, int>? lastAddons;
  String? lastTransaction;
  BillingFailure? nextFailure;

  Future<void> _maybeFail() async {
    if (nextFailure case final failure?) {
      nextFailure = null;
      throw failure;
    }
  }

  @override
  Future<MyBilling> myBilling() async {
    calls.add('my');
    await _maybeFail();
    return billing;
  }

  @override
  Future<List<BillingPack>> catalog() async {
    calls.add('catalog');
    return catalogPacks;
  }

  MyBillingRequest _add(MyBillingRequest request) {
    billing = MyBilling(
      plan: billing.plan,
      limits: billing.limits,
      features: billing.features,
      usage: billing.usage,
      organizations: billing.organizations,
      requests: [request, ...billing.requests],
      invoices: billing.invoices,
      payment: billing.payment,
    );
    return request;
  }

  @override
  Future<CreatedRequest> requestPack(
    String packId,
    BillingDuration duration,
    Map<String, int> addons,
  ) async {
    calls.add('request $packId ${duration.wireName}');
    await _maybeFail();
    lastAddons = addons;
    final request = _add(
      MyBillingRequest(
        id: 'rq1',
        addonsOnly: false,
        packId: packId,
        duration: duration,
        addons: addons,
        amount: 26000,
        reference: 'TK-AB12',
        status: RequestStatus.pending,
        createdAt: DateTime.utc(2026, 11, 20),
      ),
    );
    return (id: request.id, reference: request.reference, amount: 26000);
  }

  @override
  Future<CreatedRequest> requestAddons(Map<String, int> addons) async {
    calls.add('addons');
    await _maybeFail();
    lastAddons = addons;
    final request = _add(
      MyBillingRequest(
        id: 'rq2',
        addonsOnly: true,
        addons: addons,
        amount: 600,
        reference: 'TK-CD34',
        status: RequestStatus.pending,
        createdAt: DateTime.utc(2026, 11, 20),
      ),
    );
    return (id: request.id, reference: request.reference, amount: 600);
  }

  @override
  Future<void> declarePayment(
    String requestId,
    PaymentChannel channel,
    String? transaction,
  ) async {
    calls.add('declare $requestId ${channel.wireName}');
    await _maybeFail();
    lastTransaction = transaction;
    billing = MyBilling(
      plan: billing.plan,
      limits: billing.limits,
      features: billing.features,
      usage: billing.usage,
      organizations: billing.organizations,
      requests: [
        for (final r in billing.requests)
          if (r.id == requestId)
            MyBillingRequest(
              id: r.id,
              addonsOnly: r.addonsOnly,
              packId: r.packId,
              duration: r.duration,
              addons: r.addons,
              amount: r.amount,
              reference: r.reference,
              status: r.status,
              createdAt: r.createdAt,
              declaredChannel: channel,
            )
          else
            r,
      ],
      invoices: billing.invoices,
      payment: billing.payment,
    );
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    calls.add('cancel $requestId');
    await _maybeFail();
  }

  EventBilling eventBillingValue = const EventBilling(
    mode: EventBillingMode.inherit,
    system: BillingSystem.flat,
  );

  @override
  Future<void> startTrial(String packId) async {
    calls.add('trial $packId');
    await _maybeFail();
    billing = MyBilling(
      plan: BillingPlan(
        pack: catalogPacks.firstWhere((p) => p.id == packId),
        duration: BillingDuration.trial,
        subscriptionId: 'trial',
        periodEnd: DateTime.utc(2030, 6, 15),
      ),
      limits: billing.limits,
      features: billing.features,
      usage: billing.usage,
      organizations: billing.organizations,
      requests: billing.requests,
      invoices: billing.invoices,
      payment: billing.payment,
      trialUsed: true,
    );
  }

  @override
  Future<EventBilling> eventBilling(String eventId) async {
    calls.add('event $eventId');
    await _maybeFail();
    return eventBillingValue;
  }

  @override
  Future<EventBilling> setEventBilling(
    String eventId,
    EventBillingMode mode,
    String? usagePackId,
  ) async {
    calls.add('event-set $eventId ${mode.wireName} $usagePackId');
    await _maybeFail();
    return eventBillingValue = EventBilling(
      mode: mode,
      system: mode == EventBillingMode.usage
          ? BillingSystem.usage
          : BillingSystem.flat,
      usagePackId: usagePackId,
      packName: mode == EventBillingMode.usage ? 'Soirée' : null,
    );
  }

  @override
  Future<EventBilling> addEventAddon(
    String eventId,
    BillingOption option,
    int units,
  ) async {
    calls.add('event-addon $eventId ${option.key} $units');
    await _maybeFail();
    return eventBillingValue;
  }

  @override
  Future<void> setOrganizationBilling(
    String organizationId,
    BillingSystem system,
    String? usagePackId,
  ) async {
    calls.add('org $organizationId ${system.wireName} $usagePackId');
    await _maybeFail();
  }
}
