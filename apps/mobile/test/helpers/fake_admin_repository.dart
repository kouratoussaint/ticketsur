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

/// [AdminRepository] en mémoire.
class FakeAdminRepository implements AdminRepository {
  new({
    this.admin = false,
    List<AdminOrganization>? organizations,
    List<AdminPublicEvent>? events,
    List<AuditEntry>? audit,
    this.failure,
  }) : orgs = organizations ?? [adminOrganization()],
       publicEventList = events ?? [adminEvent()],
       audit = audit ?? [];

  bool admin;
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
