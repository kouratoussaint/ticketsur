import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';

/// Événements relus sur l'appareil, avec l'heure où ils ont été reçus.
typedef CachedEvents = ({List<PublicEventSummary> events, DateTime savedAt});

/// Derniers résultats de l'Explorer et « À la une », gardés sur l'appareil
/// pour rester affichés sans réseau (lot 4-10). Données publiques
/// seulement ; les événements terminés sont écartés à la relecture.
class CatalogCache {
  const new(this._preferences);

  final SharedPreferences _preferences;

  /// Premières pages des dernières recherches (les plus récentes d'abord).
  static const resultsKey = 'catalog.results';

  /// Dernière liste « À la une ».
  static const featuredKey = 'catalog.featured';

  /// Nombre de recherches gardées.
  static const maxQueries = 4;

  /// Identifie une recherche (la casse et les espaces ne comptent pas).
  static String keyOf(CatalogQuery query) => jsonEncode({
    'search': query.search.trim().toLowerCase(),
    'kinds': [for (final kind in query.kinds) kind.wireName]..sort(),
    'city': query.city,
    'period': query.period.name,
    'free': query.freeOnly,
  });

  /// Garde la première page de [query], reçue à [at].
  Future<void> saveResults(
    CatalogQuery query,
    List<PublicEventSummary> events,
    DateTime at,
  ) async {
    final key = keyOf(query);
    final kept = [
      for (final entry in _entries())
        if (entry['key'] != key) entry,
    ].take(maxQueries - 1);
    await _preferences.setString(
      resultsKey,
      jsonEncode([_encode(events, at, key: key), ...kept]),
    );
  }

  /// Résultats gardés pour [query], sans les événements terminés à [now] ;
  /// `null` si cette recherche n'a jamais abouti sur l'appareil.
  CachedEvents? results(CatalogQuery query, {required DateTime now}) {
    final key = keyOf(query);
    for (final entry in _entries()) {
      if (entry['key'] == key) return _decode(entry, now);
    }
    return null;
  }

  Future<void> saveFeatured(List<PublicEventSummary> events, DateTime at) =>
      _preferences.setString(featuredKey, jsonEncode(_encode(events, at)));

  /// « À la une » gardé, sans les événements terminés à [now].
  CachedEvents? featured({required DateTime now}) {
    final raw = _preferences.getString(featuredKey);
    if (raw == null) return null;
    try {
      return _decode(Map<String, Object?>.from(jsonDecode(raw) as Map), now);
    } on Object {
      return null;
    }
  }

  List<Map<String, Object?>> _entries() {
    final raw = _preferences.getString(resultsKey);
    if (raw == null) return const [];
    try {
      return [
        for (final entry in jsonDecode(raw) as List<Object?>)
          Map<String, Object?>.from(entry! as Map),
      ];
    } on Object {
      return const [];
    }
  }

  static Map<String, Object?> _encode(
    List<PublicEventSummary> events,
    DateTime at, {
    String? key,
  }) => {
    'key': ?key,
    'saved_at': at.toUtc().toIso8601String(),
    'events': [for (final event in events) event.toJson()],
  };

  static CachedEvents? _decode(Map<String, Object?> entry, DateTime now) {
    try {
      return (
        savedAt: DateTime.parse(entry['saved_at']! as String).toUtc(),
        events: [
          for (final row in entry['events']! as List<Object?>)
            PublicEventSummary.fromJson(Map<String, Object?>.from(row! as Map)),
        ].where((event) => event.endsAt.isAfter(now)).toList(),
      );
    } on Object {
      return null;
    }
  }
}
