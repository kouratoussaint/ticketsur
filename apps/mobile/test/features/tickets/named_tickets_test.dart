import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/tickets/data/supabase_ticket_repository.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_event_setup_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_ticket_repository.dart';

void main() {
  group('titulaire : mêmes règles que le serveur', () {
    test('téléphone : formats courants vers l’international', () {
      expect(normalizePhone('70 11 22 33'), '+22670112233');
      expect(normalizePhone('0022670112233'), '+22670112233');
      expect(normalizePhone('+225 07 08 09 10 11'), '+2250708091011');
      expect(normalizePhone('+226-70.11.22.33'), '+22670112233');
      expect(normalizePhone('   '), isNull);
      expect(normalizePhone(null), isNull);
    });

    test('nom et e-mail normalisés, champs vides → au porteur', () {
      final result = validateHolder(
        name: '  Awa   Ouédraogo ',
        phone: '70 11 22 33',
        email: ' AWA@Exemple.BF ',
      );
      expect(result.problem, isNull);
      expect(
        result.holder,
        const TicketHolder(
          name: 'Awa Ouédraogo',
          phone: '+22670112233',
          email: 'awa@exemple.bf',
        ),
      );
      final empty = validateHolder(name: ' ', phone: '');
      expect(empty.holder!.isEmpty, isTrue);
    });

    test('erreurs : nom trop long, téléphone ou e-mail invalides', () {
      expect(
        validateHolder(name: 'a' * 121).problem,
        HolderProblem.nameTooLong,
      );
      // Caractères comptés comme char_length (pas en UTF-16).
      expect(validateHolder(name: '🎉' * 120).problem, isNull);
      expect(validateHolder(phone: '12').problem, HolderProblem.phoneInvalid);
      expect(
        validateHolder(phone: '+0 70 11 22 33').problem,
        HolderProblem.phoneInvalid,
      );
      expect(
        validateHolder(email: 'pas-un-mail').problem,
        HolderProblem.emailInvalid,
      );
    });

    test('liste : titulaire lu, conservé à l’annulation', () {
      final ticket = TicketSummary.fromJson(const {
        'id': 't1',
        'public_reference': 'TS-AAAA-0001',
        'category_name': 'VIP',
        'status': 'issued',
        'issued_at': '2030-01-01T12:00:00Z',
        'holder_name': 'Awa',
        'holder_phone': '+22670112233',
        'holder_email': null,
      });
      expect(ticket.holder.name, 'Awa');
      expect(ticket.holder.phone, '+22670112233');
      expect(ticket.withStatus(TicketStatus.revoked).holder.name, 'Awa');
      expect(ticket.withHolder(TicketHolder.none).holder.isEmpty, isTrue);
    });

    test('codes serveur des titulaires', () {
      TicketFailure map(String code) =>
          mapTicketError(PostgrestException(message: code, code: '22023'));
      expect(map('holder_name_invalid'), TicketFailure.holderNameInvalid);
      expect(map('holder_phone_invalid'), TicketFailure.holderPhoneInvalid);
      expect(map('holder_email_invalid'), TicketFailure.holderEmailInvalid);
      expect(map('ticket_not_editable'), TicketFailure.notEditable);
      expect(map('issue_rows_invalid'), TicketFailure.invalid);
      expect(map('category_not_found'), TicketFailure.invalid);
    });

    test('PDF : ticket nominatif généré', () async {
      await initializeDateFormatting('fr');
      final bytes = await buildTicketsPdf(
        event: testEvent(title: 'Gala'),
        organizationName: 'Faso Événements',
        tickets: [
          TicketSecret(
            ticketId: 't1',
            reference: 'TS-AAAA-0001',
            token: fakeToken(1),
            categoryName: 'VIP',
            holderName: 'Awa Ouédraogo → 🎉',
          ),
        ],
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  group('écrans', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late FakeEventRepository events;
    late FakeEventSetupRepository setup;
    late FakeTicketRepository tickets;

    Future<void> openTickets(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: events,
            setup: setup,
            tickets: tickets,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Tickets'),
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
          TicketCategory(id: 'c1', eventId: 'e1', name: 'VIP', capacity: 100),
        ],
      );
      tickets = FakeTicketRepository()..categoryNames = const {'c1': 'VIP'};
    });

    testWidgets('un ticket nominatif : nom normalisé, imprimé sur le ticket', (
      tester,
    ) async {
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-issue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('issue-holder')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('holder-name')),
        ' Awa  Ouédraogo ',
      );
      await tester.enterText(find.byKey(const Key('holder-phone')), '70112233');
      await tapVisible(tester, find.byKey(const Key('issue-submit')));

      expect(tickets.calls, ['issueNamed 1']);
      expect(tickets.namedRows.single.categoryId, 'c1');
      expect(
        tickets.namedRows.single.holder,
        const TicketHolder(name: 'Awa Ouédraogo', phone: '+22670112233'),
      );

      await tapVisible(tester, find.byKey(const Key('issue-see')));
      expect(find.text('Titulaire : Awa Ouédraogo'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('ticket-holder-name'))).data,
        'Awa Ouédraogo',
      );
    });

    testWidgets('téléphone invalide : signalé avant l’envoi', (tester) async {
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-issue')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('holder-phone')), '12');
      await tapVisible(tester, find.byKey(const Key('issue-submit')));
      expect(tickets.calls, isEmpty);
      expect(find.text('Numéro de téléphone invalide.'), findsOneWidget);

      // Corriger efface l'erreur.
      await tester.enterText(find.byKey(const Key('holder-phone')), '');
      await tester.pumpAndSettle();
      expect(find.text('Numéro de téléphone invalide.'), findsNothing);
    });

    testWidgets(
      'lot de plusieurs tickets : pas de titulaire, émission anonyme',
      (tester) async {
        await openTickets(tester);
        await tester.tap(find.byKey(const Key('tickets-issue')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('issue-quick-10')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('issue-holder')), findsNothing);
        await tapVisible(tester, find.byKey(const Key('issue-submit')));
        expect(tickets.calls, ['issue c1 10']);
      },
    );

    testWidgets('liste : le nom d’abord, recherche par nom', (tester) async {
      tickets.tickets.addAll([
        TicketSummary(
          id: 'tk-a',
          reference: 'TS-AAAA-0101',
          categoryName: 'VIP',
          status: TicketStatus.issued,
          issuedAt: DateTime.utc(2030),
          holder: const TicketHolder(name: 'Issa Sawadogo'),
        ),
        TicketSummary(
          id: 'tk-b',
          reference: 'TS-AAAA-0102',
          categoryName: 'VIP',
          status: TicketStatus.issued,
          issuedAt: DateTime.utc(2030),
        ),
      ]);
      await openTickets(tester);
      expect(find.text('Issa Sawadogo'), findsOneWidget);
      // Statut dans sa pastille (direction artistique) : la ligne garde
      // la référence et la catégorie.
      expect(find.text('TS-AAAA-0101 · VIP'), findsOneWidget);
      // En-tête plus haut : la seconde ligne est plus bas.
      await tester.scrollUntilVisible(
        find.text('TS-AAAA-0102'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('TS-AAAA-0102'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('tickets-search')), 'issa');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-tk-a')), findsOneWidget);
      expect(find.byKey(const Key('ticket-tk-b')), findsNothing);
    });

    testWidgets('fiche : ajouter puis modifier le titulaire', (tester) async {
      tickets.tickets.add(
        TicketSummary(
          id: 'tk-a',
          reference: 'TS-AAAA-0101',
          categoryName: 'VIP',
          status: TicketStatus.issued,
          issuedAt: DateTime.utc(2030),
        ),
      );
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('ticket-tk-a')));
      await tester.pumpAndSettle();
      expect(find.text('Aucun titulaire : ticket au porteur'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('ticket-holder-edit')));
      await tester.enterText(find.byKey(const Key('holder-name')), 'Moussa');
      await tester.enterText(
        find.byKey(const Key('holder-email')),
        'MOUSSA@exemple.bf',
      );
      await tapVisible(tester, find.byKey(const Key('holder-save')));

      expect(tickets.calls, ['setHolder tk-a Moussa']);
      expect(find.byKey(const Key('holder-save')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('ticket-holder-name'))).data,
        'Moussa',
      );
      expect(find.text('moussa@exemple.bf'), findsOneWidget);
    });

    testWidgets('fiche : ticket utilisé, titulaire figé', (tester) async {
      tickets.tickets.add(
        TicketSummary(
          id: 'tk-r',
          reference: 'TS-AAAA-0103',
          categoryName: 'VIP',
          status: TicketStatus.redeemed,
          issuedAt: DateTime.utc(2030),
          redeemedAt: DateTime.utc(2030, 1, 2),
          redeemedCheckpoint: 'Porte A',
          holder: const TicketHolder(name: 'Awa'),
        ),
      );
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('ticket-tk-r')));
      await tester.pumpAndSettle();
      expect(find.text('Titulaire : Awa'), findsOneWidget);
      expect(find.byKey(const Key('ticket-holder-edit')), findsNothing);
    });
  });
}
