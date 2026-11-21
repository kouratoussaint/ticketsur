import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/features/announcements/domain/announcement.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_accounts_repository.dart';
import '../../helpers/fake_admin_events_repository.dart';
import '../../helpers/fake_admin_orgs_repository.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_admin_tools_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_support_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'toussaint@tikeo.bf');

  group('domaine', () {
    test('recherche globale lue ; filtre du journal par adresse', () {
      final result = GlobalSearchResult.fromJson(const {
        'accounts': [
          {'id': 'u2', 'name': 'Awa', 'email': 'a@b.bf', 'status': 'disabled'},
        ],
        'organizations': [
          {'id': 'o1', 'name': 'Kwabo', 'status': 'active', 'closed': true},
        ],
        'events': [
          {
            'id': 'e1',
            'title': 'Gala',
            'status': 'in_progress',
            'starts_at': '2026-12-24T20:00:00Z',
          },
        ],
        'tickets': <Object>[],
      });
      expect(result.accounts.single.active, isFalse);
      expect(result.organizations.single.closed, isTrue);
      expect(result.events.single.status, EventStatus.inProgress);
      expect(result.tickets, isEmpty);
      expect(result.isEmpty, isFalse);
      expect(const GlobalSearchResult().isEmpty, isTrue);

      const scope = AuditScope(eventId: 'e1', label: 'Gala');
      expect(scope.toQuery(), {'evenement': 'e1', 'nom': 'Gala'});
      expect(AuditScope.fromQuery(scope.toQuery()), scope);
      expect(const AuditScope().isEmpty, isTrue);

      expect(
        AdminAccountsFailure.fromCode('message_no_recipients'),
        AdminAccountsFailure.messageNoRecipients,
      );
      expect(
        AdminAccountsFailure.fromCode('message_days_invalid'),
        AdminAccountsFailure.messageInvalid,
      );
      final announcement = Announcement.fromJson(const {
        'id': 'a1',
        'title': 'Porte Nord',
        'body': 'Entrée par la porte Nord.',
        'level': 'info',
        'starts_at': '2026-11-21T10:00:00Z',
        'audiences': <Object>[],
        'target_kind': 'event',
        'target_name': 'Gala',
      });
      expect(announcement.targeted, isTrue);
      expect(announcement.targetName, 'Gala');
    });
  });

  group('écrans', () {
    late FakeAdminRepository admin;
    late FakeAdminAccountsRepository accounts;
    late FakeAdminOrgsRepository orgs;
    late FakeAdminEventsRepository events;
    late FakeAdminToolsRepository tools;
    FakeAnnouncementRepository? announcements;

    setUp(() {
      admin = FakeAdminRepository(admin: true);
      accounts = FakeAdminAccountsRepository(
        accounts: {'u-awa': accountDetail()},
      );
      orgs = FakeAdminOrgsRepository();
      events = FakeAdminEventsRepository();
      tools = FakeAdminToolsRepository();
      announcements = null;
    });

    Future<void> openApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            admin: admin,
            adminAccounts: accounts,
            adminOrgs: orgs,
            adminEvents: events,
            adminTools: tools,
            announcements: announcements,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    void go(WidgetTester tester, String path) =>
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);

    Future<void> tap(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    Future<void> writeMessage(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key('message-title')),
        'Porte Nord',
      );
      await tester.enterText(
        find.byKey(const Key('message-body')),
        'Entrée par la porte Nord.',
      );
    }

    testWidgets('recherche globale : sections et ouverture d’une fiche', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.console);
      await tester.pumpAndSettle();
      await tap(tester, 'console-search');
      expect(find.byKey(const Key('console-search-idle')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('console-search-field')),
        'k',
      );
      await tester.tap(find.byKey(const Key('console-search-submit')));
      await tester.pumpAndSettle();
      expect(find.text('De 2 à 60 caractères.'), findsOneWidget);
      expect(tools.calls, isEmpty);

      await tester.enterText(
        find.byKey(const Key('console-search-field')),
        'kwabo',
      );
      await tester.tap(find.byKey(const Key('console-search-submit')));
      await tester.pumpAndSettle();
      expect(tools.calls, ['search kwabo']);
      for (final section in [
        'accounts',
        'organizations',
        'events',
        'tickets',
      ]) {
        expect(find.byKey(Key('console-search-$section')), findsOneWidget);
      }
      await tap(tester, 'console-search-event-e1');
      expect(find.byKey(const Key('event-admin-detail')), findsOneWidget);
    });

    testWidgets('recherche sans résultat', (tester) async {
      tools.result = const GlobalSearchResult();
      await openApp(tester);
      go(tester, '${AppRoutes.consoleSearch}?q=zzz');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-search-empty')), findsOneWidget);
    });

    testWidgets('message à un compte : conversation du support', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleAccount('u-awa'));
      await tester.pumpAndSettle();
      await tap(tester, 'account-message');
      expect(find.textContaining('dans « Support »'), findsOneWidget);
      expect(find.byKey(const Key('message-days-7')), findsNothing);
      await tester.tap(find.byKey(const Key('message-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('message-error')), findsOneWidget);
      await writeMessage(tester);
      await tester.tap(find.byKey(const Key('message-submit')));
      await tester.pumpAndSettle();
      expect(tools.calls.last, 'message account u-awa Porte Nord 7');
      expect(find.text('Message envoyé à 1 personne'), findsOneWidget);
    });

    testWidgets('message aux membres d’une structure, 30 jours', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleOrganization('o1'));
      await tester.pumpAndSettle();
      await tap(tester, 'org-message');
      await writeMessage(tester);
      await tester.tap(find.byKey(const Key('message-days-30')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('message-submit')));
      await tester.pumpAndSettle();
      expect(tools.calls.last, 'message organization o1 Porte Nord 30');
      expect(find.text('Message envoyé à 12 personnes'), findsOneWidget);
    });

    testWidgets('message aux détenteurs : personne de relié', (tester) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleEvent('e1'));
      await tester.pumpAndSettle();
      await tap(tester, 'event-admin-message');
      await writeMessage(tester);
      tools.failure = AdminAccountsFailure.messageNoRecipients;
      await tester.tap(find.byKey(const Key('message-submit')));
      await tester.pumpAndSettle();
      final error = tester.widget<Text>(find.byKey(const Key('message-error')));
      expect(error.data, contains('Aucun destinataire'));
      expect(find.byKey(const Key('message-sheet')), findsOneWidget);
    });

    testWidgets('rôle finance : pas de message, journal oui', (tester) async {
      accounts.meValue = AdminMe(
        role: AdminRole.finance,
        permissions: permissionsOf(AdminRole.finance),
        mfaEnrolled: true,
      );
      await openApp(tester);
      go(tester, AppRoutes.consoleAccount('u-awa'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-message')), findsNothing);
      expect(find.byKey(const Key('account-journal')), findsOneWidget);
    });

    testWidgets('journal filtré depuis une fiche, puis tout le journal', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleEvent('e1'));
      await tester.pumpAndSettle();
      await tap(tester, 'event-admin-journal');
      expect(find.text('Filtré : Concert de Noël'), findsOneWidget);
      expect(admin.auditScopes.last.eventId, 'e1');
      await tester.tap(find.byTooltip('Tout le journal'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-audit-scope')), findsNothing);
      expect(admin.auditScopes.last.isEmpty, isTrue);
    });

    testWidgets('journal par administrateur', (tester) async {
      accounts.admins = [
        const PlatformAdmin(
          id: 'adm2',
          displayName: 'Moussa Support',
          role: AdminRole.support,
        ),
      ];
      await openApp(tester);
      go(tester, AppRoutes.consoleJournal);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-audit-admin')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-audit-admin-adm2')));
      await tester.pumpAndSettle();
      expect(admin.auditScopes.last.actorId, 'adm2');
      expect(find.text('Filtré : Moussa Support'), findsOneWidget);
    });

    testWidgets('annonces : message réservé, sans modification', (
      tester,
    ) async {
      announcements = FakeAnnouncementRepository(
        all: [
          Announcement(
            id: 'a9',
            title: 'Porte Nord',
            body: 'Entrée par la porte Nord.',
            important: false,
            startsAt: DateTime.now().toUtc().add(const Duration(days: 1)),
            scheduled: true,
            targetKind: 'event',
            targetName: 'Concert de Noël',
          ),
        ],
      );
      await openApp(tester);
      go(tester, AppRoutes.consoleAnnouncements);
      await tester.pumpAndSettle();
      expect(
        find.text('Réservé aux détenteurs de « Concert de Noël »'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('console-announcement-edit-a9')),
        findsNothing,
      );
    });
  });
}
