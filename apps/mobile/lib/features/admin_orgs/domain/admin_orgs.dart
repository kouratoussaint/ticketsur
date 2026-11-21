import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart'
    show AccountAction;
import 'package:ticketsur/features/events/domain/event.dart' show EventStatus;
import 'package:ticketsur/features/organizations/domain/organization.dart'
    show MemberRole;

DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value).toUtc() : null;

int _int(Object? value) => (value as num?)?.toInt() ?? 0;

/// Membre d'une structure vu par la console.
@immutable
final class OrgMember {
  const new({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.active,
    this.email,
  });

  factory fromJson(Map<String, dynamic> json) => OrgMember(
    userId: json['user_id']! as String,
    displayName: json['display_name']! as String,
    email: json['email'] as String?,
    role: MemberRole.fromWire(json['role']),
    active: json['active'] as bool? ?? true,
  );

  final String userId;
  final String displayName;
  final String? email;
  final MemberRole role;
  final bool active;
}

/// Invitation en cours (jamais le code, seulement ses 4 derniers caractères).
@immutable
final class OrgInvitationSummary {
  const new({
    required this.id,
    required this.role,
    required this.codeHint,
    required this.expiresAt,
  });

  factory fromJson(Map<String, dynamic> json) => OrgInvitationSummary(
    id: json['id']! as String,
    role: MemberRole.fromWire(json['role']),
    codeHint: json['code_hint'] as String? ?? '',
    expiresAt: _date(json['expires_at'])!,
  );

  final String id;
  final MemberRole role;
  final String codeHint;
  final DateTime expiresAt;
}

/// Événement récent d'une structure.
@immutable
final class OrgEventSummary {
  const new({
    required this.id,
    required this.title,
    required this.status,
    required this.startsAt,
    this.tickets = 0,
    this.admitted = 0,
  });

  factory fromJson(Map<String, dynamic> json) => OrgEventSummary(
    id: json['id']! as String,
    title: json['title']! as String,
    status: EventStatus.fromWire(json['status']),
    startsAt: _date(json['starts_at'])!,
    tickets: _int(json['tickets']),
    admitted: _int(json['admitted']),
  );

  final String id;
  final String title;
  final EventStatus status;
  final DateTime startsAt;
  final int tickets;
  final int admitted;
}

/// Fiche complète d'une structure (`admin_organization_detail`).
@immutable
final class OrganizationDetail {
  const new({
    required this.id,
    required this.name,
    required this.active,
    required this.createdAt,
    required this.ownerId,
    required this.ownerName,
    this.slug = '',
    this.ownerEmail,
    this.logoPath,
    this.phone,
    this.contactEmail,
    this.city,
    this.publicPhone,
    this.disabledReason,
    this.closedAt,
    this.trashedAt,
    this.purgedAt,
    this.purgeDueAt,
    this.members = const [],
    this.invitations = const [],
    this.events = const [],
    this.eventsTotal = 0,
    this.eventsUpcoming = 0,
    this.ticketsIssued = 0,
    this.ticketsAdmitted = 0,
    this.packName,
    this.packEndsAt,
    this.invoices = 0,
    this.invoicesDue = 0,
    this.actions = const [],
  });

  factory fromJson(Map<String, dynamic> json) {
    final owner = (json['owner'] as Map?)?.cast<String, dynamic>() ?? {};
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) => [
      for (final item in (json[key] as List<dynamic>? ?? []))
        parse((item as Map).cast<String, dynamic>()),
    ];
    return OrganizationDetail(
      id: json['id']! as String,
      name: json['name']! as String,
      slug: json['slug'] as String? ?? '',
      active: json['status'] == 'active',
      createdAt: _date(json['created_at'])!,
      ownerId: owner['id'] as String? ?? '',
      ownerName: owner['display_name'] as String? ?? '—',
      ownerEmail: owner['email'] as String?,
      logoPath: json['logo_path'] as String?,
      phone: json['phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      city: json['city'] as String?,
      publicPhone: json['public_phone'] as String?,
      disabledReason: json['disabled_reason'] as String?,
      closedAt: _date(json['closed_at']),
      trashedAt: _date(json['trashed_at']),
      purgedAt: _date(json['purged_at']),
      purgeDueAt: _date(json['purge_due_at']),
      members: list('members', OrgMember.fromJson),
      invitations: list('invitations', OrgInvitationSummary.fromJson),
      events: list('events', OrgEventSummary.fromJson),
      eventsTotal: _int(json['events_total']),
      eventsUpcoming: _int(json['events_upcoming']),
      ticketsIssued: _int(json['tickets_issued']),
      ticketsAdmitted: _int(json['tickets_admitted']),
      packName: json['pack_name'] as String?,
      packEndsAt: _date(json['pack_ends_at']),
      invoices: _int(json['invoices']),
      invoicesDue: _int(json['invoices_due']),
      actions: list('actions', AccountAction.fromJson),
    );
  }

  final String id;
  final String name;
  final String slug;
  final bool active;
  final DateTime createdAt;
  final String ownerId;
  final String ownerName;
  final String? ownerEmail;
  final String? logoPath;
  final String? phone;
  final String? contactEmail;
  final String? city;
  final String? publicPhone;
  final String? disabledReason;
  final DateTime? closedAt;
  final DateTime? trashedAt;
  final DateTime? purgedAt;
  final DateTime? purgeDueAt;
  final List<OrgMember> members;
  final List<OrgInvitationSummary> invitations;
  final List<OrgEventSummary> events;
  final int eventsTotal;
  final int eventsUpcoming;
  final int ticketsIssued;
  final int ticketsAdmitted;
  final String? packName;
  final DateTime? packEndsAt;
  final int invoices;
  final int invoicesDue;
  final List<AccountAction> actions;

  bool get closed => closedAt != null;
  bool get trashed => trashedAt != null && purgedAt == null;
  bool get purged => purgedAt != null;

  /// Ouverte aux modifications (ni fermée, ni à la corbeille, ni effacée).
  bool get editable => !closed && trashedAt == null && !purged;
}

/// Ce que ferait la suppression (`admin_organization_delete_preview`).
@immutable
final class OrgDeletePreview {
  const new({
    required this.trash,
    this.eventsToCancel = 0,
    this.ticketsToCancel = 0,
    this.holdersToNotify = 0,
    this.members = 0,
    this.invoices = 0,
  });

  factory fromJson(Map<String, dynamic> json) => OrgDeletePreview(
    trash: json['mode'] == 'trash',
    eventsToCancel: _int(json['events_to_cancel']),
    ticketsToCancel: _int(json['tickets_to_cancel']),
    holdersToNotify: _int(json['holders_to_notify']),
    members: _int(json['members']),
    invoices: _int(json['invoices']),
  );

  /// Vrai : corbeille (structure vide) ; faux : fermeture définitive.
  final bool trash;
  final int eventsToCancel;
  final int ticketsToCancel;
  final int holdersToNotify;
  final int members;
  final int invoices;
}

/// Résultat d'une suppression.
@immutable
final class OrgDeleteOutcome {
  const new({
    required this.trash,
    this.eventsCancelled = 0,
    this.ticketsCancelled = 0,
    this.holdersNotified = 0,
  });

  factory fromJson(Map<String, dynamic> json) => OrgDeleteOutcome(
    trash: json['mode'] == 'trash',
    eventsCancelled: _int(json['events_cancelled']),
    ticketsCancelled: _int(json['tickets_cancelled']),
    holdersNotified: _int(json['holders_notified']),
  );

  final bool trash;
  final int eventsCancelled;
  final int ticketsCancelled;
  final int holdersNotified;
}

/// Élément de la corbeille (structures ; événements au lot 4-11c).
@immutable
final class TrashItem {
  const new({
    required this.id,
    required this.name,
    required this.trashedAt,
    required this.purgeDueAt,
    this.ownerName,
  });

  factory fromJson(Map<String, dynamic> json) => TrashItem(
    id: json['id']! as String,
    name: json['name']! as String,
    ownerName: json['owner_name'] as String?,
    trashedAt: _date(json['trashed_at'])!,
    purgeDueAt: _date(json['purge_due_at'])!,
  );

  final String id;
  final String name;
  final String? ownerName;
  final DateTime trashedAt;
  final DateTime purgeDueAt;

  /// Jours restants avant l'effacement (0 au plus tôt).
  int daysLeft(DateTime now) {
    final hours = purgeDueAt.difference(now).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }
}

/// Structures depuis la console (migration 5000, ADR 0039). Les échecs sont
/// des `AdminAccountsFailure`.
abstract interface class AdminOrgsRepository {
  Future<OrganizationDetail> detail(String organizationId);

  /// Nouvelle structure pour [ownerId] ; renvoie son identifiant.
  Future<String> create({
    required String ownerId,
    required String name,
    required String reason,
    String? city,
    bool? notify,
  });

  Future<void> update(
    String organizationId, {
    required String name,
    required String reason,
    String? city,
    String? phone,
    String? contactEmail,
    String? publicPhone,
    bool? notify,
  });

  Future<void> removeLogo(
    String organizationId, {
    required String reason,
    bool? notify,
  });

  Future<void> setMemberRole(
    String organizationId,
    String userId,
    MemberRole role, {
    required String reason,
    bool? notify,
  });

  Future<void> removeMember(
    String organizationId,
    String userId, {
    required String reason,
    bool? notify,
  });

  Future<void> revokeInvitation(String invitationId, {required String reason});

  Future<OrgDeletePreview> deletePreview(String organizationId);

  Future<OrgDeleteOutcome> delete(
    String organizationId, {
    required String confirmName,
    required String reason,
    bool? notify,
  });

  Future<List<TrashItem>> trash();

  Future<void> restore(
    String organizationId, {
    required String reason,
    bool? notify,
  });

  Future<void> purgeNow(
    String organizationId, {
    required String confirmName,
    required String reason,
  });

  /// Adresse publique du logo (bucket `org-logos`).
  String logoUrl(String path);
}
