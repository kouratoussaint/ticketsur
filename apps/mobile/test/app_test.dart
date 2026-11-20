import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/configuration_error_app.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/presentation/sign_up_page.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_catalog_repository.dart';

void main() {
  testWidgets('démarre sur l’accueil Tikéo et ouvre l’inscription', (
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
          deviceLocalesProvider.overrideWithValue(const [Locale('fr')]),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Sans compte : l'Explorer, puis « Organiser » (présentation).
    expect(find.byType(ExplorePage), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Organiser'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Votre événement en un clic'), findsOneWidget);
    final signIn = tester.widget<OutlinedButton>(
      find.byKey(const Key('welcome-sign-in')),
    );
    expect(signIn.onPressed, isNotNull);

    // Plus d'aperçu des écrans ; créer un compte ou entrer un code.
    expect(find.byKey(const Key('welcome-verdict-preview')), findsNothing);
    expect(find.byKey(const Key('welcome-sign-up')), findsOneWidget);
    expect(find.byKey(const Key('welcome-code')), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcome-sign-up')));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpPage), findsOneWidget);
    expect(find.byKey(const Key('tikeo-logo')), findsOneWidget);
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
