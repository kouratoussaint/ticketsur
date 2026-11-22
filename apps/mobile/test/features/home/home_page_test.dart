import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/dashboard/presentation/event_dashboard_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/profile/domain/profile.dart';
import 'package:ticketsur/features/profile/profile_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dashboard_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_profile_repository.dart';

void main() {
  late FakeDashboardRepository dashboard;

  setUp(() {
    dashboard = FakeDashboardRepository(next: sampleDashboard(eventId: 'e2'));
  });

  Future<void> openHome(
    WidgetTester tester, {
    List<TicketEvent>? events,
    String displayName = 'Awa Ouédraogo',
  }) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(
            user: const AuthUser(id: 'u1', email: 'awa@faso.bf'),
          ),
          organizations: FakeOrganizationRepository([testOrganization]),
          profile: FakeProfileRepository(
            UserProfile(id: 'u1', displayName: displayName),
          ),
          events: FakeEventRepository(
            events ??
                [
                  testEvent(
                    id: 'e1',
                    title: 'Forum',
                    status: EventStatus.published,
                  ),
                  testEvent(
                    id: 'e2',
                    title: 'Nuit du jazz',
                    status: EventStatus.inProgress,
                  ),
                  testEvent(id: 'e3', title: 'Gala'),
                ],
          ),
          dashboard: dashboard,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('salutation par le prénom et initiales dans l’avatar', (
    tester,
  ) async {
    await openHome(tester);
    expect(textOf(tester, 'home-hello'), 'Bonjour Awa');
    expect(
      find.descendant(
        of: find.byKey(const Key('home-avatar')),
        matching: find.text('AO'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('home-avatar')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage).hitTestable(), findsOneWidget);
  });

  testWidgets('nom vide : « Bonjour » seul', (tester) async {
    await openHome(tester, displayName: '  ');
    expect(textOf(tester, 'home-hello'), 'Bonjour');
  });

  testWidgets(
    'l’événement en cours passe en tête, avec ses chiffres d’entrée',
    (tester) async {
      await openHome(tester);
      expect(find.byKey(const ValueKey('home-next-e2')), findsOneWidget);
      expect(textOf(tester, 'home-stat-admitted'), '42');
      expect(textOf(tester, 'home-stat-issued'), '120');
      expect(textOf(tester, 'home-stat-attendance'), formatPercent(0.35));
      // Les autres événements sont listés dessous, pas celui du bandeau.
      expect(find.byKey(const Key('home-event-e1')), findsOneWidget);
      expect(find.byKey(const Key('home-event-e3')), findsOneWidget);
      expect(find.byKey(const Key('home-event-e2')), findsNothing);
    },
  );

  testWidgets('le tableau de bord reprend la lecture de l’Accueil', (
    tester,
  ) async {
    // Point « En direct » animé en continu : animations réduites.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openHome(tester);
    expect(dashboard.calls, ['e2']);
    await tester.tap(find.byKey(const Key('home-dashboard')));
    await tester.pumpAndSettle();
    expect(find.byType(EventDashboardPage), findsOneWidget);
    expect(dashboard.calls, ['e2']);
  });

  testWidgets('chiffres indisponibles : le lien vers le tableau reste', (
    tester,
  ) async {
    dashboard.failure = DashboardFailure.network;
    await openHome(tester);
    expect(find.byKey(const Key('home-stat-admitted')), findsNothing);
    expect(find.byKey(const Key('home-dashboard')), findsOneWidget);
  });

  testWidgets('un événement de la liste ouvre sa fiche', (tester) async {
    await openHome(tester);
    await tester.tap(find.byKey(const Key('home-event-e1')));
    await tester.pumpAndSettle();
    expect(find.text('Forum'), findsWidgets);
    expect(find.byKey(const Key('home-event-e1')).hitTestable(), findsNothing);
  });

  testWidgets('« Entrés » et « Émis » ouvrent l’onglet Tickets filtré', (
    tester,
  ) async {
    await openHome(tester);
    bool chipSelected(String key) =>
        tester.widget<ChoiceChip>(find.byKey(Key(key))).selected;

    await tester.tap(find.byKey(const Key('home-stat-admitted')));
    await tester.pumpAndSettle();
    expect(chipSelected('tickets-filter-redeemed'), isTrue);

    // Retour à l'Accueil, puis « Émis » : tous les statuts, même onglet.
    await tester.tap(find.text('Organiser').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-stat-issued')));
    await tester.pumpAndSettle();
    expect(chipSelected('tickets-filter-all'), isTrue);
    expect(chipSelected('tickets-filter-redeemed'), isFalse);
  });

  testWidgets('tuile « En cours » : liste des événements filtrée', (
    tester,
  ) async {
    await openHome(tester);
    final tile = find.byKey(const Key('home-tile-live'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('event-card-e2')), findsOneWidget);
    expect(find.byKey(const Key('event-card-e1')), findsNothing);
  });
}
