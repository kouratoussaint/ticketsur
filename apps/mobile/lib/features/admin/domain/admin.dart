import 'package:flutter/foundation.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

/// Chiffres de la plateforme (`admin_overview`, version 1).
@immutable
final class AdminOverview {
  const new({
    required this.serverTime,
    required this.organizations,
    required this.organizationsActive,
    required this.organizationsDisabled,
    required this.organizationsNew7d,
    required this.accounts,
    required this.accountsDisabled,
    required this.accountsDeletionRequested,
    required this.accountsNew7d,
    required this.events,
    required this.eventsUpcoming,
    required this.eventsInProgress,
    required this.eventsListed,
    required this.eventsBlocked,
    required this.ticketsIssued,
    required this.ticketsRedeemed,
    required this.ticketsIssued7d,
    required this.scansAccepted24h,
    required this.scansRefused24h,
    this.accountsDeletionDue = 0,
    this.accountsDeleted = 0,
  });

  factory fromJson(Map<String, Object?> json) {
    if (json['version'] != 1) throw AdminFailure.unknown;
    Map<String, Object?> section(String key) =>
        Map<String, Object?>.from(json[key]! as Map);
    int n(Map<String, Object?> map, String key) => (map[key]! as num).toInt();
    final orgs = section('organizations');
    final accounts = section('accounts');
    final events = section('events');
    final tickets = section('tickets');
    final scans = section('scans_24h');
    return AdminOverview(
      serverTime: DateTime.parse(json['server_time']! as String).toUtc(),
      organizations: n(orgs, 'total'),
      organizationsActive: n(orgs, 'active'),
      organizationsDisabled: n(orgs, 'disabled'),
      organizationsNew7d: n(orgs, 'new_7d'),
      accounts: n(accounts, 'total'),
      accountsDisabled: n(accounts, 'disabled'),
      accountsDeletionRequested: n(accounts, 'deletion_requested'),
      accountsNew7d: n(accounts, 'new_7d'),
      accountsDeletionDue: (accounts['deletion_due'] as num?)?.toInt() ?? 0,
      accountsDeleted: (accounts['deleted'] as num?)?.toInt() ?? 0,
      events: n(events, 'total'),
      eventsUpcoming: n(events, 'upcoming'),
      eventsInProgress: n(events, 'in_progress'),
      eventsListed: n(events, 'listed'),
      eventsBlocked: n(events, 'blocked'),
      ticketsIssued: n(tickets, 'issued'),
      ticketsRedeemed: n(tickets, 'redeemed'),
      ticketsIssued7d: n(tickets, 'issued_7d'),
      scansAccepted24h: n(scans, 'accepted'),
      scansRefused24h: n(scans, 'refused'),
    );
  }

  final DateTime serverTime;
  final int organizations;
  final int organizationsActive;
  final int organizationsDisabled;
  final int organizationsNew7d;
  final int accounts;
  final int accountsDisabled;
  final int accountsDeletionRequested;
  final int accountsNew7d;

  /// Comptes dont la suppression demandée est arrivée à échéance (30 jours).
  final int accountsDeletionDue;

  /// Comptes supprimés définitivement (anonymisés).
  final int accountsDeleted;
  final int events;
  final int eventsUpcoming;
  final int eventsInProgress;
  final int eventsListed;
  final int eventsBlocked;
  final int ticketsIssued;
  final int ticketsRedeemed;
  final int ticketsIssued7d;
  final int scansAccepted24h;
  final int scansRefused24h;
}

/// Une organisation vue de la console (`admin_organizations`).
@immutable
final class AdminOrganization {
  const new({
    required this.id,
    required this.name,
    required this.slug,
    required this.active,
    required this.createdAt,
    required this.ownerName,
    required this.members,
    required this.events,
    required this.tickets,
    this.lastEventAt,
    this.disabledAt,
    this.disabledReason,
    this.closedAt,
  });

  factory fromJson(Map<String, Object?> json) => AdminOrganization(
    id: json['id']! as String,
    name: json['name']! as String,
    slug: json['slug']! as String,
    active: json['status'] == 'active',
    createdAt: DateTime.parse(json['created_at']! as String).toUtc(),
    ownerName: json['owner_name']! as String,
    members: (json['members']! as num).toInt(),
    events: (json['events']! as num).toInt(),
    tickets: (json['tickets']! as num).toInt(),
    lastEventAt: _date(json['last_event_at']),
    disabledAt: _date(json['disabled_at']),
    disabledReason: json['disabled_reason'] as String?,
    closedAt: _date(json['closed_at']),
  );

  final String id;
  final String name;
  final String slug;
  final bool active;
  final DateTime createdAt;
  final String ownerName;
  final int members;
  final int events;
  final int tickets;
  final DateTime? lastEventAt;
  final DateTime? disabledAt;
  final String? disabledReason;

  /// Fermée pour toujours (lot 4-11b) : ni réactivation ni modification.
  final DateTime? closedAt;
}

/// Filtre de la liste des comptes (`admin_accounts`, `p_filter`).
enum AccountFilter {
  all('all'),
  disabled('disabled'),
  deletion('deletion'),
  due('due'),
  deleted('deleted');

  new(this.wireName);

  final String wireName;
}

/// Un compte vu de la console (`admin_accounts`).
@immutable
final class AdminAccount {
  const new({
    required this.id,
    required this.displayName,
    required this.active,
    required this.createdAt,
    this.email,
    this.platformAdmin = false,
    this.lastSignInAt,
    this.deletionRequestedAt,
    this.deletionDueAt,
    this.deletedAt,
    this.disabledAt,
    this.disabledReason,
    this.memberships = 0,
    this.ownedStructures = 0,
  });

  factory fromJson(Map<String, Object?> json) => AdminAccount(
    id: json['id']! as String,
    displayName: json['display_name']! as String,
    email: json['email'] as String?,
    active: json['status'] == 'active',
    platformAdmin: json['is_platform_admin'] == true,
    createdAt: DateTime.parse(json['created_at']! as String).toUtc(),
    lastSignInAt: _date(json['last_sign_in_at']),
    deletionRequestedAt: _date(json['deletion_requested_at']),
    deletionDueAt: _date(json['deletion_due_at']),
    deletedAt: _date(json['deleted_at']),
    disabledAt: _date(json['disabled_at']),
    disabledReason: json['disabled_reason'] as String?,
    memberships: (json['memberships'] as num?)?.toInt() ?? 0,
    ownedStructures: (json['owned_structures'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String displayName;
  final String? email;
  final bool active;
  final bool platformAdmin;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final DateTime? deletionRequestedAt;
  final DateTime? deletionDueAt;
  final DateTime? deletedAt;
  final DateTime? disabledAt;
  final String? disabledReason;
  final int memberships;
  final int ownedStructures;

  bool get deleted => deletedAt != null;

  /// Suppression demandée et délai de 30 jours écoulé à [now].
  bool dueAt(DateTime now) =>
      !deleted && deletionDueAt != null && !deletionDueAt!.isAfter(now);
}

/// Un événement du catalogue public vu de la console
/// (`admin_public_events`).
@immutable
final class AdminPublicEvent {
  const new({
    required this.id,
    required this.title,
    required this.organizationName,
    required this.kind,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.listed,
    this.city,
    this.coverUrl,
    this.description,
    this.blockedAt,
    this.blockedReason,
  });

  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? coverUrlOf,
  }) {
    final cover = json['cover_path'] as String?;
    return AdminPublicEvent(
      id: json['id']! as String,
      title: json['title']! as String,
      organizationName: json['organization_name']! as String,
      kind: EventKind.fromWire(json['kind']),
      status: EventStatus.fromWire(json['status']),
      startsAt: DateTime.parse(json['starts_at']! as String).toUtc(),
      endsAt: DateTime.parse(json['ends_at']! as String).toUtc(),
      listed: json['listed'] == true,
      city: json['city'] as String?,
      coverUrl: cover == null || coverUrlOf == null ? null : coverUrlOf(cover),
      description: json['description'] as String?,
      blockedAt: _date(json['blocked_at']),
      blockedReason: json['blocked_reason'] as String?,
    );
  }

  final String id;
  final String title;
  final String organizationName;
  final EventKind kind;
  final EventStatus status;
  final DateTime startsAt;
  final DateTime endsAt;

  /// Visible aujourd'hui dans le catalogue.
  final bool listed;
  final String? city;
  final String? coverUrl;
  final String? description;

  /// Retiré du catalogue par la plateforme.
  final DateTime? blockedAt;
  final String? blockedReason;

  bool get blocked => blockedAt != null;
}

/// Une ligne du journal d'audit (`admin_audit_logs`).
@immutable
final class AuditEntry {
  const new({
    required this.id,
    required this.createdAt,
    required this.action,
    required this.resourceType,
    this.resourceId,
    this.organizationName,
    this.actorName,
    this.details = const {},
  });

  factory fromJson(Map<String, Object?> json) => AuditEntry(
    id: json['id']! as String,
    createdAt: DateTime.parse(json['created_at']! as String).toUtc(),
    action: json['action']! as String,
    resourceType: json['resource_type']! as String,
    resourceId: json['resource_id'] as String?,
    organizationName: json['organization_name'] as String?,
    actorName: json['actor_name'] as String?,
    details: Map<String, Object?>.from(
      (json['details'] as Map?) ?? const <String, Object?>{},
    ),
  );

  final String id;
  final DateTime createdAt;
  final String action;
  final String resourceType;
  final String? resourceId;
  final String? organizationName;
  final String? actorName;
  final Map<String, Object?> details;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();

/// Échecs de la console.
enum AdminFailure implements Exception {
  /// Compte sans le rôle d'administrateur de la plateforme.
  forbidden,

  /// Double authentification activée : code demandé (session aal1).
  mfaRequired,

  /// Rôle d'administration sans cette permission (lot 4-11a).
  roleForbidden,

  /// Suspension ou retrait sans motif.
  reasonRequired,

  /// Organisation ou événement introuvable.
  notFound,

  /// Action impossible pour ce compte (le sien, déjà supprimé, pas encore
  /// à échéance, administrateur).
  notAllowed,

  /// « À la une » : événement non public ou passé, ou période invalide.
  featuredInvalid,

  /// « À la une » : événement déjà dans la liste.
  featuredExists,

  /// Attribution : compte désactivé ou supprimé.
  accountInactive,

  /// Attribution : déjà propriétaire de cette structure.
  alreadyOwner,

  /// Attribution : le propriétaire ne change de rôle que par un transfert.
  ownerLocked,

  /// Attribution : le pack du compte ne permet pas une structure de plus.
  structureLimit,

  /// Pas de réseau.
  network,

  /// Autre erreur.
  unknown,
}

/// Structure d'un compte, vue de la console (#10).
@immutable
final class AdminAccountStructure {
  const new({
    required this.organizationId,
    required this.name,
    required this.role,
    required this.active,
    this.organizationActive = true,
  });

  factory fromJson(Map<String, Object?> json) => AdminAccountStructure(
    organizationId: json['organization_id']! as String,
    name: json['name']! as String,
    role: MemberRole.fromWire(json['role']! as String),
    active: json['active'] == true,
    organizationActive: json['organization_status'] != 'disabled',
  );

  final String organizationId;
  final String name;
  final MemberRole role;

  /// Appartenance active.
  final bool active;
  final bool organizationActive;
}

/// Mise en avant « À la une » (console, ADR 0028).
@immutable
final class FeaturedEntry {
  const new({
    required this.id,
    required this.eventId,
    required this.title,
    required this.organizationName,
    required this.kind,
    required this.eventStartsAt,
    required this.eventEndsAt,
    required this.position,
    required this.startsAt,
    required this.endsAt,
    required this.listed,
    required this.live,
    this.city,
    this.coverUrl,
  });

  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? coverUrlOf,
  }) {
    DateTime at(String key) => DateTime.parse(json[key]! as String).toUtc();
    final cover = json['cover_path'] as String?;
    return FeaturedEntry(
      id: json['id']! as String,
      eventId: json['event_id']! as String,
      title: json['title']! as String,
      organizationName: json['organization_name']! as String,
      kind: EventKind.fromWire(json['kind']),
      eventStartsAt: at('event_starts_at'),
      eventEndsAt: at('event_ends_at'),
      position: (json['position']! as num).toInt(),
      startsAt: at('starts_at'),
      endsAt: at('ends_at'),
      listed: json['listed'] == true,
      live: json['live'] == true,
      city: json['city'] as String?,
      coverUrl: cover == null || coverUrlOf == null ? null : coverUrlOf(cover),
    );
  }

  final String id;
  final String eventId;
  final String title;
  final String organizationName;
  final EventKind kind;
  final DateTime eventStartsAt;
  final DateTime eventEndsAt;
  final int position;

  /// Période de mise en avant.
  final DateTime startsAt;
  final DateTime endsAt;

  /// Événement encore public et à venir.
  final bool listed;

  /// Affiché dans Explorer en ce moment.
  final bool live;
  final String? city;
  final String? coverUrl;
}

/// Familles d'actions du journal, pour le filtre.
enum AuditFilter {
  all(null),
  console('admin.'),
  events('event.'),
  tickets('ticket'),
  organizations('organization.');

  new(this.prefix);

  /// Préfixe de l'action côté serveur ; `null` : tout.
  final String? prefix;
}

/// Console d'administration de la plateforme (migration 1900). Chaque appel
/// est vérifié côté serveur : sans le rôle, [AdminFailure.forbidden].
/// Chiffres d'un jour (UTC) de la plateforme (migration 4700).
@immutable
final class DailyStat {
  const new({
    required this.day,
    this.accounts = 0,
    this.organizations = 0,
    this.eventsPublished = 0,
    this.ticketsIssued = 0,
    this.entries = 0,
  });

  factory fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return DailyStat(
      day: DateTime.parse(json['day']! as String),
      accounts: n('accounts'),
      organizations: n('organizations'),
      eventsPublished: n('events_published'),
      ticketsIssued: n('tickets_issued'),
      entries: n('entries'),
    );
  }

  final DateTime day;
  final int accounts;
  final int organizations;
  final int eventsPublished;
  final int ticketsIssued;
  final int entries;

  int valueOf(DailyMetric metric) => switch (metric) {
    DailyMetric.accounts => accounts,
    DailyMetric.organizations => organizations,
    DailyMetric.events => eventsPublished,
    DailyMetric.tickets => ticketsIssued,
    DailyMetric.entries => entries,
  };
}

/// Courbes de la vue d'ensemble.
enum DailyMetric { accounts, organizations, events, tickets, entries }

abstract interface class AdminRepository {
  /// Le compte connecté est-il administrateur de la plateforme ?
  Future<bool> isPlatformAdmin();

  Future<AdminOverview> overview();

  /// Chiffres par jour des [days] derniers jours, du plus ancien à
  /// aujourd'hui.
  Future<List<DailyStat>> dailyStats({int days = 30});

  Future<List<AdminOrganization>> organizations({
    String search = '',
    bool disabledOnly = false,
    int offset = 0,
    int limit = 30,
  });

  /// Suspend ([active] faux, [reason] obligatoire) ou réactive.
  Future<void> setOrganizationActive(
    String organizationId, {
    required bool active,
    String? reason,
  });

  Future<List<AdminPublicEvent>> publicEvents({
    String search = '',
    bool blockedOnly = false,
    int offset = 0,
    int limit = 30,
  });

  /// Retire du catalogue ([blocked], [reason] obligatoire) ou rétablit.
  Future<void> setEventBlocked(
    String eventId, {
    required bool blocked,
    String? reason,
  });

  /// Comptes, du plus récent au plus ancien.
  Future<List<AdminAccount>> accounts({
    String search = '',
    AccountFilter filter = AccountFilter.all,
    int offset = 0,
    int limit = 30,
  });

  /// Désactive ([active] faux, [reason] obligatoire) ou réactive un compte.
  Future<void> setAccountActive(
    String userId, {
    required bool active,
    String? reason,
  });

  /// Supprime définitivement un compte arrivé à échéance ; renvoie le nombre
  /// de structures suspendues.
  Future<int> purgeAccount(String userId);

  /// Supprime tous les comptes arrivés à échéance.
  Future<({int accounts, int structures})> purgeDueAccounts();

  /// Structures d'un compte (rôle, appartenance active).
  Future<List<AdminAccountStructure>> accountStructures(String userId);

  /// Attribue une structure à un compte (#10) : [MemberRole.owner] =
  /// transfert (l'ancien propriétaire devient gestionnaire). [reason]
  /// obligatoire.
  Future<void> assignOrganization(
    String userId, {
    required String organizationId,
    required MemberRole role,
    required String reason,
  });

  /// « À la une », dans l'ordre d'affichage.
  Future<List<FeaturedEntry>> featuredEvents();

  /// Met un événement public à venir à la une (fin par défaut : la fin de
  /// l'événement).
  Future<void> addFeatured(
    String eventId, {
    DateTime? startsAt,
    DateTime? endsAt,
  });

  /// Période de mise en avant.
  Future<void> setFeaturedPeriod(String id, DateTime startsAt, DateTime endsAt);

  /// Monter (-1) ou descendre (+1) d'un rang.
  Future<void> moveFeatured(String id, int direction);

  Future<void> removeFeatured(String id);

  /// Journal, du plus récent au plus ancien.
  Future<List<AuditEntry>> auditLogs({
    AuditFilter filter = AuditFilter.all,
    int offset = 0,
    int limit = 50,
  });
}
