import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_event_setup_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_ticket_repository.dart';

TicketSummary _ticket(String id, int batch, TicketStatus status) =>
    TicketSummary(
      id: id,
      reference: 'TS-AAAA-${id.toUpperCase().padLeft(4, '0')}',
      categoryId: 'c1',
      categoryName: 'VIP',
      status: status,
      issuedAt: DateTime.utc(2030, 6, 1, batch),
      redeemedAt: status == TicketStatus.redeemed
          ? DateTime.utc(2030, 6, 20)
          : null,
      batchNumber: batch,
    );

void main() {
  const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');

  test('lot lu depuis le serveur ; limites à 1 000', () {
    final batch = TicketBatch.fromJson(const {
      'id': 'b1',
      'number': 3,
      'created_at': '2030-06-01T12:40:00Z',
      'created_by_name': 'Awa',
      'total': 250,
      'issued': 248,
      'redeemed': 1,
      'revoked': 1,
      'named': 0,
      'categories': ['Standard', 'VIP'],
    });
    expect(batch.number, 3);
    expect(batch.categories, ['Standard', 'VIP']);
    expect(maxBatchSize, 1000);
    expect(maxNamedBatchSize, 1000);
    final summary = TicketSummary.fromJson(const {
      'id': 't1',
      'public_reference': 'TS-AAAA-0001',
      'category_name': 'VIP',
      'status': 'issued',
      'issued_at': '2030-06-01T12:00:00Z',
      'batch_number': 2,
    });
    expect(summary.batchNumber, 2);
  });

  group('écrans', () {
    late FakeTicketRepository tickets;
    late List<List<SharedFile>> shared;

    setUp(() {
      tickets = FakeTicketRepository([
        _ticket('t5', 2, TicketStatus.issued),
        _ticket('t4', 2, TicketStatus.issued),
        _ticket('t3', 2, TicketStatus.redeemed),
        _ticket('t2', 1, TicketStatus.issued),
        _ticket('t1', 1, TicketStatus.issued),
      ]);
      tickets.batchList.addAll([
        TicketBatch(
          id: 'batch-1',
          number: 1,
          createdAt: DateTime.utc(2030, 6, 1, 1),
          createdBy: 'Awa',
          total: 2,
        ),
        TicketBatch(
          id: 'batch-2',
          number: 2,
          createdAt: DateTime.utc(2030, 6, 1, 2),
          createdBy: 'Awa',
          total: 3,
        ),
      ]);
      shared = [];
    });

    Future<void> openTickets(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: FakeEventRepository([
              testEvent(
                id: 'e1',
                title: 'Gala',
                status: EventStatus.published,
                startsAt: DateTime.utc(2030, 6, 20, 20),
              ),
            ]),
            setup: FakeEventSetupRepository(
              categories: const [
                TicketCategory(
                  id: 'c1',
                  eventId: 'e1',
                  name: 'VIP',
                  capacity: 100,
                  issued: 5,
                  redeemed: 1,
                ),
              ],
            ),
            tickets: tickets,
            shareFiles: (files, {text}) async => shared.add(files),
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .go(AppRoutes.tickets);
      await tester.pumpAndSettle();
    }

    Future<void> openBatches(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('tickets-batches')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('batches-sheet')), findsOneWidget);
    }

    testWidgets('lots : liste, filtre par lot, numéro sur chaque ligne', (
      tester,
    ) async {
      await openTickets(tester);
      // Le numéro du lot figure sur la ligne du ticket.
      expect(find.textContaining('Lot 2'), findsWidgets);
      await openBatches(tester);
      expect(find.text('Lot 2 · 3 tickets'), findsOneWidget);
      expect(find.text('Lot 1 · 2 tickets'), findsOneWidget);
      // Le plus récent en premier.
      expect(
        tester.getTopLeft(find.byKey(const Key('batch-2'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('batch-1'))).dy),
      );
      expect(find.text('2 valables · 0 utilisés · 0 annulés'), findsOneWidget);

      await tester.tap(find.byKey(const Key('batch-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tickets-batch-filter')), findsOneWidget);
      expect(tickets.batchQueries.last, 'batch-1');
      expect(find.byKey(const Key('ticket-t1')), findsOneWidget);
      expect(find.byKey(const Key('ticket-t5')), findsNothing);

      // Effacer le filtre : tous les lots.
      await tester.tap(find.byTooltip('Tous les lots'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tickets-batch-filter')), findsNothing);
      expect(find.byKey(const Key('ticket-t5')), findsOneWidget);
    });

    testWidgets('sélectionner tout un lot, puis la planche de ses valables', (
      tester,
    ) async {
      await openTickets(tester);
      await openBatches(tester);
      await tester.tap(find.byKey(const Key('batch-select-2')));
      await tester.pumpAndSettle();
      expect(tickets.calls, contains('batchTickets batch-2'));
      expect(find.byKey(const Key('tickets-selection-bar')), findsOneWidget);
      expect(find.text('3 sélectionnés'), findsOneWidget);
      // Le lot reste affiché.
      expect(find.byKey(const Key('tickets-batch-filter')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tickets-bulk-sheet')));
      await tester.pumpAndSettle();
      // Le ticket déjà utilisé n'est pas imprimé.
      expect(find.text('2 tickets à imprimer'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('print-generate')));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
      expect(tickets.calls, contains('export t4,t5'));
      expect(shared.single.single.name, 'Planche-2.pdf');
    });

    testWidgets('planche directe depuis la liste des lots', (tester) async {
      await openTickets(tester);
      await openBatches(tester);
      await tester.tap(find.byKey(const Key('batch-print-1')));
      await tester.pumpAndSettle();
      expect(find.text('2 tickets à imprimer'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('print-generate')));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
      expect(tickets.calls, contains('export t1,t2'));
      // Rien n'est resté sélectionné.
      expect(find.byKey(const Key('tickets-selection-bar')), findsNothing);
    });

    testWidgets('lot affiché : « Tout sélectionner » prend le lot entier', (
      tester,
    ) async {
      await openTickets(tester);
      await openBatches(tester);
      await tester.tap(find.byKey(const Key('batch-2')));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('ticket-t5')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selection-all')));
      await tester.pumpAndSettle();
      expect(tickets.calls, contains('batchTickets batch-2'));
      expect(find.text('3 sélectionnés'), findsOneWidget);
    });

    testWidgets('nouvelle émission : un nouveau lot', (tester) async {
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-issue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('issue-quick-1000')));
      await tester.pumpAndSettle();
      expect(find.textContaining('De 1 à 1 000 par lot'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('issue-quantity')), '1001');
      await tester.pumpAndSettle();
      expect(
        find.text('Saisissez un nombre entre 1 et 1 000.'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const Key('issue-quantity')), '2');
      await tester.pumpAndSettle();
      final submit = find.byKey(const Key('issue-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(tickets.calls, contains('issue c1 2'));
      expect(tickets.batchList.last.number, 3);
    });
  });
}
