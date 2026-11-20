import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_scan_repository.dart';

const _user = AuthUser(id: 'u1', email: 'agent@exemple.bf');

Map<String, Object?> _withHolder(Map<String, Object?> response, String name) =>
    {
      ...response,
      'ticket': {
        'public_reference': 'TS-AAAA-0001',
        'category': 'VIP',
        'holder_name': name,
      },
    };

void main() {
  late FakeScanRepository scan;

  setUp(() {
    scan = FakeScanRepository(posts: [testPost()])
      ..matches.addAll([
        const DoorMatch(
          ticketId: 't1',
          reference: 'TS-AAAA-0001',
          category: 'VIP',
          status: TicketStatus.issued,
          holderName: 'Aïcha Ouédraogo',
          phoneHint: '•• 33',
        ),
        const DoorMatch(
          ticketId: 't2',
          reference: 'TS-BBBB-0002',
          category: 'Standard',
          status: TicketStatus.redeemed,
          holderName: 'Issa Sawadogo',
        ),
      ]);
  });

  Future<void> openPost(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(user: _user),
          organizations: FakeOrganizationRepository([
            Organization(
              id: testOrganization.id,
              name: testOrganization.name,
              slug: testOrganization.slug,
              role: MemberRole.controller,
            ),
          ]),
          scan: scan,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('control-door-p1')));
    await tester.pumpAndSettle();
  }

  test('nom du titulaire lu dans la réponse du serveur', () {
    final verdict = ScanVerdict.fromServer(
      _withHolder(scanResponse('r1', 'accepted', validationId: 'v1'), 'Awa'),
      expectedRequestId: 'r1',
    );
    expect(verdict.holderName, 'Awa');
    // Serveur ancien : pas de nom, rien ne change.
    expect(
      ScanVerdict.fromServer(
        scanResponse('r2', 'accepted', validationId: 'v2'),
        expectedRequestId: 'r2',
      ).holderName,
      isNull,
    );
  });

  testWidgets('QR perdu : recherche par nom, validation, nom affiché', (
    tester,
  ) async {
    scan.script.add(
      (id) => _withHolder(
        scanResponse(id, 'accepted', validationId: 'v1'),
        'Aïcha Ouédraogo',
      ),
    );
    await openPost(tester);
    await tester.tap(find.byKey(const Key('scanner-search')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('door-search-field')), 'ai');
    await tester.tap(find.byKey(const Key('door-search-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Au moins 3 caractères.'), findsOneWidget);
    expect(scan.queries, isEmpty);

    await tester.enterText(find.byKey(const Key('door-search-field')), 'aïcha');
    await tester.tap(find.byKey(const Key('door-search-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('door-match-t1')), findsOneWidget);
    expect(find.textContaining('•• 33'), findsOneWidget);
    await tester.tap(find.byKey(const Key('door-validate-t1')));
    await tester.pumpAndSettle();

    expect(scan.ticketIds, ['t1']);
    expect(scan.tokens, isEmpty);
    expect(find.text('ENTRÉE AUTORISÉE'), findsOneWidget);
    expect(find.textContaining('Titulaire : Aïcha Ouédraogo'), findsOneWidget);
  });

  testWidgets('ticket déjà utilisé : le serveur refuse, comme au scan', (
    tester,
  ) async {
    scan.script.add(
      (id) => scanResponse(
        id,
        'already_used',
        firstValidatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
    await openPost(tester);
    await tester.tap(find.byKey(const Key('scanner-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('door-search-field')), 'issa');
    await tester.tap(find.byKey(const Key('door-search-submit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Utilisé'), findsOneWidget);
    await tester.tap(find.byKey(const Key('door-validate-t2')));
    await tester.pumpAndSettle();
    expect(find.text('ENTRÉE AUTORISÉE'), findsNothing);
    expect(find.byKey(const Key('verdict-title')), findsOneWidget);
  });

  testWidgets('aucun résultat ; contrôle fermé : message clair', (
    tester,
  ) async {
    await openPost(tester);
    await tester.tap(find.byKey(const Key('scanner-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('door-search-field')), 'zzz');
    await tester.tap(find.byKey(const Key('door-search-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('door-search-empty')), findsOneWidget);
    scan.lookupFailure = DoorLookupFailure.forbidden;
    await tester.tap(find.byKey(const Key('door-search-submit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('contrôle est ouvert'), findsOneWidget);
  });
}
