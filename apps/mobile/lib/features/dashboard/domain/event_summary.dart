import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart'
    show DashboardFailure;

/// Entrées acceptées pendant une heure, à l'heure de l'événement.
@immutable
final class HourStat {
  const new({required this.at, required this.entries});

  /// Début de l'heure, en heure locale de l'événement (sans fuseau).
  final DateTime at;
  final int entries;
}

/// Personnes entrées et entrées d'un jour (heure de l'événement).
@immutable
final class DayStat {
  const new({required this.date, required this.people, required this.entries});

  final DateTime date;
  final int people;
  final int entries;
}

/// Un événement de la structure dans la comparaison du bilan.
@immutable
final class ComparedEvent {
  const new({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.issued,
    required this.admitted,
    this.current = false,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final int issued;
  final int admitted;

  /// L'événement du bilan.
  final bool current;

  /// Taux de présence (0 à 1).
  double get attendance => issued == 0 ? 0 : (admitted / issued).clamp(0, 1);
}

/// Bilan d'après-événement (`event_summary`, version 1).
@immutable
final class EventSummary {
  const new({
    required this.eventId,
    this.hours = const [],
    this.peak,
    this.days = const [],
    this.passTickets = 0,
    this.passEntries = 0,
    this.firstEntryAt,
    this.lastEntryAt,
    this.comparison = const [],
  });

  /// Lit la réponse de `event_summary`. Lève [DashboardFailure.unknown]
  /// pour une version inconnue.
  factory fromJson(Object? json) {
    if (json is! Map || json['version'] != supportedVersion) {
      throw DashboardFailure.unknown;
    }
    final map = Map<String, Object?>.from(json);
    final eventId = map['event_id'];
    if (eventId is! String) throw DashboardFailure.unknown;
    final passes = _map(map['passes']);
    return EventSummary(
      eventId: eventId,
      hours: _list(map['hours'], _hour).nonNulls.toList(),
      peak: map['peak'] is Map ? _hour(_map(map['peak'])) : null,
      days: _list(map['days'], (row) {
        final date = _local(row['date']);
        return date == null
            ? null
            : DayStat(
                date: date,
                people: _int(row['people']),
                entries: _int(row['entries']),
              );
      }).nonNulls.toList(),
      passTickets: _int(passes['tickets']),
      passEntries: _int(passes['entries']),
      firstEntryAt: _instant(map['first_entry_at']),
      lastEntryAt: _instant(map['last_entry_at']),
      comparison: _list(map['comparison'], (row) {
        final id = row['id'];
        final starts = _instant(row['starts_at']);
        if (id is! String || starts == null) return null;
        return ComparedEvent(
          id: id,
          title: (row['title'] as String?) ?? '',
          startsAt: starts,
          issued: _int(row['issued']),
          admitted: _int(row['admitted']),
          current: row['current'] == true,
        );
      }).nonNulls.toList(),
    );
  }

  /// Version du contrat comprise par cette application.
  static const int supportedVersion = 1;

  final String eventId;
  final List<HourStat> hours;

  /// Heure la plus chargée ; `null` sans entrée.
  final HourStat? peak;
  final List<DayStat> days;

  /// Tickets de pass (catégories à plusieurs entrées) et leurs entrées.
  final int passTickets;
  final int passEntries;

  /// Première et dernière entrée acceptées (UTC).
  final DateTime? firstEntryAt;
  final DateTime? lastEntryAt;

  /// Cet événement et les derniers de la structure, du plus récent au plus
  /// ancien.
  final List<ComparedEvent> comparison;

  /// Aucune entrée enregistrée.
  bool get isEmpty => hours.isEmpty;

  /// Moyenne de présence des autres événements comparés ; `null` sans eux.
  double? get averageOthers {
    final others = [
      for (final e in comparison)
        if (!e.current && e.issued > 0) e,
    ];
    if (others.isEmpty) return null;
    return others.fold<double>(0, (sum, e) => sum + e.attendance) /
        others.length;
  }

  static HourStat? _hour(Map<String, Object?> row) {
    final at = _local(row['at']);
    return at == null ? null : HourStat(at: at, entries: _int(row['entries']));
  }
}

/// Accès au bilan d'un événement.
abstract interface class SummaryRepository {
  /// Lève une [DashboardFailure] en cas d'échec.
  /// [closed] : structure fermée, en consultation seule
  /// (`closed_event_summary`).
  Future<EventSummary> summary(String eventId, {bool closed = false});
}

int _int(Object? value) => value is num ? value.toInt() : 0;

/// Heure murale de l'événement (« 2026-11-20T21:00 »), sans conversion.
DateTime? _local(Object? value) {
  if (value is! String) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day, parsed.hour);
}

DateTime? _instant(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

Map<String, Object?> _map(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const {};

List<T?> _list<T>(Object? value, T? Function(Map<String, Object?>) read) => [
  if (value is List)
    for (final item in value)
      if (item is Map) read(Map<String, Object?>.from(item)),
];
