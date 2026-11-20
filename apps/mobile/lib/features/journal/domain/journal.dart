import 'package:flutter/foundation.dart';

/// Une ligne du journal de la structure (migration 2900).
@immutable
final class JournalEntry {
  const new({
    required this.id,
    required this.createdAt,
    required this.action,
    this.actorName,
    this.byPlatform = false,
    this.subject,
    this.details = const {},
  });

  factory fromJson(Map<String, Object?> json) => JournalEntry(
    id: json['id']! as String,
    createdAt: DateTime.parse(json['created_at']! as String).toUtc(),
    action: json['action']! as String,
    actorName: json['actor_name'] as String?,
    byPlatform: json['by_platform'] == true,
    subject: json['subject'] as String?,
    details: Map<String, Object?>.from(
      (json['details'] as Map?) ?? const <String, Object?>{},
    ),
  );

  final String id;
  final DateTime createdAt;
  final String action;

  /// Auteur ; `null` pour une action de l'équipe Tikéo ([byPlatform]).
  final String? actorName;
  final bool byPlatform;

  /// Objet : « TS-… · Événement » ou titre de l'événement.
  final String? subject;
  final Map<String, Object?> details;
}

/// Familles d'actions du journal.
enum JournalFilter {
  all([]),
  events(['event.', 'category.', 'checkpoint.']),
  tickets(['ticket', 'tickets.']),
  control(['scan.', 'assignment.']),
  team(['member.', 'invitation.']),
  structure(['organization.', 'admin.']);

  new(this.prefixes);

  /// Préfixes envoyés au serveur ; vide : tout.
  final List<String> prefixes;
}

abstract interface class JournalRepository {
  Future<List<JournalEntry>> entries(
    String organizationId, {
    JournalFilter filter = JournalFilter.all,
    int offset = 0,
    int limit = 50,
  });
}
