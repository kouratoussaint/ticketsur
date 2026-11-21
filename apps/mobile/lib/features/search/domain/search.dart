import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Événement trouvé par la recherche globale.
@immutable
final class SearchEventHit {
  const new({
    required this.id,
    required this.title,
    required this.status,
    required this.kind,
    required this.startsAt,
    this.venue,
    this.city,
  });

  factory fromJson(Map<String, Object?> json) => SearchEventHit(
    id: json['id']! as String,
    title: json['title']! as String,
    status: EventStatus.fromWire(json['status']),
    kind: EventKind.fromWire(json['kind']),
    startsAt: DateTime.parse(json['starts_at']! as String).toUtc(),
    venue: json['venue'] as String?,
    city: json['city'] as String?,
  );

  final String id;
  final String title;
  final EventStatus status;
  final EventKind kind;
  final DateTime startsAt;
  final String? venue;
  final String? city;
}

/// Ticket trouvé par la recherche globale (tous les événements).
@immutable
final class SearchTicketHit {
  const new({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.reference,
    required this.category,
    required this.status,
    this.eventNumber,
    this.holderName,
    this.holderPhone,
    this.isInvitation = false,
  });

  factory fromJson(Map<String, Object?> json) => SearchTicketHit(
    id: json['id']! as String,
    eventId: json['event_id']! as String,
    eventTitle: json['event_title']! as String,
    reference: json['public_reference']! as String,
    category: json['category']! as String,
    status: TicketStatus.fromWire(json['status']),
    eventNumber: (json['event_number'] as num?)?.toInt(),
    holderName: json['holder_name'] as String?,
    holderPhone: json['holder_phone'] as String?,
    isInvitation: json['is_invitation'] == true,
  );

  final String id;
  final String eventId;
  final String eventTitle;
  final String reference;
  final String category;
  final TicketStatus status;
  final int? eventNumber;
  final String? holderName;
  final String? holderPhone;
  final bool isInvitation;
}

@immutable
final class PromoterSearchResult {
  const new({this.events = const [], this.tickets = const []});

  factory fromJson(Map<String, Object?> json) => PromoterSearchResult(
    events: [
      for (final e in json['events']! as List)
        SearchEventHit.fromJson(Map<String, Object?>.from(e as Map)),
    ],
    tickets: [
      for (final t in json['tickets']! as List)
        SearchTicketHit.fromJson(Map<String, Object?>.from(t as Map)),
    ],
  );

  final List<SearchEventHit> events;
  final List<SearchTicketHit> tickets;

  bool get isEmpty => events.isEmpty && tickets.isEmpty;
}

enum SearchFailure implements Exception { forbidden, network, unknown }

/// Longueur minimale d'une recherche (comme le serveur).
const minSearchLength = 2;

/// Recherche globale du promoteur (lot 4-6b, migration 4400).
abstract interface class SearchRepository {
  /// Événements et tickets de [organizationId] qui correspondent à [query]
  /// (2 à 60 caractères).
  Future<PromoterSearchResult> search(String organizationId, String query);
}
