import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/configuration_error_app.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_preview_page.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  testWidgets('démarre sur l’accueil Tikéo et ouvre la galerie', (
    tester,
  ) async {
    // Comme au démarrage réel : préférences de l'appareil (thème choisi).
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Votre événement en un clic'), findsOneWidget);
    final signIn = tester.widget<FilledButton>(
      find.byKey(const Key('welcome-sign-in')),
    );
    expect(signIn.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('welcome-verdict-preview')));
    await tester.pumpAndSettle();
    expect(find.byType(VerdictPreviewPage), findsOneWidget);
    expect(find.text('Ticket déjà utilisé'), findsOneWidget);
  });

  testWidgets('configuration refusée : écran explicite, aucun appel', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ConfigurationErrorApp(
        problem: "Clé secrète interdite dans l'application",
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Configuration manquante'), findsOneWidget);
    expect(
      find.text("Clé secrète interdite dans l'application"),
      findsOneWidget,
    );
  });
}
