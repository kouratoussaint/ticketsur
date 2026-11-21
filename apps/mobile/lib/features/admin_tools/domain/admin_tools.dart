import 'package:flutter/foundation.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart'
    show AdminMe, AdminPermission;
import 'package:ticketsur/features/events/domain/event.dart' show EventStatus;
import 'package:ticketsur/features/platform/domain/platform_status.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart'
    show TicketStatus;

/// Destinataire d'un message ciblé (lot 4-11d).
enum MessageTargetKind {
  /// Un compte : conversation du support ouverte par l'équipe.
  account,

  /// Les membres actifs d'une structure.
  organization,

  /// Les détenteurs reliés (« Mes tickets ») d'un événement.
  event;

  String get wireName => name;
}

@immutable
final class MessageTarget {
  const new({required this.kind, required this.id, required this.name});

  final MessageTargetKind kind;
  final String id;

  /// Nom affiché (compte, structure ou événement).
  final String name;
}

@immutable
final class SearchAccount {
  const new({
    required this.id,
    required this.name,
    this.email,
    this.active = true,
    this.deleted = false,
  });

  factory fromJson(Map<String, dynamic> json) => SearchAccount(
    id: json['id']! as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String?,
    active: json['status'] != 'disabled',
    deleted: json['deleted'] as bool? ?? false,
  );

  final String id;
  final String name;
  final String? email;
  final bool active;
  final bool deleted;
}

@immutable
final class SearchOrganization {
  const new({
    required this.id,
    required this.name,
    this.ownerName,
    this.active = true,
    this.closed = false,
  });

  factory fromJson(Map<String, dynamic> json) => SearchOrganization(
    id: json['id']! as String,
    name: json['name'] as String? ?? '',
    ownerName: json['owner_name'] as String?,
    active: json['status'] != 'disabled',
    closed: json['closed'] as bool? ?? false,
  );

  final String id;
  final String name;
  final String? ownerName;
  final bool active;
  final bool closed;
}

@immutable
final class SearchEvent {
  const new({
    required this.id,
    required this.title,
    required this.status,
    this.startsAt,
    this.organizationName,
  });

  factory fromJson(Map<String, dynamic> json) => SearchEvent(
    id: json['id']! as String,
    title: json['title'] as String? ?? '',
    status: EventStatus.fromWire(json['status']),
    startsAt: switch (json['starts_at']) {
      final String at => DateTime.parse(at).toUtc(),
      _ => null,
    },
    organizationName: json['organization_name'] as String?,
  );

  final String id;
  final String title;
  final EventStatus status;
  final DateTime? startsAt;
  final String? organizationName;
}

@immutable
final class SearchTicket {
  const new({
    required this.id,
    required this.reference,
    required this.status,
    this.holderName,
    this.eventTitle,
  });

  factory fromJson(Map<String, dynamic> json) => SearchTicket(
    id: json['id']! as String,
    reference: json['reference'] as String? ?? '',
    status: TicketStatus.fromWire(json['status']),
    holderName: json['holder_name'] as String?,
    eventTitle: json['event_title'] as String?,
  );

  final String id;
  final String reference;
  final TicketStatus status;
  final String? holderName;
  final String? eventTitle;
}

/// Résultat de la recherche globale de la console.
@immutable
final class GlobalSearchResult {
  const new({
    this.accounts = const [],
    this.organizations = const [],
    this.events = const [],
    this.tickets = const [],
  });

  factory fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) of) => [
      for (final row in (json[key] as List<dynamic>?) ?? const [])
        of((row as Map).cast<String, dynamic>()),
    ];
    return GlobalSearchResult(
      accounts: list('accounts', SearchAccount.fromJson),
      organizations: list('organizations', SearchOrganization.fromJson),
      events: list('events', SearchEvent.fromJson),
      tickets: list('tickets', SearchTicket.fromJson),
    );
  }

  final List<SearchAccount> accounts;
  final List<SearchOrganization> organizations;
  final List<SearchEvent> events;
  final List<SearchTicket> tickets;

  bool get isEmpty =>
      accounts.isEmpty &&
      organizations.isEmpty &&
      events.isEmpty &&
      tickets.isEmpty;
}

/// Exports pour Excel (migration 5300), avec la permission demandée.
enum ExportKind {
  accounts(AdminPermission.accounts),
  organizations(AdminPermission.organizations),
  events(AdminPermission.events),
  invoices(AdminPermission.billing),

  /// Tout administrateur.
  journal(null);

  new(this.permission);

  final String? permission;

  String get wireName => name;

  bool allowedFor(AdminMe? me) =>
      me != null && (permission == null || me.can(permission!));
}

/// Un export : colonnes (clés techniques) et lignes, 50 000 au plus.
@immutable
final class ConsoleExport {
  const new({
    required this.kind,
    required this.columns,
    required this.rows,
    this.truncated = false,
  });

  factory fromJson(ExportKind kind, Map<String, dynamic> json) => ConsoleExport(
    kind: kind,
    columns: [
      for (final c in (json['columns'] as List<dynamic>?) ?? const []) '$c',
    ],
    rows: [
      for (final row in (json['rows'] as List<dynamic>?) ?? const [])
        List<Object?>.from(row as List<dynamic>),
    ],
    truncated: json['truncated'] as bool? ?? false,
  );

  final ExportKind kind;
  final List<String> columns;
  final List<List<Object?>> rows;

  /// Plus de 50 000 lignes : seules les plus récentes sont exportées.
  final bool truncated;
}

/// Outils de la console (migrations 5200 et 5300) : recherche globale,
/// messages ciblés, maintenance et inscriptions, exports. Les échecs sont
/// des `AdminAccountsFailure`.
abstract interface class AdminToolsRepository {
  /// 2 à 60 caractères ; les tickets à partir de 3.
  Future<GlobalSearchResult> search(String query);

  /// Envoie un message ; renvoie le nombre de destinataires. [days] : durée
  /// du bandeau pour une structure ou un événement (1 à 30).
  Future<int> sendMessage(
    MessageTarget target, {
    required String title,
    required String body,
    int days = 7,
  });

  /// Maintenance et inscriptions (permission `settings`).
  Future<PlatformStatus> savePlatformStatus({
    required bool maintenance,
    required String message,
    required bool blockWrites,
    required bool signupsOpen,
  });

  /// Export complet d'une liste (journalisé : type et nombre de lignes).
  Future<ConsoleExport> export(ExportKind kind);
}
