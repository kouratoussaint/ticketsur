import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin/presentation/console_page.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/updates/domain/update_checker.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_legal_repository.dart';
import '../../helpers/fake_organization_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'awa@exemple.bf');

  group('domaine', () {
    test('numéro de build lu dans le nom de la version', () {
      expect(buildFromTag('pilote-81'), 81);
      expect(buildFromTag('v1.0'), isNull);
      expect(buildFromTag(null), isNull);
    });

    test('corps découpé en intertitres, puces et paragraphes', () {
      final blocks = parseLegalBody(
        'Premier\nparagraphe.\n\n## Titre\n- Puce une\n- Puce deux\nFin.',
      );
      expect(blocks.map((b) => (b.runtimeType, b.text)).toList(), [
        (LegalParagraph, 'Premier paragraphe.'),
        (LegalHeading, 'Titre'),
        (LegalBullet, 'Puce une'),
        (LegalBullet, 'Puce deux'),
        (LegalParagraph, 'Fin.'),
      ]);
    });
  });

  group('écrans', () {
    late FakeLegalRepository legal;
    late FakeUpdateChecker updates;

    setUp(() {
      legal = FakeLegalRepository();
      updates = FakeUpdateChecker();
    });

    Future<void> openApp(
      WidgetTester tester, {
      AuthUser? signedIn = user,
      int installedBuild = 0,
      Map<String, Object> preferences = const {},
    }) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: signedIn),
            organizations: FakeOrganizationRepository([testOrganization]),
            admin: FakeAdminRepository(admin: true),
            legal: legal,
            updates: updates,
            installedBuild: installedBuild,
            preferences: preferences,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> reveal(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> go(WidgetTester tester, String path) async {
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
      await tester.pumpAndSettle();
    }

    testWidgets('profil → paramètres : réglages, version, mentions', (
      tester,
    ) async {
      await openApp(tester, installedBuild: 80);
      await go(tester, AppRoutes.profile);
      expect(find.byKey(const Key('profile-appearance')), findsNothing);
      final entry = find.byKey(const Key('profile-settings'));
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-appearance')), findsOneWidget);
      expect(find.byKey(const Key('profile-feedback')), findsOneWidget);
      await reveal(tester, find.text('Version pilote 80'));
      final terms = find.byKey(const Key('settings-legal-terms'));
      await reveal(tester, terms);
      await tester.tap(terms);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('legal-terms')), findsOneWidget);
      expect(find.text('1. Le service'), findsOneWidget);
      expect(find.text('Version 1 du 1 mai 2030'), findsOneWidget);
    });

    testWidgets('mentions lisibles sans compte', (tester) async {
      await openApp(tester, signedIn: null);
      await go(tester, AppRoutes.legal(LegalSlug.privacy));
      expect(find.byKey(const Key('legal-privacy')), findsOneWidget);
      expect(find.text('Vos droits'), findsOneWidget);
    });

    testWidgets('inscription : liens vers les mentions', (tester) async {
      await openApp(tester, signedIn: null);
      await go(tester, AppRoutes.signUp);
      final notice = find.byKey(const Key('sign-up-legal'));
      await tester.ensureVisible(notice);
      expect(
        find.textContaining('vous acceptez', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('mention indisponible : message et nouvel essai', (
      tester,
    ) async {
      legal.failure = LegalFailure.network;
      await openApp(tester);
      await go(tester, AppRoutes.legal(LegalSlug.terms));
      expect(find.byKey(const Key('legal-error')), findsOneWidget);
      legal.failure = null;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('legal-terms')), findsOneWidget);
    });

    testWidgets('nouvelle version : carte, point sur Profil, lien', (
      tester,
    ) async {
      updates.latest = 85;
      await openApp(tester, installedBuild: 80);
      expect(
        tester
            .widget<Badge>(find.byKey(const Key('nav-profile-badge')))
            .isLabelVisible,
        isTrue,
      );
      await go(tester, AppRoutes.profile);
      expect(find.byKey(const Key('update-banner')), findsOneWidget);
      expect(find.textContaining('version pilote 85'), findsOneWidget);
    });

    testWidgets('à jour : pas de carte ; vérification récente non refaite', (
      tester,
    ) async {
      updates.latest = 80;
      await openApp(
        tester,
        installedBuild: 80,
        preferences: {
          'updates.last_check': '2030-05-31T20:00:00.000Z',
          'updates.latest': 80,
        },
      );
      await go(tester, AppRoutes.profile);
      expect(find.byKey(const Key('update-banner')), findsNothing);
      expect(updates.calls, 0);
      await go(tester, AppRoutes.settings);
      await reveal(tester, find.byKey(const Key('settings-check-update')));
      await tester.tap(find.byKey(const Key('settings-check-update')));
      await tester.pumpAndSettle();
      expect(updates.calls, 1);
      expect(find.text('Vous avez la dernière version.'), findsOneWidget);
    });

    testWidgets('version de développement : aucune vérification', (
      tester,
    ) async {
      updates.latest = 999;
      await openApp(tester);
      await go(tester, AppRoutes.settings);
      await reveal(tester, find.text('Version de développement'));
      expect(updates.calls, 0);
    });

    testWidgets('console : modifier, prévisualiser et publier un document', (
      tester,
    ) async {
      await openApp(tester);
      await go(tester, AppRoutes.console);
      final tile = find.byKey(const Key('console-nav-legal'));
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ConsolePage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('1 passage entre crochets reste à compléter.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('console-legal-terms')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('console-legal-body')),
        'Texte édité par Tikéo SARL.\n\n## Nouveau\n- Puce ajoutée ici.',
      );
      await tester.tap(find.text('Aperçu'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-legal-preview')), findsOneWidget);
      expect(find.text('Nouveau'), findsOneWidget);
      await tester.tap(find.byKey(const Key('console-legal-save')));
      await tester.pumpAndSettle();
      expect(find.text('Publier la version 2 ?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('console-legal-confirm')));
      await tester.pumpAndSettle();
      expect(legal.saved.single.$1, LegalSlug.terms);
      expect(legal.documents[LegalSlug.terms]!.version, 2);
      // Retour à la liste, relue : plus de passage à compléter.
      expect(find.byKey(const Key('console-legal-terms')), findsOneWidget);
      expect(
        find.textContaining('1 passage entre crochets reste à compléter.'),
        findsNothing,
      );
    });
  });
}
