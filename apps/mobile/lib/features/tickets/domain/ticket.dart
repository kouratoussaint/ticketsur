import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/tickets/domain/ticket_holder.dart';

export 'package:ticketsur/features/tickets/domain/ticket_holder.dart';

/// Statut d'un ticket (côté serveur : `ticket_status`).
enum TicketStatus {
  /// Émis, pas encore utilisé : valable à l'entrée.
  issued('issued'),

  /// Utilisé à l'entrée (première validation).
  redeemed('redeemed'),

  /// Annulé par un organisateur.
  revoked('revoked'),

  /// Expiré.
  expired('expired');

  new(this.wireName);

  final String wireName;

  /// Statut correspondant à [value] ; inconnu → annulé (jamais valable).
  static TicketStatus fromWire(Object? value) => values.firstWhere(
    (s) => s.wireName == value,
    orElse: () => TicketStatus.revoked,
  );
}

/// Ticket tel que listé pour les organisateurs : aucun secret.
@immutable
final class TicketSummary {
  const new({
    required this.id,
    required this.reference,
    required this.categoryName,
    required this.status,
    required this.issuedAt,
    this.categoryId,
    this.redeemedAt,
    this.redeemedCheckpoint,
    this.revokedAt,
    this.holder = TicketHolder.none,
  });

  /// Lit une ligne de `event_tickets`.
  factory fromJson(Map<String, Object?> json) => TicketSummary(
    id: json['id']! as String,
    reference: json['public_reference']! as String,
    categoryId: json['category_id'] as String?,
    categoryName: json['category_name']! as String,
    status: TicketStatus.fromWire(json['status']),
    issuedAt: DateTime.parse(json['issued_at']! as String).toUtc(),
    redeemedAt: _date(json['redeemed_at']),
    redeemedCheckpoint: json['redeemed_checkpoint_name'] as String?,
    revokedAt: _date(json['revoked_at']),
    holder: TicketHolder.fromJson(json),
  );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toUtc() : null;

  final String id;

  /// Référence lisible « TS-XXXX-XXXX » (pas un secret).
  final String reference;
  final String? categoryId;
  final String categoryName;
  final TicketStatus status;
  final DateTime issuedAt;
  final DateTime? redeemedAt;
  final String? redeemedCheckpoint;
  final DateTime? revokedAt;

  /// Titulaire (ticket nominatif) ; vide pour un ticket au porteur.
  final TicketHolder holder;

  TicketSummary withHolder(TicketHolder next) => TicketSummary(
    id: id,
    reference: reference,
    categoryId: categoryId,
    categoryName: categoryName,
    status: status,
    issuedAt: issuedAt,
    redeemedAt: redeemedAt,
    redeemedCheckpoint: redeemedCheckpoint,
    revokedAt: revokedAt,
    holder: next,
  );

  TicketSummary withStatus(TicketStatus next) => TicketSummary(
    id: id,
    reference: reference,
    categoryId: categoryId,
    categoryName: categoryName,
    status: next,
    issuedAt: issuedAt,
    redeemedAt: redeemedAt,
    redeemedCheckpoint: redeemedCheckpoint,
    revokedAt: next == TicketStatus.revoked
        ? (revokedAt ?? DateTime.now().toUtc())
        : revokedAt,
    holder: holder,
  );
}

/// Une page de tickets et le total correspondant au filtre.
@immutable
final class TicketPage {
  const new({required this.items, required this.total});

  final List<TicketSummary> items;
  final int total;
}

/// Ticket avec son jeton QR : obtenu à l'émission ou par ré-export audité.
///
/// Le jeton est un secret au porteur : [toString] le masque.
@immutable
final class TicketSecret {
  const new({
    required this.ticketId,
    required this.reference,
    required this.token,
    required this.categoryName,
    this.status = TicketStatus.issued,
    this.holderName,
  });

  final String ticketId;
  final String reference;

  /// « TS1.… » — contenu du QR.
  final String token;
  final String categoryName;
  final TicketStatus status;

  /// Nom du titulaire imprimé sur le ticket, s'il y en a un.
  final String? holderName;

  TicketSecret withHolderName(String? name) => TicketSecret(
    ticketId: ticketId,
    reference: reference,
    token: token,
    categoryName: categoryName,
    status: status,
    holderName: name,
  );

  @override
  String toString() => 'TicketSecret($reference, TS1.***)';
}

/// Échecs liés aux tickets.
enum TicketFailure implements Exception {
  /// Ticket ou événement inconnu, ou droits insuffisants.
  notFound,

  /// Émission impossible : événement en brouillon.
  eventNotPublished,

  /// Quota de la catégorie dépassé.
  categoryCapacityExceeded,

  /// Capacité de l'événement dépassée.
  eventCapacityExceeded,

  /// Quantité, catégorie ou événement refusés.
  invalid,

  /// Nom du titulaire trop long.
  holderNameInvalid,

  /// Téléphone du titulaire invalide.
  holderPhoneInvalid,

  /// E-mail du titulaire invalide.
  holderEmailInvalid,

  /// Titulaire figé : ticket déjà utilisé, annulé ou expiré.
  notEditable,

  /// Serveur injoignable.
  network,

  /// Toute autre erreur.
  unknown;

  /// Échec correspondant au code serveur [code].
  static TicketFailure fromServerCode(String? code) => switch (code) {
    'event_not_found' || 'ticket_not_found' => notFound,
    'event_not_published' => eventNotPublished,
    'category_capacity_exceeded' => categoryCapacityExceeded,
    'event_capacity_exceeded' => eventCapacityExceeded,
    'export_params_invalid' ||
    'issue_rows_invalid' ||
    'category_not_found' => invalid,
    'holder_name_invalid' => holderNameInvalid,
    'holder_phone_invalid' => holderPhoneInvalid,
    'holder_email_invalid' => holderEmailInvalid,
    'ticket_not_editable' => notEditable,
    _ => unknown,
  };
}

/// Nombre maximal de tickets par lot dans l'application.
const int maxBatchSize = 500;

/// Nombre maximal de tickets par ré-export (identique au serveur).
const int maxExportSize = 200;

/// Nombre maximal de lignes par émission nominative (identique au serveur).
const int maxNamedBatchSize = 500;

/// Accès aux tickets d'un événement.
abstract interface class TicketRepository {
  Future<TicketPage> list(
    String eventId, {
    TicketStatus? status,
    String? search,
    int limit = 50,
    int offset = 0,
  });

  /// Émet [quantity] tickets ; les jetons ne sont renvoyés qu'ici.
  Future<List<TicketSecret>> issue(
    String eventId,
    String categoryId,
    int quantity, {
    required String categoryName,
  });

  /// Émet un ticket par ligne (catégories mélangées possibles), tout ou
  /// rien ; les jetons ne sont renvoyés qu'ici, dans l'ordre des lignes.
  Future<List<TicketSecret>> issueNamed(String eventId, List<TicketRow> rows);

  /// Renseigne, corrige ou efface le titulaire d'un ticket valable.
  Future<TicketHolder> setHolder(String ticketId, TicketHolder holder);

  /// Ré-export audité des jetons (tickets annulés exclus).
  Future<List<TicketSecret>> export(List<String> ticketIds);

  /// Annule un ticket ; renvoie son statut final.
  Future<TicketStatus> revoke(String ticketId, {String? reason});
}
