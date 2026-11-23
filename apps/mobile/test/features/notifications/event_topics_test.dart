import 'package:flutter_test/flutter_test.dart';
import 'package:ticketsur/features/notifications/application/event_topics.dart';

import '../../helpers/fake_catalog_repository.dart';

void main() {
  test(
    'sujets des villes : mêmes que `private.city_topic` (99_event_broadcasts)',
    () {
      expect(cityTopic('Bobo-Dioulasso'), 'tikeo_city_bobo_dioulasso');
      expect(cityTopic("Fada N'Gourma"), 'tikeo_city_fada_n_gourma');
      expect(cityTopic('Fada N’Gourma'), 'tikeo_city_fada_n_gourma');
      expect(cityTopic('Pô'), 'tikeo_city_po');
      expect(cityTopic(' Dédougou '), 'tikeo_city_dedougou');
    },
  );

  test('sujets voulus : ville ou toutes, favoris à venir seulement', () {
    final now = DateTime.utc(2030, 6, 2);
    final favorites = [
      publicEvent(id: 'a'),
      publicEvent(id: 'b', startsAt: DateTime.utc(2030, 3, 5)),
    ];
    expect(
      eventTopicsFor(
        newEvents: true,
        city: null,
        favorites: favorites,
        now: now,
      ),
      {'tikeo_city_all', 'tikeo_event_a'},
    );
    expect(
      eventTopicsFor(
        newEvents: true,
        city: 'Koudougou',
        favorites: const [],
        now: now,
      ),
      {'tikeo_city_koudougou'},
    );
    expect(
      eventTopicsFor(
        newEvents: false,
        city: 'Koudougou',
        favorites: favorites,
        now: now,
      ),
      {'tikeo_event_a'},
    );
  });
}
