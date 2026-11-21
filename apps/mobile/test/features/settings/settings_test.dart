import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin/presentation/console_page.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/profile/domain/profile.dart';
import 'package:ticketsur/features/updates/domain/update_checker.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_legal_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_profile_repository.dart';

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
    FakeProfileRepository? profiles;

    setUp(() {
      legal = FakeLegalRepository();
      updates = FakeUpdateChecker();
      profiles = null;
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
            profile: profiles,
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
      // À propos sorti des Paramètres (#8) ; mot de passe dans Compte (#7).
      expect(find.byKey(const Key('settings-version')), findsNothing);
      await reveal(tester, find.byKey(const Key('settings-password')));
      expect(find.byKey(const Key('settings-email')), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings-password')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('password-new')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await go(tester, AppRoutes.profile);
      final about = find.byKey(const Key('profile-about'));
      await tester.ensureVisible(about);
      await tester.tap(about);
      await tester.pumpAndSettle();
      expect(find.text('Version pilote 80'), findsOneWidget);
      final terms = find.byKey(const Key('about-legal-terms'));
      await tester.ensureVisible(terms);
      await tester.pumpAndSettle();
      await tester.tap(terms);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('legal-terms')), findsOneWidget);
      expect(find.text('1. Le service'), findsOneWidget);
      expect(find.text('Version 1 du 1 mai 2030'), findsOneWidget);
    });

    testWidgets('rappels avant l’événement : réglage du compte', (
      tester,
    ) async {
      profiles = FakeProfileRepository();
      await openApp(tester);
      await go(tester, AppRoutes.settings);
      final toggle = find.byKey(const Key('settings-reminders'));
      await reveal(tester, toggle);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(profiles!.reminderCalls, [false]);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

      profiles!.nextFailure = ProfileFailure.network;
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-reminders-error')), findsOneWidget);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    });

    testWidgets('sans compte : pas de réglage des rappels', (tester) async {
      await openApp(tester, signedIn: null);
      await go(tester, AppRoutes.settings);
      expect(find.byKey(const Key('settings-reminders')), findsNothing);
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
      // Au lancement : fenêtre « Nouvelle version disponible » (#9).
      expect(find.byKey(const Key('update-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('update-dialog-later')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-dialog')), findsNothing);
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

    testWidgets('à jour : vérifiée au lancement, puis à la demande', (
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
      expect(find.byKey(const Key('update-dialog')), findsNothing);
      // Une vérification à chaque lancement, même récente.
      expect(updates.calls, 1);
      await go(tester, AppRoutes.about);
      expect(find.byKey(const Key('about-up-to-date')), findsOneWidget);
      expect(find.textContaining('Dernière vérification'), findsOneWidget);
      await tester.tap(find.byKey(const Key('about-check-update')));
      await tester.pumpAndSettle();
      expect(updates.calls, 2);
      expect(find.text('Vous avez la dernière version.'), findsWidgets);
    });

    testWidgets('version de développement : aucune vérification', (
      tester,
    ) async {
      updates.latest = 999;
      await openApp(tester);
      await go(tester, AppRoutes.about);
      expect(find.text('Version de développement'), findsOneWidget);
      expect(updates.calls, 0);
    });

    testWidgets('console : version anglaise modifiée à part', (tester) async {
      legal.english[LegalSlug.privacy] = LegalDocument(
        slug: LegalSlug.privacy,
        title: 'Privacy policy',
        body: 'We protect your data. [to complete]',
        version: 1,
        updatedAt: DateTime.utc(2030, 5),
      );
      await openApp(tester);
      await go(tester, AppRoutes.consoleLegal);
      await tester.tap(find.byKey(const Key('console-legal-locale-en')));
      await tester.pumpAndSettle();
      expect(find.text('Privacy policy'), findsOneWidget);
      await tester.tap(find.byKey(const Key('console-legal-privacy')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('console-legal-body')),
        'We protect your data and never sell it.',
      );
      await tester.tap(find.byKey(const Key('console-legal-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-legal-confirm')));
      await tester.pumpAndSettle();
      expect(legal.savedLocales, ['en']);
      expect(legal.english[LegalSlug.privacy]!.version, 2);
      // La version française n'a pas changé.
      expect(legal.documents[LegalSlug.privacy]!.version, 2);
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
      // L'en-tête repousse les modules : la ligne doit être à l'écran.
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
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
