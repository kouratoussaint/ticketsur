import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/journal/domain/journal.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_journal_repository.dart';
import '../helpers/fake_organization_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
  final journal = FakeJournalRepository([
    JournalEntry(
      id: 'j1',
      createdAt: DateTime.utc(2030, 6, 20, 21),
      action: 'scan.manual',
      actorName: 'Issa (contrôleur)',
      subject: 'TS-AAAA-0001 · Gala',
      details: const {'result': 'accepted', 'request_id': 'secret-technique'},
    ),
    JournalEntry(
      id: 'j2',
      createdAt: DateTime.utc(2030, 6, 20, 18),
      action: 'ticket.revoked',
      actorName: 'Awa',
      subject: 'TS-BBBB-0002 · Gala',
      details: const {'reason': 'Doublon', 'bulk': true},
    ),
    JournalEntry(
      id: 'j3',
      createdAt: DateTime.utc(2030, 6, 19, 9),
      action: 'admin.organization_status_changed',
      byPlatform: true,
      details: const {'status': 'active'},
    ),
  ]);

  Future<void> openApp(WidgetTester tester, MemberRole role) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
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
          journal: journal,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .go(AppRoutes.profile);
    await tester.pumpAndSettle();
  }

  testWidgets('propriétaire : journal lisible, identifiants cachés, filtres', (
    tester,
  ) async {
    await openApp(tester, MemberRole.owner);
    final entry = find.byKey(const Key('profile-journal'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Entrée validée sans QR (recherche)'),
      findsOneWidget,
    );
    expect(find.textContaining('TS-AAAA-0001 · Gala'), findsOneWidget);
    expect(find.textContaining('par Issa (contrôleur)'), findsOneWidget);
    expect(find.textContaining('résultat : entrée autorisée'), findsOneWidget);
    expect(find.textContaining('secret-technique'), findsNothing);
    expect(find.textContaining("par l'équipe Tikéo"), findsOneWidget);

    await tester.tap(find.byKey(const Key('journal-filter-tickets')));
    await tester.pumpAndSettle();
    expect(journal.filters.last, JournalFilter.tickets);
    expect(find.byKey(const Key('journal-entry-j2')), findsOneWidget);
    expect(find.byKey(const Key('journal-entry-j1')), findsNothing);
    expect(find.textContaining('motif : Doublon'), findsOneWidget);
  });

  testWidgets('gestionnaire : pas d’entrée Journal', (tester) async {
    await openApp(tester, MemberRole.manager);
    expect(find.byKey(const Key('profile-journal')), findsNothing);
  });
}
