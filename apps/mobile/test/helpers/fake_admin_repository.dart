import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/events/domain/event.dart';

/// Vue d'ensemble type.
AdminOverview sampleOverview() => AdminOverview.fromJson(const {
  'version': 1,
  'server_time': '2030-06-01T12:00:00Z',
  'organizations': {'total': 12, 'active': 11, 'disabled': 1, 'new_7d': 2},
  'accounts': {
    'total': 48,
    'disabled': 1,
    'deletion_requested': 3,
    'deletion_due': 1,
    'deleted': 2,
    'new_7d': 6,
  },
  'events': {
    'total': 30,
    'upcoming': 9,
    'in_progress': 1,
    'listed': 7,
    'blocked': 1,
  },
  'tickets': {'issued': 4200, 'redeemed': 1300, 'issued_7d': 640},
  'scans_24h': {'accepted': 180, 'refused': 12},
});

AdminOrganization adminOrganization({
  String id = 'o1',
  String name = 'Kwabo Événements',
  bool active = true,
  String? reason,
}) => AdminOrganization(
  id: id,
  name: name,
  slug: 'kwabo',
  active: active,
  createdAt: DateTime.utc(2030, 5, 2),
  ownerName: 'Awa Ouédraogo',
  members: 3,
  events: 4,
  tickets: 250,
  disabledAt: active ? null : DateTime.utc(2030, 5, 20),
  disabledReason: active ? null : reason,
);

AdminPublicEvent adminEvent({
  String id = 'p1',
  String title = 'Festival Kwabo',
  bool blocked = false,
  String? reason,
}) => AdminPublicEvent(
  id: id,
  title: title,
  organizationName: 'Kwabo Événements',
  kind: EventKind.concert,
  status: EventStatus.published,
  startsAt: DateTime.utc(2030, 6, 20, 20),
  endsAt: DateTime.utc(2030, 6, 21),
  listed: !blocked,
  city: 'Ouagadougou',
  description: 'Trois scènes en plein air.',
  blockedAt: blocked ? DateTime.utc(2030, 6, 2) : null,
  blockedReason: blocked ? reason : null,
);

AdminAccount adminAccount({
  String id = 'u2',
  String name = 'Awa Ouédraogo',
  bool active = true,
  bool due = false,
  bool deleted = false,
  bool admin = false,
  String? reason,
}) {
  final requested = due ? DateTime.utc(2026, 9, 2) : null;
  return AdminAccount(
    id: id,
    displayName: deleted ? 'Compte supprimé' : name,
    email: deleted ? 'supprime-$id@supprime.invalid' : '$id@faso.bf',
    active: active && !deleted,
    platformAdmin: admin,
    createdAt: DateTime.utc(2026, 8, 2),
    lastSignInAt: DateTime.utc(2026, 11, 18, 9),
    deletionRequestedAt: requested,
    deletionDueAt: requested?.add(const Duration(days: 30)),
    deletedAt: deleted ? DateTime.utc(2026, 11, 3) : null,
    disabledAt: active ? null : DateTime.utc(2026, 11, 2),
    disabledReason: active ? null : reason,
    memberships: 1,
    ownedStructures: 1,
  );
}

/// [AdminRepository] en mémoire.
class FakeAdminRepository implements AdminRepository {
  new({
    this.admin = false,
    List<AdminOrganization>? organizations,
    List<AdminPublicEvent>? events,
    List<AuditEntry>? audit,
    List<AdminAccount>? accounts,
    this.failure,
  }) : accountList = accounts ?? [adminAccount()],
       orgs = organizations ?? [adminOrganization()],
       publicEventList = events ?? [adminEvent()],
       audit = audit ?? [];

  bool admin;
  final List<AdminAccount> accountList;
  final List<(String, bool, String?)> accountStatusCalls = [];
  final List<String> purgeCalls = [];
  int purgeAllCalls = 0;
  final List<(String, AccountFilter)> accountQueries = [];
  final List<AdminOrganization> orgs;
  final List<AdminPublicEvent> publicEventList;
  final List<AuditEntry> audit;

  /// Échec de toutes les lectures.
  AdminFailure? failure;

  final List<(String, bool, String?)> statusCalls = [];
  final List<(String, bool, String?)> blockCalls = [];
  final List<(String, bool)> orgQueries = [];
  final List<(String, bool)> eventQueries = [];
  final List<(AuditFilter, int)> auditQueries = [];

  /// « À la une » en mémoire.
  final List<FeaturedEntry> featured = [];
  final List<String> featuredCalls = [];

  @override
  Future<List<FeaturedEntry>> featuredEvents() async {
    _check();
    return [...featured];
  }

  @override
  Future<void> addFeatured(
    String eventId, {
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    featuredCalls.add('add $eventId');
    _check();
    if (featured.any((f) => f.eventId == eventId)) {
      throw AdminFailure.featuredExists;
    }
    final event = publicEventList.firstWhere((e) => e.id == eventId);
    featured.add(
      FeaturedEntry(
        id: 'f-$eventId',
        eventId: eventId,
        title: event.title,
        organizationName: event.organizationName,
        kind: event.kind,
        eventStartsAt: event.startsAt,
        eventEndsAt: event.endsAt,
        position: featured.length + 1,
        startsAt: startsAt ?? DateTime.utc(2030, 6),
        endsAt: endsAt ?? event.endsAt,
        listed: true,
        live: true,
        city: event.city,
      ),
    );
  }

  @override
  Future<void> setFeaturedPeriod(
    String id,
    DateTime startsAt,
    DateTime endsAt,
  ) async {
    featuredCalls.add('period $id');
    _check();
  }

  @override
  Future<void> moveFeatured(String id, int direction) async {
    featuredCalls.add('move $id $direction');
    _check();
    final index = featured.indexWhere((f) => f.id == id);
    final other = index + direction;
    if (other < 0 || other >= featured.length) return;
    final item = featured.removeAt(index);
    featured.insert(other, item);
  }

  @override
  Future<void> removeFeatured(String id) async {
    featuredCalls.add('remove $id');
    _check();
    featured.removeWhere((f) => f.id == id);
  }

  void _check() {
    if (failure case final failure?) throw failure;
    if (!admin) throw AdminFailure.forbidden;
  }

  @override
  Future<bool> isPlatformAdmin() async => admin;

  @override
  Future<AdminOverview> overview() async {
    _check();
    return sampleOverview();
  }

  @override
  Future<List<AdminOrganization>> organizations({
    String search = '',
    bool disabledOnly = false,
    int offset = 0,
    int limit = 30,
  }) async {
    orgQueries.add((search, disabledOnly));
    _check();
    return orgs
        .where((o) => !disabledOnly || !o.active)
        .where((o) => o.name.toLowerCase().contains(search.toLowerCase()))
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<void> setOrganizationActive(
    String organizationId, {
    required bool active,
    String? reason,
  }) async {
    statusCalls.add((organizationId, active, reason));
    _check();
    if (!active && (reason == null || reason.trim().isEmpty)) {
      throw AdminFailure.reasonRequired;
    }
    final index = orgs.indexWhere((o) => o.id == organizationId);
    final o = orgs[index];
    orgs[index] = adminOrganization(
      id: o.id,
      name: o.name,
      active: active,
      reason: reason,
    );
  }

  @override
  Future<List<AdminPublicEvent>> publicEvents({
    String search = '',
    bool blockedOnly = false,
    int offset = 0,
    int limit = 30,
  }) async {
    eventQueries.add((search, blockedOnly));
    _check();
    return publicEventList
        .where((e) => !blockedOnly || e.blocked)
        .where((e) => e.title.toLowerCase().contains(search.toLowerCase()))
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<void> setEventBlocked(
    String eventId, {
    required bool blocked,
    String? reason,
  }) async {
    blockCalls.add((eventId, blocked, reason));
    _check();
    if (blocked && (reason == null || reason.trim().isEmpty)) {
      throw AdminFailure.reasonRequired;
    }
    final index = publicEventList.indexWhere((e) => e.id == eventId);
    final e = publicEventList[index];
    publicEventList[index] = adminEvent(
      id: e.id,
      title: e.title,
      blocked: blocked,
      reason: reason,
    );
  }

  @override
  Future<List<AdminAccount>> accounts({
    String search = '',
    AccountFilter filter = AccountFilter.all,
    int offset = 0,
    int limit = 30,
  }) async {
    accountQueries.add((search, filter));
    _check();
    final now = DateTime.now().toUtc();
    return accountList
        .where(
          (a) => switch (filter) {
            AccountFilter.all => true,
            AccountFilter.disabled => !a.active && !a.deleted,
            AccountFilter.deletion =>
              a.deletionRequestedAt != null && !a.deleted,
            AccountFilter.due => a.dueAt(now),
            AccountFilter.deleted => a.deleted,
          },
        )
        .where(
          (a) =>
              a.displayName.toLowerCase().contains(search.toLowerCase()) ||
              (a.email ?? '').contains(search.toLowerCase()),
        )
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<void> setAccountActive(
    String userId, {
    required bool active,
    String? reason,
  }) async {
    accountStatusCalls.add((userId, active, reason));
    _check();
    final index = accountList.indexWhere((a) => a.id == userId);
    final a = accountList[index];
    accountList[index] = adminAccount(
      id: a.id,
      name: a.displayName,
      active: active,
      reason: reason,
    );
  }

  @override
  Future<int> purgeAccount(String userId) async {
    purgeCalls.add(userId);
    _check();
    final index = accountList.indexWhere((a) => a.id == userId);
    accountList[index] = adminAccount(id: userId, deleted: true);
    return 1;
  }

  @override
  Future<({int accounts, int structures})> purgeDueAccounts() async {
    purgeAllCalls++;
    _check();
    final now = DateTime.now().toUtc();
    var count = 0;
    for (var i = 0; i < accountList.length; i++) {
      if (accountList[i].dueAt(now)) {
        accountList[i] = adminAccount(id: accountList[i].id, deleted: true);
        count++;
      }
    }
    return (accounts: count, structures: count);
  }

  @override
  Future<List<AuditEntry>> auditLogs({
    AuditFilter filter = AuditFilter.all,
    int offset = 0,
    int limit = 50,
  }) async {
    auditQueries.add((filter, offset));
    _check();
    return audit
        .where(
          (a) => filter.prefix == null || a.action.startsWith(filter.prefix!),
        )
        .skip(offset)
        .take(limit)
        .toList();
  }
}
