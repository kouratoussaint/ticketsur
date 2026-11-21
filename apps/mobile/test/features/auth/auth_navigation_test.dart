import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_widgets.dart';
import 'package:ticketsur/features/auth/presentation/forgot_password_page.dart';
import 'package:ticketsur/features/auth/presentation/sign_in_page.dart';
import 'package:ticketsur/features/auth/presentation/sign_up_page.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/profile/profile_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_organization_repository.dart';

/// Retour sur la connexion et la création de compte (#12), déconnexion vers
/// Explorer (#13).
void main() {
  late FakeAuthRepository auth;

  setUp(() {
    auth = FakeAuthRepository();
    signOutRequested = false;
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await appOverrides(
            auth: auth,
            organizations: FakeOrganizationRepository([testOrganization]),
          ),
          mailboxOpenerProvider.overrideWithValue(() async => true),
        ],
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  GoRouter router(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Navigator).first));

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openSignInFromExplore(WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.byType(ExplorePage), findsOneWidget);
    await tester.tap(find.text('Compte'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
  }

  testWidgets('Explorer → Connexion → Retour : Explorer', (tester) async {
    await openSignInFromExplore(tester);
    await back(tester);
    expect(find.byType(SignInPage), findsNothing);
    expect(find.byType(ExplorePage), findsOneWidget);
  });

  testWidgets('Connexion ↔ Création de compte : sans boucle, Retour à '
      "l'écran d'origine", (tester) async {
    await openSignInFromExplore(tester);
    await tap(tester, 'sign-in-sign-up');
    expect(find.byType(SignUpPage), findsOneWidget);
    await tap(tester, 'sign-up-to-sign-in');
    expect(find.byType(SignInPage), findsOneWidget);
    await tap(tester, 'sign-in-sign-up');
    // Flèche de l'en-tête : même comportement que le Retour d'Android.
    await tester.tap(find.byTooltip('Retour').first);
    await tester.pumpAndSettle();
    expect(find.byType(SignUpPage), findsNothing);
    expect(find.byType(SignInPage), findsNothing);
    expect(find.byType(ExplorePage), findsOneWidget);
  });

  testWidgets('Mot de passe oublié → Retour : Connexion', (tester) async {
    await openSignInFromExplore(tester);
    await tap(tester, 'sign-in-forgot');
    expect(find.byType(ForgotPasswordPage), findsOneWidget);
    await back(tester);
    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets("Confirmer l'adresse → Retour : Connexion", (tester) async {
    auth.signUpNeedsConfirmation = true;
    await openSignInFromExplore(tester);
    await tap(tester, 'sign-in-sign-up');
    await tester.enterText(find.byKey(const Key('sign-up-name')), 'Awa Traoré');
    await tester.enterText(
      find.byKey(const Key('sign-up-email')),
      'awa@exemple.bf',
    );
    await tester.enterText(
      find.byKey(const Key('sign-up-password')),
      'motdepasse12',
    );
    await tap(tester, 'sign-up-submit');
    expect(find.byKey(const Key('sign-up-confirm')), findsOneWidget);
    await back(tester);
    expect(find.byType(SignInPage), findsOneWidget);
    // Puis Retour : l'écran d'origine.
    await back(tester);
    expect(find.byType(ExplorePage), findsOneWidget);
  });

  testWidgets("Connexion ouverte sans écran d'origine : Retour → Explorer", (
    tester,
  ) async {
    await pumpApp(tester);
    router(tester).go(AppRoutes.signIn);
    await tester.pumpAndSettle();
    await back(tester);
    expect(find.byType(ExplorePage), findsOneWidget);
  });

  testWidgets('lien profond : connexion puis la page demandée, pile vidée', (
    tester,
  ) async {
    await pumpApp(tester);
    router(tester).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'awa@exemple.bf',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'motdepasse12',
    );
    await tap(tester, 'sign-in-submit');
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);
  });

  testWidgets('déconnexion : Explorer, jamais la connexion', (tester) async {
    auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'awa@exemple.bf'),
    );
    await pumpApp(tester);
    router(tester).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    await tap(tester, 'profile-sign-out');
    expect(find.byType(SignInPage), findsNothing);
    expect(find.byType(ExplorePage), findsOneWidget);
    expect(router(tester).state.matchedLocation, AppRoutes.discover);
  });

  test('destination après la connexion : chemin local seulement', () {
    expect(AppRoutes.afterSignIn('/profil'), '/profil');
    expect(AppRoutes.afterSignIn(null), AppRoutes.home);
    expect(AppRoutes.afterSignIn('https://exemple.bf'), AppRoutes.home);
    expect(AppRoutes.afterSignIn('//exemple.bf'), AppRoutes.home);
    expect(AppRoutes.afterSignIn('/connexion?suite=x'), AppRoutes.home);
    expect(
      authRedirect(signedIn: false, location: '/profil', target: '/profil'),
      '/connexion?suite=%2Fprofil',
    );
    expect(
      authRedirect(signedIn: false, location: '/profil', afterSignOut: true),
      AppRoutes.discover,
    );
  });
}
