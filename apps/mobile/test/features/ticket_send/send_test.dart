import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/ticket_send/application/send_providers.dart';
import 'package:ticketsur/features/ticket_send/data/channel_ticket_sender.dart';
import 'package:ticketsur/features/ticket_send/domain/ticket_sender.dart';
import 'package:ticketsur/features/ticket_send/presentation/ticket_send_page.dart';
import 'package:ticketsur/features/tickets/data/supabase_ticket_repository.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_ticket_repository.dart';
import '../../helpers/fake_ticket_sender.dart';

TicketSummary _ticket(
  String id, {
  String? name,
  String? phone,
  String? email,
  TicketDelivery? delivered,
  TicketStatus status = TicketStatus.issued,
}) => TicketSummary(
  id: id,
  reference: 'TS-AAAA-${id.substring(id.length - 4)}',
  categoryName: 'VIP',
  status: status,
  issuedAt: DateTime.utc(2030),
  redeemedAt: status == TicketStatus.redeemed ? DateTime.utc(2030, 2) : null,
  holder: TicketHolder(name: name, phone: phone, email: email),
  lastDelivery: delivered,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('domaine', () {
    test('canaux : coordonnées requises, valeurs serveur', () {
      const phone = TicketHolder(phone: '+22670112233');
      const email = TicketHolder(email: 'a@b.bf');
      expect(DeliveryChannel.whatsapp.reaches(phone), isTrue);
      expect(DeliveryChannel.sms.reaches(phone), isTrue);
      expect(DeliveryChannel.email.reaches(phone), isFalse);
      expect(DeliveryChannel.email.reaches(email), isTrue);
      expect(DeliveryChannel.whatsapp.reaches(email), isFalse);
      expect(DeliveryChannel.fromWire('sms'), DeliveryChannel.sms);
      expect(DeliveryChannel.fromWire('pigeon'), isNull);
    });

    test('liste : dernier envoi lu, conservé par les copies', () {
      final ticket = TicketSummary.fromJson(const {
        'id': 't1',
        'public_reference': 'TS-AAAA-0001',
        'category_name': 'VIP',
        'status': 'issued',
        'issued_at': '2030-01-01T12:00:00Z',
        'last_delivery_channel': 'whatsapp',
        'last_delivery_at': '2030-01-02T09:30:00Z',
      });
      expect(ticket.lastDelivery?.channel, DeliveryChannel.whatsapp);
      expect(ticket.lastDelivery?.at, DateTime.utc(2030, 1, 2, 9, 30));
      expect(
        ticket.withHolder(TicketHolder.none).lastDelivery,
        ticket.lastDelivery,
      );
      final never = TicketSummary.fromJson(const {
        'id': 't2',
        'public_reference': 'TS-AAAA-0002',
        'category_name': 'VIP',
        'status': 'issued',
        'issued_at': '2030-01-01T12:00:00Z',
      });
      expect(never.lastDelivery, isNull);
      expect(
        mapTicketError(
          const PostgrestException(
            message: 'ticket_not_sendable',
            code: '55000',
          ),
        ),
        TicketFailure.notSendable,
      );
    });

    test('message : nom, événement, date, lieu ; jamais le jeton', () async {
      await initializeDateFormatting('fr');
      final l10n = AppLocalizationsFr();
      final event = testEvent(title: 'Gala', city: 'Bobo-Dioulasso');
      final named = ticketMessage(l10n, event, holderName: 'Awa');
      expect(
        named,
        startsWith('Bonjour Awa, voici votre ticket pour « Gala »'),
      );
      expect(named, contains('Palais des sports, Bobo-Dioulasso'));
      expect(named, isNot(contains('TS1.')));
      expect(
        ticketMessage(l10n, event),
        startsWith('Bonjour, voici votre ticket'),
      );
    });

    group('canal Android', () {
      const channel = MethodChannel('ticketsur/send');
      TestDefaultBinaryMessenger messenger() =>
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      late List<MethodCall> calls;
      late Object? Function(MethodCall) reply;

      setUp(() {
        calls = [];
        messenger().setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final value = reply(call);
          if (value is PlatformException) throw value;
          return value;
        });
      });
      tearDown(() => messenger().setMockMethodCallHandler(channel, null));

      Future<SendOutcome> send(DeliveryChannel to) =>
          const ChannelTicketSender().send(
            channel: to,
            holder: const TicketHolder(
              name: 'Awa',
              phone: '+22670112233',
              email: 'awa@exemple.bf',
            ),
            text: 'Bonjour',
            subject: 'Votre ticket',
            attachment: (
              bytes: Uint8List.fromList([1, 2]),
              name: 'Ticket.png',
              mimeType: 'image/png',
            ),
          );

      test('méthode par canal, arguments transmis', () async {
        reply = (_) => 'opened';
        expect(await send(DeliveryChannel.whatsapp), SendOutcome.opened);
        expect(calls.single.method, 'whatsapp');
        final args = calls.single.arguments as Map<Object?, Object?>;
        expect(args['phone'], '+22670112233');
        expect(args['text'], 'Bonjour');
        expect(args['fileName'], 'Ticket.png');
        expect(args['mimeType'], 'image/png');
        expect(args['bytes'], Uint8List.fromList([1, 2]));
        await send(DeliveryChannel.email);
        expect(calls.last.method, 'email');
        expect(
          (calls.last.arguments as Map<Object?, Object?>)['email'],
          'awa@exemple.bf',
        );
      });

      test('application absente, erreur native, réponse inconnue', () async {
        reply = (_) => 'app_missing';
        expect(await send(DeliveryChannel.sms), SendOutcome.appMissing);
        reply = (_) => PlatformException(code: 'send_failed');
        expect(await send(DeliveryChannel.sms), SendOutcome.failed);
        reply = (_) => 'bizarre';
        expect(await send(DeliveryChannel.sms), SendOutcome.failed);
      });
    });
  });

  group('écrans', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late FakeTicketRepository tickets;
    late FakeTicketSender sender;
    late FakeTicketRenderer renderer;

    Future<void> openTickets(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: FakeEventRepository([
              testEvent(id: 'e1', title: 'Gala', status: EventStatus.published),
            ]),
            tickets: tickets,
            sender: sender,
            renderer: renderer,
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
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> openDetail(WidgetTester tester, String id) async {
      await openTickets(tester);
      await tester.tap(find.byKey(Key('ticket-$id')));
      await tester.pumpAndSettle();
    }

    setUp(() async {
      await initializeDateFormatting('fr');
      tickets = FakeTicketRepository();
      sender = FakeTicketSender();
      renderer = FakeTicketRenderer();
    });

    testWidgets('fiche : WhatsApp avec l’image, puis envoi confirmé', (
      tester,
    ) async {
      tickets.tickets.add(
        _ticket(
          'tk-0001',
          name: 'Awa Ouédraogo',
          phone: '+22670112233',
          email: 'awa@exemple.bf',
        ),
      );
      await openDetail(tester, 'tk-0001');
      expect(find.byKey(const Key('ticket-send-whatsapp')), findsOneWidget);
      expect(find.byKey(const Key('ticket-send-sms')), findsOneWidget);
      expect(find.byKey(const Key('ticket-send-email')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('ticket-send-whatsapp')));
      // Jeton relu (ré-export audité), image rendue au nom du titulaire.
      expect(tickets.calls, ['export tk-0001']);
      expect(renderer.rendered, ['TS-AAAA-0001:Awa Ouédraogo']);
      final request = sender.requests.single;
      expect(request.channel, DeliveryChannel.whatsapp);
      expect(request.holder.phone, '+22670112233');
      expect(request.attachment!.mimeType, 'image/png');
      expect(request.attachment!.name, 'Ticket-TS-AAAA-0001.png');
      expect(request.text, startsWith('Bonjour Awa Ouédraogo'));

      // Rien n'est enregistré avant la confirmation.
      expect(find.text('Le ticket est-il parti ?'), findsOneWidget);
      expect(tickets.deliveries, isEmpty);
      await tester.tap(find.byKey(const Key('send-confirm-yes')));
      await tester.pumpAndSettle();
      expect(tickets.deliveries, [('tk-0001', DeliveryChannel.whatsapp)]);
      expect(find.byKey(const Key('ticket-last-delivery')), findsOneWidget);
      expect(find.textContaining('Dernier envoi : WhatsApp'), findsOneWidget);
    });

    testWidgets('fiche : e-mail avec le PDF ; « Non » n’enregistre rien', (
      tester,
    ) async {
      tickets.tickets.add(_ticket('tk-0002', email: 'issa@exemple.bf'));
      await openDetail(tester, 'tk-0002');
      expect(find.byKey(const Key('ticket-send-whatsapp')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('ticket-send-email')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('ticket-send-email')));
        await Future<void>.delayed(const Duration(seconds: 1));
      });
      await tester.pumpAndSettle();
      final request = sender.requests.single;
      expect(request.attachment!.mimeType, 'application/pdf');
      expect(request.subject, 'Votre ticket : Gala');
      expect(String.fromCharCodes(request.attachment!.bytes.take(4)), '%PDF');
      await tester.tap(find.byKey(const Key('send-confirm-no')));
      await tester.pumpAndSettle();
      expect(tickets.deliveries, isEmpty);
    });

    testWidgets(
      'fiche : WhatsApp absent, message ; sans coordonnées, conseil',
      (tester) async {
        sender.outcome = SendOutcome.appMissing;
        tickets.tickets.addAll([
          _ticket('tk-0003', phone: '+22670112233'),
          _ticket('tk-0004', name: 'Sans contact'),
        ]);
        await openDetail(tester, 'tk-0003');
        await tapVisible(tester, find.byKey(const Key('ticket-send-whatsapp')));
        expect(
          find.text("WhatsApp n'est pas installé sur ce téléphone."),
          findsOneWidget,
        );
        expect(find.text('Le ticket est-il parti ?'), findsNothing);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('ticket-tk-0004')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('ticket-send-no-contact')), findsOneWidget);
      },
    );

    testWidgets('ticket utilisé : pas d’envoi proposé', (tester) async {
      tickets.tickets.add(
        _ticket(
          'tk-0005',
          phone: '+22670112233',
          status: TicketStatus.redeemed,
        ),
      );
      await openDetail(tester, 'tk-0005');
      expect(find.byKey(const Key('ticket-send-card')), findsNothing);
    });

    testWidgets('série : ordre d’émission, confirmer, passer, terminer', (
      tester,
    ) async {
      // Du plus récent au plus ancien, comme le serveur.
      tickets.tickets.addAll([
        _ticket(
          'tk-0014',
          name: 'Déjà envoyé',
          phone: '+22670000014',
          delivered: (
            channel: DeliveryChannel.whatsapp,
            at: DateTime.utc(2030),
          ),
        ),
        _ticket('tk-0013', name: 'Sans téléphone', email: 'x@y.bf'),
        _ticket('tk-0012', name: 'Issa', phone: '+22670000012'),
        _ticket('tk-0011', name: 'Awa', phone: '+22670000011'),
      ]);
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-send')));
      await tester.pumpAndSettle();
      expect(find.byType(TicketSendPage), findsOneWidget);
      expect(find.text('Ticket 1 sur 2'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('send-current-name'))).data,
        'Awa',
      );

      await tapVisible(tester, find.byKey(const Key('send-open')));
      // Un seul ré-export pour les tickets de la série.
      expect(tickets.calls.first, 'export tk-0011,tk-0012');
      expect(sender.requests.single.holder.phone, '+22670000011');
      await tapVisible(tester, find.byKey(const Key('send-confirm')));
      expect(tickets.deliveries, [('tk-0011', DeliveryChannel.whatsapp)]);

      expect(find.text('Ticket 2 sur 2'), findsOneWidget);
      expect(find.text('1 envoyé · aucun passé'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('send-skip')));

      expect(find.byKey(const Key('send-done')), findsOneWidget);
      expect(find.text('1 envoyé · 1 passé'), findsOneWidget);
      expect(tickets.calls.where((c) => c.startsWith('export')), hasLength(1));

      // Par e-mail : seul le ticket avec une adresse est proposé.
      await tapVisible(tester, find.byKey(const Key('send-channel-email')));
      expect(find.text('Ticket 1 sur 1'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('send-current-name'))).data,
        'Sans téléphone',
      );
    });

    testWidgets('série : rien à envoyer', (tester) async {
      tickets.tickets.add(_ticket('tk-0021', name: 'Sans contact'));
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-send')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('send-empty')), findsOneWidget);
      expect(find.text('Aucun ticket à envoyer par WhatsApp'), findsOneWidget);
    });

    testWidgets('liste : ticket envoyé signalé', (tester) async {
      tickets.tickets.add(
        _ticket(
          'tk-0031',
          name: 'Awa',
          delivered: (channel: DeliveryChannel.sms, at: DateTime.utc(2030)),
        ),
      );
      await openTickets(tester);
      expect(find.textContaining('Envoyé par SMS le'), findsOneWidget);
    });
  });
}
