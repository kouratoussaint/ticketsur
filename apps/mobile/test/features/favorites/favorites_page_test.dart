import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/favorites/application/favorites_providers.dart';
import 'package:ticketsur/features/favorites/presentation/favorites_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_organization_repository.dart';

// Horloge des tests : 1er juin 2030.
final _now = DateTime.utc(2030, 6);

final PublicEventSummary _gala = publicEvent(
  id: 'f1',
  title: 'Gala de Bobo',
  city: 'Bobo-Dioulasso',
  startsAt: DateTime.utc(2030, 6, 10, 20),
);
final PublicEventSummary _forum = publicEvent(
  id: 'f2',
  title: 'Forum numérique',
  kind: EventKind.conference,
  startsAt: DateTime.utc(2030, 7, 1, 9),
);
final PublicEventSummary _match = publicEvent(
  id: 'f3',
  title: 'Match de gala',
  kind: EventKind.sport,
  startsAt: DateTime.utc(2030, 5, 1, 16),
);

Map<String, Object?> _json(PublicEventSummary e) => {
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

void main() {
  group('filtres (#15)', () {
    final all = [_match, _gala, _forum];

    List<String> ids(FavoritesFilter filter, FavoritesPeriod period) => [
      for (final e in filterFavorites(
        all,
        filter: filter,
        period: period,
        now: _now,
      ))
        e.id,
    ];

    test('période, type, ville, recherche sans accents', () {
      const none = FavoritesFilter();
      expect(ids(none, FavoritesPeriod.upcoming), ['f1', 'f2']);
      expect(ids(none, FavoritesPeriod.past), ['f3']);
      expect(ids(none, FavoritesPeriod.all), hasLength(3));
      expect(
        ids(const FavoritesFilter(kind: EventKind.sport), FavoritesPeriod.all),
        ['f3'],
      );
      expect(
        ids(const FavoritesFilter(city: 'Bobo-Dioulasso'), FavoritesPeriod.all),
        ['f1'],
      );
      expect(
        ids(const FavoritesFilter(text: 'NUMERIQUE'), FavoritesPeriod.all),
        ['f2'],
      );
      expect(
        ids(const FavoritesFilter(text: 'gala'), FavoritesPeriod.all),
        unorderedEquals(['f1', 'f3']),
      );
    });

    test('tri : plus proches de maintenant, ou plus récents', () {
      // Le 1er juin : gala (10 juin), match (1er mai), forum (1er juillet).
      expect(ids(const FavoritesFilter(), FavoritesPeriod.all), [
        'f1',
        'f3',
        'f2',
      ]);
      expect(
        ids(
          const FavoritesFilter(sort: FavoritesSort.recent),
          FavoritesPeriod.all,
        ),
        ['f2', 'f1', 'f3'],
      );
    });
  });

  group('écran Mes favoris (#15)', () {
    Future<void> pumpFavorites(
      WidgetTester tester,
      List<PublicEventSummary> favorites,
    ) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(),
            organizations: FakeOrganizationRepository(),
            catalog: FakeCatalogRepository([_gala, _forum, _match]),
            preferences: {
              favoritesPreferenceKey: jsonEncode([
                for (final e in favorites) _json(e),
              ]),
            },
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Favoris'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesPage), findsOneWidget);
    }

    Future<void> tapChip(WidgetTester tester, String key) async {
      final chip = find.byKey(Key(key));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    testWidgets('puces avec compteurs, type, recherche, tri et ville', (
      tester,
    ) async {
      await pumpFavorites(tester, [_gala, _forum, _match]);
      expect(find.text('3 événements gardés sur ce téléphone'), findsOneWidget);
      expect(find.text('À venir (2)'), findsOneWidget);
      expect(find.text('Passés (1)'), findsOneWidget);
      expect(find.text('Tous (3)'), findsOneWidget);
      // À venir par défaut.
      expect(find.text('Gala de Bobo'), findsOneWidget);
      expect(find.text('Forum numérique'), findsOneWidget);
      expect(find.text('Match de gala'), findsNothing);

      await tapChip(tester, 'favorites-past');
      expect(find.text('Match de gala'), findsOneWidget);
      expect(find.text('Gala de Bobo'), findsNothing);

      await tapChip(tester, 'favorites-all');
      await tapChip(tester, 'favorites-kind-conference');
      expect(find.text('Forum numérique'), findsOneWidget);
      expect(find.text('Gala de Bobo'), findsNothing);
      await tapChip(tester, 'favorites-kind-all');

      await tester.enterText(find.byKey(const Key('favorites-search')), 'bobo');
      await tester.pumpAndSettle();
      expect(find.text('Gala de Bobo'), findsOneWidget);
      expect(find.text('Forum numérique'), findsNothing);
      await tester.enterText(find.byKey(const Key('favorites-search')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favorites-no-match')), findsOneWidget);
      await tester.tap(find.byKey(const Key('favorites-reset')));
      await tester.pumpAndSettle();
      expect(find.text('Forum numérique'), findsOneWidget);

      // Tri et ville dans la feuille des filtres.
      await tester.tap(find.byKey(const Key('favorites-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('favorites-city-Ouagadougou')));
      await tester.tap(find.byKey(const Key('favorites-sort-recent')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('favorites-filters-apply')));
      await tester.pumpAndSettle();
      expect(find.text('Gala de Bobo'), findsNothing);
      final forum = tester.getTopLeft(find.text('Forum numérique'));
      final match = tester.getTopLeft(find.text('Match de gala'));
      // Plus récent d'abord.
      expect(forum.dy, lessThan(match.dy));
    });

    testWidgets('cœur rouge : retirer, puis « Annuler »', (tester) async {
      await pumpFavorites(tester, [_gala, _forum]);
      final heart = find.byKey(const Key('favorite-f1'));
      final icon = tester.widget<IconButton>(heart).selectedIcon! as Icon;
      expect(icon.icon, Icons.favorite_rounded);
      expect(icon.color, isNot(const Color(0xFFFF6B3D)));
      await tester.tap(heart);
      await tester.pumpAndSettle();
      expect(find.text('Gala de Bobo'), findsNothing);
      expect(find.text('Retiré de vos favoris'), findsOneWidget);
      await tester.tap(find.byKey(const Key('favorite-undo')));
      await tester.pumpAndSettle();
      expect(find.text('Gala de Bobo'), findsOneWidget);
    });

    testWidgets('état vide illustré, lien vers Explorer', (tester) async {
      await pumpFavorites(tester, const []);
      expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
      await tester.tap(find.byKey(const Key('favorites-explore')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-list')), findsOneWidget);
    });
  });
}
