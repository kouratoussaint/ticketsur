import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/organizations/data/supabase_organization_repository.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/create_organization_page.dart';
import 'package:ticketsur/features/scanner/presentation/control_home_page.dart';

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

  group('compte classique (sans structure)', () {
    setUp(() => orgs = FakeOrganizationRepository());

    testWidgets('Explorer, Favoris, Profil ; aucun module de promoteur', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byType(CreateOrganizationPage), findsNothing);
      expect(find.byType(ExplorePage).hitTestable(), findsOneWidget);
      final bar = find.byType(NavigationBar);
      for (final label in ['Explorer', 'Favoris', 'Profil']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
        );
      }
      for (final label in ['Organiser', 'Tickets', 'Équipe', 'Contrôle']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsNothing,
        );
      }
    });

    Future<void> openCreate(WidgetTester tester) async {
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-become-promoter')));
      await tester.pumpAndSettle();
      expect(find.byType(CreateOrganizationPage), findsOneWidget);
    }

    testWidgets('nom trop court refusé localement', (tester) async {
      await pumpApp(tester);
      await openCreate(tester);
      await tester.enterText(find.byKey(const Key('org-name')), ' A ');
      await tester.tap(find.byKey(const Key('org-create-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text("Saisissez un nom d'au moins 2 caractères"),
        findsOneWidget,
      );
      expect(orgs.createCalls, isEmpty);
    });

    testWidgets('devenir promoteur : la structure créée ouvre l’espace', (
      tester,
    ) async {
      await pumpApp(tester);
      await openCreate(tester);
      await tester.enterText(
        find.byKey(const Key('org-name')),
        '  Nuits Sacrées  ',
      );
      await tester.tap(find.byKey(const Key('org-create-submit')));
      await tester.pumpAndSettle();
      expect(orgs.createCalls, ['  Nuits Sacrées  ']);
      // Barre du promoteur ; l'Accueil affiche la nouvelle structure.
      final bar = find.byType(NavigationBar);
      expect(
        find.descendant(of: bar, matching: find.text('Organiser')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: bar, matching: find.text('Organiser')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      final title = tester.widget<Text>(find.byKey(const Key('home-org-name')));
      expect(title.data, 'Nuits Sacrées');
      expect(find.textContaining('Propriétaire').hitTestable(), findsOneWidget);
    });

    testWidgets('limite atteinte : message clair', (tester) async {
      orgs.nextCreateFailure = OrganizationFailure.limitReached;
      await pumpApp(tester);
      await openCreate(tester);
      await tester.enterText(find.byKey(const Key('org-name')), 'Sixième');
      await tester.tap(find.byKey(const Key('org-create-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Vous avez atteint la limite de 5 structures.'),
        findsOneWidget,
      );
      expect(find.byType(CreateOrganizationPage), findsOneWidget);
    });
  });

  testWidgets('chargement en échec : bouton Réessayer', (tester) async {
    orgs = FakeOrganizationRepository([testOrganization])
      ..nextLoadFailure = OrganizationFailure.network;
    await pumpApp(tester);
    expect(find.text('Impossible de charger vos structures.'), findsOneWidget);
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
      // Contrôleur dans « Gala de Bobo » : barre réduite, onglet Contrôle.
      expect(find.byType(ControlHomePage).hitTestable(), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Événements'),
        ),
        findsNothing,
      );
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

  testWidgets('autre compte sur le même téléphone : liste rechargée', (
    tester,
  ) async {
    orgs = FakeOrganizationRepository([testOrganization]);
    await pumpApp(tester);
    expect(orgs.loadCalls, 1);

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Compte'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'autre@exemple.bf',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'motdepasse-solide',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(orgs.loadCalls, 2, reason: 'aucune liste réutilisée d’un compte');
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
