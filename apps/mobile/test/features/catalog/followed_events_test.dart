import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/followed_organizations_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/wallet/presentation/wallet_pages.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_organization_repository.dart';

/// Lot 4-12a (ADR 0049) : « De vos structures suivies », périodes en un
/// geste, compte à rebours de Mon ticket.
void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('compte à rebours de Mon ticket', () {
    final l10n = AppLocalizationsFr();
    final event = TicketEvent(
      id: 'e1',
      organizationId: 'o1',
      title: 'Soirée',
      timezone: 'Africa/Ouagadougou',
      startsAt: DateTime.utc(2030, 6, 20, 21),
      endsAt: DateTime.utc(2030, 6, 21, 1),
      status: EventStatus.published,
    );
    String at(DateTime now) => walletCountdown(l10n, event, now).label;

    test('jours comptés dans le fuseau de l’événement', () {
      expect(at(DateTime.utc(2030, 6, 17, 23, 30)), 'Dans 3 jours');
      expect(at(DateTime.utc(2030, 6, 19, 8)), 'Demain à 21:00');
      expect(at(DateTime.utc(2030, 6, 20, 0, 5)), "Aujourd'hui à 21:00");
    });

    test('en cours puis terminé', () {
      final live = walletCountdown(l10n, event, DateTime.utc(2030, 6, 20, 22));
      expect((live.label, live.live), ('En cours', true));
      final ended = walletCountdown(l10n, event, DateTime.utc(2030, 6, 21, 1));
      expect((ended.label, ended.ended), ('Terminé', true));
    });
  });

  group('Explorer', () {
    late FakeCatalogRepository catalog;

    final page = PublicOrganization(
      id: 'org-1',
      name: 'Faso Live',
      city: 'Ouagadougou',
      createdAt: DateTime.utc(2026, 3, 2),
      followers: 3,
      events: [
        publicEvent(id: 'f2', title: 'Gala', startsAt: DateTime.utc(2030, 7)),
        publicEvent(id: 'f1', title: 'Concert'),
      ],
    );

    Future<void> pump(WidgetTester tester, {bool signedIn = true}) async {
      tester.view.physicalSize = const Size(1080, 3400);
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
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      catalog = FakeCatalogRepository([publicEvent(id: 'p9', title: 'Foire')])
        ..organizations['org-1'] = page
        ..followedIds.add('org-1');
    });

    testWidgets('« De vos structures suivies » : du plus proche au plus loin', (
      tester,
    ) async {
      await pump(tester);
      final section = find.byKey(const Key('explore-followed'));
      await tester.scrollUntilVisible(
        section,
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('explore-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('De vos structures suivies'), findsOneWidget);
      final first = tester.getTopLeft(
        find.byKey(const Key('explore-followed-f1')),
      );
      final second = tester.getTopLeft(
        find.byKey(const Key('explore-followed-f2')),
      );
      expect(first.dy, lessThan(second.dy));

      await tester.tap(find.byKey(const Key('explore-followed-all')));
      await tester.pumpAndSettle();
      expect(find.byType(FollowedOrganizationsPage), findsOneWidget);
    });

    testWidgets('masquée pendant une recherche et sans compte', (tester) async {
      await pump(tester);
      await tester.enterText(find.byKey(const Key('explore-search')), 'Foire');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-followed')), findsNothing);
    });

    testWidgets('visiteur : rien n’est demandé', (tester) async {
      await pump(tester, signedIn: false);
      expect(find.byKey(const Key('explore-followed')), findsNothing);
      expect(catalog.followedEventsCalls, 0);
    });

    testWidgets('périodes en un geste : choisie, puis retirée', (tester) async {
      await pump(tester, signedIn: false);
      await tester.tap(find.byKey(const Key('explore-period-weekend')));
      await tester.pumpAndSettle();
      expect(catalog.queries.last.period, CatalogPeriod.weekend);
      // Le badge des filtres compte la période.
      expect(find.text('1'), findsWidgets);

      await tester.tap(find.byKey(const Key('explore-period-weekend')));
      await tester.pumpAndSettle();
      expect(catalog.queries.last.period, CatalogPeriod.any);
    });
  });
}
