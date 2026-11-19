import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Ligne de la liste du rapport (`event_report_rows`) : un ticket, sans jeton.
@immutable
final class ReportRow {
  const new({
    required this.reference,
    required this.categoryName,
    required this.status,
    required this.issuedAt,
    this.holder = TicketHolder.none,
    this.redeemedAt,
    this.checkpointName,
    this.revokedAt,
    this.lastDelivery,
  });

  factory fromJson(Map<String, Object?> json) => ReportRow(
    reference: json['public_reference']! as String,
    categoryName: json['category_name']! as String,
    status: TicketStatus.fromWire(json['status']),
    issuedAt: DateTime.parse(json['issued_at']! as String).toUtc(),
    holder: TicketHolder.fromJson(json),
    redeemedAt: _date(json['redeemed_at']),
    checkpointName: json['redeemed_checkpoint_name'] as String?,
    revokedAt: _date(json['revoked_at']),
    lastDelivery: switch ((
      DeliveryChannel.fromWire(json['last_delivery_channel']),
      _date(json['last_delivery_at']),
    )) {
      (final DeliveryChannel channel, final DateTime at) => (
        channel: channel,
        at: at,
      ),
      _ => null,
    },
  );

  final String reference;
  final String categoryName;
  final TicketStatus status;
  final DateTime issuedAt;
  final TicketHolder holder;
  final DateTime? redeemedAt;
  final String? checkpointName;
  final DateTime? revokedAt;
  final TicketDelivery? lastDelivery;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}

/// Échecs du rapport.
enum ReportFailure implements Exception {
  /// Événement inconnu ou droits insuffisants.
  notFound,

  /// Serveur injoignable.
  network,

  /// Toute autre erreur.
  unknown,
}

/// Accès à la liste du rapport (chaque appel est journalisé côté serveur).
abstract interface class ReportRepository {
  /// Lève une [ReportFailure] en cas d'échec.
  Future<List<ReportRow>> rows(String eventId);
}
