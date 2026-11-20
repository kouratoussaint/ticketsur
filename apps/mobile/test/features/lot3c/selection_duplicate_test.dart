import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/events/presentation/duplicate_event_sheet.dart';
import 'package:ticketsur/features/home/first_steps_card.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_event_setup_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_ticket_repository.dart';

TicketSummary _ticket(String id, TicketStatus status) => TicketSummary(
  id: id,
  reference: 'TS-AAAA-${id.toUpperCase().padLeft(4, '0')}',
  categoryId: 'c1',
  categoryName: 'VIP',
  status: status,
  issuedAt: DateTime.utc(2030, 6),
  redeemedAt: status == TicketStatus.redeemed
      ? DateTime.utc(2030, 6, 20)
      : null,
  revokedAt: status == TicketStatus.revoked ? DateTime.utc(2030, 6, 2) : null,
);

void main() {
  const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');

  test('début proposé : une semaine après, jamais dans le passé', () {
    final source = testEvent(startsAt: DateTime.utc(2030, 6, 20, 20));
    expect(
      suggestedCopyStart(source, DateTime.utc(2030, 6)),
      DateTime.utc(2030, 6, 27, 20),
    );
    expect(
      suggestedCopyStart(source, DateTime.utc(2030, 7, 10)),
      DateTime.utc(2030, 7, 11, 20),
    );
  });

  group('écrans', () {
    late FakeEventRepository events;
    late FakeEventSetupRepository setup;
    late FakeTicketRepository tickets;
    late List<List<SharedFile>> shared;

    setUp(() {
      events = FakeEventRepository([
        testEvent(
          id: 'e1',
          title: 'Gala',
          status: EventStatus.published,
          startsAt: DateTime.utc(2030, 6, 20, 20),
        ),
      ]);
      setup = FakeEventSetupRepository(
        categories: const [
          TicketCategory(
            id: 'c1',
            eventId: 'e1',
            name: 'VIP',
            capacity: 100,
            issued: 3,
            redeemed: 1,
          ),
        ],
      );
      tickets = FakeTicketRepository([
        _ticket('t1', TicketStatus.issued),
        _ticket('t2', TicketStatus.issued),
        _ticket('t3', TicketStatus.redeemed),
      ]);
      shared = [];
    });

    Future<ProviderContainer> openApp(
      WidgetTester tester, {
      Organization organization = testOrganization,
      Map<String, Object> preferences = const {},
    }) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([organization]),
            events: events,
            setup: setup,
            tickets: tickets,
            shareFiles: (files, {text}) async => shared.add(files),
            preferences: preferences,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(TicketSurApp)),
      );
    }

    Future<void> go(WidgetTester tester, String path) async {
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
      await tester.pumpAndSettle();
    }

    testWidgets('sélection : appui long, tout sélectionner, annuler', (
      tester,
    ) async {
      await openApp(tester);
      await go(tester, AppRoutes.tickets);
      expect(find.byKey(const Key('tickets-selection-bar')), findsNothing);

      await tester.longPress(find.byKey(const Key('ticket-t1')));
      await tester.pumpAndSettle();
      expect(find.text('1 sélectionné'), findsOneWidget);
      expect(find.byKey(const Key('tickets-issue')), findsNothing);
      // En sélection, un appui simple coche au lieu d'ouvrir.
      await tester.tap(find.byKey(const Key('ticket-t3')));
      await tester.pumpAndSettle();
      expect(find.text('2 sélectionnés'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ticket-t3')));
      await tester.pumpAndSettle();
      expect(find.text('1 sélectionné'), findsOneWidget);

      await tester.tap(find.byKey(const Key('selection-all')));
      await tester.pumpAndSettle();
      expect(find.text('3 sélectionnés'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tickets-bulk-revoke')));
      await tester.pumpAndSettle();
      // Deux tickets valables sur trois : le ticket utilisé n'est pas compté.
      expect(find.text('Annuler 2 tickets ?'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('tickets-bulk-reason')),
        'Doublons',
      );
      await tester.tap(find.byKey(const Key('tickets-bulk-revoke-confirm')));
      await tester.pumpAndSettle();
      expect(tickets.calls, contains('revokeMany t1,t2 Doublons'));
      expect(find.text('2 tickets annulés.'), findsOneWidget);
      expect(find.byKey(const Key('tickets-selection-bar')), findsNothing);
    });

    testWidgets('sélection : PDF des seuls tickets valables', (tester) async {
      await openApp(tester);
      await go(tester, AppRoutes.tickets);
      await tester.longPress(find.byKey(const Key('ticket-t1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-t2')));
      await tester.tap(find.byKey(const Key('ticket-t3')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('tickets-bulk-pdf')));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
      expect(tickets.calls, contains('export t1,t2'));
      final file = shared.single.single;
      expect(file.name, 'Tickets-2.pdf');
      expect(latin1.decode(file.bytes).startsWith('%PDF'), isTrue);
    });

    testWidgets('sélection : planche A4 à imprimer', (tester) async {
      await openApp(tester);
      await go(tester, AppRoutes.tickets);
      await tester.longPress(find.byKey(const Key('ticket-t1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-t2')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('tickets-bulk-sheet')));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
      final file = shared.single.single;
      expect(file.name, 'Planche-2.pdf');
      final text = latin1.decode(file.bytes, allowInvalid: true);
      // Une seule page A4 pour deux tickets.
      expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 1);
    });

    testWidgets('sélection : Retour la quitte sans quitter l’écran', (
      tester,
    ) async {
      await openApp(tester);
      await go(tester, AppRoutes.tickets);
      await tester.longPress(find.byKey(const Key('ticket-t1')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tickets-selection-bar')), findsNothing);
      expect(find.byKey(const Key('ticket-t1')), findsOneWidget);
    });

    testWidgets('dupliquer un événement : copie en brouillon ouverte', (
      tester,
    ) async {
      await openApp(tester);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.eventDetail('e1'))
          .ignore();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-duplicate')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('duplicate-title')))
            .controller!
            .text,
        'Gala (copie)',
      );
      await tester.tap(find.byKey(const Key('duplicate-submit')));
      await tester.pumpAndSettle();
      final (source, title, start, end) = events.duplicateCalls.single;
      expect((source, title), ('e1', 'Gala (copie)'));
      expect(end.difference(start), const Duration(hours: 4));
      expect(start.weekday, DateTime.utc(2030, 6, 20).weekday);
      expect(start.isAfter(DateTime.now()), isTrue);
      // La copie est ouverte.
      expect(find.text('Gala (copie)'), findsWidgets);
      expect(find.text('Copie créée en brouillon.'), findsOneWidget);
    });

    testWidgets('gestionnaire : peut dupliquer', (tester) async {
      await openApp(
        tester,
        organization: const Organization(
          id: 'org-test',
          name: 'Organisation de test',
          slug: 'organisation-de-test',
          role: MemberRole.manager,
        ),
      );
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.eventDetail('e1'))
          .ignore();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event-duplicate')), findsOneWidget);
    });

    testWidgets('premiers pas : progression, raccourci, masquer', (
      tester,
    ) async {
      final container = await openApp(tester);
      expect(find.byKey(const Key('first-steps')), findsOneWidget);
      // Événement créé et publié, tickets émis ; ni contrôleur ni numéro.
      expect(find.text('3 sur 5'), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(const Key('first-step-event')))
            .onTap,
        isNull,
      );
      await tester.tap(find.byKey(const Key('first-steps-hide')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('first-steps')), findsNothing);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getBool(firstStepsHiddenKey('org-test')),
        isTrue,
      );
    });

    testWidgets('premiers pas : tout fait, rien n’apparaît', (tester) async {
      await openApp(
        tester,
        preferences: {firstStepsHiddenKey('org-test'): true},
      );
      expect(find.byKey(const Key('first-steps')), findsNothing);
    });
  });
}
