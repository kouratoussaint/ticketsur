import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/application/catalog_cache.dart';
import 'package:ticketsur/features/catalog/domain/burkina_cities.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/catalog/presentation/public_event_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';
import 'package:ticketsur/l10n/l10n.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_event_setup_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/navigation.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('domaine', () {
    test('itinéraire : par la position si elle est connue', () {
      final uri = directionsUri(
        PublicEventDetail(
          summary: publicEvent(),
          categories: const [],
          latitude: 12.3714,
          longitude: -1.5197,
        ),
      );
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['destination'], '12.3714,-1.5197');
      final detail = PublicEventDetail.fromJson({
        ...publicEvent().toJson(),
        'latitude': 12.3714,
        'longitude': -1.5197,
        'organization': const {'name': 'Faso Live'},
        'categories': const <Object?>[],
      });
      expect((detail.latitude, detail.longitude), (12.3714, -1.5197));
    });

    test('page publique d’une structure lue', () {
      final page = PublicOrganization.fromJson({
        'id': 'o1',
        'name': 'Faso Live',
        'city': 'Kaya',
        'logo_path': 'o1/logo.png',
        'public_phone': '+22670000000',
        'created_at': '2026-03-01T00:00:00Z',
        'past_events': 4,
        'events': [publicEvent(id: 'x1').toJson()],
      }, logoUrlOf: (path) => 'https://logos/$path');
      expect(page.logoUrl, 'https://logos/o1/logo.png');
      expect((page.pastEvents, page.events.single.id), (4, 'x1'));
      final detail = PublicEventDetail.fromJson({
        ...publicEvent().toJson(),
        'organization': const {'id': 'o1', 'name': 'Faso Live'},
        'categories': const <Object?>[],
      });
      expect(detail.organizationId, 'o1');
    });

    test('événement gardé sur l’appareil puis relu à l’identique', () {
      final event = publicEvent(
        minPrice: 1500,
        coverUrl: 'https://exemple.test/affiche.jpg',
      );
      final back = PublicEventSummary.fromJson(event.toJson());
      expect(back.toJson(), event.toJson());
      expect(back.coverUrl, 'https://exemple.test/affiche.jpg');
      final bare = PublicEventSummary.fromJson(
        publicEvent(venue: null, city: null).toJson(),
      );
      expect((bare.venue, bare.city, bare.minPrice), (null, null, null));
    });

    test(
      'cache : 4 recherches au plus, casse ignorée, terminés écartés',
      () async {
        SharedPreferences.setMockInitialValues({});
        final cache = CatalogCache(await SharedPreferences.getInstance());
        final saved = DateTime.utc(2030, 6, 1, 12);
        final soon = publicEvent(
          id: 'soon',
          startsAt: DateTime.utc(2030, 6, 1, 8),
        ); // terminé à 12:00
        final later = publicEvent(id: 'later');
        await cache.saveResults(const CatalogQuery(search: ' Jazz '), [
          soon,
          later,
        ], saved);
        final hit = cache.results(
          const CatalogQuery(search: 'jazz'),
          now: DateTime.utc(2030, 6, 1, 13),
        )!;
        expect([for (final e in hit.events) e.id], ['later']);
        expect(hit.savedAt, saved);
        expect(
          cache.results(const CatalogQuery(city: 'Kaya'), now: saved),
          isNull,
        );
        for (final city in ['Kaya', 'Koudougou', 'Banfora', 'Ouahigouya']) {
          await cache.saveResults(CatalogQuery(city: city), [later], saved);
        }
        expect(
          cache.results(const CatalogQuery(search: 'jazz'), now: saved),
          isNull,
        );
        expect(
          cache.results(const CatalogQuery(city: 'Kaya'), now: saved),
          isNotNull,
        );
        await cache.saveFeatured([later], saved);
        expect(cache.featured(now: saved)!.events.single.id, 'later');
      },
    );

    test('« il y a » : instant, minutes, heures, jours', () {
      final l10n = AppLocalizationsFr();
      final now = DateTime.utc(2030, 6, 1, 12);
      String ago(Duration d) => timeAgo(l10n, now.subtract(d), now);
      expect(ago(const Duration(seconds: 20)), "à l'instant");
      expect(ago(const Duration(minutes: 5)), 'il y a 5 min');
      expect(ago(const Duration(hours: 2, minutes: 10)), 'il y a 2 h');
      expect(ago(const Duration(days: 1)), 'il y a 1 jour');
      expect(ago(const Duration(days: 3)), 'il y a 3 jours');
    });

    test('périodes : aujourd’hui, week-end, semaine', () {
      // Mercredi 5 juin 2030, 10:00 (heure du Burkina = UTC).
      final wednesday = DateTime.utc(2030, 6, 5, 10);
      expect(CatalogPeriod.any.range(wednesday), (from: null, to: null));
      expect(CatalogPeriod.today.range(wednesday), (
        from: wednesday,
        to: DateTime.utc(2030, 6, 6),
      ));
      expect(CatalogPeriod.weekend.range(wednesday), (
        from: DateTime.utc(2030, 6, 8),
        to: DateTime.utc(2030, 6, 10),
      ));
      final saturday = DateTime.utc(2030, 6, 8, 15);
      expect(CatalogPeriod.weekend.range(saturday), (
        from: saturday,
        to: DateTime.utc(2030, 6, 10),
      ));
      expect(CatalogPeriod.week.range(wednesday).to, DateTime.utc(2030, 6, 13));
    });

    test('critères : filtres comptés, recherche et ville à part', () {
      const empty = CatalogQuery();
      expect((empty.filterCount, empty.narrowed), (0, false));
      expect(const CatalogQuery(city: 'Kaya').narrowed, isFalse);
      const full = CatalogQuery(
        kinds: {EventKind.sport, EventKind.gala},
        period: CatalogPeriod.today,
        freeOnly: true,
      );
      expect((full.filterCount, full.narrowed), (4, true));
      expect(const CatalogQuery(search: 'jazz').narrowed, isTrue);
    });

    test('villes : les 49 communes urbaines, sans doublon', () {
      expect(burkinaCities, hasLength(49));
      expect(burkinaCities.toSet(), hasLength(49));
      expect(burkinaCities.take(2), ['Ouagadougou', 'Bobo-Dioulasso']);
    });

    test('lien WhatsApp : chiffres seuls, message encodé', () {
      final uri = whatsAppUri('+226 70 11 22 33', 'Bonjour « Gala »');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/22670112233');
      expect(uri.queryParameters['text'], 'Bonjour « Gala »');
    });

    test('fiche publique lue depuis le serveur', () {
      final detail = PublicEventDetail.fromJson(const {
        'id': 'e1',
        'title': 'Gala',
        'kind': 'gala',
        'starts_at': '2030-06-20T20:00:00Z',
        'ends_at': '2030-06-21T01:00:00Z',
        'timezone': 'Africa/Ouagadougou',
        'city': 'Kaya',
        'description': 'Soirée',
        'organization': {'name': 'Faso Live', 'public_phone': '+22670112233'},
        'categories': [
          {'name': 'Standard', 'indicative_price': 2000},
          {'name': 'VIP', 'indicative_price': null},
        ],
      });
      expect(detail.summary.organizationName, 'Faso Live');
      expect(detail.summary.kind, EventKind.gala);
      expect(detail.publicPhone, '+22670112233');
      expect(detail.categories, [
        (name: 'Standard', price: 2000),
        (name: 'VIP', price: null),
      ]);
    });
  });

  group('Explorer sans compte', () {
    late FakeCatalogRepository catalog;
    late List<Uri> opened;
    late List<String> shared;
    final calendared = <CalendarEntry>[];

    final events = [
      publicEvent(id: 'p1', minPrice: 2000),
      publicEvent(
        id: 'p2',
        title: 'Finale inter-quartiers',
        kind: EventKind.sport,
        city: 'Bobo-Dioulasso',
        minPrice: 0,
      ),
      publicEvent(
        id: 'p3',
        title: 'Forum Jeunes & Numérique',
        kind: EventKind.conference,
      ),
    ];

    Future<void> pumpGuest(
      WidgetTester tester, {
      Map<String, Object> preferences = const {},
    }) async {
      opened = [];
      shared = [];
      calendared.clear();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(),
            catalog: catalog,
            calendar: (entry) async {
              calendared.add(entry);
              return true;
            },
            openLink: (uri) async {
              opened.add(uri);
              return true;
            },
            share: (text) async => shared.add(text),
            preferences: preferences,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      catalog =
          FakeCatalogRepository(events, {
              'p1': PublicEventDetail(
                summary: events.first,
                description: 'Trois formations en plein air.',
                publicPhone: '+22670112233',
                organizationId: 'org-1',
                categories: const [
                  (name: 'Standard', price: 2000),
                  (name: 'Étudiants', price: 0),
                  (name: 'VIP', price: null),
                ],
              ),
            })
            // « À la une » : un seul événement choisi (ADR 0028).
            ..featuredEvents = [events.first];
    });

    testWidgets('à l’ouverture : événements, mise en avant, compteur', (
      tester,
    ) async {
      await pumpGuest(tester);
      expect(find.byType(ExplorePage), findsOneWidget);
      expect(find.byKey(const Key('explore-featured')), findsOneWidget);
      // À la une et dans la liste, qui reste complète.
      expect(find.text('Soirée Afro-Jazz'), findsWidgets);
      expect(find.text('Dès 2\u202f000 FCFA'), findsWidgets);
      await tester.scrollUntilVisible(
        find.byKey(const Key('public-event-p2')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('public-event-p2')), findsOneWidget);
      expect(find.text('Entrée gratuite'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Explorer'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('recherche puis catégorie', (tester) async {
      await pumpGuest(tester);
      await tester.enterText(find.byKey(const Key('explore-search')), 'forum');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(catalog.queries.last.search, 'forum');
      expect(find.byKey(const Key('explore-featured')), findsNothing);
      expect(find.byKey(const Key('public-event-p3')), findsOneWidget);
      expect(find.byKey(const Key('public-event-p1')), findsNothing);

      await tester.enterText(find.byKey(const Key('explore-search')), '');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('explore-kind-sport')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('explore-kind-sport')));
      await tester.pumpAndSettle();
      expect(catalog.queries.last.kinds, {EventKind.sport});
      expect(find.byKey(const Key('public-event-p2')), findsOneWidget);
      expect(find.text('Soirée Afro-Jazz'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('explore-kind-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('explore-kind-all')));
      await tester.pumpAndSettle();
      expect(catalog.queries.last.kinds, isEmpty);
    });

    testWidgets('ville choisie dans la liste du Burkina', (tester) async {
      await pumpGuest(tester);
      await tester.tap(find.byKey(const Key('explore-city')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('city-Bobo-Dioulasso')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('city-Bobo-Dioulasso')));
      await tester.pumpAndSettle();
      expect(catalog.queries.last.city, 'Bobo-Dioulasso');
      expect(find.text('Bobo-Dioulasso'), findsWidgets);
      expect(find.byKey(const Key('public-event-p2')), findsNothing);
      // Un seul résultat : c'est lui qui est mis en avant.
      expect(find.byKey(const Key('explore-featured')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Prochainement à Bobo-Dioulasso'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Prochainement à Bobo-Dioulasso'), findsOneWidget);
    });

    testWidgets('filtres : catégories, période, gratuit ; puis effacer', (
      tester,
    ) async {
      await pumpGuest(tester);
      await tester.tap(find.byKey(const Key('explore-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-kind-conference')));
      await tester.tap(find.byKey(const Key('filter-period-weekend')));
      await tester.tap(find.byKey(const Key('filter-free')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('filters-apply')));
      await tester.tap(find.byKey(const Key('filters-apply')));
      await tester.pumpAndSettle();
      final query = catalog.queries.last;
      expect(query.kinds, {EventKind.conference});
      expect(query.period, CatalogPeriod.weekend);
      expect(query.freeOnly, isTrue);
      expect(find.text('3'), findsOneWidget); // badge des filtres

      await tester.tap(find.byKey(const Key('explore-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filters-clear')));
      await tester.ensureVisible(find.byKey(const Key('filters-apply')));
      await tester.tap(find.byKey(const Key('filters-apply')));
      await tester.pumpAndSettle();
      expect(catalog.queries.last, const CatalogQuery());
    });

    testWidgets('aucun résultat : message et « Effacer les filtres »', (
      tester,
    ) async {
      await pumpGuest(tester);
      await tester.enterText(find.byKey(const Key('explore-search')), 'zzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-empty')), findsOneWidget);
      await tester.tap(find.text('Effacer les filtres'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-featured')), findsOneWidget);
    });

    testWidgets('sans réseau : message et « Réessayer »', (tester) async {
      catalog.failure = CatalogFailure.network;
      await pumpGuest(tester);
      expect(find.byKey(const Key('explore-error')), findsOneWidget);
      catalog.failure = null;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-featured')), findsOneWidget);
    });

    /// Explorer déjà ouvert il y a 5 minutes : première page et « À la une »
    /// gardées sur l'appareil.
    Future<Map<String, Object>> visitedBefore() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = CatalogCache(prefs);
      // Horloge du catalogue en test : 1er juin 2030, 00:00.
      final at = DateTime.utc(2030, 5, 31, 23, 55);
      await cache.saveResults(const CatalogQuery(), events, at);
      await cache.saveFeatured([events.first], at);
      return {
        for (final key in [CatalogCache.resultsKey, CatalogCache.featuredKey])
          key: prefs.getString(key)!,
      };
    }

    testWidgets('sans réseau après une visite : derniers résultats et '
        'bandeau, puis mise à jour au retour du réseau', (tester) async {
      final preferences = await visitedBefore();
      catalog.failure = CatalogFailure.network;
      await pumpGuest(tester, preferences: preferences);
      expect(find.byKey(const Key('explore-error')), findsNothing);
      expect(find.byKey(const Key('explore-offline')), findsOneWidget);
      expect(find.text('Hors ligne, mis à jour il y a 5 min'), findsOneWidget);
      expect(find.byKey(const Key('explore-featured')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('public-event-p3')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('3 événements'), findsOneWidget);
      expect(find.byKey(const Key('explore-more')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('explore-offline')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );

      // Toujours sans réseau : nouvel essai, le bandeau reste.
      final asked = catalog.queries.length;
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(catalog.queries.length, asked + 1);
      expect(find.byKey(const Key('explore-offline')), findsOneWidget);

      // Le réseau revient : l'essai suivant (30 s) remplace la liste.
      catalog.failure = null;
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-offline')), findsNothing);
      expect(find.byKey(const Key('public-event-p3')), findsOneWidget);
    });

    testWidgets('sans réseau : retour dans l’app, nouvel essai immédiat', (
      tester,
    ) async {
      final preferences = await visitedBefore();
      catalog.failure = CatalogFailure.network;
      await pumpGuest(tester, preferences: preferences);
      expect(find.byKey(const Key('explore-offline')), findsOneWidget);
      catalog.failure = null;
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-offline')), findsNothing);
    });

    testWidgets('sans réseau, autre recherche jamais faite : message', (
      tester,
    ) async {
      final preferences = await visitedBefore();
      catalog.failure = CatalogFailure.network;
      await pumpGuest(tester, preferences: preferences);
      await tester.enterText(find.byKey(const Key('explore-search')), 'forum');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-error')), findsOneWidget);
      expect(find.byKey(const Key('explore-offline')), findsNothing);
    });

    testWidgets('fiche publique : prix, WhatsApp, partage', (tester) async {
      await pumpGuest(tester);
      await tester.tap(find.byKey(const Key('explore-featured')));
      await tester.pumpAndSettle();
      expect(find.byType(PublicEventPage), findsOneWidget);
      expect(find.byKey(const Key('public-event-title')), findsOneWidget);
      await tester.scrollUntilVisible(find.text('VIP'), 200);
      expect(find.text('2\u202f000 FCFA'), findsOneWidget);
      expect(find.text('Entrée gratuite'), findsOneWidget);
      expect(find.text('Prix auprès du promoteur'), findsOneWidget);

      await tester.tap(find.byKey(const Key('public-event-whatsapp')));
      await tester.pumpAndSettle();
      final uri = opened.single;
      expect(uri.path, '/22670112233');
      expect(uri.queryParameters['text'], contains('« Soirée Afro-Jazz »'));

      // Partager : feuille de l'image ; le texte seul reste possible (#18).
      await tester.tap(find.byKey(const Key('public-event-share')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event-share-sheet')), findsOneWidget);
      final textOnly = find.byKey(const Key('event-share-text'));
      await tester.ensureVisible(textOnly);
      await tester.pumpAndSettle();
      await tester.tap(textOnly);
      await tester.pumpAndSettle();
      expect(shared.single, contains('Soirée Afro-Jazz'));
      expect(shared.single, contains('Obtenez votre ticket sur Tikéo.'));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ExplorePage), findsOneWidget);
    });

    testWidgets('fiche : « À propos » en tuile, structure touchable, page de '
        'la structure', (tester) async {
      catalog.organizations['org-1'] = PublicOrganization(
        id: 'org-1',
        name: 'Faso Live',
        city: 'Ouagadougou',
        publicPhone: '+22670112233',
        createdAt: DateTime.utc(2026, 3, 2),
        pastEvents: 4,
        events: [events[1], events.first],
      );
      await pumpGuest(tester);
      await tester.tap(find.byKey(const Key('explore-featured')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('public-event-about')),
          matching: find.text('Trois formations en plein air.'),
        ),
        findsOneWidget,
      );
      final organizer = find.byKey(const Key('public-event-organizer'));
      await tester.scrollUntilVisible(organizer, 200);
      await tester.pumpAndSettle();
      expect(find.text('Voir la structure et ses événements'), findsOneWidget);
      await tester.tap(organizer);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('public-org-page')), findsOneWidget);
      expect(find.byKey(const Key('public-org-name')), findsOneWidget);
      expect(find.text('Sur Tikéo depuis 2026'), findsOneWidget);
      expect(find.text('Déjà organisés'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.byKey(const Key('public-org-whatsapp')));
      await tester.pumpAndSettle();
      expect(opened.single.path, '/22670112233');
      expect(opened.single.queryParameters['text'], contains('Faso Live'));

      final other = find.byKey(Key('public-event-${events[1].id}'));
      await tester.scrollUntilVisible(other, 200);
      await tester.pumpAndSettle();
      await tester.tap(other);
      await tester.pumpAndSettle();
      expect(find.byType(PublicEventPage), findsOneWidget);
      expect(find.text(events[1].title), findsWidgets);
    });

    testWidgets('fiche : agenda, itinéraire, type et ville vers l’Explorer', (
      tester,
    ) async {
      await pumpGuest(tester);
      await tester.tap(find.byKey(const Key('explore-featured')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('public-event-calendar')));
      await tester.pumpAndSettle();
      expect(calendared.single.title, 'Soirée Afro-Jazz');
      expect(calendared.single.location, 'Jardin de la musique, Ouagadougou');
      expect(calendared.single.description, 'Trois formations en plein air.');

      await tester.tap(find.byKey(const Key('public-event-directions')));
      await tester.pumpAndSettle();
      expect(opened.single.host, 'www.google.com');
      expect(opened.single.path, '/maps/search/');
      expect(
        opened.single.queryParameters['query'],
        'Jardin de la musique, Ouagadougou',
      );

      await tester.tap(find.byKey(const Key('public-event-kind')));
      await tester.pumpAndSettle();
      expect(find.byType(ExplorePage), findsOneWidget);
      expect(catalog.queries.last.kinds, {EventKind.concert});

      // Filtre actif : « À la une » masquée ; la fiche s'ouvre depuis la liste.
      final tile = find.byKey(const Key('public-event-p1'));
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('explore-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('public-event-city')));
      await tester.pumpAndSettle();
      expect(find.byType(ExplorePage), findsOneWidget);
      expect(catalog.queries.last.city, 'Ouagadougou');
      expect(catalog.queries.last.kinds, isEmpty);
    });

    testWidgets('fiche : « Du même organisateur », sans l’événement ouvert', (
      tester,
    ) async {
      catalog.organizations['org-1'] = PublicOrganization(
        id: 'org-1',
        name: 'Faso Live',
        createdAt: DateTime.utc(2026, 3, 2),
        events: events,
      );
      await pumpGuest(tester);
      await tester.tap(find.byKey(const Key('explore-featured')));
      await tester.pumpAndSettle();
      final section = find.byKey(const Key('public-event-same-org'));
      await tester.scrollUntilVisible(section, 200);
      await tester.pumpAndSettle();
      Finder inSection(String id) => find.descendant(
        of: section,
        matching: find.byKey(Key('public-event-$id')),
      );
      expect(inSection('p1'), findsNothing);
      expect(inSection('p2'), findsOneWidget);
      expect(inSection('p3'), findsOneWidget);
      // Trois au plus : pas de « Tout voir » pour deux.
      expect(find.byKey(const Key('public-event-same-org-all')), findsNothing);
      await tester.ensureVisible(inSection('p2'));
      await tester.pumpAndSettle();
      await tester.tap(inSection('p2'));
      await tester.pumpAndSettle();
      expect(find.text('Finale inter-quartiers'), findsWidgets);
    });

    testWidgets('page d’une structure qui n’est plus visible : message', (
      tester,
    ) async {
      await pumpGuest(tester);
      await tester.tap(find.byKey(const Key('explore-featured')));
      await tester.pumpAndSettle();
      final organizer = find.byKey(const Key('public-event-organizer'));
      await tester.scrollUntilVisible(organizer, 200);
      await tester.pumpAndSettle();
      await tester.tap(organizer);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('public-org-error')), findsOneWidget);
      expect(
        find.text("Cette structure n'est plus visible sur Tikéo."),
        findsOneWidget,
      );
    });

    testWidgets('fiche sans numéro public : pas de bouton WhatsApp', (
      tester,
    ) async {
      await pumpGuest(tester);
      // En-tête plus haut (direction artistique) : la ligne est plus bas.
      await tester.scrollUntilVisible(
        find.byKey(const Key('public-event-p3')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('explore-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('public-event-p3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('public-event-whatsapp')), findsNothing);
      expect(find.byKey(const Key('public-event-no-contact')), findsOneWidget);
      // Sans structure connue (ancienne réponse) : bloc non touchable.
      final organizer = find.byKey(const Key('public-event-organizer'));
      await tester.scrollUntilVisible(organizer, 200);
      await tester.pumpAndSettle();
      expect(find.text('Voir la structure et ses événements'), findsNothing);
      await tester.tap(organizer);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('public-org-page')), findsNothing);
    });

    testWidgets(
      '« Organiser » et « Compte » ouvrent présentation et connexion',
      (tester) async {
        await pumpGuest(tester);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Organiser'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('welcome-sign-in')), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Compte'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
      },
    );
  });

  group('organisateur', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');

    testWidgets('Explorer dans la barre de l’espace connecté', (tester) async {
      final catalog = FakeCatalogRepository([publicEvent(id: 'p1')]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            catalog: catalog,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Explorer'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExplorePage).hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('explore-featured')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('explore-featured')));
      await tester.pumpAndSettle();
      expect(find.byType(PublicEventPage), findsOneWidget);
    });

    testWidgets('rendre un événement public, puis privé', (tester) async {
      final events = FakeEventRepository([
        testEvent(id: 'e1', status: EventStatus.published),
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: events,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await openEventsList(tester);
      await tester.tap(find.byKey(const Key('event-card-e1')));
      await tester.pumpAndSettle();
      final toggle = find.byKey(const Key('event-public'));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(events.publicCalls, [('e1', true)]);
      expect(find.text("Visible dans l'Explorer"), findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(events.publicCalls.last, ('e1', false));
    });

    testWidgets('prix indicatif d’une catégorie', (tester) async {
      final setup = FakeEventSetupRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: FakeEventRepository([
              testEvent(id: 'e1', status: EventStatus.published),
            ]),
            setup: setup,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await openEventsList(tester);
      await tester.tap(find.byKey(const Key('event-card-e1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('category-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('category-add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('setup-name')), 'Standard');
      await tester.enterText(find.byKey(const Key('setup-price')), '2000');
      await tester.ensureVisible(find.byKey(const Key('setup-submit')));
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.pumpAndSettle();
      expect(setup.calls, ['createCategory Standard null', 'price cat-1 2000']);
      expect(
        setup.categoryRows.single,
        isA<TicketCategory>().having((c) => c.indicativePrice, 'prix', 2000),
      );
    });

    testWidgets('numéro WhatsApp public de l’organisation', (tester) async {
      final orgs = FakeOrganizationRepository([testOrganization]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: orgs,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        GoRouter.of(tester.element(find.byType(NavigationBar)))
            .push(AppRoutes.editOrganization),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('org-public-phone-field')),
        '70 11 22 33',
      );
      await tester.ensureVisible(find.byKey(const Key('org-save')));
      await tester.tap(find.byKey(const Key('org-save')));
      await tester.pumpAndSettle();
      expect(orgs.updateCalls.single.$2.publicPhone, '70 11 22 33');
      expect(orgs.organizations.single.publicPhone, '70 11 22 33');
    });
  });
}
