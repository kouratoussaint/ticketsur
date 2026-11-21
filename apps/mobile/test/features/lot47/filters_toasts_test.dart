import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/remembered_filters.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/navigation.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');

  test('filtres : par compte, par appareil, oubli du compte', () async {
    SharedPreferences.setMockInitialValues({
      'filters.u2.events.filter': 'past',
    });
    final prefs = await SharedPreferences.getInstance();
    final mine = RememberedFilters(prefs, 'u1')
      ..write('events.filter', 'drafts')
      ..write('explore.city', 'Bobo-Dioulasso', device: true);
    await Future<void>.delayed(Duration.zero);
    expect(mine.read('events.filter'), 'drafts');
    // Un autre compte ne voit pas mes filtres.
    expect(RememberedFilters(prefs, 'u2').read('events.filter'), 'past');
    // Sans compte : seulement ceux de l'appareil.
    const guest = 'explore.city';
    expect(RememberedFilters(prefs, null).read('events.filter'), isNull);
    expect(
      RememberedFilters(prefs, null).read(guest, device: true),
      'Bobo-Dioulasso',
    );
    await RememberedFilters.forgetAccount(prefs, 'u1');
    expect(mine.read('events.filter'), isNull);
    expect(mine.read(guest, device: true), 'Bobo-Dioulasso');
    expect(prefs.getString('filters.u2.events.filter'), 'past');
    expect(enumByName(EventsFilter.values, 'drafts'), EventsFilter.drafts);
    expect(enumByName(EventsFilter.values, 'inconnu'), isNull);
  });

  Future<FakeAuthRepository> pump(
    WidgetTester tester, {
    Map<String, Object> preferences = const {},
    FakeCatalogRepository? catalog,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final auth = FakeAuthRepository(user: user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: auth,
          organizations: FakeOrganizationRepository([testOrganization]),
          events: FakeEventRepository([
            testEvent(id: 'e1', title: 'Brouillon A'),
            testEvent(
              id: 'e2',
              title: 'Concert publié',
              status: EventStatus.published,
            ),
          ]),
          catalog: catalog,
          preferences: preferences,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('liste des événements : filtre retrouvé, puis oublié à la '
      'déconnexion', (tester) async {
    final auth = await pump(
      tester,
      preferences: {'filters.u1.events.filter': 'drafts'},
    );
    await openEventsList(tester);
    expect(find.byKey(const Key('event-card-e1')), findsOneWidget);
    expect(find.byKey(const Key('event-card-e2')), findsNothing);

    await tester.tap(find.byKey(const Key('events-filter-all')));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('filters.u1.events.filter'), 'all');

    await auth.signOut();
    await tester.pumpAndSettle();
    expect(prefs.getString('filters.u1.events.filter'), isNull);
  });

  testWidgets('Explorer : la ville choisie est retrouvée', (tester) async {
    final catalog = FakeCatalogRepository([]);
    await pump(
      tester,
      catalog: catalog,
      preferences: {'filters.device.explore.city': 'Bobo-Dioulasso'},
    );
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .go(AppRoutes.explore);
    await tester.pumpAndSettle();
    expect(catalog.queries.last.city, 'Bobo-Dioulasso');
  });

  testWidgets('sélection : les messages passent au-dessus de la barre '
      'd’actions', (tester) async {
    await pump(tester);
    await openEventsList(tester);
    expect(Toaster.bottomClearance.value, 0);
    await tester.longPress(find.byKey(const Key('event-card-e2')));
    await tester.pumpAndSettle();
    final bar = tester.getSize(
      find.byKey(const Key('events-selection-actions')),
    );
    expect(Toaster.bottomClearance.value, bar.height);
    // Rien d'archivable : le message s'affiche au-dessus de la barre.
    await tester.tap(find.byKey(const Key('events-bulk-archive')));
    await tester.pumpAndSettle();
    final snack = find
        .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
        .first;
    expect(
      tester.getBottomLeft(snack).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('events-selection-actions'))).dy,
      ),
    );
    await tester.tap(find.byKey(const Key('selection-close')));
    await tester.pumpAndSettle();
    expect(Toaster.bottomClearance.value, 0);
  });
}
