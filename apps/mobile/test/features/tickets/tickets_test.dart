import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/data/supabase_ticket_repository.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_detail_page.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_event_setup_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_ticket_repository.dart';

void main() {
  group('domaine', () {
    test('codes serveur', () {
      for (final (code, failure) in [
        ('event_not_published', TicketFailure.eventNotPublished),
        ('category_capacity_exceeded', TicketFailure.categoryCapacityExceeded),
        ('event_capacity_exceeded', TicketFailure.eventCapacityExceeded),
        ('ticket_not_found', TicketFailure.notFound),
        ('export_params_invalid', TicketFailure.invalid),
      ]) {
        expect(
          mapTicketError(PostgrestException(message: code, code: '22023')),
          failure,
          reason: code,
        );
      }
      expect(
        mapTicketError(
          const PostgrestException(message: 'Quantité', code: '22023'),
        ),
        TicketFailure.invalid,
      );
    });

    test('le jeton n’apparaît jamais dans toString', () {
      final secret = TicketSecret(
        ticketId: 't',
        reference: 'TS-AAAA-0001',
        token: fakeToken(1),
        categoryName: 'VIP',
      );
      expect(secret.toString(), isNot(contains(fakeToken(1))));
    });

    test('texte PDF : accents gardés, symboles hors jeu remplacés', () {
      expect(pdfSafe('Événement « été » à Bobo'), 'Événement « été » à Bobo');
      expect(pdfSafe('A → B 🎉'), 'A - B ?');
      expect(pdfSafe('l’entrée – 20:00…'), "l'entrée - 20:00...");
    });

    test('PDF : une page par billet, QR inclus', () async {
      await initializeDateFormatting('fr');
      final bytes = await buildTicketsPdf(
        event: testEvent(title: 'Gala → été'),
        organizationName: 'Faso Événements',
        tickets: [
          for (var i = 1; i <= 3; i++)
            TicketSecret(
              ticketId: 't$i',
              reference: 'TS-AAAA-000$i',
              token: fakeToken(i),
              categoryName: 'Standard',
            ),
        ],
      );
      final text = latin1.decode(bytes, allowInvalid: true);
      expect(text.startsWith('%PDF'), isTrue);
      expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 3);
    });
  });

  group('onglet Billets', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late FakeEventRepository events;
    late FakeEventSetupRepository setup;
    late FakeTicketRepository tickets;
    late List<List<SharedFile>> shared;

    Future<void> openTickets(
      WidgetTester tester, {
      MemberRole role = MemberRole.owner,
    }) async {
      shared = [];
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([
              Organization(
                id: testOrganization.id,
                name: testOrganization.name,
                slug: testOrganization.slug,
                role: role,
              ),
            ]),
            events: events,
            setup: setup,
            tickets: tickets,
            shareFiles: (files, {text}) async => shared.add(files),
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Billets'),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    setUp(() {
      events = FakeEventRepository([
        testEvent(id: 'e1', title: 'Gala', status: EventStatus.published),
      ]);
      setup = FakeEventSetupRepository(
        categories: const [
          TicketCategory(
            id: 'c1',
            eventId: 'e1',
            name: 'VIP',
            capacity: 100,
            issued: 4,
            redeemed: 1,
          ),
        ],
      );
      tickets = FakeTicketRepository();
    });

    testWidgets('aucun événement publié : invitation à publier', (
      tester,
    ) async {
      events = FakeEventRepository([testEvent(id: 'd1')]); // brouillon
      await openTickets(tester);
      expect(find.byKey(const Key('tickets-no-event')), findsOneWidget);
      expect(find.byKey(const Key('tickets-issue')), findsNothing);
    });

    testWidgets('contrôleur : billets gérés par les organisateurs', (
      tester,
    ) async {
      await openTickets(tester, role: MemberRole.controller);
      expect(find.byKey(const Key('tickets-controller')), findsOneWidget);
    });

    testWidgets('émettre un lot puis le partager en PDF', (tester) async {
      await openTickets(tester);
      expect(find.text('4 émis · 1 entrés'), findsOneWidget);
      expect(find.byKey(const Key('tickets-empty')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tickets-issue')));
      await tester.pumpAndSettle();
      expect(find.textContaining('96 restants'), findsOneWidget);
      await tester.tap(find.byKey(const Key('issue-quick-10')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('issue-quantity')), '3');
      await tapVisible(tester, find.byKey(const Key('issue-submit')));

      expect(tickets.calls, ['issue c1 3']);
      expect(find.text('3 billets émis'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('issue-share-pdf')));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
      expect(shared, hasLength(1));
      final file = shared.single.single;
      expect(file.name, 'Billets-3.pdf');
      expect(file.mimeType, 'application/pdf');
      expect(latin1.decode(file.bytes).startsWith('%PDF'), isTrue);

      await tapVisible(tester, find.byKey(const Key('issue-see')));
      expect(find.byKey(const Key('ticket-tk-1')), findsOneWidget);
      expect(find.byKey(const Key('ticket-tk-3')), findsOneWidget);
    });

    testWidgets('refus serveur : quota atteint', (tester) async {
      tickets.nextFailure = TicketFailure.categoryCapacityExceeded;
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-issue')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('issue-submit')));
      expect(find.text('Quota de la catégorie atteint.'), findsOneWidget);
    });

    testWidgets('billet émis dans la session : QR affiché sans ré-export', (
      tester,
    ) async {
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-issue')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('issue-submit')));
      await tapVisible(tester, find.byKey(const Key('issue-see')));
      expect(find.byType(TicketDetailPage), findsOneWidget);
      expect(find.byKey(const Key('ticket-qr')), findsOneWidget);
      expect(tickets.calls.where((c) => c.startsWith('export')), isEmpty);
    });

    testWidgets('billet plus ancien : QR sur demande, ré-export journalisé', (
      tester,
    ) async {
      tickets = FakeTicketRepository([
        TicketSummary(
          id: 'old',
          reference: 'TS-OLDD-0001',
          categoryName: 'VIP',
          status: TicketStatus.issued,
          issuedAt: DateTime.utc(2029, 12),
        ),
      ])..tokens['old'] = fakeToken(7);
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('ticket-old')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-qr')), findsNothing);
      expect(
        find.text(
          "Le retéléchargement est inscrit au journal de l'organisation.",
        ),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('ticket-show-qr')));
      expect(tickets.calls, ['export old']);
      expect(find.byKey(const Key('ticket-qr')), findsOneWidget);
      expect(find.byKey(const Key('ticket-share-image')), findsOneWidget);
    });

    testWidgets('annuler un billet avec motif', (tester) async {
      tickets = FakeTicketRepository([
        TicketSummary(
          id: 'b1',
          reference: 'TS-BBBB-0001',
          categoryName: 'VIP',
          status: TicketStatus.issued,
          issuedAt: DateTime.utc(2029, 12),
        ),
      ]);
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('ticket-b1')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('ticket-revoke')));
      await tester.enterText(
        find.byKey(const Key('ticket-revoke-reason')),
        'Doublon',
      );
      await tester.tap(find.byKey(const Key('ticket-revoke-confirm')));
      await tester.pumpAndSettle();
      expect(tickets.calls, ['revoke b1 Doublon']);
      expect(find.text('Billet annulé'), findsWidgets);
      expect(find.byKey(const Key('ticket-revoke')), findsNothing);
      expect(find.byKey(const Key('ticket-show-qr')), findsNothing);
    });

    testWidgets('filtre « Utilisés »', (tester) async {
      tickets = FakeTicketRepository([
        TicketSummary(
          id: 'u1',
          reference: 'TS-UUUU-0001',
          categoryName: 'VIP',
          status: TicketStatus.redeemed,
          issuedAt: DateTime.utc(2029, 12),
          redeemedAt: DateTime.utc(2030, 1, 1, 20),
          redeemedCheckpoint: 'Entrée',
        ),
        TicketSummary(
          id: 'v1',
          reference: 'TS-VVVV-0001',
          categoryName: 'VIP',
          status: TicketStatus.issued,
          issuedAt: DateTime.utc(2029, 12),
        ),
      ]);
      await openTickets(tester);
      expect(find.byKey(const Key('tickets-count')), findsOneWidget);
      expect(find.text('2 sur 2'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tickets-filter-redeemed')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-u1')), findsOneWidget);
      expect(find.byKey(const Key('ticket-v1')), findsNothing);
      expect(find.textContaining('Entrée'), findsOneWidget);
    });
  });
}
