import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/home/coming_soon_pages.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/profile/profile_page.dart';
import 'package:ticketsur/features/welcome/welcome_page.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  late FakeAuthRepository auth;
  late int exits;

  Future<void> pumpApp(WidgetTester tester, {bool reduceMotion = false}) async {
    exits = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(auth: auth, onExit: () async => exits++),
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const TicketSurApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Simule le bouton Retour d'Android.
  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  setUp(() => auth = FakeAuthRepository());

  group('double appui sur Retour pour quitter', () {
    testWidgets('accueil public : 1er appui = message, 2e = sortie', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byType(WelcomePage), findsOneWidget);

      await pressBack(tester);
      expect(
        find.text('Appuyez encore sur Retour pour quitter TicketSûr'),
        findsOneWidget,
      );
      expect(exits, 0);

      await pressBack(tester);
      expect(exits, 1);
    });

    testWidgets('page empilée : Retour revient en arrière, sans message', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('welcome-sign-in')));
      await tester.pumpAndSettle();

      await pressBack(tester);
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byKey(const Key('exit-confirm')), findsNothing);
      expect(exits, 0);
    });

    testWidgets('un 2e appui après le délai redemande confirmation', (
      tester,
    ) async {
      var now = DateTime(2026, 11, 18, 12);
      var count = 0;
      await tester.pumpApp(
        ProviderScope(
          overrides: [appExitProvider.overrideWithValue(() async => count++)],
          child: DoubleBackToExit(
            clock: () => now,
            child: const Text('racine'),
          ),
        ),
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      now = now.add(const Duration(seconds: 3)); // délai de 2 s dépassé
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(count, 0);
      expect(find.byKey(const Key('exit-confirm')), findsOneWidget);

      now = now.add(const Duration(seconds: 1));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(count, 1);
    });
  });

  group('espace connecté', () {
    setUp(
      () => auth = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
      ),
    );

    testWidgets('barre de navigation à cinq onglets', (tester) async {
      await pumpApp(tester);
      expect(find.byType(HomePage), findsOneWidget);
      final bar = tester.widget<NavigationBar>(
        find.byKey(const Key('app-navigation-bar')),
      );
      expect(bar.destinations, hasLength(5));
      for (final label in ['Accueil', 'Événements', 'Billets', 'Équipe']) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('changer d’onglet affiche le module', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Événements').last);
      await tester.pumpAndSettle();
      expect(find.text('Vos événements'), findsWidgets);
      expect(find.byType(EventsTabPage).hitTestable(), findsOneWidget);

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-email')), findsOneWidget);
    });

    testWidgets('Retour depuis un onglet ramène à l’Accueil, puis quitte', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Billets').last);
      await tester.pumpAndSettle();
      expect(find.byType(TicketsTabPage).hitTestable(), findsOneWidget);

      await pressBack(tester);
      expect(find.byType(HomePage).hitTestable(), findsOneWidget);
      expect(exits, 0);

      await pressBack(tester);
      expect(find.byKey(const Key('exit-confirm')), findsOneWidget);
      await pressBack(tester);
      expect(exits, 1);
    });

    testWidgets('déconnexion depuis le Profil', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-sign-out')));
      await tester.pumpAndSettle();
      expect(auth.signOutCalls, 1);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('« supprimer les animations » respecté', (tester) async {
      await pumpApp(tester, reduceMotion: true);
      await tester.tap(find.text('Profil').last);
      await tester.pump();
      // Sans animation, l'onglet est complet dès la première image.
      expect(find.byType(ProfilePage).hitTestable(), findsOneWidget);
    });
  });

  test('bannière d’accueil : texte blanc lisible sur tout le dégradé', () {
    for (final color in const [TicketSurColors.navy, Color(0xFF0B4A8F)]) {
      expect(
        contrastRatio(TicketSurColors.white, color),
        greaterThanOrEqualTo(7),
      );
    }
  });
}
