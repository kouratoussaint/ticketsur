import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_detail_page.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/search/data/supabase_search_repository.dart';
import 'package:ticketsur/features/search/domain/search.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_detail_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_search_repository.dart';
import '../../helpers/fake_ticket_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'awa@kwabo.bf');

  test('réponse du serveur lue ; erreurs traduites', () {
    final result = PromoterSearchResult.fromJson(const {
      'events': [
        {
          'id': 'e1',
          'title': 'Nuit du Djembé',
          'status': 'published',
          'kind': 'concert',
          'starts_at': '2030-06-20T20:00:00Z',
          'ends_at': '2030-06-21T00:00:00Z',
          'venue': null,
          'city': 'Bobo-Dioulasso',
        },
      ],
      'tickets': [
        {
          'id': 't1',
          'event_id': 'e1',
          'event_title': 'Nuit du Djembé',
          'event_starts_at': '2030-06-20T20:00:00Z',
          'public_reference': 'TS-AB12-CD34',
          'event_number': 12,
          'holder_name': 'Aïcha',
          'holder_phone': '+22670112233',
          'category': 'VIP',
          'is_invitation': true,
          'status': 'redeemed',
        },
      ],
    });
    expect(result.events.single.city, 'Bobo-Dioulasso');
    expect(result.events.single.status, EventStatus.published);
    expect(result.tickets.single.status, TicketStatus.redeemed);
    expect(result.tickets.single.eventNumber, 12);
    expect(result.tickets.single.isInvitation, isTrue);
    expect(
      mapSearchError(const supabase.PostgrestException(message: 'forbidden')),
      SearchFailure.forbidden,
    );
  });

  Future<FakeSearchRepository> pumpSearch(
    WidgetTester tester, {
    PromoterSearchResult result = const PromoterSearchResult(),
    MemberRole role = MemberRole.owner,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final search = FakeSearchRepository(result: result);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(user: user),
          organizations: FakeOrganizationRepository([
            testOrganization.withRole(role),
          ]),
          events: FakeEventRepository([
            testEvent(id: 'e1', title: 'Nuit du Djembé'),
          ]),
          tickets: FakeTicketRepository(),
          search: search,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
    return search;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('search-field')), text);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }

  testWidgets('Accueil → recherche ; événements et tickets trouvés', (
    tester,
  ) async {
    final search = await pumpSearch(
      tester,
      result: PromoterSearchResult(
        events: [
          SearchEventHit(
            id: 'e1',
            title: 'Nuit du Djembé',
            status: EventStatus.published,
            kind: EventKind.concert,
            startsAt: DateTime.utc(2030, 6, 20, 20),
            city: 'Bobo-Dioulasso',
          ),
        ],
        tickets: [
          searchTicket(),
          searchTicket(id: 't2', holder: null, status: TicketStatus.redeemed),
        ],
      ),
    );
    await tester.tap(find.byKey(const Key('home-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-idle')), findsOneWidget);

    // Une lettre : pas de recherche.
    await type(tester, 'a');
    expect(search.queries, isEmpty);
    expect(find.byKey(const Key('search-idle')), findsOneWidget);

    await type(tester, 'ouedr');
    expect(search.queries, [(testOrganization.id, 'ouedr')]);
    expect(find.text('1 événement'), findsOneWidget);
    expect(find.text('2 tickets'), findsOneWidget);
    expect(find.text('Aïcha Ouédraogo'), findsOneWidget);
    // Sans titulaire : la référence sert de titre.
    expect(find.text('TS-AB12-CD34'), findsOneWidget);
    expect(find.text('Utilisé'), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-event-e1')));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailPage), findsOneWidget);

    // Retour, puis ouverture d'un ticket.
    GoRouter.of(tester.element(find.byType(EventDetailPage))).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('search-ticket-t1')));
    await tester.tap(find.byKey(const Key('search-ticket-t1')));
    await tester.pumpAndSettle();
    expect(find.byType(TicketDetailPage), findsOneWidget);
  });

  testWidgets('aucun résultat, puis erreur réseau', (tester) async {
    final search = await pumpSearch(tester);
    unawaited(
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push(AppRoutes.search),
    );
    await tester.pumpAndSettle();
    await type(tester, 'zzz');
    expect(find.text('Rien pour « zzz »'), findsOneWidget);
    search.failure = SearchFailure.network;
    await type(tester, 'zzzz');
    expect(find.byKey(const Key('search-error')), findsOneWidget);
    expect(find.text('Pas de connexion : réessayez.'), findsOneWidget);
  });

  testWidgets('contrôleur : pas de recherche sur l’Accueil', (tester) async {
    await pumpSearch(tester, role: MemberRole.controller);
    expect(find.byKey(const Key('home-search')), findsNothing);
  });
}
