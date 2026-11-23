import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/events/domain/cities.dart';
import 'package:ticketsur/features/favorites/application/favorites_providers.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

/// Sujets Firebase des événements (ADR 0054) : nouveaux événements de la
/// ville choisie dans l'Explorer (ou de toutes les villes) et changements
/// importants des événements en favori. Gérés sur l'appareil, avec ou sans
/// compte.

/// Préférence « Nouveaux événements » (Paramètres › Notifications).
const String newEventsPreference = 'notifications.new_events';

/// Sujets d'événements auxquels l'appareil est abonné.
const String eventTopicsPreference = 'notifications.event_topics';

/// Sujet « toutes les villes ».
const String allCitiesTopic = 'tikeo_city_all';

/// Nombre maximal d'événements en favori suivis.
const int favoriteTopicsLimit = 100;

/// Sujet d'une ville : même calcul que `private.city_topic` sur le serveur.
String cityTopic(String city) {
  final slug = foldAccents(city.trim())
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'tikeo_city_$slug';
}

/// Sujet d'un événement en favori.
String eventTopic(String eventId) => 'tikeo_event_$eventId';

/// Sujets voulus pour l'appareil.
Set<String> eventTopicsFor({
  required bool newEvents,
  required String? city,
  required List<PublicEventSummary> favorites,
  required DateTime now,
}) => {
  if (newEvents && (city == null || city.trim().isEmpty)) allCitiesTopic,
  if (newEvents && city != null && city.trim().isNotEmpty) cityTopic(city),
  for (final event
      in favorites
          .where((e) => e.endsAt.isAfter(now))
          .take(favoriteTopicsLimit))
    eventTopic(event.id),
};

/// « Nouveaux événements » : activé par défaut, réglable sur l'appareil.
class NewEventsSetting extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(newEventsPreference) ?? true;

  Future<void> set({required bool enabled}) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(newEventsPreference, enabled);
  }
}

final NotifierProvider<NewEventsSetting, bool> newEventsProvider =
    NotifierProvider<NewEventsSetting, bool>(NewEventsSetting.new);

/// Tient les abonnements de l'appareil à jour (regardé par l'app) :
/// notifications actives, réglage, ville de l'Explorer, favoris.
final FutureProvider<Set<String>> eventTopicsProvider =
    FutureProvider<Set<String>>((ref) async {
      final status = ref.watch(pushSyncProvider).value;
      final wanted = status == PushStatus.active
          ? eventTopicsFor(
              newEvents: ref.watch(newEventsProvider),
              city: ref.watch(catalogQueryProvider.select((q) => q.city)),
              favorites: ref.watch(favoritesProvider),
              now: DateTime.now(),
            )
          : <String>{};
      final service = ref.read(pushServiceProvider);
      final preferences = ref.read(sharedPreferencesProvider);
      final previous = {...?preferences.getStringList(eventTopicsPreference)};
      for (final topic in wanted.difference(previous)) {
        await service.subscribe(topic);
      }
      for (final topic in previous.difference(wanted)) {
        await service.unsubscribe(topic);
      }
      await preferences.setStringList(eventTopicsPreference, [...wanted]);
      return wanted;
    });
