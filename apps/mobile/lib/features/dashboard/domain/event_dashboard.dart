import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';

/// Compteurs des tickets d'un événement.
///
/// Toujours : [issued] = [admitted] + [remaining] + [expired].
@immutable
final class TicketCounts {
  const new({
    this.issued = 0,
    this.admitted = 0,
    this.remaining = 0,
    this.revoked = 0,
    this.expired = 0,
  });

  factory fromJson(Map<String, Object?> json) => TicketCounts(
    issued: _int(json['issued']),
    admitted: _int(json['admitted']),
    remaining: _int(json['remaining']),
    revoked: _int(json['revoked']),
    expired: _int(json['expired']),
  );

  /// Émis, annulés exclus.
  final int issued;

  /// Déjà entrés.
  final int admitted;

  /// Valables, pas encore entrés.
  final int remaining;

  /// Annulés par l'organisateur.
  final int revoked;

  /// Expirés sans être utilisés.
  final int expired;

  /// Part des tickets émis déjà entrés (0 à 1).
  double get attendance => issued == 0 ? 0 : admitted / issued;

  @override
  bool operator ==(Object other) =>
      other is TicketCounts &&
      other.issued == issued &&
      other.admitted == admitted &&
      other.remaining == remaining &&
      other.revoked == revoked &&
      other.expired == expired;

  @override
  int get hashCode =>
      Object.hash(issued, admitted, remaining, revoked, expired);
}

/// Tentatives de scan d'un événement.
@immutable
final class ScanCounts {
  const new({
    this.total = 0,
    this.accepted = 0,
    this.refused = 0,
    this.recentAccepted = 0,
    this.recentMinutes = 15,
    this.byOutcome = const {},
    this.lastAt,
    this.lastAcceptedAt,
  });

  factory fromJson(Map<String, Object?> json) {
    final raw = json['by_outcome'];
    final byOutcome = <ScanResult, int>{};
    if (raw is Map) {
      for (final MapEntry(:key, :value) in raw.entries) {
        final result = ScanResult.fromWire(key);
        // Motif inconnu de cette version : compté avec les refus génériques.
        final slot = result ?? ScanResult.unavailable;
        byOutcome[slot] = (byOutcome[slot] ?? 0) + _int(value);
      }
    }
    return ScanCounts(
      total: _int(json['total']),
      accepted: _int(json['accepted']),
      refused: _int(json['refused']),
      recentAccepted: _int(json['recent_accepted']),
      recentMinutes: _int(json['recent_minutes'], fallback: 15),
      byOutcome: byOutcome,
      lastAt: _date(json['last_at']),
      lastAcceptedAt: _date(json['last_accepted_at']),
    );
  }

  final int total;
  final int accepted;
  final int refused;

  /// Entrées des [recentMinutes] dernières minutes (débit).
  final int recentAccepted;
  final int recentMinutes;

  /// Refus par motif, du plus fréquent au moins fréquent via [refusals].
  final Map<ScanResult, int> byOutcome;

  /// Heure serveur (UTC) de la dernière tentative.
  final DateTime? lastAt;

  /// Heure serveur (UTC) de la dernière entrée.
  final DateTime? lastAcceptedAt;

  /// Motifs de refus triés par fréquence décroissante.
  List<MapEntry<ScanResult, int>> get refusals =>
      byOutcome.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
}

/// Remplissage et entrées d'une catégorie.
@immutable
final class CategoryStats {
  const new({
    required this.id,
    required this.name,
    this.capacity,
    this.issued = 0,
    this.admitted = 0,
  });

  factory fromJson(Map<String, Object?> json) => CategoryStats(
    id: json['id']! as String,
    name: json['name']! as String,
    capacity: (json['capacity'] as num?)?.toInt(),
    issued: _int(json['issued']),
    admitted: _int(json['admitted']),
  );

  final String id;
  final String name;
  final int? capacity;
  final int issued;
  final int admitted;

  /// Part des tickets émis déjà entrés (0 à 1).
  double get attendance => issued == 0 ? 0 : admitted / issued;
}

/// Activité d'une porte.
@immutable
final class CheckpointStats {
  const new({
    required this.id,
    required this.name,
    this.active = true,
    this.admitted = 0,
    this.refused = 0,
    this.lastAt,
  });

  factory fromJson(Map<String, Object?> json) => CheckpointStats(
    id: json['id']! as String,
    name: json['name']! as String,
    active: json['active'] as bool? ?? true,
    admitted: _int(json['admitted']),
    refused: _int(json['refused']),
    lastAt: _date(json['last_at']),
  );

  final String id;
  final String name;
  final bool active;
  final int admitted;
  final int refused;
  final DateTime? lastAt;
}

/// Activité d'un contrôleur.
@immutable
final class ControllerStats {
  const new({
    required this.userId,
    required this.displayName,
    this.accepted = 0,
    this.refused = 0,
    this.lastAt,
  });

  factory fromJson(Map<String, Object?> json) => ControllerStats(
    userId: json['user_id']! as String,
    displayName: json['display_name'] as String? ?? '',
    accepted: _int(json['accepted']),
    refused: _int(json['refused']),
    lastAt: _date(json['last_at']),
  );

  final String userId;
  final String displayName;
  final int accepted;
  final int refused;
  final DateTime? lastAt;
}

/// Tranche de la chronologie des scans.
@immutable
final class TimelineBucket {
  const new({required this.at, this.accepted = 0, this.refused = 0});

  factory fromJson(Map<String, Object?> json) => TimelineBucket(
    at: _date(json['at']) ?? DateTime.utc(1970),
    accepted: _int(json['accepted']),
    refused: _int(json['refused']),
  );

  /// Début de la tranche (UTC).
  final DateTime at;
  final int accepted;
  final int refused;

  int get total => accepted + refused;
}

/// Tableau de bord d'un événement (`event_dashboard`, version 1).
@immutable
final class EventDashboard {
  const new({
    required this.eventId,
    required this.serverTime,
    this.capacity,
    this.scanOpensAt,
    this.scanClosesAt,
    this.tickets = const TicketCounts(),
    this.scans = const ScanCounts(),
    this.categories = const [],
    this.checkpoints = const [],
    this.controllers = const [],
    this.stepMinutes,
    this.timeline = const [],
  });

  /// Lit la réponse de `event_dashboard`. Lève [DashboardFailure.unknown]
  /// pour une version inconnue ou une réponse incomplète.
  factory fromJson(Object? json) {
    if (json is! Map || json['version'] != supportedVersion) {
      throw DashboardFailure.unknown;
    }
    final map = Map<String, Object?>.from(json);
    final serverTime = _date(map['server_time']);
    final eventId = map['event_id'];
    if (serverTime == null || eventId is! String) {
      throw DashboardFailure.unknown;
    }
    final timeline = _map(map['timeline']);
    return EventDashboard(
      eventId: eventId,
      serverTime: serverTime,
      capacity: (map['capacity'] as num?)?.toInt(),
      scanOpensAt: _date(map['scan_opens_at']),
      scanClosesAt: _date(map['scan_closes_at']),
      tickets: TicketCounts.fromJson(_map(map['tickets'])),
      scans: ScanCounts.fromJson(_map(map['scans'])),
      categories: _list(map['categories'], CategoryStats.fromJson),
      checkpoints: _list(map['checkpoints'], CheckpointStats.fromJson),
      controllers: _list(map['controllers'], ControllerStats.fromJson),
      stepMinutes: (timeline['step_minutes'] as num?)?.toInt(),
      timeline: _list(timeline['buckets'], TimelineBucket.fromJson),
    );
  }

  /// Version du contrat comprise par cette application.
  static const int supportedVersion = 1;

  final String eventId;

  /// Heure du serveur au moment du calcul (UTC).
  final DateTime serverTime;

  /// Capacité de l'événement ; `null` : non limitée.
  final int? capacity;

  /// Fenêtre de contrôle (UTC).
  final DateTime? scanOpensAt;
  final DateTime? scanClosesAt;

  final TicketCounts tickets;
  final ScanCounts scans;
  final List<CategoryStats> categories;
  final List<CheckpointStats> checkpoints;
  final List<ControllerStats> controllers;

  /// Durée d'une tranche de [timeline], en minutes ; `null` sans scan.
  final int? stepMinutes;
  final List<TimelineBucket> timeline;

  /// Vrai si le contrôle est ouvert à l'heure du serveur.
  bool get scanWindowOpen =>
      scanOpensAt != null &&
      scanClosesAt != null &&
      !serverTime.isBefore(scanOpensAt!) &&
      !serverTime.isAfter(scanClosesAt!);
}

/// Échecs du tableau de bord.
enum DashboardFailure implements Exception {
  /// Événement inconnu ou droits insuffisants.
  notFound,

  /// Serveur injoignable.
  network,

  /// Toute autre erreur (réponse inattendue comprise).
  unknown,
}

/// Accès au tableau de bord d'un événement.
abstract interface class DashboardRepository {
  /// Lève une [DashboardFailure] en cas d'échec.
  Future<EventDashboard> load(String eventId);
}

int _int(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : fallback;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

Map<String, Object?> _map(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const {};

List<T> _list<T>(Object? value, T Function(Map<String, Object?>) read) => [
  if (value is List)
    for (final item in value)
      if (item is Map) read(Map<String, Object?>.from(item)),
];
