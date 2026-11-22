import 'package:flutter/foundation.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
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
    this.eventNumber,
    this.organizationLogoPath,
    this.organizationLogoUrl,
    this.template,
    this.organizationId,
    this.eventListed = false,
  });

  /// Lit une ligne de `my_tickets` (ou du cache de l'appareil, qui garde
  /// aussi les adresses des images). [coverUrlOf] : bucket `event-covers`
  /// (photo et design importé) ; [logoUrlOf] : bucket `org-logos`.
  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? coverUrlOf,
    String Function(String path)? logoUrlOf,
  }) {
    final logoPath = json['organization_logo_path'] as String?;
    final templateJson = json['template'];
    final cachedImage = templateJson is Map
        ? templateJson['image_url'] as String?
        : null;
    final event = TicketEvent.fromJson({
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
      'tagline': json['tagline'],
    }, coverUrlOf: coverUrlOf);
    return WalletTicket._read(
      json,
      event: switch ((coverUrlOf, json['cover_url'])) {
        (null, final String url) => event.withCover(event.coverPath, url),
        _ => event,
      },
      organizationLogoPath: logoPath,
      organizationLogoUrl: logoPath == null
          ? null
          : logoUrlOf?.call(logoPath) ??
                json['organization_logo_url'] as String?,
      template: templateFromJson(
        templateJson,
        imageUrlOf: (path) => coverUrlOf?.call(path) ?? cachedImage ?? '',
      ),
    );
  }

  factory _read(
    Map<String, Object?> json, {
    required TicketEvent event,
    required String? organizationLogoPath,
    required String? organizationLogoUrl,
    required TicketTemplate? template,
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
    event: event,
    eventNumber: (json['event_number'] as num?)?.toInt(),
    organizationLogoPath: organizationLogoPath,
    organizationLogoUrl: organizationLogoUrl,
    template: template,
    organizationId: json['organization_id'] as String?,
    eventListed: json['event_listed'] == true,
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

  /// Numéro d'ordre dans l'événement (« N° 000123 »).
  final int? eventNumber;
  final String? organizationLogoPath;
  final String? organizationLogoUrl;

  /// Modèle de la catégorie, `null` : modèle proposé.
  final TicketTemplate? template;

  /// Structure organisatrice (page publique) ; `null` avant la migration
  /// 5600 ou dans un ancien cache.
  final String? organizationId;

  /// Événement visible au catalogue : sa fiche publique peut s'ouvrir.
  final bool eventListed;

  /// De quoi dessiner le ticket avec son modèle.
  TicketArt get art => TicketArt(
    event: event,
    organizationName: organizationName,
    organizationLogoUrl: organizationLogoUrl,
    templates: {'categorie': ?template},
    info: {
      if (eventNumber case final number?)
        id: (categoryId: 'categorie', number: number),
    },
  );

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
    'cover_url': event.coverUrl,
    'tagline': event.tagline,
    'event_number': eventNumber,
    'organization_logo_path': organizationLogoPath,
    'organization_logo_url': organizationLogoUrl,
    'organization_id': organizationId,
    'event_listed': eventListed,
    'template': switch (template) {
      null => null,
      final CustomTemplate custom => {
        ...templateToJson(custom),
        'image_url': custom.imageUrl,
      },
      final t => templateToJson(t),
    },
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
