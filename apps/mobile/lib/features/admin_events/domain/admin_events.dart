import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart'
    show AccountAction;
import 'package:ticketsur/features/events/domain/event.dart' show EventStatus;
import 'package:ticketsur/features/tickets/domain/ticket.dart'
    show TicketStatus;

DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value).toUtc() : null;

int _int(Object? value) => (value as num?)?.toInt() ?? 0;

Map<String, dynamic> _map(Object? value) =>
    (value as Map?)?.cast<String, dynamic>() ?? const {};

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) parse) => [
  for (final item in (value as List<dynamic>? ?? []))
    parse((item as Map).cast<String, dynamic>()),
];

/// Événement de la plateforme dans la liste de la console.
@immutable
final class AdminEventRow {
  const new({
    required this.id,
    required this.title,
    required this.status,
    required this.startsAt,
    required this.organizationId,
    required this.organizationName,
    this.city,
    this.isPublic = false,
    this.blocked = false,
    this.tickets = 0,
    this.admitted = 0,
  });

  factory fromJson(Map<String, dynamic> json) => AdminEventRow(
    id: json['id']! as String,
    title: json['title']! as String,
    status: EventStatus.fromWire(json['status']),
    startsAt: _date(json['starts_at'])!,
    city: json['city'] as String?,
    isPublic: json['is_public'] as bool? ?? false,
    blocked: json['blocked'] as bool? ?? false,
    organizationId: json['organization_id']! as String,
    organizationName: json['organization_name']! as String,
    tickets: _int(json['tickets']),
    admitted: _int(json['admitted']),
  );

  final String id;
  final String title;
  final EventStatus status;
  final DateTime startsAt;
  final String? city;
  final bool isPublic;
  final bool blocked;
  final String organizationId;
  final String organizationName;
  final int tickets;
  final int admitted;
}

/// Catégorie d'un événement vue par la console.
@immutable
final class AdminEventCategory {
  const new({
    required this.id,
    required this.name,
    this.capacity,
    this.issued = 0,
    this.admitted = 0,
    this.isInvitation = false,
  });

  factory fromJson(Map<String, dynamic> json) => AdminEventCategory(
    id: json['id']! as String,
    name: json['name']! as String,
    capacity: (json['capacity'] as num?)?.toInt(),
    issued: _int(json['issued']),
    admitted: _int(json['admitted']),
    isInvitation: json['is_invitation'] as bool? ?? false,
  );

  final String id;
  final String name;
  final int? capacity;
  final int issued;
  final int admitted;
  final bool isInvitation;
}

/// Fiche d'un événement (`admin_event_detail`).
@immutable
final class AdminEventDetail {
  const new({
    required this.id,
    required this.title,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.organizationId,
    required this.organizationName,
    this.timezone = 'Africa/Ouagadougou',
    this.venue,
    this.city,
    this.venueAddress,
    this.description,
    this.tagline,
    this.capacity,
    this.isPublic = false,
    this.blocked = false,
    this.blockedReason,
    this.organizationClosed = false,
    this.trashedAt,
    this.purgeDueAt,
    this.categories = const [],
    this.checkpoints = const [],
    this.ticketsTotal = 0,
    this.ticketsValid = 0,
    this.ticketsAdmitted = 0,
    this.ticketsRevoked = 0,
    this.ticketsToCancel = 0,
    this.holdersToNotify = 0,
    this.hasInvoice = false,
    this.actions = const [],
  });

  factory fromJson(Map<String, dynamic> json) {
    final org = _map(json['organization']);
    return AdminEventDetail(
      id: json['id']! as String,
      title: json['title']! as String,
      status: EventStatus.fromWire(json['status']),
      startsAt: _date(json['starts_at'])!,
      endsAt: _date(json['ends_at'])!,
      timezone: json['timezone'] as String? ?? 'Africa/Ouagadougou',
      venue: json['venue'] as String?,
      city: json['city'] as String?,
      venueAddress: json['venue_address'] as String?,
      description: json['description'] as String?,
      tagline: json['tagline'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      isPublic: json['is_public'] as bool? ?? false,
      blocked: json['blocked'] as bool? ?? false,
      blockedReason: json['blocked_reason'] as String?,
      organizationId: org['id'] as String? ?? '',
      organizationName: org['name'] as String? ?? '—',
      organizationClosed: org['closed'] as bool? ?? false,
      trashedAt: _date(json['trashed_at']),
      purgeDueAt: _date(json['purge_due_at']),
      categories: _list(json['categories'], AdminEventCategory.fromJson),
      checkpoints: [
        for (final name in (json['checkpoints'] as List<dynamic>? ?? []))
          name as String,
      ],
      ticketsTotal: _int(json['tickets_total']),
      ticketsValid: _int(json['tickets_valid']),
      ticketsAdmitted: _int(json['tickets_admitted']),
      ticketsRevoked: _int(json['tickets_revoked']),
      ticketsToCancel: _int(json['tickets_to_cancel']),
      holdersToNotify: _int(json['holders_to_notify']),
      hasInvoice: json['has_invoice'] as bool? ?? false,
      actions: _list(json['actions'], AccountAction.fromJson),
    );
  }

  final String id;
  final String title;
  final EventStatus status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String timezone;
  final String? venue;
  final String? city;
  final String? venueAddress;
  final String? description;
  final String? tagline;
  final int? capacity;
  final bool isPublic;
  final bool blocked;
  final String? blockedReason;
  final String organizationId;
  final String organizationName;
  final bool organizationClosed;
  final DateTime? trashedAt;
  final DateTime? purgeDueAt;
  final List<AdminEventCategory> categories;
  final List<String> checkpoints;
  final int ticketsTotal;
  final int ticketsValid;
  final int ticketsAdmitted;
  final int ticketsRevoked;
  final int ticketsToCancel;
  final int holdersToNotify;
  final bool hasInvoice;
  final List<AccountAction> actions;

  bool get trashed => trashedAt != null;

  /// Modifiable (texte, dates, public) : ni clôturé, ni annulé, ni archivé.
  bool get editable =>
      !trashed &&
      (status == EventStatus.draft ||
          status == EventStatus.published ||
          status == EventStatus.inProgress);

  /// États proposés : ceux du promoteur, plus l'annulation en cours.
  List<EventStatus> get nextStatuses => [
    ...status.nextStatuses.where(
      (next) =>
          !(status == EventStatus.published &&
              next == EventStatus.draft &&
              ticketsTotal > 0),
    ),
    if (status == EventStatus.inProgress) EventStatus.cancelled,
  ];

  /// Corbeille : brouillon sans ticket seulement.
  bool get trashable =>
      !trashed && status == EventStatus.draft && ticketsTotal == 0;
}

/// Ticket trouvé par la recherche de la console.
@immutable
final class AdminTicketRow {
  const new({
    required this.id,
    required this.reference,
    required this.status,
    required this.eventId,
    required this.eventTitle,
    required this.startsAt,
    required this.organizationName,
    required this.categoryName,
    this.holderName,
  });

  factory fromJson(Map<String, dynamic> json) => AdminTicketRow(
    id: json['id']! as String,
    reference: json['public_reference']! as String,
    status: TicketStatus.fromWire(json['status']),
    holderName: json['holder_name'] as String?,
    eventId: json['event_id']! as String,
    eventTitle: json['event_title']! as String,
    startsAt: _date(json['starts_at'])!,
    organizationName: json['organization_name']! as String,
    categoryName: json['category_name']! as String,
  );

  final String id;
  final String reference;
  final TicketStatus status;
  final String? holderName;
  final String eventId;
  final String eventTitle;
  final DateTime startsAt;
  final String organizationName;
  final String categoryName;
}

/// Envoi d'un ticket (canal et date ; jamais le message).
typedef TicketDelivery = ({String channel, DateTime sentAt});

/// Fiche d'un ticket (`admin_ticket_detail`) ; jamais le QR.
@immutable
final class AdminTicketDetail {
  const new({
    required this.id,
    required this.reference,
    required this.status,
    required this.issuedAt,
    required this.eventId,
    required this.eventTitle,
    required this.eventStartsAt,
    required this.organizationId,
    required this.organizationName,
    required this.categoryName,
    this.eventNumber,
    this.revokedAt,
    this.holderName,
    this.holderPhone,
    this.holderEmail,
    this.walletOwner,
    this.entriesUsed = 0,
    this.firstEntryAt,
    this.firstEntryDoor,
    this.lastEntryAt,
    this.isInvitation = false,
    this.deliveries = const [],
    this.actions = const [],
  });

  factory fromJson(Map<String, dynamic> json) {
    final event = _map(json['event']);
    final org = _map(json['organization']);
    final category = _map(json['category']);
    return AdminTicketDetail(
      id: json['id']! as String,
      reference: json['public_reference']! as String,
      eventNumber: (json['event_number'] as num?)?.toInt(),
      status: TicketStatus.fromWire(json['status']),
      issuedAt: _date(json['issued_at'])!,
      revokedAt: _date(json['revoked_at']),
      holderName: json['holder_name'] as String?,
      holderPhone: json['holder_phone'] as String?,
      holderEmail: json['holder_email'] as String?,
      walletOwner: json['wallet_owner'] as String?,
      entriesUsed: _int(json['entries_used']),
      firstEntryAt: _date(json['first_entry_at']),
      firstEntryDoor: json['first_entry_door'] as String?,
      lastEntryAt: _date(json['last_entry_at']),
      eventId: event['id'] as String? ?? '',
      eventTitle: event['title'] as String? ?? '—',
      eventStartsAt: _date(event['starts_at']) ?? DateTime.utc(2000),
      organizationId: org['id'] as String? ?? '',
      organizationName: org['name'] as String? ?? '—',
      categoryName: category['name'] as String? ?? '—',
      isInvitation: category['is_invitation'] as bool? ?? false,
      deliveries: [
        for (final item in (json['deliveries'] as List<dynamic>? ?? []))
          (
            channel: (item as Map)['channel'] as String,
            sentAt: DateTime.parse(item['sent_at'] as String).toUtc(),
          ),
      ],
      actions: _list(json['actions'], AccountAction.fromJson),
    );
  }

  final String id;
  final String reference;
  final int? eventNumber;
  final TicketStatus status;
  final DateTime issuedAt;
  final DateTime? revokedAt;
  final String? holderName;
  final String? holderPhone;
  final String? holderEmail;
  final String? walletOwner;
  final int entriesUsed;
  final DateTime? firstEntryAt;
  final String? firstEntryDoor;
  final DateTime? lastEntryAt;
  final String eventId;
  final String eventTitle;
  final DateTime eventStartsAt;
  final String organizationId;
  final String organizationName;
  final String categoryName;
  final bool isInvitation;
  final List<TicketDelivery> deliveries;
  final List<AccountAction> actions;
}

/// Résultat d'un changement d'état (annulation : tickets et détenteurs).
typedef EventStatusOutcome = ({int ticketsCancelled, int holdersNotified});

/// Champs modifiables d'un événement par la console.
@immutable
final class AdminEventEdit {
  const new({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.timezone,
    this.venue,
    this.city,
    this.venueAddress,
    this.description,
    this.tagline,
    this.capacity,
    this.isPublic,
  });

  /// Champs actuels de [event] (point de départ d'une modification).
  factory of(AdminEventDetail event) => AdminEventEdit(
    title: event.title,
    startsAt: event.startsAt,
    endsAt: event.endsAt,
    timezone: event.timezone,
    venue: event.venue,
    city: event.city,
    venueAddress: event.venueAddress,
    description: event.description,
    tagline: event.tagline,
    capacity: event.capacity,
  );

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String timezone;
  final String? venue;
  final String? city;
  final String? venueAddress;
  final String? description;
  final String? tagline;
  final int? capacity;

  /// Null : inchangé.
  final bool? isPublic;

  AdminEventEdit copyWith({
    String? title,
    DateTime? startsAt,
    DateTime? endsAt,
    String? Function()? venue,
    String? Function()? city,
    String? Function()? venueAddress,
    String? Function()? description,
    String? Function()? tagline,
    int? Function()? capacity,
    bool? isPublic,
  }) => AdminEventEdit(
    title: title ?? this.title,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    timezone: timezone,
    venue: venue == null ? this.venue : venue(),
    city: city == null ? this.city : city(),
    venueAddress: venueAddress == null ? this.venueAddress : venueAddress(),
    description: description == null ? this.description : description(),
    tagline: tagline == null ? this.tagline : tagline(),
    capacity: capacity == null ? this.capacity : capacity(),
    isPublic: isPublic ?? this.isPublic,
  );
}

/// Événements et tickets depuis la console (migration 5100, ADR 0040).
/// Les échecs sont des `AdminAccountsFailure`.
abstract interface class AdminEventsRepository {
  Future<List<AdminEventRow>> events({
    String search = '',
    EventStatus? status,
    String? organizationId,
    int offset = 0,
    int limit = 30,
  });

  Future<AdminEventDetail> eventDetail(String eventId);

  Future<void> updateEvent(
    String eventId,
    AdminEventEdit edit, {
    required String reason,
    bool? notify,
  });

  Future<EventStatusOutcome> setStatus(
    String eventId,
    EventStatus status, {
    required String reason,
    bool? notify,
  });

  Future<void> move(
    String eventId,
    String organizationId, {
    required String reason,
    bool? notify,
  });

  Future<void> trash(String eventId, {required String reason, bool? notify});

  Future<void> restore(String eventId, {required String reason, bool? notify});

  /// Tickets émis par l'administrateur (réglage de la console) ; renvoie
  /// leur nombre.
  Future<int> issueTickets(
    String eventId, {
    required String categoryId,
    required int quantity,
    required String reason,
  });

  Future<List<AdminTicketRow>> findTickets(String query);

  Future<AdminTicketDetail> ticketDetail(String ticketId);

  Future<void> revokeTicket(
    String ticketId, {
    required String reason,
    bool? notify,
  });

  Future<void> setTicketHolder(
    String ticketId, {
    required String reason,
    String? name,
    String? phone,
    String? email,
  });
}
