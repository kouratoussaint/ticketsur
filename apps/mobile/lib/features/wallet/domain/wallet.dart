import 'package:flutter/foundation.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Un ticket de « Mes tickets » (migration 2700), avec son événement.
@immutable
final class WalletTicket {
  const new({
    required this.id,
    required this.reference,
    required this.status,
    required this.categoryName,
    required this.event,
    required this.organizationName,
    this.isInvitation = false,
    this.holderName,
    this.token,
    this.redeemedAt,
  });

  /// Lit une ligne de `my_tickets` (ou du cache de l'appareil).
  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? coverUrlOf,
  }) => WalletTicket(
    id: json['ticket_id']! as String,
    reference: json['public_reference']! as String,
    status: TicketStatus.fromWire(json['status']),
    categoryName: json['category_name']! as String,
    isInvitation: json['is_invitation'] == true,
    holderName: json['holder_name'] as String?,
    token: json['qr_token'] as String?,
    redeemedAt: switch (json['redeemed_at']) {
      final String at => DateTime.parse(at).toUtc(),
      _ => null,
    },
    organizationName: json['organization_name'] as String? ?? '',
    event: TicketEvent.fromJson({
      'id': json['event_id'],
      'organization_id': '',
      'title': json['event_title'],
      'venue': json['venue'],
      'timezone': json['timezone'],
      'starts_at': json['starts_at'],
      'ends_at': json['ends_at'],
      'status': json['event_status'],
      'city': json['city'],
      'kind': json['kind'],
      'cover_path': json['cover_path'],
    }, coverUrlOf: coverUrlOf),
  );

  final String id;
  final String reference;
  final TicketStatus status;
  final String categoryName;
  final bool isInvitation;
  final String? holderName;

  /// Contenu du QR : seulement pour un ticket encore valable.
  final String? token;
  final DateTime? redeemedAt;
  final TicketEvent event;
  final String organizationName;

  /// Événement terminé.
  bool isPastAt(DateTime now) => event.endsAt.isBefore(now);

  /// Ligne pour le cache de l'appareil (même forme que `my_tickets`).
  Map<String, Object?> toJson() => {
    'ticket_id': id,
    'public_reference': reference,
    'status': status.wireName,
    'category_name': categoryName,
    'is_invitation': isInvitation,
    'holder_name': holderName,
    'qr_token': token,
    'redeemed_at': redeemedAt?.toIso8601String(),
    'organization_name': organizationName,
    'event_id': event.id,
    'event_title': event.title,
    'venue': event.venue,
    'timezone': event.timezone,
    'starts_at': event.startsAt.toIso8601String(),
    'ends_at': event.endsAt.toIso8601String(),
    'event_status': event.status.wireName,
    'city': event.city,
    'kind': event.kind.wireName,
    'cover_path': event.coverPath,
  };
}

/// Échecs de « Mes tickets ».
enum WalletFailure implements Exception {
  /// Le code lu n'est pas un ticket Tikéo.
  invalidCode,

  /// Aucun ticket ne correspond à ce QR.
  unknown,

  /// Ticket annulé par l'organisateur.
  revoked,

  /// Déjà dans le compte d'une autre personne.
  claimed,

  /// Pas de réseau.
  network,

  /// Autre erreur.
  other,
}

/// Format du QR Tikéo : « TS1. » + 43 caractères.
final RegExp walletTokenPattern = RegExp(r'^TS1\.[A-Za-z0-9_-]{43}$');

abstract interface class WalletRepository {
  Future<List<WalletTicket>> mine();

  /// Ajoute le ticket dont on présente le QR ; renvoie son identifiant.
  Future<String> claim(String token);

  /// Retire un ticket de « Mes tickets ».
  Future<void> release(String ticketId);
}
