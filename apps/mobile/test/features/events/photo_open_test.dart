import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/featured_card.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/photo_viewer.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');

  Future<void> pump(
    WidgetTester tester, {
    FakeEventRepository? events,
    FakeCatalogRepository? catalog,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: events,
            catalog: catalog,
          ),
          imageBytesProvider.overrideWithValue(
            (url) async => Uint8List.fromList([1, 2, 3]),
          ),
        ],
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  void go(WidgetTester tester, String path) =>
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);

  Future<void> closeViewer(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('photo-viewer-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsNothing);
  }

  FakeEventRepository withCover() => FakeEventRepository([
    testEvent(
      id: 'e1',
      title: 'Nuit du Djembé',
      status: EventStatus.published,
      coverPath: 'org/e1/photo.jpg',
      city: 'Ouagadougou',
    ),
  ]);

  testWidgets('fiche promoteur : bouton et appui sur le titre ouvrent la '
      'photo en grand', (tester) async {
    await pump(tester, events: withCover());
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .push(AppRoutes.eventDetail('e1'))
        .ignore();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('event-photo-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsOneWidget);
    await closeViewer(tester);

    // Même un appui sur le titre (posé sur la photo) l'ouvre.
    await tester.tap(
      find.byKey(const Key('event-detail-title')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsOneWidget);
  });

  testWidgets('fiche publique : bouton « Voir la photo en grand »', (
    tester,
  ) async {
    final event = publicEvent(id: 'p1', coverUrl: 'https://covers.test/p1.jpg');
    await pump(
      tester,
      catalog: FakeCatalogRepository(
        [event],
        {'p1': PublicEventDetail(summary: event, categories: const [])},
      ),
    );
    go(tester, AppRoutes.publicEvent('p1'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Voir la photo en grand'), findsOneWidget);
    await tester.tap(find.byKey(const Key('public-event-photo-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsOneWidget);
  });

  testWidgets('Organiser : photo entière en haut, texte dessous', (
    tester,
  ) async {
    await pump(tester, events: withCover());
    final photo = find.byKey(const Key('home-next-event-photo'));
    expect(photo, findsOneWidget);
    expect(tester.widget<WholePhoto>(photo).url, isNotNull);
    final title = find.descendant(
      of: find.byKey(const Key('home-next-event')),
      matching: find.text('Nuit du Djembé'),
    );
    // Le titre est sous la photo, plus jamais posé dessus.
    expect(
      tester.getTopLeft(title).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(photo).dy),
    );
  });
}
