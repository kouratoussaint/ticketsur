import 'package:flutter/foundation.dart' show Uint8List, immutable;

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

/// Type d'événement (côté serveur : `event_kind`).
enum EventKind {
  /// Concert, spectacle.
  concert('concert'),

  /// Conférence, séminaire.
  conference('conference'),

  /// Culte, célébration religieuse.
  worship('worship'),

  /// Rencontre sportive.
  sport('sport'),

  /// Mariage, cérémonie familiale.
  wedding('wedding'),

  /// Formation, atelier.
  training('training'),

  /// Gala, soirée.
  gala('gala'),

  /// Autre.
  other('other');

  new(this.wireName);

  /// Valeur échangée avec le serveur.
  final String wireName;

  /// Type correspondant à [value], [other] s'il est inconnu.
  static EventKind fromWire(Object? value) => values.firstWhere(
    (kind) => kind.wireName == value,
    orElse: () => EventKind.other,
  );
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
    this.city,
    this.countryCode = 'BF',
    this.venueAddress,
    this.description,
    this.kind = EventKind.other,
    this.coverPath,
    this.coverUrl,
    this.isPublic = false,
    this.publicBlockedReason,
    this.publicBlocked = false,
  });

  /// Lit une ligne de `events` (lecture directe ou retour de fonction).
  /// [coverUrlOf] transforme le chemin Storage de la photo en adresse
  /// affichable.
  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? coverUrlOf,
  }) {
    final coverPath = json['cover_path'] as String?;
    return TicketEvent(
      id: json['id']! as String,
      organizationId: json['organization_id']! as String,
      title: json['title']! as String,
      venue: json['venue'] as String?,
      timezone: json['timezone']! as String,
      startsAt: DateTime.parse(json['starts_at']! as String).toUtc(),
      endsAt: DateTime.parse(json['ends_at']! as String).toUtc(),
      capacity: (json['capacity'] as num?)?.toInt(),
      status: EventStatus.fromWire(json['status']),
      city: json['city'] as String?,
      countryCode: (json['country_code'] as String?) ?? 'BF',
      venueAddress: json['venue_address'] as String?,
      description: json['description'] as String?,
      kind: EventKind.fromWire(json['kind']),
      coverPath: coverPath,
      coverUrl: coverPath == null ? null : coverUrlOf?.call(coverPath),
      isPublic: json['is_public'] == true,
      publicBlocked: json['public_blocked_at'] != null,
      publicBlockedReason: json['public_blocked_reason'] as String?,
    );
  }

  final String id;
  final String organizationId;
  final String title;
  final String? venue;
  final String timezone;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? capacity;
  final EventStatus status;
  final String? city;
  final String countryCode;
  final String? venueAddress;
  final String? description;
  final EventKind kind;

  /// Chemin de la photo dans le bucket `event-covers`.
  final String? coverPath;

  /// Adresse publique de la photo, `null` sans photo.
  final String? coverUrl;

  /// Visible dans le catalogue public une fois publié (`set_event_public`).
  final bool isPublic;

  /// Retiré du catalogue par Tikéo : l'organisateur ne peut plus le rendre
  /// public (`event_blocked`).
  final bool publicBlocked;

  /// Motif du retrait, lisible par l'organisateur.
  final String? publicBlockedReason;

  /// Copie avec une autre visibilité.
  TicketEvent withPublic(bool value) => _copy(isPublic: value);

  /// Photo et ville présentes : le serveur acceptera la publication.
  bool get readyToPublish => coverPath != null && city != null;

  /// Copie avec un autre statut.
  TicketEvent withStatus(EventStatus next) => _copy(status: next);

  /// Copie avec une autre photo.
  TicketEvent withCover(String? path, String? url) =>
      _copy(coverPath: path, coverUrl: url, clearCover: path == null);

  TicketEvent _copy({
    EventStatus? status,
    String? coverPath,
    String? coverUrl,
    bool clearCover = false,
    bool? isPublic,
  }) => TicketEvent(
    id: id,
    organizationId: organizationId,
    title: title,
    venue: venue,
    timezone: timezone,
    startsAt: startsAt,
    endsAt: endsAt,
    capacity: capacity,
    status: status ?? this.status,
    city: city,
    countryCode: countryCode,
    venueAddress: venueAddress,
    description: description,
    kind: kind,
    coverPath: clearCover ? null : coverPath ?? this.coverPath,
    coverUrl: clearCover ? null : coverUrl ?? this.coverUrl,
    isPublic: isPublic ?? this.isPublic,
    publicBlocked: publicBlocked,
    publicBlockedReason: publicBlockedReason,
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
      other.status == status &&
      other.city == city &&
      other.countryCode == countryCode &&
      other.venueAddress == venueAddress &&
      other.description == description &&
      other.kind == kind &&
      other.coverPath == coverPath &&
      other.coverUrl == coverUrl &&
      other.isPublic == isPublic &&
      other.publicBlocked == publicBlocked &&
      other.publicBlockedReason == publicBlockedReason;

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
    city,
    countryCode,
    venueAddress,
    description,
    kind,
    coverPath,
    coverUrl,
    isPublic,
    publicBlocked,
    publicBlockedReason,
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
    this.city,
    this.countryCode = 'BF',
    this.venueAddress,
    this.description,
    this.kind = EventKind.other,
  });

  /// Brouillon prérempli à partir d'un événement existant.
  factory of(TicketEvent event) => EventDraft(
    title: event.title,
    venue: event.venue,
    timezone: event.timezone,
    startsAt: event.startsAt,
    endsAt: event.endsAt,
    capacity: event.capacity,
    city: event.city,
    countryCode: event.countryCode,
    venueAddress: event.venueAddress,
    description: event.description,
    kind: event.kind,
  );

  final String title;
  final String? venue;
  final String timezone;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? capacity;
  final String? city;
  final String countryCode;
  final String? venueAddress;
  final String? description;
  final EventKind kind;

  /// Durée maximale d'un événement (identique au serveur).
  static const Duration maxDuration = Duration(days: 31);

  /// Longueur maximale de la description (identique au serveur).
  static const int maxDescription = 2000;

  static String? _clean(String? text) {
    final value = text?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Paramètres communs de `create_event` / `update_event`.
  Map<String, Object?> toParams() => {
    'p_title': title.trim(),
    'p_venue': _clean(venue),
    'p_timezone': timezone,
    'p_starts_at': startsAt.toUtc().toIso8601String(),
    'p_ends_at': endsAt.toUtc().toIso8601String(),
    'p_capacity': capacity,
    'p_city': _clean(city),
    'p_country_code': countryCode,
    'p_venue_address': _clean(venueAddress),
    'p_description': _clean(description),
    'p_kind': kind.wireName,
  };
}

/// Photo choisie sur le téléphone, prête à être envoyée.
@immutable
final class CoverImage {
  const new({required this.bytes, required this.mimeType});

  final Uint8List bytes;

  /// `image/jpeg`, `image/png` ou `image/webp`.
  final String mimeType;

  /// Taille maximale acceptée par le bucket (2 Mo).
  static const int maxBytes = 2 * 1024 * 1024;

  /// Extension de fichier correspondant au type.
  String get extension => switch (mimeType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
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

  /// Photo ou ville manquante pour publier (`event_incomplete`).
  incomplete,

  /// Ville hors limites (`event_city_invalid`).
  cityInvalid,

  /// Adresse trop longue (`event_address_invalid`).
  addressInvalid,

  /// Description trop longue (`event_description_invalid`).
  descriptionInvalid,

  /// Photo refusée : introuvable, trop lourde ou d'un format non accepté
  /// (`event_cover_invalid`, refus du bucket).
  coverInvalid,

  /// Retiré du catalogue par Tikéo (`event_blocked`).
  blocked,

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
    'event_incomplete' => incomplete,
    'event_city_invalid' => cityInvalid,
    'event_address_invalid' => addressInvalid,
    'event_description_invalid' => descriptionInvalid,
    'event_cover_invalid' => coverInvalid,
    'event_blocked' => blocked,
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

  /// Envoie [image] puis la rattache à [event] comme photo de couverture.
  /// L'ancienne photo est supprimée du stockage.
  Future<TicketEvent> setCover(TicketEvent event, CoverImage image);

  /// Rend l'événement visible (ou non) dans le catalogue public.
  Future<TicketEvent> setPublic(String eventId, {required bool public});

  /// Copie [source] en brouillon (catégories, portes, équipe ; jamais les
  /// tickets) aux nouvelles dates ; la photo est recopiée dans un fichier
  /// distinct. Renvoie l'identifiant de la copie.
  Future<String> duplicate(
    TicketEvent source, {
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
  });
}
