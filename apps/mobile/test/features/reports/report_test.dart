import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/reports/domain/report.dart';
import 'package:ticketsur/features/reports/presentation/report_files.dart';
import 'package:ticketsur/features/ticket_import/domain/table_reader.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dashboard_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_report_repository.dart';

final _rows = [
  ReportRow(
    reference: 'TS-AAAA-0001',
    categoryName: 'VIP',
    status: TicketStatus.redeemed,
    issuedAt: DateTime.utc(2026, 11, 20, 10),
    redeemedAt: DateTime.utc(2026, 11, 20, 20, 5),
    checkpointName: 'Porte A',
    holder: const TicketHolder(
      name: 'Awa Ouédraogo',
      phone: '+22670112233',
      email: 'awa@exemple.bf',
    ),
    lastDelivery: (
      channel: DeliveryChannel.whatsapp,
      at: DateTime.utc(2026, 11, 20, 11),
    ),
  ),
  ReportRow(
    reference: 'TS-AAAA-0002',
    categoryName: 'Standard',
    status: TicketStatus.issued,
    issuedAt: DateTime.utc(2026, 11, 20, 10),
    holder: const TicketHolder(name: '=HYPERLINK("x")'),
  ),
];

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('fichiers', () {
    test('nom de fichier tiré du titre', () {
      expect(fileSlug("Gala d'été 2026 !"), 'gala-d-ete-2026');
      expect(fileSlug('🎉'), 'evenement');
      expect(fileSlug('a' * 60), hasLength(40));
    });

    test('téléphone gardé en texte par Excel, chiffres complets', () {
      expect(csvPhone('+22670112233'), '00226 70 11 22 33');
      expect(csvPhone('+2250708091011'), '0022507 08 09 10 11');
      expect(csvPhone(null), '');
    });

    test('cellules : formules neutralisées, séparateurs cités', () {
      expect(csvCell('=1+1'), "'=1+1");
      expect(csvCell('+226'), "'+226");
      expect(csvCell('@moi'), "'@moi");
      expect(csvCell('a;b'), '"a;b"');
      expect(csvCell('dit "oui"'), '"dit ""oui"""');
      expect(csvCell('Awa'), 'Awa');
    });

    test('liste CSV : BOM, en-tête, heures du fuseau, relue sans perte', () {
      final bytes = buildReportCsv(
        AppLocalizationsFr(),
        event: testEvent(title: 'Gala'),
        rows: _rows,
      );
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(bytes), contains('\r\n'));
      final table = readTable('rapport.csv', bytes);
      expect(table.first.first, 'Référence');
      expect(table.first, hasLength(12));
      expect(table[1], [
        'TS-AAAA-0001',
        'VIP',
        'Utilisé',
        'Awa Ouédraogo',
        '00226 70 11 22 33',
        'awa@exemple.bf',
        '20/11/2026 10:00',
        '20/11/2026 20:05',
        'Porte A',
        '',
        'WhatsApp',
        '20/11/2026 11:00',
      ]);
      // Formule neutralisée ; ticket jamais envoyé : colonnes vides.
      expect(table[2][3], "'=HYPERLINK(\"x\")");
      expect(table[2][10], '');
    });

    test('ligne du rapport lue depuis le serveur', () {
      final row = ReportRow.fromJson(const {
        'public_reference': 'TS-AAAA-0001',
        'category_name': 'VIP',
        'status': 'redeemed',
        'holder_name': 'Awa',
        'holder_phone': '+22670112233',
        'issued_at': '2026-11-20T10:00:00Z',
        'redeemed_at': '2026-11-20T20:05:00Z',
        'redeemed_checkpoint_name': 'Porte A',
        'last_delivery_channel': 'sms',
        'last_delivery_at': '2026-11-20T11:00:00Z',
      });
      expect(row.status, TicketStatus.redeemed);
      expect(row.holder.name, 'Awa');
      expect(row.checkpointName, 'Porte A');
      expect(row.lastDelivery?.channel, DeliveryChannel.sms);
    });

    test('bilan PDF : complet ou événement vide', () async {
      final l10n = AppLocalizationsFr();
      final full = await buildReportPdf(
        l10n,
        event: testEvent(title: 'Gala → été', city: 'Ouagadougou'),
        dashboard: sampleDashboard(),
        organizationName: 'Faso Événements',
      );
      expect(String.fromCharCodes(full.take(4)), '%PDF');
      final empty = await buildReportPdf(
        l10n,
        event: testEvent(title: 'Vide'),
        dashboard: EventDashboard(
          eventId: 'e1',
          serverTime: DateTime.utc(2026, 11, 20),
        ),
        organizationName: '',
      );
      expect(String.fromCharCodes(empty.take(4)), '%PDF');
    });
  });

  group('écran', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late List<List<SharedFile>> shared;
    late FakeReportRepository report;
    late FakeDashboardRepository dashboard;

    Future<void> openReport(WidgetTester tester) async {
      shared = [];
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: FakeEventRepository([
              testEvent(
                id: 'e1',
                title: 'Gala été',
                status: EventStatus.inProgress,
              ),
            ]),
            dashboard: dashboard,
            report: report,
            shareFiles: (files, {text}) async => shared.add(files),
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('home-dashboard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-dashboard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dashboard-report')));
      await tester.pumpAndSettle();
    }

    setUp(() {
      report = FakeReportRepository(_rows);
      dashboard = FakeDashboardRepository(next: sampleDashboard(eventId: 'e1'));
    });

    testWidgets('bilan PDF partagé, chiffres relus', (tester) async {
      await openReport(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('report-pdf')));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
      final file = shared.single.single;
      expect(file.name, 'Rapport-gala-ete.pdf');
      expect(file.mimeType, 'application/pdf');
      expect(String.fromCharCodes(file.bytes.take(4)), '%PDF');
      // Une lecture pour l'écran, une pour le rapport.
      expect(dashboard.calls, hasLength(2));
      expect(find.byKey(const Key('report-pdf')), findsNothing);
    });

    testWidgets('liste CSV partagée', (tester) async {
      await openReport(tester);
      await tester.tap(find.byKey(const Key('report-csv')));
      await tester.pumpAndSettle();
      final file = shared.single.single;
      expect(file.name, 'Tickets-gala-ete.csv');
      expect(file.mimeType, 'text/csv');
      expect(report.calls, ['e1']);
    });

    testWidgets('refus du serveur : message, la feuille reste ouverte', (
      tester,
    ) async {
      report.failure = ReportFailure.notFound;
      await openReport(tester);
      await tester.tap(find.byKey(const Key('report-csv')));
      await tester.pumpAndSettle();
      expect(shared, isEmpty);
      expect(find.textContaining('Rapport indisponible'), findsOneWidget);
    });
  });
}
