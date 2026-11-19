import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/sign_up_page.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/favorites/application/favorites_providers.dart';
import 'package:ticketsur/features/favorites/presentation/favorites_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/scanner/presentation/control_home_page.dart';
import 'package:ticketsur/features/welcome/welcome_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_organization_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeOrganizationRepository orgs;
  late FakeCatalogRepository catalog;

  setUp(() {
    auth = FakeAuthRepository();
    orgs = FakeOrganizationRepository();
    catalog = FakeCatalogRepository([
      publicEvent(id: 'p1'), // « Soirée Afro-Jazz »
      publicEvent(id: 'p2', title: 'Forum numérique'),
    ]);
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> preferences = const {},
  }) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: auth,
          organizations: orgs,
          catalog: catalog,
          preferences: preferences,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  void go(WidgetTester tester, String path) => unawaitedPush(tester, path);

  Future<void> fill(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  group('présentation sans compte', () {
    testWidgets('découverte d’événements, sans aperçu des écrans', (
      tester,
    ) async {
      await pumpApp(tester);
      go(tester, AppRoutes.organize);
      await tester.pumpAndSettle();
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byKey(const Key('welcome-event-p1')), findsOneWidget);
      expect(find.byKey(const Key('welcome-verdict-preview')), findsNothing);
      expect(find.byKey(const Key('tikeo-logo')), findsOneWidget);

      await tester.tap(find.byKey(const Key('welcome-code')));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpPage), findsOneWidget);
      // Arrivée par le code : le champ du code en premier.
      expect(
        tester.getTopLeft(find.byKey(const Key('sign-up-code'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('sign-up-name'))).dy),
      );
    });
  });

  group('création de compte', () {
    Future<void> openSignUp(WidgetTester tester) async {
      await pumpApp(tester);
      go(tester, AppRoutes.signUp);
      await tester.pumpAndSettle();
      await fill(tester, 'sign-up-name', 'Awa Ouédraogo');
      await fill(tester, 'sign-up-email', 'awa@faso.bf');
      await fill(tester, 'sign-up-password', 'motdepasse');
    }

    testWidgets('compte classique par défaut : Explorer, Favoris, Profil', (
      tester,
    ) async {
      await openSignUp(tester);
      await tester.tap(find.byKey(const Key('sign-up-submit')));
      await tester.pumpAndSettle();
      expect(auth.signUpCalls.single, (
        email: 'awa@faso.bf',
        name: 'Awa Ouédraogo',
      ));
      expect(orgs.createCalls, isEmpty);
      expect(find.byType(ExplorePage).hitTestable(), findsOneWidget);
      final bar = find.byType(NavigationBar);
      expect(
        find.descendant(of: bar, matching: find.text('Favoris')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.text('Organiser')),
        findsNothing,
      );
    });

    testWidgets('mot de passe court et nom manquant refusés localement', (
      tester,
    ) async {
      await pumpApp(tester);
      go(tester, AppRoutes.signUp);
      await tester.pumpAndSettle();
      await fill(tester, 'sign-up-email', 'awa@faso.bf');
      await fill(tester, 'sign-up-password', 'court');
      await tester.tap(find.byKey(const Key('sign-up-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Indiquez votre nom.'), findsOneWidget);
      expect(find.text('8 caractères au moins.'), findsOneWidget);
      expect(auth.signUpCalls, isEmpty);
    });

    testWidgets('promoteur : structure et numéro WhatsApp créés', (
      tester,
    ) async {
      await openSignUp(tester);
      expect(find.byKey(const Key('sign-up-structure')), findsNothing);
      await tester.tap(find.byKey(const Key('sign-up-promoter')));
      await tester.pumpAndSettle();
      // Structure obligatoire une fois la case cochée.
      await tester.tap(find.byKey(const Key('sign-up-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Indiquez le nom de votre structure.'), findsOneWidget);
      expect(auth.signUpCalls, isEmpty);

      await fill(tester, 'sign-up-structure', 'Kwabo Événements');
      await fill(tester, 'sign-up-public-phone', '70 11 22 33');
      await tester.tap(find.byKey(const Key('sign-up-submit')));
      await tester.pumpAndSettle();
      expect(orgs.createCalls, ['Kwabo Événements']);
      expect(orgs.updateCalls.single.$2.publicPhone, '70 11 22 33');
      // Espace du promoteur.
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Organiser'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('code d’invitation : équipe rejointe après l’inscription', (
      tester,
    ) async {
      orgs.nextJoin = const JoinOutcome(
        JoinResult.joined,
        Organization(
          id: 'org-x',
          name: 'Festival Invité',
          slug: 'festival-invite',
          role: MemberRole.controller,
        ),
      );
      await openSignUp(tester);
      await fill(tester, 'sign-up-code', 'abcd efgh jkmn');
      expect(find.text('TSI-ABCD-EFGH-JKMN'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sign-up-submit')));
      await tester.pumpAndSettle();
      expect(orgs.joinCalls, ['TSI-ABCD-EFGH-JKMN']);
      expect(find.byType(ControlHomePage).hitTestable(), findsOneWidget);
    });

    testWidgets('confirmation par e-mail exigée : message, pas de session', (
      tester,
    ) async {
      auth.signUpNeedsConfirmation = true;
      await openSignUp(tester);
      await tester.tap(find.byKey(const Key('sign-up-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sign-up-confirm')), findsOneWidget);
      expect(find.byType(SignUpPage), findsOneWidget);
    });

    testWidgets('adresse déjà utilisée : message', (tester) async {
      auth.nextSignUpFailure = AuthFailure.emailTaken;
      await openSignUp(tester);
      await tester.tap(find.byKey(const Key('sign-up-submit')));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpPage), findsOneWidget);
      expect(orgs.createCalls, isEmpty);
    });

    testWidgets('connexion → « Créer un compte »', (tester) async {
      await pumpApp(tester);
      go(tester, AppRoutes.signIn);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tikeo-logo')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sign-in-sign-up')));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpPage), findsOneWidget);
    });
  });

  group('favoris', () {
    testWidgets('sans compte : cœur dans l’Explorer, onglet Favoris', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('favorite-p2')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Favoris'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesPage), findsOneWidget);
      expect(find.text('Forum numérique'), findsOneWidget);
      expect(find.text('Soirée Afro-Jazz'), findsNothing);

      // Retirer depuis la liste des favoris.
      await tester.tap(find.byKey(const Key('favorite-p2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
    });

    testWidgets('gardés sur l’appareil d’une ouverture à l’autre', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('favorite-p1')));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ExplorePage)),
      );
      final saved = container
          .read(sharedPreferencesProvider)
          .getString(favoritesPreferenceKey);
      expect(saved, contains('Soirée Afro-Jazz'));

      await pumpApp(tester, preferences: {favoritesPreferenceKey: saved!});
      go(tester, AppRoutes.favorites);
      await tester.pumpAndSettle();
      expect(find.text('Soirée Afro-Jazz'), findsOneWidget);
    });
  });

  group('rôles', () {
    test('un contrôleur ne va jamais sur les pages du promoteur', () {
      for (final path in [
        AppRoutes.home,
        AppRoutes.events,
        AppRoutes.eventDetail('e1'),
        AppRoutes.eventDashboard('e1'),
        AppRoutes.tickets,
        AppRoutes.team,
        AppRoutes.editOrganization,
      ]) {
        expect(
          roleRedirect(role: MemberRole.controller, location: path),
          AppRoutes.control,
          reason: path,
        );
      }
      expect(
        roleRedirect(role: MemberRole.controller, location: AppRoutes.scanner),
        isNull,
      );
      expect(
        roleRedirect(role: MemberRole.controller, location: AppRoutes.profile),
        isNull,
      );
    });

    test('compte classique : ni promoteur ni contrôle', () {
      for (final path in [
        AppRoutes.home,
        AppRoutes.tickets,
        AppRoutes.control,
        AppRoutes.history,
      ]) {
        expect(
          roleRedirect(role: null, location: path),
          AppRoutes.explore,
          reason: path,
        );
      }
      expect(roleRedirect(role: null, location: AppRoutes.profile), isNull);
      expect(
        roleRedirect(role: null, location: AppRoutes.favoritesTab),
        isNull,
      );
    });

    test('promoteur : tout son espace, et le contrôle', () {
      for (final path in [
        AppRoutes.home,
        AppRoutes.tickets,
        AppRoutes.control,
        AppRoutes.posts,
      ]) {
        expect(roleRedirect(role: MemberRole.owner, location: path), isNull);
        expect(roleRedirect(role: MemberRole.manager, location: path), isNull);
      }
    });
  });
}

/// Navigation programmatique (comme un lien interne).
void unawaitedPush(WidgetTester tester, String path) {
  GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
}
