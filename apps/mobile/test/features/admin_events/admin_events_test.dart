import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_events/domain/admin_events.dart';
import 'package:ticketsur/features/admin_orgs/domain/admin_orgs.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_accounts_repository.dart';
import '../../helpers/fake_admin_events_repository.dart';
import '../../helpers/fake_admin_orgs_repository.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'toussaint@tikeo.bf');

  group('domaine', () {
    test('fiche d’un événement lue ; états proposés', () {
      final event = AdminEventDetail.fromJson(const {
        'id': 'e1',
        'title': 'Gala',
        'status': 'in_progress',
        'starts_at': '2026-12-24T20:00:00Z',
        'ends_at': '2026-12-25T02:00:00Z',
        'timezone': 'Africa/Ouagadougou',
        'organization': {'id': 'o1', 'name': 'Kwabo', 'closed': false},
        'categories': [
          {'id': 'c1', 'name': 'VIP', 'issued': 10, 'admitted': 3},
        ],
        'checkpoints': ['Nord'],
        'tickets_total': 10,
        'tickets_to_cancel': 7,
        'holders_to_notify': 2,
        'actions': <Object>[],
      });
      expect(event.categories.single.admitted, 3);
      expect(event.checkpoints, ['Nord']);
      expect(event.nextStatuses, [EventStatus.closed, EventStatus.cancelled]);
      expect(event.editable, isTrue);
      expect(event.trashable, isFalse);
      expect(
        adminEventDetail().nextStatuses,
        isNot(contains(EventStatus.draft)),
      );
      expect(
        adminEventDetail(status: EventStatus.draft, ticketsTotal: 0).trashable,
        isTrue,
      );
    });

    test('fiche d’un ticket lue, jamais de QR ; erreurs', () {
      final ticket = AdminTicketDetail.fromJson(const {
        'id': 't1',
        'public_reference': 'TS-AB12-CD34',
        'status': 'redeemed',
        'issued_at': '2026-11-20T09:00:00Z',
        'entries_used': 1,
        'first_entry_at': '2026-12-24T20:10:00Z',
        'first_entry_door': 'Nord',
        'event': {
          'id': 'e1',
          'title': 'Gala',
          'starts_at': '2026-12-24T20:00:00Z',
        },
        'organization': {'id': 'o1', 'name': 'Kwabo'},
        'category': {'name': 'VIP', 'is_invitation': true},
        'deliveries': [
          {'channel': 'sms', 'sent_at': '2026-11-20T10:00:00Z'},
        ],
        'actions': <Object>[],
      });
      expect(ticket.status, TicketStatus.redeemed);
      expect(ticket.firstEntryDoor, 'Nord');
      expect(ticket.isInvitation, isTrue);
      expect(ticket.deliveries.single.channel, 'sms');
      expect(
        AdminAccountsFailure.fromCode('event_invalid_transition'),
        AdminAccountsFailure.eventTransition,
      );
      expect(
        AdminAccountsFailure.fromCode('billing_option_public_catalog'),
        AdminAccountsFailure.billingBlocked,
      );
      expect(
        AdminAccountsFailure.fromCode('holder_phone_invalid'),
        AdminAccountsFailure.holderInvalid,
      );
      expect(
        AdminAccountsFailure.fromCode('event_tagline_invalid'),
        AdminAccountsFailure.eventFieldInvalid,
      );
    });
  });

  group('écrans', () {
    late FakeAdminRepository admin;
    late FakeAdminAccountsRepository accounts;
    late FakeAdminOrgsRepository orgs;
    late FakeAdminEventsRepository events;

    setUp(() {
      admin = FakeAdminRepository(admin: true);
      accounts = FakeAdminAccountsRepository();
      orgs = FakeAdminOrgsRepository();
      events = FakeAdminEventsRepository();
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
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    void go(WidgetTester tester, String path) =>
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);

    Future<void> openEvent(WidgetTester tester, [String id = 'e1']) async {
      go(tester, AppRoutes.consoleEvents);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('console-event-$id')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event-admin-detail')), findsOneWidget);
    }

    Future<void> confirmWithReason(WidgetTester tester, String reason) async {
      await tester.enterText(
        find.byKey(const Key('account-action-reason')),
        reason,
      );
      await tester.tap(find.byKey(const Key('account-action-confirm')));
      await tester.pumpAndSettle();
    }

    Future<void> tapAction(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    testWidgets('console : entrées Événements et Tickets', (tester) async {
      await openApp(tester);
      go(tester, AppRoutes.console);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-nav-events')), findsOneWidget);
      expect(find.byKey(const Key('console-nav-tickets')), findsOneWidget);
    });

    testWidgets('fiche : catégories, portes, tickets', (tester) async {
      await openApp(tester);
      await openEvent(tester);
      expect(find.byKey(const Key('event-admin-category-c1')), findsOneWidget);
      expect(find.text('Portes : Entrée principale'), findsOneWidget);
      expect(find.textContaining('Émis : 120'), findsOneWidget);
      // Publié avec tickets : pas de retour en brouillon.
      expect(find.byKey(const Key('event-admin-status-draft')), findsNothing);
      expect(
        find.byKey(const Key('event-admin-status-cancelled')),
        findsOneWidget,
      );
    });

    testWidgets('modifier le titre, motif obligatoire', (tester) async {
      await openApp(tester);
      await openEvent(tester);
      await tapAction(tester, 'event-admin-edit');
      await tester.enterText(
        find.byKey(const Key('account-field-title')),
        'Concert de Noël 2026',
      );
      await confirmWithReason(tester, 'Faute de frappe');
      expect(
        events.calls.last,
        'update e1 Concert de Noël 2026 Faute de frappe false',
      );
      expect(events.edits.last.startsAt, DateTime.utc(2026, 12, 24, 20));
      expect(events.edits.last.isPublic, isNull);
    });

    testWidgets('dates et public : même fiche, champs gardés', (tester) async {
      await openApp(tester);
      await openEvent(tester);
      await tapAction(tester, 'event-admin-dates');
      await tester.tap(find.byKey(const Key('event-dates-submit')));
      await tester.pumpAndSettle();
      await confirmWithReason(tester, 'Report demandé');
      expect(events.edits.last.endsAt, DateTime.utc(2026, 12, 25));
      expect(events.edits.last.venue, 'Maison du peuple');

      await tapAction(tester, 'event-admin-public');
      await confirmWithReason(tester, 'Contenu à revoir');
      expect(events.edits.last.isPublic, isFalse);
    });

    testWidgets('annuler : conséquences affichées, tickets annulés', (
      tester,
    ) async {
      await openApp(tester);
      await openEvent(tester);
      await tapAction(tester, 'event-admin-status-cancelled');
      expect(
        find.textContaining('100 tickets non entrés annulés'),
        findsOneWidget,
      );
      expect(find.textContaining('12 détenteurs prévenus'), findsOneWidget);
      await confirmWithReason(tester, 'Salle fermée');
      expect(events.calls.last, 'status e1 cancelled Salle fermée');
      expect(
        find.descendant(
          of: find.byKey(const Key('event-admin-status')),
          matching: find.text('Annulé'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('déplacer vers une autre structure', (tester) async {
      admin.orgs.add(adminOrganization(id: 'o2', name: 'Faso Live'));
      await openApp(tester);
      await openEvent(tester);
      await tapAction(tester, 'event-admin-move');
      await tester.enterText(find.byKey(const Key('move-search')), 'Faso');
      await tester.tap(find.byKey(const Key('move-find')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('move-org-o1')), findsNothing);
      await tester.tap(find.byKey(const Key('move-org-o2')));
      await tester.pumpAndSettle();
      await confirmWithReason(tester, 'Mauvaise structure');
      expect(events.calls.last, 'move e1 o2 Mauvaise structure');
    });

    testWidgets('brouillon sans ticket : corbeille puis restaurer', (
      tester,
    ) async {
      events.eventDetails['e2'] = adminEventDetail(
        id: 'e2',
        title: 'Brouillon',
        status: EventStatus.draft,
        ticketsTotal: 0,
      );
      await openApp(tester);
      await openEvent(tester, 'e2');
      await tapAction(tester, 'event-admin-trash');
      await confirmWithReason(tester, 'Doublon');
      expect(events.calls.last, 'trash e2 Doublon');
      expect(find.byKey(const Key('event-admin-trashed')), findsOneWidget);
      expect(find.byKey(const Key('event-admin-edit')), findsNothing);
      await tapAction(tester, 'event-admin-restore');
      await confirmWithReason(tester, 'Erreur');
      expect(events.calls.last, 'restore e2 Erreur');
    });

    testWidgets('émettre : seulement si le réglage est activé', (tester) async {
      await openApp(tester);
      await openEvent(tester);
      expect(find.byKey(const Key('event-admin-issue')), findsNothing);
    });

    testWidgets('émettre des tickets à la place du promoteur', (tester) async {
      accounts.meValue = AdminMe(
        role: AdminRole.superAdmin,
        permissions: permissionsOf(AdminRole.superAdmin),
        mfaEnrolled: true,
        adminIssueTickets: true,
      );
      await openApp(tester);
      await openEvent(tester);
      await tapAction(tester, 'event-admin-issue');
      await tester.tap(find.byKey(const Key('issue-cat-c2')));
      await tester.enterText(find.byKey(const Key('issue-count')), '5');
      await tester.enterText(
        find.byKey(const Key('issue-reason')),
        'Promoteur sans réseau',
      );
      await tester.tap(find.byKey(const Key('issue-submit')));
      await tester.pumpAndSettle();
      expect(events.calls.last, 'issue e1 c2 5 Promoteur sans réseau');
    });

    testWidgets('rôle support : fiche en lecture', (tester) async {
      accounts.meValue = AdminMe(
        role: AdminRole.support,
        permissions: permissionsOf(AdminRole.support),
        mfaEnrolled: true,
      );
      await openApp(tester);
      await openEvent(tester);
      expect(find.byKey(const Key('event-admin-edit')), findsNothing);
      expect(
        find.byKey(const Key('event-admin-status-cancelled')),
        findsNothing,
      );
    });

    testWidgets('tickets : recherche, fiche, titulaire, annulation', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleTickets);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('console-ticket-search')),
        'ai',
      );
      await tester.tap(find.byKey(const Key('console-ticket-find')));
      await tester.pumpAndSettle();
      expect(find.text('De 3 à 60 caractères.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('console-ticket-search')),
        'aïcha',
      );
      await tester.tap(find.byKey(const Key('console-ticket-find')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-ticket-t1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-admin-detail')), findsOneWidget);
      expect(find.text('Dans « Mes tickets » de Aïcha S.'), findsOneWidget);

      await tapAction(tester, 'ticket-admin-holder');
      await tester.enterText(
        find.byKey(const Key('account-field-name')),
        'Moussa Kaboré',
      );
      await confirmWithReason(tester, 'Erreur de saisie');
      expect(
        events.calls.last,
        'holder t1 Moussa Kaboré +22670123456 Erreur de saisie',
      );

      await tapAction(tester, 'ticket-admin-revoke');
      expect(find.byKey(const Key('account-action-notify')), findsOneWidget);
      await confirmWithReason(tester, 'Fraude');
      expect(events.calls.last, 'revoke t1 Fraude false');
      expect(find.byKey(const Key('ticket-admin-revoke')), findsNothing);
    });

    testWidgets('corbeille : restaurer un brouillon', (tester) async {
      final now = DateTime.now().toUtc();
      orgs.trashItems.add(
        TrashItem(
          id: 'e9',
          name: 'Brouillon oublié',
          ownerName: 'Kwabo Événements',
          kind: TrashKind.event,
          trashedAt: now,
          purgeDueAt: now.add(const Duration(days: 30)),
        ),
      );
      await openApp(tester);
      go(tester, AppRoutes.consoleTrash);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('trash-restore-e9')));
      await tester.pumpAndSettle();
      await confirmWithReason(tester, 'Supprimé par erreur');
      expect(events.calls, ['restore e9 Supprimé par erreur']);
      expect(orgs.calls, isEmpty);
    });
  });
}
