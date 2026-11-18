import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/features/scanner/presentation/control_home_page.dart';
import 'package:ticketsur/features/scanner/presentation/scanner_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_scan_repository.dart';

const _token = 'TS1.abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ';
const _user = AuthUser(id: 'u1', email: 'agent@exemple.bf');

void main() {
  late FakeScanRepository scan;

  Future<void> pumpApp(
    WidgetTester tester, {
    MemberRole role = MemberRole.controller,
    FakeEventRepository? events,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(user: _user),
          organizations: FakeOrganizationRepository([
            Organization(
              id: testOrganization.id,
              name: testOrganization.name,
              slug: testOrganization.slug,
              role: role,
            ),
          ]),
          events: events,
          scan: scan,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder navLabel(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  setUp(() => scan = FakeScanRepository(posts: [testPost()]));

  group('contrôleur', () {
    testWidgets('barre réduite : Contrôle, Historique, Profil', (tester) async {
      await pumpApp(tester);
      expect(navLabel('Contrôle'), findsOneWidget);
      expect(navLabel('Historique'), findsOneWidget);
      expect(navLabel('Profil'), findsOneWidget);
      expect(navLabel('Événements'), findsNothing);
      expect(navLabel('Billets'), findsNothing);
      expect(navLabel('Équipe'), findsNothing);
      // Ouvre directement sur le contrôle.
      expect(find.byType(ControlHomePage).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('control-event-e1')), findsOneWidget);
    });

    testWidgets('choisir sa porte, coller un code : entrée autorisée, '
        'puis billet suivant', (tester) async {
      scan.script.add((id) => scanResponse(id, 'accepted', validationId: 'v1'));
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('control-door-p1')));
      await tester.pumpAndSettle();
      expect(find.byType(ScannerPage), findsOneWidget);
      expect(find.text('Entrée Nord'), findsOneWidget);

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData'
            ? <String, Object?>{'text': _token}
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.byKey(const Key('scanner-paste')));
      await tester.pumpAndSettle();

      expect(scan.tokens, [_token]);
      expect(find.text('ENTRÉE AUTORISÉE'), findsOneWidget);
      await tester.tap(find.byKey(const Key('verdict-next')));
      await tester.pumpAndSettle();
      expect(find.text('1 billet vérifié'), findsOneWidget);
      expect(find.byKey(const Key('scanner-code')), findsOneWidget);
    });

    testWidgets('déjà utilisé : refus avec heure et porte de la première '
        'entrée', (tester) async {
      scan.script.add(
        (id) => scanResponse(
          id,
          'already_used',
          firstValidatedAt: DateTime.utc(2030, 1, 1, 19, 30).toIso8601String(),
        ),
      );
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('control-door-p1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('scanner-code')), _token);
      await tester.tap(find.byKey(const Key('scanner-validate')));
      await tester.pumpAndSettle();
      expect(find.text('ENTRÉE REFUSÉE'), findsOneWidget);
      expect(find.text('Ticket déjà utilisé'), findsOneWidget);
      // 19:30 UTC = 19:30 à Ouagadougou (UTC+0).
      expect(find.textContaining('19:30'), findsWidgets);
      expect(find.textContaining('Entrée Nord'), findsWidgets);
    });

    testWidgets('serveur injoignable : « état à confirmer », Réessayer '
        'rejoue la même requête', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('control-door-p1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('scanner-code')), _token);
      await tester.tap(find.byKey(const Key('scanner-validate')));
      await tester.pumpAndSettle();
      expect(find.text('ÉTAT À CONFIRMER'), findsOneWidget);
      expect(find.text('ENTRÉE AUTORISÉE'), findsNothing);
      final firstId = scan.requestIds.first;
      expect(scan.requestIds.toSet(), {firstId});

      scan.script.add((id) => scanResponse(id, 'accepted', validationId: 'v1'));
      await tester.tap(find.byKey(const Key('verdict-retry')));
      await tester.pumpAndSettle();
      expect(scan.requestIds.last, firstId);
      expect(find.text('ENTRÉE AUTORISÉE'), findsOneWidget);
    });

    testWidgets('aucun poste : explication', (tester) async {
      scan = FakeScanRepository();
      await pumpApp(tester);
      expect(find.byKey(const Key('control-empty')), findsOneWidget);
    });

    testWidgets('historique des scans récents', (tester) async {
      scan = FakeScanRepository(
        posts: [testPost()],
        recent: [
          RecentScan(
            id: 's1',
            serverTime: DateTime.utc(2030, 1, 1, 20),
            outcome: ScanResult.accepted,
            eventTitle: 'Gala',
            checkpointName: 'Entrée Nord',
            reference: 'TS-AAAA-0001',
            category: 'VIP',
          ),
          RecentScan(
            id: 's2',
            serverTime: DateTime.utc(2030, 1, 1, 20, 5),
            outcome: ScanResult.alreadyUsed,
            reference: 'TS-AAAA-0001',
          ),
        ],
      );
      await pumpApp(tester);
      await tester.tap(navLabel('Historique'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-s1')), findsOneWidget);
      expect(find.text('ENTRÉE REFUSÉE · Ticket déjà utilisé'), findsOneWidget);
      expect(find.textContaining('TS-AAAA-0001'), findsNWidgets(2));
    });

    testWidgets('Retour depuis le poste de scan : liste des postes', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('control-door-p1')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ScannerPage), findsNothing);
      expect(find.byType(ControlHomePage).hitTestable(), findsOneWidget);
    });
  });

  group('organisateur affecté', () {
    testWidgets('raccourci sur l’Accueil et bouton sur la fiche', (
      tester,
    ) async {
      await pumpApp(
        tester,
        role: MemberRole.owner,
        events: FakeEventRepository([
          testEvent(id: 'e1', title: 'Gala', status: EventStatus.inProgress),
        ]),
      );
      expect(navLabel('Événements'), findsOneWidget);
      expect(find.byKey(const Key('home-control')), findsOneWidget);
      expect(find.text('1 porte vous est attribuée'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home-control')));
      await tester.pumpAndSettle();
      expect(find.byType(ControlHomePage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(navLabel('Événements'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-card-e1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-control')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('control-door-p1')), findsOneWidget);
    });

    testWidgets('non affecté : aucun raccourci', (tester) async {
      scan = FakeScanRepository();
      await pumpApp(tester, role: MemberRole.owner);
      expect(find.byKey(const Key('home-control')), findsNothing);
    });
  });
}
