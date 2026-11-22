import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';

import '../helpers/goldens.dart';
import '../helpers/showcase.dart';

/// Captures de référence (lot 4-9) : 12 écrans clés en clair et en sombre,
/// avec les vraies polices. Une différence visuelle non voulue fait échouer
/// la vérification.
///
/// Après un changement voulu, régénérer les images :
/// `flutter test --update-goldens test/goldens` ; les nouvelles images
/// font partie de la PR.
void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens();
  });
  tearDown(() => appLocaleTag = 'fr');

  final screens = <String, (String, bool)>{
    'explorer': (AppRoutes.discover, false),
    'fiche_publique': (AppRoutes.publicEvent('p1'), false),
    'connexion': (AppRoutes.signIn, false),
    'accueil': (AppRoutes.home, true),
    'evenements': (AppRoutes.events, true),
    'tableau_de_bord': (AppRoutes.eventDashboard('e2'), true),
    'tickets': (AppRoutes.tickets, true),
    // La fiche s'ouvre depuis la liste (elle reçoit le ticket choisi).
    'fiche_ticket': ('${AppRoutes.tickets}#ticket-tk-0', true),
    'verdicts': (AppRoutes.verdictPreview, true),
    'mon_ticket': (AppRoutes.walletTicket('w1'), true),
    'profil': (AppRoutes.profile, true),
    'console': (AppRoutes.console, true),
  };

  for (final mode in ['light', 'dark']) {
    for (final MapEntry(key: name, value: (path, signedIn))
        in screens.entries) {
      testWidgets('capture $mode : $name', (tester) async {
        tester.view.physicalSize = const Size(720, 1600);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: await showcaseOverrides(signedIn: signedIn, mode: mode),
            child: const TicketSurApp(),
          ),
        );
        await tester.pumpAndSettle();
        final parts = path.split('#');
        final route = parts.first;
        final tap = parts.length > 1 ? parts.last : null;
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(route);
        await tester.pumpAndSettle();
        if (tap != null) {
          await tester.tap(find.byKey(Key(tap)));
          await tester.pumpAndSettle();
        }
        await tester.pumpAndSettle();
        await precacheVisibleImages(tester);
        await expectLater(
          find.byType(TicketSurApp),
          matchesGoldenFile('references/${name}_$mode.png'),
        );
      });
    }
  }
}
