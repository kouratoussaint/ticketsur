import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/appearance.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_catalog_repository.dart';
import '../helpers/fake_organization_repository.dart';

void main() {
  group('taille du texte (#11)', () {
    test('échelle du téléphone multipliée par la taille choisie', () {
      const scaler = AppTextScaler(TextScaler.linear(1.2), 1.3);
      expect(scaler.scale(10), closeTo(15.6, 1e-9));
      expect(TextSize.values.map((s) => s.factor), [0.9, 1, 1.15, 1.3]);
    });

    test('échelle réduite d’un cran', () {
      final text = TicketSurTheme.light().textTheme;
      expect(text.headlineMedium!.fontSize, 24);
      expect(text.titleLarge!.fontSize, 18);
      expect(text.bodyLarge!.fontSize, 14);
      expect(text.labelMedium!.fontSize, 13);
    });

    Future<SharedPreferences> pumpSettings(
      WidgetTester tester, {
      String? size,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final overrides = await appOverrides(
        auth: FakeAuthRepository(
          user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
        ),
        organizations: FakeOrganizationRepository([testOrganization]),
        preferences: {'appearance.text_size': ?size},
      );
      await tester.pumpWidget(
        ProviderScope(overrides: overrides, child: const TicketSurApp()),
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .go(AppRoutes.settings);
      await tester.pumpAndSettle();
      return await SharedPreferences.getInstance();
    }

    double previewHeight(WidgetTester tester) =>
        tester.getSize(find.text('Concert de Bobo')).height;

    testWidgets('Très grande : texte agrandi partout, choix mémorisé', (
      tester,
    ) async {
      final prefs = await pumpSettings(tester);
      final picker = find.byKey(const Key('settings-text-size'));
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      final before = previewHeight(tester);
      expect(
        MediaQuery.textScalerOf(tester.element(picker)).scale(10),
        closeTo(10, 1e-9),
      );

      await tester.tap(find.byKey(const Key('text-size-extraLarge')));
      await tester.pumpAndSettle();
      expect(prefs.getString('appearance.text_size'), 'extraLarge');
      expect(
        MediaQuery.textScalerOf(tester.element(picker)).scale(10),
        closeTo(13, 1e-9),
      );
      expect(previewHeight(tester), greaterThan(before * 1.2));
    });

    testWidgets('choix relu au lancement', (tester) async {
      await pumpSettings(tester, size: 'small');
      final picker = find.byKey(const Key('settings-text-size'));
      expect(
        MediaQuery.textScalerOf(tester.element(picker)).scale(10),
        closeTo(9, 1e-9),
      );
      final button = tester.widget<SegmentedButton<TextSize>>(
        find.byType(SegmentedButton<TextSize>),
      );
      expect(button.selected, {TextSize.small});
    });
  });

  group('sélection du texte par appui long (#17)', () {
    Future<void> open(WidgetTester tester, String path) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(),
            catalog: FakeCatalogRepository(
              [publicEvent(id: 'p1')],
              {
                'p1': PublicEventDetail(
                  summary: publicEvent(id: 'p1'),
                  description: 'Trois formations en plein air.',
                  publicPhone: '+22670112233',
                  categories: const [(name: 'Standard', price: 2000)],
                ),
              },
            ),
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
      await tester.pumpAndSettle();
    }

    testWidgets('fiche publique : description sélectionnable', (tester) async {
      await open(tester, AppRoutes.publicEvent('p1'));
      final description = find.text('Trois formations en plein air.');
      await tester.ensureVisible(description);
      expect(
        find.ancestor(of: description, matching: find.byType(SelectionArea)),
        findsOneWidget,
      );
      // La barre du bas (boutons) reste hors de la zone de sélection.
      expect(
        find.ancestor(
          of: find.byKey(const Key('public-event-whatsapp')),
          matching: find.byType(SelectionArea),
        ),
        findsNothing,
      );
    });

    testWidgets('mentions légales sélectionnables', (tester) async {
      await open(tester, AppRoutes.legal(LegalSlug.terms));
      expect(
        find.ancestor(
          of: find.byKey(const Key('legal-terms')),
          matching: find.byType(SelectionArea),
        ),
        findsOneWidget,
      );
    });
  });
}
