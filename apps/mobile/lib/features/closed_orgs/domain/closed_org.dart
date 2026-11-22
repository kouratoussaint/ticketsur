import 'package:flutter/foundation.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

/// Structure fermée par Tikéo, consultable par son propriétaire et ses
/// gestionnaires, sans rien pouvoir modifier (ADR 0044).
@immutable
final class ClosedOrganization {
  const new({
    required this.id,
    required this.name,
    required this.role,
    required this.closedAt,
    this.city,
    this.logoUrl,
    this.eventCount = 0,
  });

  /// Lit une ligne de `my_closed_organizations` ou l'en-tête de
  /// `closed_organization_events`.
  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? logoUrlOf,
  }) {
    final logo = json['logo_path'] as String?;
    return ClosedOrganization(
      id: json['id']! as String,
      name: json['name']! as String,
      city: json['city'] as String?,
      logoUrl: logo == null ? null : logoUrlOf?.call(logo),
      role: MemberRole.fromWire(json['role']),
      closedAt: DateTime.parse(json['closed_at']! as String).toUtc(),
      eventCount: (json['events'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String? city;
  final String? logoUrl;
  final MemberRole role;
  final DateTime closedAt;
  final int eventCount;
}

/// Événement d'une structure fermée, avec ses chiffres.
typedef ClosedEvent = ({
  TicketEvent event,
  int issued,
  int admitted,
  int revoked,
});

/// Une structure fermée et ses événements (du plus récent au plus ancien).
typedef ClosedOrganizationDetail = ({
  ClosedOrganization organization,
  List<ClosedEvent> events,
});

/// Échecs de la consultation.
enum ClosedOrgFailure implements Exception {
  /// Structure inconnue, rouverte, à la corbeille ou droits retirés.
  notFound,

  /// Pas de réseau.
  network,

  /// Autre erreur.
  unknown,
}

/// Consultation des structures fermées.
abstract interface class ClosedOrgRepository {
  /// Structures fermées dont le compte est propriétaire ou gestionnaire.
  Future<List<ClosedOrganization>> list();

  /// Une structure fermée et ses événements.
  Future<ClosedOrganizationDetail> detail(String organizationId);
}
