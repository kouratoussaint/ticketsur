import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

/// Clé des favoris dans les préférences de l'appareil.
const favoritesPreferenceKey = 'favorites.events';

/// Nombre maximal de favoris gardés.
const favoritesLimit = 200;

/// Événements favoris, gardés sur l'appareil (avec ou sans compte), du plus
/// proche au plus lointain. On garde un résumé pour les afficher sans réseau ;
/// la fiche, elle, est toujours relue.
class FavoritesController extends Notifier<List<PublicEventSummary>> {
  @override
  List<PublicEventSummary> build() {
    final raw = ref
        .read(sharedPreferencesProvider)
        .getString(favoritesPreferenceKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<Object?>;
      return _sorted([
        for (final item in list)
          if (item is Map) _fromJson(Map<String, Object?>.from(item)),
      ]);
    } on Object {
      // Préférence illisible : on repart de zéro plutôt que de planter.
      return const [];
    }
  }

  /// Vrai si l'événement [id] est en favori.
  bool contains(String id) => state.any((e) => e.id == id);

  /// Ajoute ou retire [event] ; renvoie vrai s'il est désormais favori.
  Future<bool> toggle(PublicEventSummary event) async {
    final added = !contains(event.id);
    final next = added
        ? [...state, event].take(favoritesLimit).toList()
        : [
            for (final e in state)
              if (e.id != event.id) e,
          ];
    state = _sorted(next);
    await _save();
    return added;
  }

  /// Retire les favoris [ids] ; renvoie les événements retirés (pour
  /// « Annuler »).
  Future<List<PublicEventSummary>> removeMany(Set<String> ids) async {
    final removed = [
      for (final e in state)
        if (ids.contains(e.id)) e,
    ];
    if (removed.isEmpty) return removed;
    state = [
      for (final e in state)
        if (!ids.contains(e.id)) e,
    ];
    await _save();
    return removed;
  }

  /// Remet des favoris retirés (« Annuler »), sans doublon.
  Future<void> restore(List<PublicEventSummary> events) async {
    final missing = [
      for (final e in events)
        if (!contains(e.id)) e,
    ];
    if (missing.isEmpty) return;
    state = _sorted([...state, ...missing].take(favoritesLimit).toList());
    await _save();
  }

  Future<void> _save() => ref
      .read(sharedPreferencesProvider)
      .setString(
        favoritesPreferenceKey,
        jsonEncode([for (final e in state) _toJson(e)]),
      );

  static List<PublicEventSummary> _sorted(List<PublicEventSummary> events) =>
      [...events]..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  static Map<String, Object?> _toJson(PublicEventSummary e) => {
    'id': e.id,
    'title': e.title,
    'kind': e.kind.wireName,
    'starts_at': e.startsAt.toIso8601String(),
    'ends_at': e.endsAt.toIso8601String(),
    'timezone': e.timezone,
    'venue': e.venue,
    'city': e.city,
    'cover_url': e.coverUrl,
    'organization_name': e.organizationName,
    'min_price': e.minPrice,
  };

  static PublicEventSummary _fromJson(Map<String, Object?> json) =>
      PublicEventSummary(
        id: json['id']! as String,
        title: json['title']! as String,
        kind: EventKind.fromWire(json['kind']),
        startsAt: DateTime.parse(json['starts_at']! as String).toUtc(),
        endsAt: DateTime.parse(json['ends_at']! as String).toUtc(),
        timezone: (json['timezone'] as String?) ?? 'Africa/Ouagadougou',
        venue: json['venue'] as String?,
        city: json['city'] as String?,
        coverUrl: json['cover_url'] as String?,
        organizationName: json['organization_name']! as String,
        minPrice: (json['min_price'] as num?)?.toInt(),
      );
}

final NotifierProvider<FavoritesController, List<PublicEventSummary>>
favoritesProvider =
    NotifierProvider<FavoritesController, List<PublicEventSummary>>(
      FavoritesController.new,
    );
