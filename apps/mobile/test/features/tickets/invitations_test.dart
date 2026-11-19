import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/ticket_send/application/send_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_card.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dashboard_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_ticket_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('données', () {
    test('marque lue sur les catégories, tickets et compteurs', () {
      expect(
        TicketCategory.fromJson(const {
          'id': 'c1',
          'event_id': 'e1',
          'name': 'Invités',
          'is_invitation': true,
        }).isInvitation,
        isTrue,
      );
      expect(
        TicketCategory.fromJson(const {
          'id': 'c1',
          'event_id': 'e1',
          'name': 'VIP',
        }).isInvitation,
        isFalse,
      );
      final ticket = TicketSummary.fromJson(const {
        'id': 't1',
        'public_reference': 'TS-AAAA-0001',
        'category_name': 'Invités',
        'status': 'issued',
        'issued_at': '2026-11-20T10:00:00Z',
        'category_is_invitation': true,
      });
      expect(ticket.isInvitation, isTrue);
      expect(ticket.withStatus(TicketStatus.redeemed).isInvitation, isTrue);
      final counts = TicketCounts.fromJson(const {
        'issued': 10,
        'invitations': 4,
        'invitations_admitted': 1,
      });
      expect((counts.invitations, counts.invitationsAdmitted), (4, 1));
      expect(
        CategoryStats.fromJson(const {
          'id': 'c1',
          'name': 'Invités',
          'is_invitation': true,
        }).isInvitation,
        isTrue,
      );
    });

    test("message d'envoi : formule d'invitation", () {
      final l10n = AppLocalizationsFr();
      final event = testEvent(title: 'Gala');
      expect(
        ticketMessage(l10n, event, holderName: 'Awa', invitation: true),
        startsWith('Bonjour Awa, vous êtes invité(e) à « Gala »'),
      );
      expect(
        ticketMessage(l10n, event, invitation: true),
        contains('Invitation personnelle'),
      );
      expect(ticketMessage(l10n, event), contains('voici votre ticket'));
    });

    test('PDF : invitation générée', () async {
      final bytes = await buildTicketsPdf(
        event: testEvent(title: 'Gala'),
        organizationName: 'Faso Événements',
        tickets: [
          TicketSecret(
            ticketId: 't1',
            reference: 'TS-AAAA-0001',
            token: fakeToken(1),
            categoryName: 'Invités',
            holderName: 'Awa',
            isInvitation: true,
          ),
        ],
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('orange des invitations lisible sur le bleu nuit', () {
      expect(
        contrastRatio(TicketSurColors.spark, TicketSurColors.navy),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('écrans', () {
    testWidgets("carte : mention et pied de page d'invitation", (tester) async {
      await tester.pumpApp(
        SingleChildScrollView(
          child: TicketCard(
            event: testEvent(title: 'Gala'),
            reference: 'TS-AAAA-0001',
            categoryName: 'Invités',
            token: fakeToken(1),
            holderName: 'Awa',
            invitation: true,
          ),
        ),
      );
      expect(find.byKey(const Key('ticket-invitation')), findsOneWidget);
      expect(find.text('INVITATION'), findsOneWidget);
      expect(find.textContaining('Invitation personnelle'), findsOneWidget);
      // Accent orange de la marque : mention et filet sous le bandeau.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('ticket-invitation')))
            .style
            ?.color,
        TicketSurColors.spark,
      );
      expect(find.byKey(const Key('ticket-invitation-strip')), findsOneWidget);

      await tester.pumpApp(
        SingleChildScrollView(
          child: TicketCard(
            event: testEvent(title: 'Gala'),
            reference: 'TS-AAAA-0002',
            categoryName: 'VIP',
            token: fakeToken(2),
          ),
        ),
      );
      expect(find.byKey(const Key('ticket-invitation')), findsNothing);
      expect(find.byKey(const Key('ticket-invitation-strip')), findsNothing);
      // Catégorie sur une pastille menthe, texte bleu nuit (≥ 7:1).
      final pill = tester.widget<DecoratedBox>(
        find.byKey(const Key('ticket-category')),
      );
      expect((pill.decoration as BoxDecoration).color, TicketSurColors.mint);
      expect(
        contrastRatio(TicketSurColors.navy, TicketSurColors.mint),
        greaterThanOrEqualTo(7),
      );
    });

    testWidgets('tableau de bord : invités comptés à part', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final base = sampleDashboard(eventId: 'e1');
      final dashboard = EventDashboard(
        eventId: base.eventId,
        serverTime: base.serverTime,
        capacity: base.capacity,
        scanOpensAt: base.scanOpensAt,
        scanClosesAt: base.scanClosesAt,
        tickets: const TicketCounts(
          issued: 120,
          admitted: 42,
          remaining: 78,
          invitations: 20,
          invitationsAdmitted: 5,
        ),
        scans: base.scans,
        categories: [
          ...base.categories,
          const CategoryStats(
            id: 'inv',
            name: 'Invités',
            isInvitation: true,
            issued: 20,
            admitted: 5,
          ),
        ],
        checkpoints: base.checkpoints,
        controllers: base.controllers,
        stepMinutes: base.stepMinutes,
        timeline: base.timeline,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(
              user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
            ),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: FakeEventRepository([
              testEvent(
                id: 'e1',
                title: 'Gala',
                status: EventStatus.inProgress,
              ),
            ]),
            dashboard: FakeDashboardRepository(next: dashboard),
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('home-dashboard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-dashboard')));
      await tester.pumpAndSettle();

      final category = find.byKey(const Key('dashboard-category-inv'));
      await tester.scrollUntilVisible(
        category,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(
          of: category,
          matching: find.textContaining('Invitations'),
        ),
        findsOneWidget,
      );
      // Ligne des invités : dans le bandeau du haut.
      final line = find.byKey(const Key('dashboard-invitations'));
      await tester.scrollUntilVisible(
        line,
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<Text>(line).data,
        'Invités : 5 entrés sur 20 invitations',
      );
    });
  });
}
