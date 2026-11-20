import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/support/domain/support.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
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
      expect(isSafePushRoute('https://exemple.com'), isFalse);
      expect(isSafePushRoute('/console'), isFalse);
      expect(isSafePushRoute('/parametres'), isTrue);
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
      expect(push.topics, {'tikeo_users'});
    });

    testWidgets('promoteur : sujet « promoters »', (tester) async {
      await openApp(tester, organizations: const [testOrganization]);
      expect(push.topics, {'tikeo_promoters'});
    });

    testWidgets('sans compte : sujet « visitors », aucun appareil', (
      tester,
    ) async {
      await openApp(tester, signedIn: null);
      expect(push.topics, {'tikeo_visitors'});
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

    Future<void> openTestTile(WidgetTester tester) async {
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.settings)
          .ignore();
      await tester.pumpAndSettle();
      final tile = find.byKey(const Key('settings-push-test'));
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
    }

    testWidgets('notification de test : jeton relu, attente côté serveur', (
      tester,
    ) async {
      await openApp(tester);
      await openTestTile(tester);
      devices.calls.clear();
      await tester.tap(find.byKey(const Key('settings-push-test')));
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
      await openApp(tester);
      await openTestTile(tester);
      await tester.tap(find.byKey(const Key('settings-push-test')));
      await tester.pump();
      await tester.pump();
      expect(
        find.text("Trop d'essais : réessayez dans une heure."),
        findsOneWidget,
      );
      expect(devices.calls, isNot(contains('flush')));
      await tester.pumpAndSettle();
    });

    testWidgets('sans compte : pas de notification de test', (tester) async {
      await openApp(tester, signedIn: null);
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
  });
}
