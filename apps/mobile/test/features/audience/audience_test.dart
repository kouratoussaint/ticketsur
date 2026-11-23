import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/audience/domain/audience.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/public_organization_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_audience_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';

/// Lot 4-12c (ADR 0051) : vues de la fiche publique, abonnés.
void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  test('série lue', () {
    final series = AudienceSeries.fromJson(
      {
        'followers': 12,
        'new_30d': 3,
        'days': [
          {'day': '2030-05-31', 'count': 1},
          {'day': '2030-06-01', 'count': 2},
        ],
      },
      totalKey: 'followers',
      recentKey: 'new_30d',
    );
    expect((series.total, series.recent), (12, 3));
    expect(series.days.last.count, 2);
    expect(series.days.first.day, DateTime.utc(2030, 5, 31));
  });

  late FakeAudienceRepository audience;

  Future<void> pump(
    WidgetTester tester,
    String route, {
    bool signedIn = true,
    bool push = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final catalog = FakeCatalogRepository(
      [publicEvent(id: 'p1')],
      {
        'p1': PublicEventDetail(
          summary: publicEvent(id: 'p1'),
          categories: const [],
        ),
      },
    );
    catalog.organizations['org-test'] = PublicOrganization(
      id: 'org-test',
      name: 'Org test',
      createdAt: DateTime.utc(2026, 3, 2),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(
            user: signedIn
                ? const AuthUser(id: 'u1', email: 'awa@faso.bf')
                : null,
          ),
          organizations: FakeOrganizationRepository(
            signedIn ? [testOrganization] : [],
          ),
          events: FakeEventRepository([
            testEvent(
              id: 'e1',
              title: 'Gala',
              status: EventStatus.published,
              isPublic: true,
            ),
            testEvent(id: 'e2', title: 'Brouillon'),
          ]),
          catalog: catalog,
          audience: audience,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(Navigator).first));
    if (push) {
      unawaited(router.push(route));
    } else {
      router.go(route);
    }
    await tester.pumpAndSettle();
  }

  setUp(() {
    audience = FakeAudienceRepository(
      views: audienceSeries(total: 380, recent: 124),
      followers: audienceSeries(),
    );
  });

  testWidgets('fiche publique : une vue par appareil et par jour', (
    tester,
  ) async {
    await pump(tester, AppRoutes.publicEvent('p1'), signedIn: false);
    expect(audience.recorded, ['p1']);
    // Numéro d'installation : 32 caractères tirés au hasard.
    expect(audience.devices.single, matches(RegExp(r'^[0-9a-f]{32}$')));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    unawaited(
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push(AppRoutes.publicEvent('p1')),
    );
    await tester.pumpAndSettle();
    expect(audience.recorded, ['p1']);
  });

  testWidgets('échec : la vue sera comptée à la prochaine ouverture', (
    tester,
  ) async {
    audience.failure = AudienceFailure.network;
    await pump(tester, AppRoutes.publicEvent('p1'), signedIn: false);
    expect(audience.recorded, isEmpty);
    audience.failure = null;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    unawaited(
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push(AppRoutes.publicEvent('p1')),
    );
    await tester.pumpAndSettle();
    expect(audience.recorded, ['p1']);
  });

  testWidgets('fiche du promoteur : vues sur 7 jours et au total', (
    tester,
  ) async {
    await pump(tester, AppRoutes.eventDetail('e1'), push: false);
    final card = find.byKey(const Key('event-views'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    expect(find.text('124 sur 7 jours · 380 au total'), findsOneWidget);
  });

  testWidgets('brouillon : pas de carte des vues', (tester) async {
    await pump(tester, AppRoutes.eventDetail('e2'), push: false);
    expect(find.byKey(const Key('event-views')), findsNothing);
  });

  testWidgets('Profil : abonnés de la structure, puis page publique', (
    tester,
  ) async {
    await pump(tester, AppRoutes.profile, push: false);
    final row = find.byKey(const Key('profile-org-followers'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: row,
        matching: find.text('12 abonnés · +3 sur 30 jours'),
      ),
      findsOneWidget,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('follower-stats-count'))).data,
      '12 abonnés',
    );
    expect(find.text('3 nouveaux abonnés sur 30 jours'), findsOneWidget);
    await tester.tap(find.byKey(const Key('follower-stats-page')));
    await tester.pumpAndSettle();
    expect(find.byType(PublicOrganizationPage), findsOneWidget);
  });
}
