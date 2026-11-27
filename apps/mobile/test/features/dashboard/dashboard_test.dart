import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/dashboard/data/supabase_dashboard_repository.dart';
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/dashboard/domain/event_summary.dart';
import 'package:ticketsur/features/dashboard/presentation/event_dashboard_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dashboard_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/navigation.dart';

/// Réponse de `event_dashboard` telle que la renvoie le serveur.
Map<String, Object?> _serverJson() => {
  'version': 1,
  'server_time': '2026-11-20T20:15:07.123+00:00',
  'event_id': 'e1',
  'status': 'in_progress',
  'capacity': 100,
  'scan_opens_at': '2026-11-20T17:00:00+00:00',
  'scan_closes_at': null,
  'control_open': true,
  'tickets': {
    'issued': 4,
    'admitted': 2,
    'remaining': 2,
    'revoked': 1,
    'expired': 0,
  },
  'scans': {
    'total': 6,
    'accepted': 2,
    'refused': 4,
    'last_at': '2026-11-20T20:14:00+00:00',
    'last_accepted_at': '2026-11-20T20:10:00+00:00',
    'recent_accepted': 2,
    'recent_minutes': 15,
    'by_outcome': {'already_used': 1, 'not_found': 2, 'teleported': 1},
  },
  'categories': [
    {'id': 'c1', 'name': 'VIP', 'capacity': 10, 'issued': 2, 'admitted': 1},
  ],
  'checkpoints': [
    {
      'id': 'p1',
      'name': 'Porte A',
      'active': true,
      'admitted': 2,
      'refused': 4,
      'last_at': '2026-11-20T20:14:00+00:00',
    },
  ],
  'controllers': [
    {
      'user_id': 'u2',
      'display_name': 'Awa',
      'accepted': 2,
      'refused': 4,
      'last_at': '2026-11-20T20:14:00+00:00',
    },
  ],
  'timeline': {
    'step_minutes': 5,
    'buckets': [
      {'at': '2026-11-20T20:05:00+00:00', 'accepted': 1, 'refused': 3},
      {'at': '2026-11-20T20:10:00+00:00', 'accepted': 1, 'refused': 1},
    ],
  },
  'money': {
    'currency': 'XOF',
    'revenue': 20000,
    'revenue_tickets': 2,
    'revenue_unpriced': 1,
    'avoided': 10000,
    'avoided_tickets': 1,
    'avoided_unpriced': 0,
    'unknown_refusals': 2,
    'double_scans': 1,
    'double_scan_seconds': 15,
    'categories': [
      {
        'id': 'c1',
        'name': 'VIP',
        'price': 10000,
        'invitation': false,
        'admitted': 2,
        'refused': 1,
        'revenue': 20000,
        'avoided': 10000,
      },
      {
        'id': 'c2',
        'name': 'Sans prix',
        'price': null,
        'invitation': false,
        'admitted': 1,
        'refused': 0,
        'revenue': null,
        'avoided': null,
      },
    ],
  },
};

void main() {
  group('domaine', () {
    test('fromJson lit toutes les sections du tableau', () {
      final dashboard = EventDashboard.fromJson(_serverJson());
      expect(dashboard.eventId, 'e1');
      expect(dashboard.serverTime, DateTime.utc(2026, 11, 20, 20, 15, 7, 123));
      expect(dashboard.capacity, 100);
      expect(dashboard.scanWindowOpen, isTrue);
      expect(dashboard.tickets.admitted, 2);
      expect(dashboard.tickets.attendance, 0.5);
      expect(dashboard.scans.refused, 4);
      expect(dashboard.scans.recentAccepted, 2);
      expect(dashboard.categories.single.capacity, 10);
      expect(dashboard.checkpoints.single.lastAt, isNotNull);
      expect(dashboard.controllers.single.displayName, 'Awa');
      expect(dashboard.stepMinutes, 5);
      expect(dashboard.timeline.map((b) => b.total), [4, 2]);
      final money = dashboard.money!;
      expect(money.revenue, 20000);
      expect(money.revenueUnpriced, 1);
      expect(money.avoided, 10000);
      expect(money.unknownRefusals, 2);
      expect(money.doubleScans, 1);
      expect(money.doubleScanSeconds, 15);
      expect(money.unpriced, isFalse);
      expect(money.categories.last.price, isNull);
      expect(money.categories.first.avoided, 10000);
    });

    test('sans montants (serveur plus ancien), ou sans aucun prix', () {
      expect(
        EventDashboard.fromJson({..._serverJson()}..remove('money')).money,
        isNull,
      );
      const free = DashboardMoney(
        categories: [
          CategoryMoney(id: 'a', name: 'Libre'),
          CategoryMoney(
            id: 'b',
            name: 'Invités',
            price: 5000,
            isInvitation: true,
          ),
        ],
      );
      expect(free.unpriced, isTrue);
    });

    test('motifs de refus triés, motif inconnu regroupé', () {
      final scans = EventDashboard.fromJson(_serverJson()).scans;
      expect(scans.refusals.first.key, ScanResult.notFound);
      expect(scans.byOutcome[ScanResult.alreadyUsed], 1);
      expect(scans.byOutcome[ScanResult.unavailable], 1);
    });

    test(
      'version inconnue ou réponse incomplète : échec, jamais de chiffres',
      () {
        expect(
          () => EventDashboard.fromJson({..._serverJson(), 'version': 2}),
          throwsA(DashboardFailure.unknown),
        );
        expect(
          () => EventDashboard.fromJson(const {'version': 1}),
          throwsA(DashboardFailure.unknown),
        );
        expect(
          () => EventDashboard.fromJson(null),
          throwsA(DashboardFailure.unknown),
        );
      },
    );

    test('événement vide : sections vides, fenêtre fermée', () {
      final dashboard = EventDashboard.fromJson(const {
        'version': 1,
        'server_time': '2026-11-20T10:00:00Z',
        'event_id': 'e1',
        'scan_opens_at': '2026-11-20T17:00:00Z',
        'scan_closes_at': '2026-11-21T06:00:00Z',
        'tickets': {'issued': 0},
        'scans': {'total': 0, 'by_outcome': <String, Object?>{}},
        'categories': <Object?>[],
        'checkpoints': <Object?>[],
        'controllers': <Object?>[],
        'timeline': {'step_minutes': null, 'buckets': <Object?>[]},
      });
      expect(dashboard.scanWindowOpen, isFalse);
      expect(dashboard.tickets.attendance, 0);
      expect(dashboard.timeline, isEmpty);
      expect(dashboard.stepMinutes, isNull);
      expect(dashboard.scans.refusals, isEmpty);
    });

    test('erreurs serveur et réseau traduites', () {
      expect(
        mapDashboardError(
          const PostgrestException(message: 'event_not_found', code: '42501'),
        ),
        DashboardFailure.notFound,
      );
      expect(
        mapDashboardError(const SocketException('hors ligne')),
        DashboardFailure.network,
      );
      expect(
        mapDashboardError(TimeoutException('lent')),
        DashboardFailure.network,
      );
      expect(mapDashboardError(StateError('?')), DashboardFailure.unknown);
    });

    test('formats : heure du fuseau de l’événement, pourcentage, milliers', () {
      final instant = DateTime.utc(2026, 11, 20, 20, 15, 7);
      expect(formatClock('Africa/Ouagadougou', instant), '20:15');
      expect(formatClock('Europe/Paris', instant, seconds: true), '21:15:07');
      expect(formatPercent(0.354), '35 %');
      expect(formatPercent(1.4), '100 %');
      expect(formatCount(1250), '1 250');
    });
  });

  group('bilan : lecture du serveur', () {
    test('réponse de event_summary', () {
      final summary = EventSummary.fromJson(const {
        'version': 1,
        'event_id': 'e1',
        'timezone': 'Africa/Ouagadougou',
        'hours': [
          {'at': '2026-11-20T20:00', 'entries': 4},
          {'at': '2026-11-20T21:00', 'entries': 9},
        ],
        'peak': {'at': '2026-11-20T21:00', 'entries': 9},
        'days': [
          {'date': '2026-11-20', 'people': 12, 'entries': 13},
        ],
        'passes': {'tickets': 2, 'entries': 3},
        'first_entry_at': '2026-11-20T20:05:00+00:00',
        'last_entry_at': '2026-11-20T21:59:00+00:00',
        'comparison': [
          {
            'id': 'e1',
            'title': 'Gala',
            'starts_at': '2026-11-20T20:00:00+00:00',
            'issued': 20,
            'admitted': 12,
            'current': true,
          },
          {
            'id': 'e0',
            'title': 'Avant',
            'starts_at': '2026-10-01T20:00:00+00:00',
            'issued': 0,
            'admitted': 0,
            'current': false,
          },
        ],
      });
      expect(summary.hours.map((h) => h.entries), [4, 9]);
      expect(summary.peak?.at, DateTime(2026, 11, 20, 21));
      expect(summary.days.single.people, 12);
      expect(summary.passEntries, 3);
      expect(summary.firstEntryAt, DateTime.utc(2026, 11, 20, 20, 5));
      expect(summary.comparison.first.attendance, 0.6);
      expect(summary.comparison.last.attendance, 0);
      // Un événement sans ticket n'entre pas dans la moyenne.
      expect(summary.averageOthers, isNull);
      expect(summary.isEmpty, isFalse);
      expect(
        () => EventSummary.fromJson(const {'version': 2, 'event_id': 'e1'}),
        throwsA(DashboardFailure.unknown),
      );
      final empty = EventSummary.fromJson(const {
        'version': 1,
        'event_id': 'e1',
        'peak': null,
      });
      expect(empty.isEmpty, isTrue);
      expect(empty.peak, isNull);
    });
  });

  group('écran', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late FakeEventRepository events;
    late FakeDashboardRepository dashboard;

    Future<void> openApp(
      WidgetTester tester, {
      MemberRole role = MemberRole.owner,
      EventStatus status = EventStatus.inProgress,
      Duration refresh = const Duration(hours: 1),
    }) async {
      events.events.add(
        testEvent(id: 'e1', title: 'Nuit du jazz', status: status),
      );
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
            dashboard: dashboard,
            dashboardRefresh: refresh,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openDashboardFromHome(
      WidgetTester tester, {
      bool settle = true,
    }) async {
      await tester.ensureVisible(find.byKey(const Key('home-dashboard')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('home-dashboard')));
      if (settle) await tester.pumpAndSettle();
    }

    String textOf(WidgetTester tester, Key key) =>
        tester.widget<Text>(find.byKey(key)).data!;

    setUp(() {
      events = FakeEventRepository();
      dashboard = FakeDashboardRepository(next: sampleDashboard(eventId: 'e1'));
    });

    // Point « En direct » animé en continu : animations réduites pour
    // pouvoir attendre la fin des transitions.
    void reduceMotion(WidgetTester tester) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    testWidgets('depuis l’Accueil : chiffres, sections et heure du serveur', (
      tester,
    ) async {
      reduceMotion(tester);
      final semantics = tester.ensureSemantics();
      await openApp(tester);
      await openDashboardFromHome(tester);

      expect(dashboard.calls, ['e1']);
      expect(
        textOf(tester, const Key('dashboard-event-title')),
        'Nuit du jazz',
      );
      expect(textOf(tester, const Key('dashboard-admitted')), '42 entrées');
      expect(
        textOf(tester, const Key('dashboard-issued')),
        'sur 120 tickets émis',
      );
      expect(textOf(tester, const Key('dashboard-percent')), '35 %');
      expect(find.byKey(const Key('dashboard-live')), findsOneWidget);
      expect(
        textOf(tester, const Key('dashboard-updated-at')),
        'Actualisé à 20:15:07',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('dashboard-kpi-remaining')),
          matching: find.text('78'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('dashboard-kpi-rate')),
          matching: find.text('Entrées / 15 min'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('dashboard-timeline-chart')), findsOneWidget);
      expect(find.text('Par tranche de 15 min'), findsOneWidget);
      expect(
        // La carte fusionne ses textes en un seul nœud d'accessibilité.
        find.bySemanticsLabel(
          RegExp('42 entrées et 8 refus entre 19:45 et 20:15'),
        ),
        findsOneWidget,
      );

      Future<void> scrollTo(Key key) async {
        await tester.scrollUntilVisible(
          find.byKey(key),
          200,
          scrollable: find.descendant(
            of: find.byKey(const Key('dashboard-body')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
      }

      await scrollTo(const Key('dashboard-money-category-cat-std'));
      expect(
        find.descendant(
          of: find.byKey(const Key('dashboard-money-revenue')),
          matching: find.textContaining('204'),
        ),
        findsOneWidget,
      );
      expect(find.text('Recettes probables'), findsOneWidget);
      expect(find.text('Pertes évitées'), findsOneWidget);
      expect(find.text('Sur 42 entrées et 5 tickets refusés.'), findsOneWidget);
      expect(find.textContaining('27 entrées ×'), findsOneWidget);
      expect(
        find.text("3 QR inconnus ou d'autres événements, sans montant."),
        findsOneWidget,
      );
      expect(
        find.text(
          '2 refus non comptés : tickets repassés moins de 15 s après leur '
          'entrée (double scan).',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('dashboard-money-no-price')), findsNothing);
      await scrollTo(const Key('dashboard-refusal-already_used'));
      expect(find.text('Ticket déjà utilisé'), findsOneWidget);
      await scrollTo(const Key('dashboard-category-cat-vip'));
      expect(find.text('15 entrés sur 20 · Quota : 20'), findsOneWidget);
      await scrollTo(const Key('dashboard-checkpoint-cp-b'));
      expect(find.text('Fermée'), findsOneWidget);
      expect(
        find.text('30 entrées · 6 refus\nDernier scan à 20:14'),
        findsOneWidget,
      );
      await scrollTo(const Key('dashboard-revoked-expired'));
      expect(find.text('Awa'), findsOneWidget);
      expect(
        textOf(tester, const Key('dashboard-revoked-expired')),
        'Tickets annulés : 3 · expirés : 0',
      );
      semantics.dispose();
    });

    testWidgets('depuis la fiche événement, pour un gestionnaire', (
      tester,
    ) async {
      reduceMotion(tester);
      await openApp(tester, role: MemberRole.manager);
      await openEventsList(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-card-e1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-dashboard')));
      await tester.pumpAndSettle();
      expect(find.byType(EventDashboardPage), findsOneWidget);
      expect(dashboard.calls, ['e1']);
    });

    testWidgets('brouillon ou contrôleur : pas d’accès au tableau', (
      tester,
    ) async {
      await openApp(tester, status: EventStatus.draft);
      expect(find.byKey(const Key('home-dashboard')), findsNothing);
      await tester.tap(find.byKey(const Key('home-next-event')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event-dashboard')), findsNothing);
    });

    testWidgets(
      'échec d’actualisation : chiffres conservés, « Non actualisé »',
      (tester) async {
        reduceMotion(tester);
        await openApp(tester);
        await openDashboardFromHome(tester);
        expect(find.byKey(const Key('dashboard-live')), findsOneWidget);

        dashboard.failure = DashboardFailure.network;
        await tester.tap(find.byKey(const Key('dashboard-refresh')));
        await tester.pumpAndSettle();

        expect(dashboard.calls, hasLength(2));
        expect(find.byKey(const Key('dashboard-stale')), findsOneWidget);
        expect(find.byKey(const Key('dashboard-live')), findsNothing);
        expect(textOf(tester, const Key('dashboard-admitted')), '42 entrées');
        expect(
          textOf(tester, const Key('dashboard-updated-at')),
          'Connexion perdue : chiffres de 20:15:07. Nouvel essai automatique.',
        );

        // Retour du réseau : nouveaux chiffres, de nouveau « En direct ».
        dashboard
          ..failure = null
          ..next = sampleDashboard(eventId: 'e1', admitted: 43);
        await tester.tap(find.byKey(const Key('dashboard-refresh')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dashboard-live')), findsOneWidget);
        expect(textOf(tester, const Key('dashboard-admitted')), '43 entrées');
      },
    );

    testWidgets('actualisation automatique tant que l’écran est ouvert', (
      tester,
    ) async {
      reduceMotion(tester);
      await openApp(tester, refresh: const Duration(seconds: 15));
      await openDashboardFromHome(tester);
      expect(dashboard.calls, hasLength(1));

      dashboard.next = sampleDashboard(eventId: 'e1', admitted: 50);
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(dashboard.calls, hasLength(2));
      expect(textOf(tester, const Key('dashboard-admitted')), '50 entrées');

      // Écran fermé : plus aucun appel.
      // Retour système (bouton Retour d'Android).
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(EventDashboardPage), findsNothing);
      await tester.pump(const Duration(seconds: 45));
      expect(dashboard.calls, hasLength(2));
    });

    testWidgets('premier chargement impossible : message et nouvel essai', (
      tester,
    ) async {
      dashboard.failure = DashboardFailure.network;
      await openApp(tester);
      await openDashboardFromHome(tester);
      expect(
        textOf(tester, const Key('dashboard-error')),
        'Impossible de charger le tableau de bord.',
      );

      reduceMotion(tester);
      dashboard.failure = null;
      await tester.tap(find.byKey(const Key('dashboard-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dashboard-body')), findsOneWidget);
    });

    testWidgets('droits insuffisants : pas de nouvel essai proposé', (
      tester,
    ) async {
      dashboard.failure = DashboardFailure.notFound;
      await openApp(tester);
      await openDashboardFromHome(tester);
      expect(
        textOf(tester, const Key('dashboard-error')),
        startsWith('Tableau de bord indisponible'),
      );
      expect(find.byKey(const Key('dashboard-retry')), findsNothing);
    });

    testWidgets('contrôle fermé, aucun ticket, aucun scan', (tester) async {
      dashboard.next = EventDashboard(
        eventId: 'e1',
        serverTime: DateTime.utc(2026, 11, 20, 10),
        scanOpensAt: DateTime.utc(2026, 11, 20, 17),
        scanClosesAt: DateTime.utc(2026, 11, 21, 6),
      );
      await openApp(tester, status: EventStatus.published);
      await openDashboardFromHome(tester);
      expect(find.byKey(const Key('dashboard-closed')), findsOneWidget);
      expect(textOf(tester, const Key('dashboard-admitted')), 'Aucune entrée');
      expect(find.byKey(const Key('dashboard-no-tickets')), findsOneWidget);
      expect(find.byKey(const Key('dashboard-timeline-empty')), findsOneWidget);
      expect(find.byKey(const Key('dashboard-refusals')), findsNothing);
      expect(find.byKey(const Key('dashboard-money')), findsNothing);
    });

    testWidgets('montants : aucune catégorie avec un prix indicatif', (
      tester,
    ) async {
      reduceMotion(tester);
      dashboard.next = EventDashboard(
        eventId: 'e1',
        serverTime: DateTime.utc(2026, 11, 20, 20),
        controlOpen: true,
        tickets: const TicketCounts(issued: 10, admitted: 4, remaining: 6),
        money: const DashboardMoney(
          revenueUnpriced: 4,
          categories: [CategoryMoney(id: 'c1', name: 'Libre', admitted: 4)],
        ),
      );
      await openApp(tester);
      await openDashboardFromHome(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('dashboard-money')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('dashboard-body')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dashboard-money-no-price')), findsOneWidget);
      expect(
        find.text('4 entrées sans prix indicatif, non comptées.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dashboard-money-category-c1')),
        findsNothing,
      );
    });

    testWidgets('bilan : présence, affluence, jours, pass et comparaison', (
      tester,
    ) async {
      reduceMotion(tester);
      await openApp(tester);
      await openDashboardFromHome(tester);
      await tester.tap(find.byKey(const Key('dashboard-summary')));
      await tester.pumpAndSettle();

      expect(dashboard.summaryCalls, ['e1']);
      expect(textOf(tester, const Key('summary-rate')), formatPercent(0.35));
      expect(
        textOf(tester, const Key('summary-people')),
        '42 personnes entrées sur 120 tickets',
      );
      expect(
        textOf(tester, const Key('summary-average')),
        'Moyenne de vos 2 derniers événements : ${formatPercent(0.625)}',
      );
      expect(
        textOf(tester, const Key('summary-passes')),
        '14 entrées avec 10 pass',
      );
      expect(
        textOf(tester, const Key('summary-span')),
        'Première entrée à 20:02, dernière à 20:40',
      );
      expect(
        find.text('Heure de pointe : 21 h – 22 h · 25 entrées'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('summary-hour-2026112021')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('summary-comparison')),
        200,
      );
      expect(find.byKey(const Key('summary-days')), findsOneWidget);
      expect(find.text('37 personnes · 37 entrées'), findsOneWidget);
      expect(find.text('Gala Tikéo (cet événement)'), findsOneWidget);
      expect(
        find.byKey(const Key('summary-compare-evt-old-1')),
        findsOneWidget,
      );
    });

    testWidgets('bilan sans entrée, puis erreur avec nouvel essai', (
      tester,
    ) async {
      reduceMotion(tester);
      dashboard.nextSummary = const EventSummary(eventId: 'e1');
      await openApp(tester);
      await openDashboardFromHome(tester);
      await tester.tap(find.byKey(const Key('dashboard-summary')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('summary-empty')), findsOneWidget);
      expect(find.byKey(const Key('summary-comparison')), findsNothing);

      dashboard.summaryFailure = DashboardFailure.network;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dashboard-summary')));
      await tester.pumpAndSettle();
      expect(find.text('Impossible de charger le bilan.'), findsOneWidget);
      dashboard.summaryFailure = null;
      await tester.tap(find.byKey(const Key('summary-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('summary-empty')), findsOneWidget);
    });

    testWidgets('animations actives : le point « En direct » ne bloque rien', (
      tester,
    ) async {
      await openApp(tester);
      await openDashboardFromHome(tester, settle: false);
      // Animation en boucle : on avance le temps au lieu d'attendre la fin.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byKey(const Key('dashboard-live')), findsOneWidget);
      expect(textOf(tester, const Key('dashboard-admitted')), '42 entrées');
    });
  });
}
