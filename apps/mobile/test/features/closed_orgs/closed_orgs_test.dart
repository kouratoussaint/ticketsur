import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/closed_orgs/data/supabase_closed_org_repository.dart';
import 'package:ticketsur/features/closed_orgs/domain/closed_org.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_closed_org_repository.dart';
import '../../helpers/fake_dashboard_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_report_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  test('réponse du serveur lue : structure, rôle, événements, chiffres', () {
    final detail = closedDetailFromJson({
      'organization': {
        'id': 'o1',
        'name': 'Kwabo',
        'city': 'Kaya',
        'logo_path': 'o1/logo.png',
        'closed_at': '2030-05-02T10:00:00Z',
        'role': 'manager',
      },
      'events': [
        {
          'id': 'e1',
          'organization_id': 'o1',
          'title': 'Festival',
          'timezone': 'Africa/Ouagadougou',
          'starts_at': '2030-04-12T20:00:00Z',
          'ends_at': '2030-04-13T02:00:00Z',
          'status': 'archived',
          'kind': 'concert',
          'issued': 120,
          'admitted': 97,
          'revoked': 3,
        },
      ],
    }, logoUrlOf: (path) => 'https://logos/$path');
    expect(detail.organization.role, MemberRole.manager);
    expect(detail.organization.logoUrl, 'https://logos/o1/logo.png');
    expect(detail.organization.closedAt, DateTime.utc(2030, 5, 2, 10));
    final event = detail.events.single;
    expect(
      (event.event.status, event.issued, event.admitted, event.revoked),
      (EventStatus.archived, 120, 97, 3),
    );
  });

  group('structure fermée en consultation seule', () {
    const user = AuthUser(id: 'u1', email: 'proprio@exemple.bf');
    late FakeClosedOrgRepository closed;
    late FakeReportRepository report;
    late FakeDashboardRepository dashboard;
    late List<List<SharedFile>> shared;

    Future<void> pumpProfile(WidgetTester tester) async {
      shared = [];
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            // Compte classique : la structure fermée n'est plus active.
            organizations: FakeOrganizationRepository(),
            closedOrgs: closed,
            report: report,
            dashboard: dashboard,
            shareFiles: (files, {text}) async => shared.add(files),
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
    }

    Future<void> openClosedRow(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.byKey(const Key('profile-closed-orgs')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(const Key('profile-closed-orgs')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-closed-orgs')));
      await tester.pumpAndSettle();
    }

    setUp(() {
      closed = FakeClosedOrgRepository(
        organizations: [closedOrganization()],
        events: {
          'org-closed': [closedEvent()],
        },
      );
      report = FakeReportRepository();
      dashboard = FakeDashboardRepository(
        next: sampleDashboard(eventId: 'ev-closed'),
      );
    });

    testWidgets('sans structure fermée : pas de ligne dans le Profil', (
      tester,
    ) async {
      closed = FakeClosedOrgRepository();
      await pumpProfile(tester);
      expect(find.byKey(const Key('profile-account')), findsOneWidget);
      expect(find.byKey(const Key('profile-closed-orgs')), findsNothing);
    });

    testWidgets('une structure : fiche, bandeau, factures, chiffres, CSV', (
      tester,
    ) async {
      await pumpProfile(tester);
      await openClosedRow(tester);
      // Une seule structure : la fiche s'ouvre directement.
      expect(find.byKey(const Key('closed-org-readonly')), findsOneWidget);
      expect(
        find.textContaining('Structure fermée le 2 mai 2030'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('closed-org-invoices')), findsOneWidget);
      expect(find.text('Festival archivé'), findsOneWidget);
      expect(
        find.text('Tickets : 120 · Entrés : 97 · Annulés : 3'),
        findsOneWidget,
      );
      // Aucune action de modification.
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.byKey(const Key('closed-event-ev-closed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-csv')));
      await tester.pumpAndSettle();
      expect(report.calls, ['closed:ev-closed']);
      expect(shared.single.single.name, 'Tickets-festival-archive.csv');
    });

    testWidgets('bilan PDF : chiffres lus en consultation', (tester) async {
      await pumpProfile(tester);
      await openClosedRow(tester);
      await tester.tap(find.byKey(const Key('closed-event-ev-closed')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('report-pdf')));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
      expect(dashboard.calls, ['closed:ev-closed']);
      expect(dashboard.summaryCalls, ['closed:ev-closed']);
      final file = shared.single.single;
      expect(String.fromCharCodes(file.bytes.take(4)), '%PDF');
    });

    testWidgets('plusieurs structures : liste ; gestionnaire sans factures', (
      tester,
    ) async {
      closed = FakeClosedOrgRepository(
        organizations: [
          closedOrganization(),
          closedOrganization(
            id: 'org-2',
            name: 'Faso Live',
            role: MemberRole.manager,
            eventCount: 0,
          ),
        ],
      );
      await pumpProfile(tester);
      await openClosedRow(tester);
      expect(find.byKey(const Key('closed-org-org-closed')), findsOneWidget);
      expect(find.text('Aucun événement · Gestionnaire'), findsOneWidget);
      await tester.tap(find.byKey(const Key('closed-org-org-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('closed-org-readonly')), findsOneWidget);
      expect(find.byKey(const Key('closed-org-invoices')), findsNothing);
      expect(find.byKey(const Key('closed-org-no-events')), findsOneWidget);
    });

    testWidgets('plus consultable : message', (tester) async {
      await pumpProfile(tester);
      closed.failure = ClosedOrgFailure.notFound;
      await openClosedRow(tester);
      expect(find.byKey(const Key('closed-org-error')), findsOneWidget);
      expect(
        find.text("Cette structure n'est plus consultable."),
        findsOneWidget,
      );
    });
  });
}
