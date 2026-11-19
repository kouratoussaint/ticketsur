import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/ticket_import/application/import_providers.dart';
import 'package:ticketsur/features/ticket_import/presentation/ticket_import_page.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_event_setup_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_ticket_repository.dart';

PickedFile _csv(String name, String text) =>
    (name: name, bytes: Uint8List.fromList(utf8.encode(text)));

void main() {
  test('lettres de colonne de tableur', () {
    expect(columnLetter(0), 'A');
    expect(columnLetter(4), 'E');
    expect(columnLetter(25), 'Z');
    expect(columnLetter(26), 'AA');
    expect(columnLetter(27), 'AB');
  });

  group('import d’une liste', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late FakeTicketRepository tickets;
    late FakeEventSetupRepository setup;
    late List<List<SharedFile>> shared;
    PickedFile? next;
    Exception? pickError;

    Future<void> openImport(WidgetTester tester) async {
      shared = [];
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: FakeEventRepository([
              testEvent(id: 'e1', title: 'Gala', status: EventStatus.published),
            ]),
            setup: setup,
            tickets: tickets,
            shareFiles: (files, {text}) async => shared.add(files),
            importPicker: () async {
              if (pickError case final error?) throw error;
              return next;
            },
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
      await tester.tap(find.byKey(const Key('tickets-import')));
      await tester.pumpAndSettle();
      expect(find.byType(TicketImportPage), findsOneWidget);
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> pick(WidgetTester tester, PickedFile file) async {
      next = file;
      await tapVisible(tester, find.byKey(const Key('import-pick')));
    }

    Future<bool> submitEnabled(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.byKey(const Key('import-submit')),
        300,
        scrollable: find
            .descendant(
              of: find.byType(TicketImportPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      return tester
              .widget<ButtonStyleButton>(find.byKey(const Key('import-submit')))
              .onPressed !=
          null;
    }

    setUp(() {
      next = null;
      pickError = null;
      setup = FakeEventSetupRepository(
        categories: const [
          TicketCategory(
            id: 'std',
            eventId: 'e1',
            name: 'Standard',
            capacity: 100,
          ),
          TicketCategory(
            id: 'vip',
            eventId: 'e1',
            name: 'VIP',
            capacity: 5,
            issued: 4,
          ),
        ],
      );
      tickets = FakeTicketRepository()
        ..categoryNames = const {'std': 'Standard', 'vip': 'VIP'};
    });

    testWidgets('CSV avec une erreur : ignorer la ligne, émettre, partager', (
      tester,
    ) async {
      await openImport(tester);
      await pick(
        tester,
        _csv(
          'invites.csv',
          'Nom;Téléphone;Catégorie\n'
              'Awa Ouédraogo;70 11 22 33;VIP\n'
              'Issa;12;\n'
              'Moussa Traoré;;standard\n'
              'Fatou;+225 07 08 09 10 11;\n',
        ),
      );

      expect(find.text('invites.csv'), findsOneWidget);
      expect(find.text('4 lignes lues'), findsOneWidget);
      expect(find.text('3 lignes prêtes'), findsOneWidget);
      expect(find.text('1 en erreur'), findsOneWidget);
      expect(find.text('Nom ← « Nom »'), findsOneWidget);
      expect(find.text('Ligne 3 · téléphone invalide'), findsOneWidget);
      expect(await submitEnabled(tester), isFalse);

      await tapVisible(tester, find.byKey(const Key('import-skip-errors')));
      expect(await submitEnabled(tester), isTrue);
      expect(find.text('Émettre 3 tickets'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('import-submit')));
      expect(tickets.calls, ['issueNamed 3']);
      expect(
        [for (final r in tickets.namedRows) '${r.categoryId}:${r.holder.name}'],
        ['vip:Awa Ouédraogo', 'std:Moussa Traoré', 'std:Fatou'],
      );
      expect(tickets.namedRows.first.holder.phone, '+22670112233');
      expect(find.text('3 tickets émis'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('import-share-pdf')));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
      expect(shared.single.single.mimeType, 'application/pdf');

      await tapVisible(tester, find.byKey(const Key('import-see')));
      expect(find.byType(TicketImportPage), findsNothing);
      expect(find.text('Awa Ouédraogo'), findsOneWidget);
    });

    testWidgets('Excel réel : en-tête sous un titre, prénom + nom', (
      tester,
    ) async {
      await openImport(tester);
      await pick(tester, (
        name: 'Liste invités.xlsx',
        bytes: File('test/fixtures/liste_invites.xlsx').readAsBytesSync(),
      ));
      expect(find.text('Prénom ← « Prénom »'), findsOneWidget);
      expect(find.text('Téléphone ← « Téléphone (WhatsApp) »'), findsOneWidget);
      expect(find.text('3 lignes prêtes'), findsOneWidget);
      expect(
        find.text('Ligne 8 · catégorie « Inconnue » inconnue'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('import-warnings')), findsOneWidget);
      expect(
        find.text("Ligne 7 · même téléphone qu'une ligne précédente"),
        findsOneWidget,
      );
    });

    testWidgets('quota de catégorie dépassé : envoi bloqué avant le serveur', (
      tester,
    ) async {
      await openImport(tester);
      await pick(tester, _csv('vip.csv', 'Nom;Catégorie\nA;VIP\nB;VIP\n'));
      expect(find.text('VIP : 2 demandés, 1 restants'), findsOneWidget);
      expect(await submitEnabled(tester), isFalse);
    });

    testWidgets('catégorie par défaut modifiable', (tester) async {
      await openImport(tester);
      await pick(tester, _csv('liste.csv', 'Nom\nAwa\n'));
      expect(find.byKey(const Key('import-category-std')), findsOneWidget);

      await tester.tap(find.byKey(const Key('import-default-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VIP').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('import-category-vip')), findsOneWidget);
      expect(find.byKey(const Key('import-category-std')), findsNothing);
    });

    testWidgets('fichiers refusés : .xls, format inconnu, trop volumineux', (
      tester,
    ) async {
      await openImport(tester);
      await pick(tester, (name: 'vieux.xls', bytes: Uint8List(4)));
      expect(find.textContaining('Ancien format Excel (.xls)'), findsOneWidget);
      expect(find.byKey(const Key('import-submit')), findsNothing);

      await pick(tester, (name: 'photo.jpg', bytes: Uint8List(4)));
      expect(find.textContaining('Format non pris en charge'), findsOneWidget);

      pickError = const ImportFileTooLarge();
      await tapVisible(tester, find.byKey(const Key('import-pick')));
      expect(find.textContaining('Fichier trop volumineux'), findsOneWidget);
    });

    testWidgets('pas de colonne de nom : message, envoi bloqué', (
      tester,
    ) async {
      await openImport(tester);
      await pick(tester, _csv('tel.csv', 'Téléphone\n70112233\n'));
      expect(find.byKey(const Key('import-no-name')), findsOneWidget);
      expect(await submitEnabled(tester), isFalse);
    });

    testWidgets('refus du serveur : message, la liste reste à l’écran', (
      tester,
    ) async {
      tickets.nextFailure = TicketFailure.eventCapacityExceeded;
      await openImport(tester);
      await pick(tester, _csv('liste.csv', 'Nom\nAwa\n'));
      expect(await submitEnabled(tester), isTrue);
      await tapVisible(tester, find.byKey(const Key('import-submit')));
      expect(find.byKey(const Key('import-error')), findsOneWidget);
      expect(find.byKey(const Key('import-done')), findsNothing);
      // La liste reste prête : un nouvel essai est possible.
      expect(await submitEnabled(tester), isTrue);
    });

    testWidgets('modèle partagé : CSV relisible avec les catégories', (
      tester,
    ) async {
      await openImport(tester);
      await tapVisible(tester, find.byKey(const Key('import-template')));
      final file = shared.single.single;
      expect(file.name, 'modele-liste-tickets.csv');
      expect(file.mimeType, 'text/csv');
      final text = utf8.decode(file.bytes);
      // BOM UTF-8 : Excel ouvre alors le fichier avec les bons accents.
      expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(text, startsWith('Nom;Téléphone;E-mail;Catégorie'));
      expect(text, contains(';Standard\r\n'));
      expect(text, contains(';VIP\r\n'));
    });

    testWidgets('accès depuis la feuille d’émission', (tester) async {
      await openImport(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tickets-issue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('issue-import')));
      await tester.pumpAndSettle();
      expect(find.byType(TicketImportPage), findsOneWidget);
    });
  });
}
