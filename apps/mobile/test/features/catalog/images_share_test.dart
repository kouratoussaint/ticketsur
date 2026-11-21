import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/event_share.dart';
import 'package:ticketsur/features/catalog/presentation/public_event_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/photo_viewer.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/l10n/gen/app_localizations.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_organization_repository.dart';

/// Images et partage (améliorations du 20/11, PR 2 : #1, #2, #3, #18).
void main() {
  const cover =
      'https://exemple.bf/storage/v1/object/public/event-covers/a.jpg';
  final events = [
    publicEvent(id: 'p1', minPrice: 2000, coverUrl: cover),
    publicEvent(id: 'p2', title: 'Forum numérique', kind: EventKind.conference),
    publicEvent(id: 'p3', title: 'Tournoi de lutte', kind: EventKind.sport),
  ];
  late FakeCatalogRepository catalog;
  late List<(Uint8List, String)> saved;
  late List<List<SharedFile>> shared;
  late List<String?> sharedTexts;
  late List<ShareFormat> rendered;

  setUp(() {
    catalog = FakeCatalogRepository(events, {
      'p1': PublicEventDetail(
        summary: events.first,
        categories: const [(name: 'Standard', price: 2000)],
      ),
    });
    saved = [];
    shared = [];
    sharedTexts = [];
    rendered = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    AuthUser? user,
    FakeAdminRepository? admin,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            catalog: catalog,
            admin: admin,
            shareFiles: (files, {text}) async {
              shared.add(files);
              sharedTexts.add(text);
            },
          ),
          imageBytesProvider.overrideWithValue(
            (url) async => Uint8List.fromList([1, 2, 3]),
          ),
          gallerySaverProvider.overrideWithValue(
            (bytes, name) async => saved.add((bytes, name)),
          ),
          eventImageRendererProvider.overrideWithValue((
            context,
            detail,
            format,
          ) async {
            rendered.add(format);
            return Uint8List.fromList([9, 9]);
          }),
        ],
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  GoRouter router(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Navigator).first));

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('nom de fichier lisible', () {
    expect(
      imageFileName('Soirée Afro-Jazz à Ouaga !'),
      'Tikeo-soiree-afro-jazz-a-ouaga',
    );
    expect(imageFileName('  '), 'Tikeo-evenement');
  });

  testWidgets('À la une : plusieurs cartes, « Obtenir un ticket » (#1, #3)', (
    tester,
  ) async {
    catalog.featuredEvents = [events[1], events[0]];
    await pump(tester);
    expect(find.byKey(const Key('explore-featured-list')), findsOneWidget);
    // Ordre choisi par l'administrateur : Forum d'abord.
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-featured')),
        matching: find.text('Forum numérique'),
      ),
      findsOneWidget,
    );
    await tap(tester, find.byKey(const Key('featured-get-ticket-p2')));
    expect(find.byType(PublicEventPage), findsOneWidget);
  });

  testWidgets('photo en grand : télécharger, partager, fermer (#2)', (
    tester,
  ) async {
    await pump(tester);
    router(tester).go(AppRoutes.publicEvent('p1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('public-event-photo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsOneWidget);
    expect(find.byKey(const Key('photo-viewer-zoom')), findsOneWidget);
    await tester.tap(find.byKey(const Key('photo-viewer-download')));
    await tester.pumpAndSettle();
    expect(saved.single.$2, 'Tikeo-soiree-afro-jazz');
    expect(find.text('Image enregistrée.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('photo-viewer-share')));
    await tester.pumpAndSettle();
    expect(shared.single.single.name, 'Tikeo-soiree-afro-jazz.jpg');
    await tester.tap(find.byKey(const Key('photo-viewer-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsNothing);
    expect(find.byType(PublicEventPage), findsOneWidget);
  });

  testWidgets('partage en image : statut puis publication (#18)', (
    tester,
  ) async {
    await pump(tester);
    router(tester).go(AppRoutes.publicEvent('p1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('public-event-share')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('event-share-preview')), findsOneWidget);
    await tap(tester, find.byKey(const Key('event-share-send')));
    expect(rendered, [ShareFormat.story]);
    expect(shared.single.single.name, 'Tikeo-soiree-afro-jazz-story.png');
    expect(sharedTexts.single, contains('Obtenez votre ticket sur Tikéo.'));
    await tap(tester, find.byKey(const Key('event-share-post')));
    await tap(tester, find.byKey(const Key('event-share-save')));
    expect(rendered.last, ShareFormat.post);
    expect(saved.single.$2, 'Tikeo-soiree-afro-jazz-post');
  });

  for (final format in ShareFormat.values) {
    testWidgets('image de partage ${format.name} : tout tient, titre long', (
      tester,
    ) async {
      tester.view.physicalSize = format.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: TicketSurTheme.light(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: EventShareImage(
            format: format,
            detail: PublicEventDetail(
              summary: publicEvent(
                id: 'p9',
                title:
                    'Grand concert de fin d’année des artistes du Kadiogo et '
                    'de leurs invités',
                minPrice: 5000,
                venue: 'Palais des sports de Ouaga 2000',
              ),
              categories: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text("Obtenez votre ticket sur l'application Tikéo"),
        findsOneWidget,
      );
      // Pas de QR sur l'image (ce n'est pas un ticket).
      expect(find.byKey(const Key('ticket-qr')), findsNothing);
    });
  }

  testWidgets('console : ajouter, ordonner, retirer (#3)', (tester) async {
    final admin = FakeAdminRepository(
      admin: true,
      events: [
        adminEvent(),
        adminEvent(id: 'p2', title: 'Gala du Kadiogo'),
      ],
    );
    await pump(
      tester,
      user: const AuthUser(id: 'u1', email: 'admin@tikeo.bf'),
      admin: admin,
    );
    router(tester).go(AppRoutes.console);
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const Key('console-nav-featured')));
    expect(find.byKey(const Key('featured-empty')), findsOneWidget);

    for (final id in ['p1', 'p2']) {
      await tester.tap(find.byKey(const Key('featured-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('featured-pick-$id')));
      await tester.pumpAndSettle();
    }
    expect(admin.featuredCalls, ['add p1', 'add p2']);
    expect(find.byKey(const Key('featured-f-p2')), findsOneWidget);
    expect(find.text('Affiché'), findsNWidgets(2));

    await tap(tester, find.byKey(const Key('featured-up-f-p2')));
    expect(admin.featured.first.eventId, 'p2');
    await tap(tester, find.byKey(const Key('featured-remove-f-p1')));
    expect(admin.featured.map((f) => f.eventId), ['p2']);
    expect(find.byKey(const Key('featured-f-p1')), findsNothing);
  });

  testWidgets('console : événement déjà à la une, message clair', (
    tester,
  ) async {
    final admin = FakeAdminRepository(admin: true);
    await admin.addFeatured('p1');
    await pump(
      tester,
      user: const AuthUser(id: 'u1', email: 'admin@tikeo.bf'),
      admin: admin,
    );
    router(tester).go(AppRoutes.consoleFeatured);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('featured-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('featured-pick-p1')));
    await tester.pumpAndSettle();
    expect(find.text('Cet événement est déjà à la une.'), findsOneWidget);
    expect(
      AdminFailure.values,
      containsAll([AdminFailure.featuredExists, AdminFailure.featuredInvalid]),
    );
  });
}
