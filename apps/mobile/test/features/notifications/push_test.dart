import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/notifications/data/push_receipts.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/support/domain/support.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_push.dart';
import '../../helpers/fake_support_repository.dart';

const _requestId = '0b8f6a52-6b55-4c41-9a5d-2f2f7f6f1a01';

void main() {
  const user = AuthUser(id: 'u1', email: 'awa@exemple.bf');

  group('domaine', () {
    test('sujets selon le compte et les rôles', () {
      expect(pushTopicsFor(signedIn: false, organizations: const []), {
        PushTopic.visitors,
      });
      expect(pushTopicsFor(signedIn: true, organizations: const []), {
        PushTopic.users,
      });
      expect(
        pushTopicsFor(
          signedIn: true,
          organizations: const [
            testOrganization,
            Organization(
              id: 'o2',
              name: 'Autre',
              slug: 'autre',
              role: MemberRole.controller,
            ),
          ],
        ),
        {PushTopic.promoters, PushTopic.controllers},
      );
    });

    test('seules les pages internes connues s’ouvrent', () {
      expect(isSafePushRoute('/support/$_requestId'), isTrue);
      expect(isSafePushRoute('/postes?evenement=$_requestId'), isTrue);
      expect(isSafePushRoute('/'), isTrue);
      // ADR 0055 : équipe, fiche du promoteur, console.
      expect(isSafePushRoute('/equipe'), isTrue);
      expect(isSafePushRoute('/evenements/$_requestId'), isTrue);
      expect(isSafePushRoute('/console/support/$_requestId'), isTrue);
      expect(isSafePushRoute('/console/signalements'), isTrue);
      expect(isSafePushRoute('/console/encaisser/demande/$_requestId'), isTrue);
      expect(isSafePushRoute('/console/comptes'), isFalse);
      expect(isSafePushRoute('https://exemple.com'), isFalse);
      expect(isSafePushRoute('/console'), isFalse);
      expect(isSafePushRoute('/parametres'), isTrue);
      // Rappels avant l'événement (migration 3500).
      expect(isSafePushRoute('/portefeuille'), isTrue);
      expect(isSafePushRoute('/mon-ticket/$_requestId'), isTrue);
      expect(isSafePushRoute('/mon-ticket/../console'), isFalse);
      expect(isSafePushRoute(null), isFalse);
    });
  });

  group('appareil', () {
    late FakePushService push;
    late FakePushRepository devices;

    setUp(() {
      push = FakePushService();
      devices = FakePushRepository();
    });

    Future<void> openApp(
      WidgetTester tester, {
      AuthUser? signedIn = user,
      List<Organization> organizations = const [],
      FakeSupportRepository? support,
      bool admin = false,
      Map<String, Object> preferences = const {},
      FakeTrayNotifier? tray,
    }) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: signedIn),
            organizations: FakeOrganizationRepository(organizations),
            push: push,
            pushDevices: devices,
            support: support,
            admin: FakeAdminRepository(admin: admin),
            preferences: preferences,
            tray: tray,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('compte classique : appareil enregistré, sujet « users »', (
      tester,
    ) async {
      await openApp(tester);
      expect(devices.registered, {'appareil-de-test'});
      expect(push.topics, {'tikeo_users', 'tikeo_city_all'});
    });

    testWidgets('promoteur : sujet « promoters »', (tester) async {
      await openApp(tester, organizations: const [testOrganization]);
      expect(push.topics, {'tikeo_promoters', 'tikeo_city_all'});
    });

    testWidgets('sans compte : sujet « visitors », aucun appareil', (
      tester,
    ) async {
      await openApp(tester, signedIn: null);
      expect(push.topics, {'tikeo_visitors', 'tikeo_city_all'});
      expect(devices.registered, isEmpty);
    });

    testWidgets('couper dans les Paramètres : sujets et appareil oubliés', (
      tester,
    ) async {
      await openApp(tester);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.settings)
          .ignore();
      await tester.pumpAndSettle();
      final toggle = find.byKey(const Key('settings-push'));
      await tester.scrollUntilVisible(
        toggle,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(push.topics, isEmpty);
      expect(devices.registered, isEmpty);
      expect(push.calls, contains('deleteToken'));
      expect(find.text('Coupées sur ce téléphone'), findsOneWidget);
    });

    testWidgets('notifications refusées : état expliqué', (tester) async {
      push.granted = false;
      await openApp(tester);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.settings)
          .ignore();
      await tester.pumpAndSettle();
      final status = find.byKey(const Key('settings-push-status'));
      await tester.scrollUntilVisible(
        status,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.textContaining('Refusées'), findsOneWidget);
      expect(devices.registered, isEmpty);
    });

    // Notification de test : dans la console (administrateurs), plus dans
    // les Paramètres (#16).
    Future<void> openTestTile(WidgetTester tester) async {
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.console)
          .ignore();
      await tester.pumpAndSettle();
      final tile = find.byKey(const Key('console-push-test'));
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
    }

    testWidgets('notification de test : jeton relu, attente côté serveur', (
      tester,
    ) async {
      await openApp(tester, admin: true);
      await openTestTile(tester);
      devices.calls.clear();
      await tester.tap(find.byKey(const Key('console-push-test')));
      await tester.pump();
      await tester.pump();
      expect(devices.calls, ['register', 'sendTest', 'flush 8s']);
      expect(find.byKey(const Key('settings-push-test-sent')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('notification de test refusée : message expliqué', (
      tester,
    ) async {
      devices.testFailure = PushTestFailure.rateLimited;
      await openApp(tester, admin: true);
      await openTestTile(tester);
      await tester.tap(find.byKey(const Key('console-push-test')));
      await tester.pump();
      await tester.pump();
      expect(
        find.text("Trop d'essais : réessayez dans une heure."),
        findsOneWidget,
      );
      expect(devices.calls, isNot(contains('flush')));
      await tester.pumpAndSettle();
    });

    testWidgets('paramètres : plus de notification de test', (tester) async {
      await openApp(tester, admin: true);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.settings)
          .ignore();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-push-test')), findsNothing);
    });

    testWidgets('message reçu application ouverte : « Voir » ouvre la page', (
      tester,
    ) async {
      final support = FakeSupportRepository(
        requests: [
          supportRequest(id: _requestId, status: SupportStatus.answered),
        ],
      );
      await openApp(tester, support: support);
      push.receive(
        const PushMessage(
          title: 'Support Tikéo',
          body: 'Nouvelle réponse : Ticket introuvable',
          route: '/support/$_requestId',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Nouvelle réponse'), findsOneWidget);
      await tester.tap(find.text('Voir'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('support-thread')), findsOneWidget);
    });

    testWidgets(
      'notification touchée : page ouverte ; adresse inconnue ignorée',
      (tester) async {
        final support = FakeSupportRepository(
          requests: [supportRequest(id: _requestId)],
        );
        await openApp(tester, support: support);
        push.tap('https://exemple.com');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('support-thread')), findsNothing);
        push.tap('/support/$_requestId');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('support-thread')), findsOneWidget);
      },
    );

    testWidgets('accusés : reçus en arrière-plan envoyés à l’ouverture', (
      tester,
    ) async {
      await openApp(
        tester,
        preferences: {
          // Jeton déjà enregistré et messages notés par l'arrière-plan.
          'notifications.token': 'appareil-de-test',
          pushReceiptsPreference: ['41', '42'],
          pushLastReceivedPreference: '2030-05-31T18:00:00.000Z',
        },
      );
      expect(devices.acks.single.$1, [41, 42]);
      expect(devices.acks.single.$2, 'appareil-de-test');

      // Reçu au premier plan : confirmé tout de suite.
      push.receive(
        const PushMessage(title: 'Tikéo', body: 'Pack activé', id: '43'),
      );
      await tester.pumpAndSettle();
      expect(devices.acks.last.$1, [43]);

      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.settings)
          .ignore();
      await tester.pumpAndSettle();
      final last = find.byKey(const Key('settings-push-last'));
      await tester.scrollUntilVisible(
        last,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester.widget<Text>(last).data,
        startsWith('Dernière notification reçue sur ce téléphone : '),
      );
    });

    testWidgets('jamais rien reçu : dit dans les Paramètres', (tester) async {
      await openApp(tester);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.settings)
          .ignore();
      await tester.pumpAndSettle();
      final last = find.byKey(const Key('settings-push-last'));
      await tester.scrollUntilVisible(
        last,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester.widget<Text>(last).data,
        "Aucune notification reçue sur ce téléphone pour l'instant.",
      );
      expect(devices.acks, isEmpty);
    });

    testWidgets('nouveaux événements : ville de l’Explorer, favoris, réglage', (
      tester,
    ) async {
      await openApp(
        tester,
        signedIn: null,
        preferences: {
          'filters.device.explore.city': 'Bobo-Dioulasso',
          'favorites.events': jsonEncode([
            publicEvent(id: 'fav-1').toJson(),
            publicEvent(
              id: 'fav-old',
              startsAt: DateTime.utc(2020, 3, 5),
            ).toJson(),
          ]),
        },
      );
      expect(push.topics, {
        'tikeo_visitors',
        'tikeo_city_bobo_dioulasso',
        'tikeo_event_fav-1',
      });

      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.settings)
          .ignore();
      await tester.pumpAndSettle();
      final toggle = find.byKey(const Key('settings-push-new-events'));
      await tester.scrollUntilVisible(
        toggle,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.text("Publiés à Bobo-Dioulasso, la ville choisie dans l'Explorer"),
        findsOneWidget,
      );
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(push.topics, {'tikeo_visitors', 'tikeo_event_fav-1'});
    });

    testWidgets('app ouverte : notification dans la barre, sans bandeau', (
      tester,
    ) async {
      final tray = FakeTrayNotifier();
      await openApp(tester, tray: tray);
      push.receive(
        const PushMessage(
          title: 'Événement modifié',
          body: '« Concert » : nouvelle date',
          route: '/portefeuille',
          tag: 'evt-1',
        ),
      );
      await tester.pumpAndSettle();
      expect(tray.shown.single.tag, 'evt-1');
      expect(find.textContaining('nouvelle date'), findsNothing);
      // Touchée : la page s'ouvre.
      tray.tap('/portefeuille');
      await tester.pumpAndSettle();
      expect(
        GoRouter.of(tester.element(find.byType(Navigator).first)).state.uri
            .toString(),
        '/portefeuille',
      );
    });
  });
}
