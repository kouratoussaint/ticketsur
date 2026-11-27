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
    this.invitations = 0,
    this.invitationsAdmitted = 0,
  });

  factory fromJson(Map<String, Object?> json) => TicketCounts(
    issued: _int(json['issued']),
    admitted: _int(json['admitted']),
    remaining: _int(json['remaining']),
    revoked: _int(json['revoked']),
    expired: _int(json['expired']),
    invitations: _int(json['invitations']),
    invitationsAdmitted: _int(json['invitations_admitted']),
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

  /// Parmi [issued], invitations (catégories d'invitations).
  final int invitations;

  /// Parmi [admitted], invités entrés.
  final int invitationsAdmitted;

  /// Part des tickets émis déjà entrés (0 à 1).
  double get attendance => issued == 0 ? 0 : admitted / issued;

  @override
  bool operator ==(Object other) =>
      other is TicketCounts &&
      other.issued == issued &&
      other.admitted == admitted &&
      other.remaining == remaining &&
      other.revoked == revoked &&
      other.expired == expired &&
      other.invitations == invitations &&
      other.invitationsAdmitted == invitationsAdmitted;

  @override
  int get hashCode => Object.hash(
    issued,
    admitted,
    remaining,
    revoked,
    expired,
    invitations,
    invitationsAdmitted,
  );
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
    this.isInvitation = false,
    this.issued = 0,
    this.admitted = 0,
  });

  factory fromJson(Map<String, Object?> json) => CategoryStats(
    id: json['id']! as String,
    name: json['name']! as String,
    capacity: (json['capacity'] as num?)?.toInt(),
    isInvitation: json['is_invitation'] == true,
    issued: _int(json['issued']),
    admitted: _int(json['admitted']),
  );

  final String id;
  final String name;
  final int? capacity;

  /// Catégorie d'invitations.
  final bool isInvitation;
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
/// Montants d'une catégorie (prix indicatif ; `null` : pas de prix).
@immutable
final class CategoryMoney {
  const new({
    required this.id,
    required this.name,
    this.price,
    this.isInvitation = false,
    this.admitted = 0,
    this.refused = 0,
    this.revenue,
    this.avoided,
  });

  factory fromJson(Map<String, Object?> json) => CategoryMoney(
    id: json['id']! as String,
    name: json['name']! as String,
    price: (json['price'] as num?)?.toInt(),
    isInvitation: json['invitation'] == true,
    admitted: _int(json['admitted']),
    refused: _int(json['refused']),
    revenue: (json['revenue'] as num?)?.toInt(),
    avoided: (json['avoided'] as num?)?.toInt(),
  );

  final String id;
  final String name;
  final int? price;
  final bool isInvitation;

  /// Tickets entrés, et tickets refusés à la porte (comptés une fois).
  final int admitted;
  final int refused;
  final int? revenue;
  final int? avoided;
}

/// Recettes probables et pertes probables évitées (ADR 0056), en FCFA, sur
/// les prix indicatifs des catégories ; les invitations ne comptent pas.
@immutable
final class DashboardMoney {
  const new({
    this.revenue = 0,
    this.revenueTickets = 0,
    this.revenueUnpriced = 0,
    this.avoided = 0,
    this.avoidedTickets = 0,
    this.avoidedUnpriced = 0,
    this.unknownRefusals = 0,
    this.doubleScans = 0,
    this.doubleScanSeconds = 15,
    this.categories = const [],
  });

  factory fromJson(Map<String, Object?> json) => DashboardMoney(
    revenue: _int(json['revenue']),
    revenueTickets: _int(json['revenue_tickets']),
    revenueUnpriced: _int(json['revenue_unpriced']),
    avoided: _int(json['avoided']),
    avoidedTickets: _int(json['avoided_tickets']),
    avoidedUnpriced: _int(json['avoided_unpriced']),
    unknownRefusals: _int(json['unknown_refusals']),
    doubleScans: _int(json['double_scans']),
    doubleScanSeconds: switch (json['double_scan_seconds']) {
      final num seconds => seconds.toInt(),
      _ => 60,
    },
    categories: _list(json['categories'], CategoryMoney.fromJson),
  );

  /// Tickets entrés × prix indicatif.
  final int revenue;
  final int revenueTickets;

  /// Tickets entrés d'une catégorie sans prix indicatif (non chiffrés).
  final int revenueUnpriced;

  /// Tickets refusés à la porte (déjà utilisés, annulés, expirés) × prix.
  final int avoided;
  final int avoidedTickets;
  final int avoidedUnpriced;

  /// QR inconnus ou d'un autre événement (non chiffrés).
  final int unknownRefusals;

  /// Refus « déjà utilisé » arrivés moins de [doubleScanSeconds] secondes
  /// après l'entrée du même ticket : doubles scans, non comptés (ADR 0057).
  final int doubleScans;
  final int doubleScanSeconds;
  final List<CategoryMoney> categories;

  /// Aucune catégorie payante n'a de prix indicatif.
  bool get unpriced =>
      categories.every((c) => c.isInvitation || c.price == null);
}

final class EventDashboard {
  const new({
    required this.eventId,
    required this.serverTime,
    this.capacity,
    this.scanOpensAt,
    this.scanClosesAt,
    this.controlOpen = false,
    this.tickets = const TicketCounts(),
    this.scans = const ScanCounts(),
    this.categories = const [],
    this.checkpoints = const [],
    this.controllers = const [],
    this.stepMinutes,
    this.timeline = const [],
    this.money,
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
      controlOpen: map['control_open'] == true,
      tickets: TicketCounts.fromJson(_map(map['tickets'])),
      scans: ScanCounts.fromJson(_map(map['scans'])),
      categories: _list(map['categories'], CategoryStats.fromJson),
      checkpoints: _list(map['checkpoints'], CheckpointStats.fromJson),
      controllers: _list(map['controllers'], ControllerStats.fromJson),
      stepMinutes: (timeline['step_minutes'] as num?)?.toInt(),
      timeline: _list(timeline['buckets'], TimelineBucket.fromJson),
      money: switch (map['money']) {
        final Map<Object?, Object?> money => DashboardMoney.fromJson(
          Map<String, Object?>.from(money),
        ),
        _ => null,
      },
    );
  }

  /// Version du contrat comprise par cette application.
  static const int supportedVersion = 1;

  final String eventId;

  /// Heure du serveur au moment du calcul (UTC).
  final DateTime serverTime;

  /// Capacité de l'événement ; `null` : non limitée.
  final int? capacity;

  /// Démarrage et arrêt du contrôle par l'organisateur (UTC) ; `null` tant
  /// qu'ils n'ont pas eu lieu.
  final DateTime? scanOpensAt;
  final DateTime? scanClosesAt;

  /// Contrôle en cours (démarré et pas encore arrêté).
  final bool controlOpen;

  final TicketCounts tickets;
  final ScanCounts scans;
  final List<CategoryStats> categories;
  final List<CheckpointStats> checkpoints;
  final List<ControllerStats> controllers;

  /// Durée d'une tranche de [timeline], en minutes ; `null` sans scan.
  final int? stepMinutes;
  final List<TimelineBucket> timeline;

  /// Recettes et pertes évitées ; `null` : serveur plus ancien.
  final DashboardMoney? money;

  /// Vrai si le contrôle est en cours.
  bool get scanWindowOpen => controlOpen;
}

/// Échecs du tableau de bord.
enum DashboardFailure implements Exception {
  /// Événement inconnu ou droits insuffisants.
  notFound,

  /// Serveur injoignable.
  network,

  /// Tableau de bord en direct non compris dans le pack (ADR 0027).
  notInPack,

  /// Toute autre erreur (réponse inattendue comprise).
  unknown,
}

/// Accès au tableau de bord d'un événement.
abstract interface class DashboardRepository {
  /// Lève une [DashboardFailure] en cas d'échec.
  /// [closed] : structure fermée, en consultation seule
  /// (`closed_event_dashboard`).
  Future<EventDashboard> load(String eventId, {bool closed = false});
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
