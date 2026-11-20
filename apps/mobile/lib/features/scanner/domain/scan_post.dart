import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// État du contrôle d'un événement, piloté par l'organisateur (« Démarrer
/// le contrôle », « Arrêter le contrôle ») ; indicatif : le serveur reste
/// seul juge.
enum ScanWindow {
  /// Pas encore démarré (événement publié).
  upcoming,

  /// En cours.
  open,

  /// Arrêté.
  closed,
}

/// Poste de contrôle de l'utilisateur : un événement et une porte (S20, S21).
@immutable
final class ScanPost {
  const new({
    required this.eventId,
    required this.eventTitle,
    required this.eventStatus,
    required this.timezone,
    required this.startsAt,
    required this.endsAt,
    required this.organizationName,
    required this.checkpointId,
    required this.checkpointName,
    this.venue,
  });

  /// Lit une ligne de `my_scan_posts`.
  factory fromJson(Map<String, Object?> json) => ScanPost(
    eventId: json['event_id']! as String,
    eventTitle: json['event_title']! as String,
    eventStatus: EventStatus.fromWire(json['event_status']),
    venue: json['venue'] as String?,
    timezone: json['timezone']! as String,
    startsAt: _date(json['starts_at']),
    endsAt: _date(json['ends_at']),
    organizationName: json['organization_name']! as String,
    checkpointId: json['checkpoint_id']! as String,
    checkpointName: json['checkpoint_name']! as String,
  );

  static DateTime _date(Object? value) =>
      DateTime.parse(value! as String).toUtc();

  final String eventId;
  final String eventTitle;
  final EventStatus eventStatus;
  final String? venue;
  final String timezone;
  final DateTime startsAt;
  final DateTime endsAt;
  final String organizationName;
  final String checkpointId;
  final String checkpointName;

  /// État du contrôle : seul le statut compte, plus aucune heure.
  ScanWindow get window => switch (eventStatus) {
    EventStatus.inProgress => ScanWindow.open,
    EventStatus.published || EventStatus.draft => ScanWindow.upcoming,
    _ => ScanWindow.closed,
  };

  /// Événement minimal, pour réutiliser les formats de date.
  TicketEvent get event => TicketEvent(
    id: eventId,
    organizationId: '',
    title: eventTitle,
    venue: venue,
    timezone: timezone,
    startsAt: startsAt,
    endsAt: endsAt,
    status: eventStatus,
  );
}

/// Tentative de scan de l'utilisateur (S27) ; jamais de jeton.
@immutable
final class RecentScan {
  const new({
    required this.id,
    required this.serverTime,
    required this.outcome,
    this.eventTitle,
    this.checkpointName,
    this.reference,
    this.category,
  });

  /// Lit une ligne de `my_recent_scans`.
  factory fromJson(Map<String, Object?> json) => RecentScan(
    id: json['id']! as String,
    serverTime: DateTime.parse(json['server_time']! as String).toUtc(),
    outcome: ScanResult.fromWire(json['outcome']) ?? ScanResult.unavailable,
    eventTitle: json['event_title'] as String?,
    checkpointName: json['checkpoint_name'] as String?,
    reference: json['public_reference'] as String?,
    category: json['category_name'] as String?,
  );

  final String id;
  final DateTime serverTime;
  final ScanResult outcome;
  final String? eventTitle;
  final String? checkpointName;
  final String? reference;
  final String? category;
}

/// Erreur de transport : la requête n'a peut-être pas abouti (à rejouer
/// avec le même identifiant).
final class ScanTransportException implements Exception {
  const new([this.cause]);

  final Object? cause;

  @override
  String toString() => 'ScanTransportException';
}

/// Accès serveur du contrôle.
abstract interface class ScanRepository {
  Future<List<ScanPost>> myPosts();

  Future<List<RecentScan>> recentScans();

  /// Appelle `validate_scan` et renvoie la réponse brute (interprétée par
  /// [ScanVerdict.fromServer]). Lève [ScanTransportException] si le serveur
  /// n'a pas répondu.
  Future<Object?> validate({
    required String requestId,
    required String eventId,
    required String checkpointId,
    required String token,
  });

  /// Recherche d'un ticket à la porte (QR perdu) : nom, téléphone ou
  /// référence. Lève [DoorLookupFailure].
  Future<List<DoorMatch>> lookup({
    required String eventId,
    required String checkpointId,
    required String query,
  });

  /// Valide le ticket choisi après une recherche (`validate_ticket_at_door`,
  /// mêmes règles que le scan). Lève [ScanTransportException] sans réponse.
  Future<Object?> validateTicket({
    required String requestId,
    required String eventId,
    required String checkpointId,
    required String ticketId,
  });
}

/// Un ticket trouvé à la porte.
@immutable
final class DoorMatch {
  const new({
    required this.ticketId,
    required this.reference,
    required this.category,
    required this.status,
    this.holderName,
    this.phoneHint,
    this.isInvitation = false,
  });

  factory fromJson(Map<String, Object?> json) => DoorMatch(
    ticketId: json['ticket_id']! as String,
    reference: json['public_reference']! as String,
    category: json['category']! as String,
    status: TicketStatus.fromWire(json['status']),
    holderName: json['holder_name'] as String?,
    phoneHint: json['phone_hint'] as String?,
    isInvitation: json['is_invitation'] == true,
  );

  final String ticketId;
  final String reference;
  final String category;
  final TicketStatus status;
  final String? holderName;

  /// Deux derniers chiffres du téléphone (« •• 33 »).
  final String? phoneHint;
  final bool isInvitation;
}

/// Échecs de la recherche à la porte.
enum DoorLookupFailure implements Exception {
  /// Moins de 3 caractères.
  tooShort,

  /// Trop de recherches en peu de temps.
  rateLimited,

  /// Contrôle fermé ou porte non affectée.
  forbidden,

  /// Pas de réseau.
  network,
}
