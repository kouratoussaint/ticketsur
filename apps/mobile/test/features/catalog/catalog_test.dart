import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/burkina_cities.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/catalog/presentation/public_event_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';

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

    Future<void> pumpGuest(WidgetTester tester) async {
      opened = [];
      shared = [];
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
            openLink: (uri) async {
              opened.add(uri);
              return true;
            },
            share: (text) async => shared.add(text),
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
