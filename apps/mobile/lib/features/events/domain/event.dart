import 'package:flutter/foundation.dart' show immutable;

/// Statut d'un événement (côté serveur : `event_status`).
enum EventStatus {
  /// Brouillon : invisible des contrôleurs, modifiable.
  draft('draft'),

  /// Publié : tickets et contrôle possibles dans la fenêtre de scan.
  published('published'),

  /// En cours : contrôle des entrées démarré.
  inProgress('in_progress'),

  /// Clôturé : plus aucun scan accepté.
  closed('closed'),

  /// Archivé : lecture seule.
  archived('archived'),

  /// Annulé.
  cancelled('cancelled');

  new(this.wireName);

  /// Valeur échangée avec le serveur.
  final String wireName;

  /// Statut correspondant à [value] ; un statut inconnu est traité comme
  /// archivé (lecture seule, aucune action proposée).
  static EventStatus fromWire(Object? value) => values.firstWhere(
    (status) => status.wireName == value,
    orElse: () => EventStatus.archived,
  );

  /// Transitions proposées dans l'interface. Le serveur
  /// (`set_event_status`) reste seul juge : cette liste ne fait qu'éviter de
  /// proposer des actions vouées à l'échec.
  List<EventStatus> get nextStatuses => switch (this) {
    draft => const [published, cancelled],
    published => const [inProgress, closed, draft, cancelled],
    inProgress => const [closed],
    closed => const [archived],
    cancelled => const [archived],
    archived => const [],
  };

  /// Statuts dans lesquels l'événement reste modifiable.
  bool get isEditable => this == draft || this == published;

  /// Statuts « vivants » (ni terminés ni archivés).
  bool get isActive => this == draft || this == published || this == inProgress;
}

/// Événement d'une organisation. Les instants sont en UTC ; [timezone] (IANA)
/// sert à l'affichage et à la saisie (EVT-02).
@immutable
final class TicketEvent {
  const new({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.timezone,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.venue,
    this.capacity,
  });

  /// Lit une ligne de `events` (lecture directe ou retour de fonction).
  factory fromJson(Map<String, Object?> json) => TicketEvent(
    id: json['id']! as String,
    organizationId: json['organization_id']! as String,
    title: json['title']! as String,
    venue: json['venue'] as String?,
    timezone: json['timezone']! as String,
    startsAt: DateTime.parse(json['starts_at']! as String).toUtc(),
    endsAt: DateTime.parse(json['ends_at']! as String).toUtc(),
    capacity: (json['capacity'] as num?)?.toInt(),
    status: EventStatus.fromWire(json['status']),
  );

  final String id;
  final String organizationId;
  final String title;
  final String? venue;
  final String timezone;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? capacity;
  final EventStatus status;

  /// Copie avec un autre statut.
  TicketEvent withStatus(EventStatus next) => TicketEvent(
    id: id,
    organizationId: organizationId,
    title: title,
    venue: venue,
    timezone: timezone,
    startsAt: startsAt,
    endsAt: endsAt,
    capacity: capacity,
    status: next,
  );

  @override
  bool operator ==(Object other) =>
      other is TicketEvent &&
      other.id == id &&
      other.organizationId == organizationId &&
      other.title == title &&
      other.venue == venue &&
      other.timezone == timezone &&
      other.startsAt == startsAt &&
      other.endsAt == endsAt &&
      other.capacity == capacity &&
      other.status == status;

  @override
  int get hashCode => Object.hash(
    id,
    organizationId,
    title,
    venue,
    timezone,
    startsAt,
    endsAt,
    capacity,
    status,
  );
}

/// Données saisies pour créer ou modifier un événement (instants en UTC).
@immutable
final class EventDraft {
  const new({
    required this.title,
    required this.timezone,
    required this.startsAt,
    required this.endsAt,
    this.venue,
    this.capacity,
  });

  /// Brouillon prérempli à partir d'un événement existant.
  factory of(TicketEvent event) => EventDraft(
    title: event.title,
    venue: event.venue,
    timezone: event.timezone,
    startsAt: event.startsAt,
    endsAt: event.endsAt,
    capacity: event.capacity,
  );

  final String title;
  final String? venue;
  final String timezone;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? capacity;

  /// Durée maximale d'un événement (identique au serveur).
  static const Duration maxDuration = Duration(days: 31);

  /// Paramètres communs de `create_event` / `update_event`.
  Map<String, Object?> toParams() => {
    'p_title': title.trim(),
    'p_venue': (venue?.trim().isEmpty ?? true) ? null : venue!.trim(),
    'p_timezone': timezone,
    'p_starts_at': startsAt.toUtc().toIso8601String(),
    'p_ends_at': endsAt.toUtc().toIso8601String(),
    'p_capacity': capacity,
  };
}

/// Échecs présentés à l'utilisateur. Les noms reprennent les codes stables
/// renvoyés par le serveur (migration 0600).
enum EventFailure implements Exception {
  /// Événement inconnu ou droits insuffisants (`event_not_found`).
  notFound,

  /// Titre hors limites (`event_title_invalid`).
  titleInvalid,

  /// Lieu trop long (`event_venue_invalid`).
  venueInvalid,

  /// Fin avant le début ou durée excessive (`event_dates_invalid`).
  datesInvalid,

  /// Fuseau inconnu (`event_timezone_invalid`).
  timezoneInvalid,

  /// Capacité hors limites (`event_capacity_invalid`).
  capacityInvalid,

  /// Capacité inférieure aux tickets émis (`event_capacity_below_issued`).
  capacityBelowIssued,

  /// Modification impossible dans ce statut (`event_locked`).
  locked,

  /// Transition refusée (`event_invalid_transition`).
  invalidTransition,

  /// Retour en brouillon impossible : tickets émis (`event_has_tickets`).
  hasTickets,

  /// Publication d'un événement terminé (`event_already_ended`).
  alreadyEnded,

  /// Serveur injoignable.
  network,

  /// Toute autre erreur.
  unknown;

  /// Échec correspondant au code serveur [code], [unknown] sinon.
  static EventFailure fromServerCode(String? code) => switch (code) {
    'event_not_found' => notFound,
    'event_title_invalid' => titleInvalid,
    'event_venue_invalid' => venueInvalid,
    'event_dates_invalid' => datesInvalid,
    'event_timezone_invalid' => timezoneInvalid,
    'event_capacity_invalid' => capacityInvalid,
    'event_capacity_below_issued' => capacityBelowIssued,
    'event_locked' => locked,
    'event_invalid_transition' => invalidTransition,
    'event_has_tickets' => hasTickets,
    'event_already_ended' => alreadyEnded,
    _ => unknown,
  };
}

/// Accès aux événements.
abstract interface class EventRepository {
  /// Événements visibles de l'organisation (RLS côté serveur).
  Future<List<TicketEvent>> list(String organizationId);

  /// Crée un événement en brouillon.
  Future<TicketEvent> create(String organizationId, EventDraft draft);

  /// Modifie un événement (brouillon ou publié).
  Future<TicketEvent> update(String eventId, EventDraft draft);

  /// Change le statut ; le serveur contrôle la transition.
  Future<TicketEvent> setStatus(String eventId, EventStatus status);
}
