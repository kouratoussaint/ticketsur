import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/organizations/data/supabase_organization_repository.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/create_organization_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_organization_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
  late FakeAuthRepository auth;
  late FakeOrganizationRepository orgs;

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> preferences = const {},
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: auth,
          organizations: orgs,
          preferences: preferences,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => auth = FakeAuthRepository(user: user));

  group('première connexion sans organisation', () {
    setUp(() => orgs = FakeOrganizationRepository());

    testWidgets('l’écran de création s’affiche d’office', (tester) async {
      await pumpApp(tester);
      expect(find.byType(CreateOrganizationPage), findsOneWidget);
      expect(find.text('Créer votre organisation'), findsOneWidget);
      expect(find.byKey(const Key('app-navigation-bar')), findsNothing);
    });

    testWidgets('nom trop court refusé localement', (tester) async {
      await pumpApp(tester);
      await tester.enterText(find.byKey(const Key('org-name')), ' A ');
      await tester.tap(find.byKey(const Key('org-create-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text("Saisissez un nom d'au moins 2 caractères"),
        findsOneWidget,
      );
      expect(orgs.createCalls, isEmpty);
    });

    testWidgets('création : entrée dans l’espace avec l’organisation', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.enterText(
        find.byKey(const Key('org-name')),
        '  Nuits Sacrées  ',
      );
      await tester.tap(find.byKey(const Key('org-create-submit')));
      await tester.pumpAndSettle();
      expect(orgs.createCalls, ['  Nuits Sacrées  ']);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(const Key('app-navigation-bar')), findsOneWidget);
      final title = tester.widget<Text>(find.byKey(const Key('home-org-name')));
      expect(title.data, 'Nuits Sacrées');
      expect(find.textContaining('Propriétaire'), findsOneWidget);
    });

    testWidgets('limite atteinte : message clair', (tester) async {
      orgs.nextCreateFailure = OrganizationFailure.limitReached;
      await pumpApp(tester);
      await tester.enterText(find.byKey(const Key('org-name')), 'Sixième');
      await tester.tap(find.byKey(const Key('org-create-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Vous avez atteint la limite de 5 organisations.'),
        findsOneWidget,
      );
      expect(find.byType(CreateOrganizationPage), findsOneWidget);
    });

    testWidgets('on peut se déconnecter sans créer d’organisation', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('org-first-sign-out')));
      await tester.pumpAndSettle();
      expect(auth.signOutCalls, 1);
      expect(find.text('Votre événement en un clic'), findsOneWidget);
    });
  });

  testWidgets('chargement en échec : bouton Réessayer', (tester) async {
    orgs = FakeOrganizationRepository([testOrganization])
      ..nextLoadFailure = OrganizationFailure.network;
    await pumpApp(tester);
    expect(
      find.text('Impossible de charger vos organisations.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('gate-retry')));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  group('plusieurs organisations', () {
    const second = Organization(
      id: 'org-2',
      name: 'Gala de Bobo',
      slug: 'gala-de-bobo',
      role: MemberRole.controller,
    );
    setUp(() => orgs = FakeOrganizationRepository([testOrganization, second]));

    testWidgets('changer d’organisation et s’en souvenir', (tester) async {
      await pumpApp(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('home-org-name'))).data,
        'Organisation de test',
      );

      await tester.tap(find.byKey(const Key('home-switch-org')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('org-option-gala-de-bobo')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('home-org-name'))).data,
        'Gala de Bobo',
      );
      expect(find.textContaining('Contrôleur'), findsOneWidget);
    });

    testWidgets('l’organisation mémorisée est reprise au démarrage', (
      tester,
    ) async {
      await pumpApp(tester, preferences: {'active_organization.u1': 'org-2'});
      expect(
        tester.widget<Text>(find.byKey(const Key('home-org-name'))).data,
        'Gala de Bobo',
      );
    });
  });

  group('traductions des erreurs serveur', () {
    final cases = <String, (Object, OrganizationFailure)>{
      '22023 nom invalide': (
        const PostgrestException(message: 'x', code: '22023'),
        OrganizationFailure.invalidName,
      ),
      '53400 limite': (
        const PostgrestException(message: 'x', code: '53400'),
        OrganizationFailure.limitReached,
      ),
      'autre code': (
        const PostgrestException(message: 'x', code: '42501'),
        OrganizationFailure.unknown,
      ),
    };
    for (final MapEntry(key: label, value: (error, expected))
        in cases.entries) {
      test(label, () => expect(mapOrganizationError(error), expected));
    }
  });

  group('Organization.fromJson', () {
    test('lit une ligne de my_organizations', () {
      final org = Organization.fromJson(const {
        'id': 'a',
        'name': 'Nuits Sacrées',
        'slug': 'nuits-sacrees',
        'role': 'manager',
      });
      expect(org.role, MemberRole.manager);
      expect(org.slug, 'nuits-sacrees');
    });

    test('rôle inconnu : le moins privilégié', () {
      expect(MemberRole.fromWire('superadmin'), MemberRole.controller);
    });
  });
}
