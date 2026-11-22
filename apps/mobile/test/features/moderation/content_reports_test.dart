import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/sign_in_page.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/moderation/data/supabase_moderation_repository.dart';
import 'package:ticketsur/features/moderation/domain/moderation.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_moderation_repository.dart';
import '../../helpers/fake_organization_repository.dart';

/// Lot 4-12b (ADR 0050) : signaler un contenu, signalements dans la console.
void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('domaine', () {
    test('groupe de signalements lu', () {
      final group = ReportGroup.fromJson({
        'kind': 'organization',
        'id': 'o1',
        'organization_id': 'o1',
        'organization_name': 'Faso Live',
        'title': 'Faso Live',
        'count': 3,
        'reasons': {'scam': 2, 'other': 1, 'inconnu': 4},
        'comments': [
          {'comment': 'Numéro injoignable', 'at': '2030-05-31T10:00:00Z'},
        ],
        'first_at': '2030-05-30T10:00:00Z',
        'last_at': '2030-05-31T10:00:00Z',
        'handled_at': null,
        'status': 'open',
        'removed': false,
      });
      expect(group.kind, ReportKind.organization);
      expect(group.reasons, {ReportReason.scam: 2, ReportReason.other: 1});
      expect(group.comments.single.comment, 'Numéro injoignable');
      expect(group.startsAt, isNull);
      expect(group.status, ReportStatus.open);
    });

    test('erreurs du signalement traduites', () {
      supabase.PostgrestException error(String message) =>
          supabase.PostgrestException(message: message);
      expect(
        mapReportError(error('report_rate_limited')),
        ReportFailure.rateLimited,
      );
      expect(
        mapReportError(error('report_target_not_found')),
        ReportFailure.notFound,
      );
      expect(mapReportError(error('autre')), ReportFailure.unknown);
    });
  });

  group('fiches publiques', () {
    late FakeCatalogRepository catalog;
    late FakeModerationRepository moderation;

    Future<void> pump(
      WidgetTester tester,
      String route, {
      bool signedIn = true,
    }) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(
              user: signedIn
                  ? const AuthUser(id: 'u1', email: 'curieux@exemple.bf')
                  : null,
            ),
            organizations: FakeOrganizationRepository(),
            catalog: catalog,
            moderation: moderation,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        GoRouter.of(tester.element(find.byType(Navigator).first)).push(route),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapReport(WidgetTester tester, String key) async {
      final button = find.byKey(Key(key));
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    setUp(() {
      moderation = FakeModerationRepository();
      catalog = FakeCatalogRepository(
        [publicEvent(id: 'p1')],
        {
          'p1': PublicEventDetail(
            summary: publicEvent(id: 'p1'),
            categories: const [],
          ),
        },
      );
      catalog.organizations['org-1'] = PublicOrganization(
        id: 'org-1',
        name: 'Faso Live',
        createdAt: DateTime.utc(2026, 3, 2),
      );
    });

    testWidgets('signaler un événement : motif, commentaire, puis « déjà »', (
      tester,
    ) async {
      await pump(tester, AppRoutes.publicEvent('p1'));
      await tapReport(tester, 'public-event-report');
      expect(find.byKey(const Key('report-sheet')), findsOneWidget);
      // Sans motif, rien n'est envoyé.
      await tester.tap(find.byKey(const Key('report-submit')));
      await tester.pumpAndSettle();
      expect(moderation.reported, isEmpty);

      await tester.tap(find.byKey(const Key('report-reason-scam')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-comment')),
        '  Numéro injoignable  ',
      );
      await tester.tap(find.byKey(const Key('report-submit')));
      await tester.pumpAndSettle();
      expect(moderation.reported, ['event p1 scam Numéro injoignable']);
      expect(find.byKey(const Key('report-sheet')), findsNothing);
      expect(
        find.text("Merci, votre signalement a été transmis à l'équipe Tikéo."),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await tapReport(tester, 'public-event-report');
      await tester.tap(find.byKey(const Key('report-reason-other')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Vous avez déjà signalé ce contenu ; il est en cours d'examen.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('limite atteinte : message dans la feuille', (tester) async {
      moderation.failure = ReportFailure.rateLimited;
      await pump(tester, AppRoutes.publicOrganization('org-1'));
      await tapReport(tester, 'public-org-report');
      await tester.tap(find.byKey(const Key('report-reason-duplicate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text("Trop de signalements aujourd'hui. Réessayez demain."),
        findsOneWidget,
      );
      expect(find.byKey(const Key('report-sheet')), findsOneWidget);
    });

    testWidgets('signaler une structure', (tester) async {
      await pump(tester, AppRoutes.publicOrganization('org-1'));
      await tapReport(tester, 'public-org-report');
      await tester.tap(find.byKey(const Key('report-reason-misleading')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-submit')));
      await tester.pumpAndSettle();
      expect(moderation.reported, ['organization org-1 misleading ∅']);
    });

    testWidgets('visiteur : connexion d’abord', (tester) async {
      await pump(tester, AppRoutes.publicEvent('p1'), signedIn: false);
      await tapReport(tester, 'public-event-report');
      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byKey(const Key('report-sheet')), findsNothing);
    });
  });

  group('console', () {
    late FakeModerationRepository moderation;

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(
              user: const AuthUser(id: 'u1', email: 'toussaint@tikeo.bf'),
            ),
            organizations: FakeOrganizationRepository([testOrganization]),
            admin: FakeAdminRepository(admin: true),
            moderation: moderation,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .go(AppRoutes.consoleReports);
      await tester.pumpAndSettle();
    }

    setUp(() {
      moderation = FakeModerationRepository(
        open: [
          reportGroup(
            count: 3,
            reasons: {ReportReason.scam: 2, ReportReason.misleading: 1},
            comments: [
              (comment: 'Faux concert', at: DateTime.utc(2030, 5, 31, 18)),
            ],
          ),
          reportGroup(
            id: 'org-r',
            kind: ReportKind.organization,
            title: 'Faso Fake',
            count: 1,
          ),
        ],
      );
    });

    testWidgets('à traiter : motifs, commentaire ; classer sans suite', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('2 à traiter'), findsOneWidget);
      expect(find.text('3 signalements'), findsOneWidget);
      expect(find.text('Arnaque ou faux événement · 2'), findsOneWidget);
      expect(find.text('« Faux concert »'), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-report-dismiss-ev-r1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Événement vérifié',
      );
      await tester.tap(find.byKey(const Key('console-report-confirm')));
      await tester.pumpAndSettle();
      expect(
        moderation.calls,
        contains('resolve event ev-r1 dismiss Événement vérifié'),
      );
      expect(find.byKey(const Key('console-report-event-ev-r1')), findsNothing);
      expect(find.text('1 à traiter'), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-reports-handled')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('console-report-event-ev-r1')),
        findsOneWidget,
      );
      expect(find.textContaining('classé sans suite'), findsOneWidget);
    });

    testWidgets('suspendre une structure signalée', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('console-report-remove-org-r')));
      await tester.pumpAndSettle();
      expect(find.text('Suspendre la structure'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Arnaque confirmée',
      );
      await tester.tap(find.byKey(const Key('console-report-confirm')));
      await tester.pumpAndSettle();
      expect(
        moderation.calls,
        contains('resolve organization org-r remove Arnaque confirmée'),
      );
    });

    testWidgets('tuile de la console : pastille du nombre à traiter', (
      tester,
    ) async {
      await pump(tester);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .go(AppRoutes.console);
      await tester.pumpAndSettle();
      final tile = find.byKey(const Key('console-nav-reports'));
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(of: tile, matching: find.text('2 à traiter')),
        findsOneWidget,
      );
    });
  });
}
