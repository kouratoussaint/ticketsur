import 'package:flutter/foundation.dart';

/// Destinataires possibles d'une annonce.
enum AnnouncementAudience {
  /// Visiteurs sans compte.
  visitors('visitors'),

  /// Comptes classiques (sans structure).
  users('users'),

  /// Promoteurs : propriétaires et gestionnaires.
  promoters('promoters'),

  /// Contrôleurs.
  controllers('controllers');

  new(this.wireName);

  final String wireName;

  static AnnouncementAudience? fromWire(Object? value) =>
      values.where((a) => a.wireName == value).firstOrNull;
}

/// Une annonce de l'équipe Tikéo.
@immutable
final class Announcement {
  const new({
    required this.id,
    required this.title,
    required this.body,
    required this.important,
    required this.startsAt,
    this.endsAt,
    this.audiences = const {},
    this.archivedAt,
    this.active = true,
    this.authorName,
    this.scheduled = false,
  });

  factory fromJson(Map<String, Object?> json) => Announcement(
    id: json['id']! as String,
    title: json['title']! as String,
    body: json['body']! as String,
    important: json['level'] == 'important',
    startsAt: DateTime.parse(json['starts_at']! as String).toUtc(),
    endsAt: switch (json['ends_at']) {
      final String at => DateTime.parse(at).toUtc(),
      _ => null,
    },
    audiences: {
      for (final value in (json['audiences'] as List<Object?>?) ?? const [])
        ?AnnouncementAudience.fromWire(value),
    },
    archivedAt: switch (json['archived_at']) {
      final String at => DateTime.parse(at).toUtc(),
      _ => null,
    },
    active: json['active'] as bool? ?? true,
    authorName: json['author_name'] as String?,
    scheduled: json['scheduled'] as bool? ?? false,
  );

  final String id;
  final String title;
  final String body;
  final bool important;
  final DateTime startsAt;
  final DateTime? endsAt;

  // Console seulement.
  final Set<AnnouncementAudience> audiences;
  final DateTime? archivedAt;
  final bool active;
  final String? authorName;

  /// Programmée : pas encore commencée (modifiable).
  final bool scheduled;
}

/// Échecs des annonces.
enum AnnouncementFailure implements Exception {
  invalid,

  /// Déjà diffusée ou archivée : ne se modifie plus.
  started,
  network,
  unknown,
}

/// Annonces (migration 2300).
abstract interface class AnnouncementRepository {
  /// Annonces en cours pour l'appelant (avec ou sans compte).
  Future<List<Announcement>> mine();

  /// Console : toutes les annonces, les plus récentes d'abord.
  Future<List<Announcement>> all({int offset = 0, int limit = 50});

  /// Console : publie une annonce, tout de suite ou à [startsAt].
  Future<String> publish({
    required String title,
    required String body,
    required Set<AnnouncementAudience> audiences,
    required bool important,
    DateTime? endsAt,
    DateTime? startsAt,
  });

  /// Console : modifie une annonce programmée.
  Future<void> update(
    String id, {
    required String title,
    required String body,
    required Set<AnnouncementAudience> audiences,
    required bool important,
    required DateTime? startsAt,
    required DateTime? endsAt,
  });

  /// Console : retire une annonce.
  Future<void> archive(String id);
}
