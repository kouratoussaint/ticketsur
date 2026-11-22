/// Signaler un contenu et traiter les signalements (lot 4-12b, ADR 0050).
library;

/// Contenu signalé.
enum ReportKind {
  event,
  organization;

  static ReportKind? fromWire(Object? value) =>
      ReportKind.values.where((k) => k.name == value).firstOrNull;
}

/// Motif d'un signalement (même liste que le serveur).
enum ReportReason {
  misleading,
  scam,
  offensive,
  duplicate,
  other;

  static ReportReason? fromWire(Object? value) =>
      ReportReason.values.where((r) => r.name == value).firstOrNull;
}

/// Où en sont les signalements d'un contenu.
enum ReportStatus {
  open,
  dismissed,
  actioned;

  static ReportStatus fromWire(Object? value) =>
      ReportStatus.values.where((s) => s.name == value).firstOrNull ??
      ReportStatus.open;
}

/// Échecs côté spectateur ; la console traduit les siens en
/// `AdminFailure`.
enum ReportFailure implements Exception {
  network,
  notFound,
  rateLimited,
  commentTooLong,
  unknown,
}

/// Commentaire laissé avec un signalement (lu dans la console seulement).
typedef ReportComment = ({String comment, DateTime at});

/// Signalements d'un même contenu, regroupés pour la console.
final class ReportGroup {
  const new({
    required this.kind,
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.title,
    required this.count,
    required this.reasons,
    required this.comments,
    required this.firstAt,
    required this.lastAt,
    required this.status,
    required this.removed,
    this.startsAt,
    this.handledAt,
  });

  factory fromJson(Map<String, Object?> json) => ReportGroup(
    kind: ReportKind.fromWire(json['kind']) ?? ReportKind.event,
    id: json['id']! as String,
    organizationId: json['organization_id']! as String,
    organizationName: json['organization_name'] as String? ?? '',
    title: json['title'] as String? ?? '',
    startsAt: switch (json['starts_at']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
    count: (json['count']! as num).toInt(),
    reasons: {
      for (final MapEntry(:key, :value)
          in ((json['reasons'] as Map?) ?? const {}).entries)
        ?ReportReason.fromWire(key): (value as num).toInt(),
    },
    comments: [
      for (final raw in (json['comments'] as List?) ?? const [])
        if (raw case {'comment': final String comment, 'at': final String at})
          (comment: comment, at: DateTime.parse(at)),
    ],
    firstAt: DateTime.parse(json['first_at']! as String),
    lastAt: DateTime.parse(json['last_at']! as String),
    handledAt: switch (json['handled_at']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
    status: ReportStatus.fromWire(json['status']),
    removed: json['removed'] == true,
  );

  final ReportKind kind;

  /// Identifiant de l'événement ou de la structure signalés.
  final String id;
  final String organizationId;
  final String organizationName;

  /// Titre de l'événement, ou nom de la structure.
  final String title;
  final DateTime? startsAt;
  final int count;
  final Map<ReportReason, int> reasons;

  /// Les 5 derniers commentaires, du plus récent au plus ancien.
  final List<ReportComment> comments;
  final DateTime firstAt;
  final DateTime lastAt;
  final DateTime? handledAt;
  final ReportStatus status;

  /// Événement retiré du catalogue, ou structure suspendue.
  final bool removed;
}

/// Une page de signalements et le nombre de contenus à traiter.
typedef ReportsPage = ({int open, List<ReportGroup> items});

abstract interface class ModerationRepository {
  /// Signale un contenu (compte connecté) ; `true` si ce compte l'avait
  /// déjà signalé (rien n'est ajouté).
  Future<bool> report(
    ReportKind kind,
    String id,
    ReportReason reason, {
    String? comment,
  });

  /// Console : à traiter ([open]) ou traités.
  Future<ReportsPage> reports({
    bool open = true,
    int offset = 0,
    int limit = 30,
  });

  /// Console : retire le contenu ([remove]) ou classe sans suite ; renvoie
  /// le nombre de signalements traités.
  Future<int> resolve(
    ReportKind kind,
    String id, {
    required bool remove,
    required String reason,
  });
}
