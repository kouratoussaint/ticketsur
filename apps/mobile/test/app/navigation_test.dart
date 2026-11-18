import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/organizations/presentation/create_organization_page.dart';
import 'package:ticketsur/features/profile/profile_page.dart';
import 'package:ticketsur/features/team/presentation/team_tab_page.dart';
import 'package:ticketsur/features/tickets/presentation/tickets_tab_page.dart';
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
      for (final label in ['Accueil', 'Événements', 'Tickets', 'Équipe']) {
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
      expect(find.byKey(const Key('events-empty')), findsOneWidget);
      expect(find.byType(EventsTabPage).hitTestable(), findsOneWidget);

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-email')), findsOneWidget);
    });

    testWidgets('Retour revient à l’onglet précédent, pas à l’Accueil', (
      tester,
    ) async {
      await pumpApp(tester);
      for (final tab in ['Événements', 'Tickets', 'Profil']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }
      expect(find.byType(ProfilePage).hitTestable(), findsOneWidget);

      await pressBack(tester);
      expect(find.byType(TicketsTabPage).hitTestable(), findsOneWidget);
      await pressBack(tester);
      expect(find.byType(EventsTabPage).hitTestable(), findsOneWidget);
      await pressBack(tester);
      expect(find.byType(HomePage).hitTestable(), findsOneWidget);
      expect(exits, 0);

      await pressBack(tester);
      expect(find.byKey(const Key('exit-confirm')), findsOneWidget);
      await pressBack(tester);
      expect(exits, 1);
    });

    testWidgets('un onglet revisité ne se répète pas dans l’historique', (
      tester,
    ) async {
      await pumpApp(tester);
      // Accueil → Tickets → Équipe → Tickets : Retour → Équipe → Accueil.
      for (final tab in ['Tickets', 'Équipe', 'Tickets']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }
      await pressBack(tester);
      expect(find.byType(TeamTabPage).hitTestable(), findsOneWidget);
      await pressBack(tester);
      expect(find.byType(HomePage).hitTestable(), findsOneWidget);
      expect(exits, 0);
    });

    testWidgets('page empilée sur un onglet : Retour la ferme d’abord', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-switch-org')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('org-create-another')));
      await tester.pumpAndSettle();
      expect(find.byType(CreateOrganizationPage), findsOneWidget);

      await pressBack(tester);
      expect(find.byType(CreateOrganizationPage), findsNothing);
      expect(find.byType(ProfilePage).hitTestable(), findsOneWidget);
      expect(exits, 0);
    });

    testWidgets('déconnexion depuis le Profil', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('profile-sign-out')));
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

  group('onglets réellement visibles (défaut constaté sur appareil)', () {
    setUp(
      () => auth = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
      ),
    );

    /// Opacité effective de l'onglet contenant [page] (fondu du conteneur).
    double opacityOf(WidgetTester tester, Type page) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byType(page),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    const tabs = {
      'Accueil': HomePage,
      'Événements': EventsTabPage,
      'Tickets': TicketsTabPage,
      'Équipe': TeamTabPage,
      'Profil': ProfilePage,
    };

    testWidgets(
      'chaque aller-retour entre onglets affiche le bon onglet seul',
      (tester) async {
        await pumpApp(tester);
        // Ordres croissants ET décroissants : le défaut ne touchait que les
        // retours vers un onglet situé plus à gauche.
        for (final target in [
          'Profil',
          'Accueil',
          'Équipe',
          'Événements',
          'Tickets',
          'Accueil',
        ]) {
          await tester.tap(find.text(target).last);
          await tester.pumpAndSettle();
          for (final MapEntry(key: label, value: page) in tabs.entries) {
            // Onglet jamais ouvert : pas encore construit.
            if (find.byType(page).evaluate().isEmpty) {
              continue;
            }
            expect(
              opacityOf(tester, page),
              label == target ? 1 : 0,
              reason: 'après « $target », onglet « $label »',
            );
          }
        }
      },
    );

    testWidgets('Retour depuis Profil : l’Accueil est visible, Profil effacé', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(opacityOf(tester, HomePage), 1);
      expect(opacityOf(tester, ProfilePage), 0);
    });
  });

  testWidgets(
    'l’application se déclare responsable de Retour auprès du système',
    (tester) async {
      final claims = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
            claims.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      auth = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
      );
      await pumpApp(tester);
      await tester.tap(find.text('Tickets').last);
      await tester.pumpAndSettle();
      expect(claims, isNotEmpty);
      expect(claims, everyElement(isTrue));
    },
  );

  test('bannière d’accueil : texte blanc lisible sur tout le dégradé', () {
    for (final color in const [TicketSurColors.navy, Color(0xFF0B4A8F)]) {
      expect(
        contrastRatio(TicketSurColors.white, color),
        greaterThanOrEqualTo(7),
      );
    }
  });
}
