import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_camera.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_overlay.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_scan_camera.dart';
import '../../helpers/fake_scan_repository.dart';
import '../../helpers/fake_sound_player.dart';
import '../../helpers/pump_app.dart';

const _token = 'TS1.abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ';
const _other = 'TS1.ZYXWVUTSRQPONMLKJIHGFEDCBAzyxwvutsrqponmlkj';

void main() {
  late FakeScanRepository scan;
  late FakeCameraFeed camera;
  late FakeSoundPlayer sounds;

  Future<void> openScanner(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(
            user: const AuthUser(id: 'u1', email: 'agent@exemple.bf'),
          ),
          organizations: FakeOrganizationRepository([
            Organization(
              id: testOrganization.id,
              name: testOrganization.name,
              slug: testOrganization.slug,
              role: MemberRole.controller,
            ),
          ]),
          scan: scan,
          camera: camera,
          sounds: sounds,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('control-door-p1')));
    await tester.pumpAndSettle();
  }

  Future<void> read(WidgetTester tester, String code) async {
    camera.code = code;
    await tester.tap(find.byKey(const Key('fake-camera-read')));
    await tester.pumpAndSettle();
  }

  setUp(() {
    scan = FakeScanRepository(posts: [testPost()]);
    camera = FakeCameraFeed();
    sounds = FakeSoundPlayer();
  });

  testWidgets('QR lu par la caméra : verdict vert et son d’entrée', (
    tester,
  ) async {
    scan.script.add((id) => scanResponse(id, 'accepted', validationId: 'v1'));
    await openScanner(tester);
    expect(find.text('Placez le QR code dans le cadre'), findsOneWidget);
    expect(find.text('Entrée Nord'), findsOneWidget);
    sounds.played.clear();

    await read(tester, _token);
    expect(scan.tokens, [_token]);
    expect(find.text('ENTRÉE AUTORISÉE'), findsOneWidget);
    expect(sounds.played, [UiSound.admitted]);
  });

  testWidgets('réarmement : même QR encore devant l’objectif ignoré, '
      'autre QR lu aussitôt', (tester) async {
    scan.script
      ..add((id) => scanResponse(id, 'accepted', validationId: 'v1'))
      ..add((id) => scanResponse(id, 'accepted', validationId: 'v2'));
    await openScanner(tester);
    await read(tester, _token);
    // Pendant le verdict, les lectures sont ignorées.
    await tester.tap(
      find.byKey(const Key('fake-camera-read')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(scan.tokens, [_token]);

    await tester.tap(find.byKey(const Key('verdict-next')));
    await tester.pumpAndSettle();
    await read(tester, _token); // toujours devant l'objectif
    expect(scan.tokens, [_token]);

    await read(tester, _other); // ticket suivant
    expect(scan.tokens, [_token, _other]);
    expect(find.text('ENTRÉE AUTORISÉE'), findsOneWidget);
  });

  testWidgets('refus : son distinct', (tester) async {
    scan.script.add((id) => scanResponse(id, 'revoked'));
    await openScanner(tester);
    sounds.played.clear();
    await read(tester, _token);
    expect(find.text('ENTRÉE REFUSÉE'), findsOneWidget);
    expect(sounds.played, [UiSound.refused]);
  });

  testWidgets('QR étranger : refusé sans appel serveur', (tester) async {
    await openScanner(tester);
    await read(tester, 'WIFI:S:reseau;T:WPA;P:secret;;');
    expect(scan.tokens, isEmpty);
    expect(find.text('Ticket introuvable'), findsOneWidget);
  });

  testWidgets('quitter le poste : retour à la liste des postes', (
    tester,
  ) async {
    await openScanner(tester);
    await tester.tap(find.byKey(const Key('scanner-leave')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('control-door-p1')), findsOneWidget);
  });

  group('caméra indisponible', () {
    testWidgets('permission refusée : explication, réessayer, saisie', (
      tester,
    ) async {
      var retries = 0;
      var manual = 0;
      await tester.pumpApp(
        CameraErrorView(
          permissionDenied: true,
          onRetry: () => retries++,
          onManualEntry: () => manual++,
        ),
      );
      expect(find.text('Accès à la caméra refusé'), findsOneWidget);
      await tester.tap(find.byKey(const Key('camera-retry')));
      await tester.tap(find.text('Saisir le code'));
      expect((retries, manual), (1, 1));
    });

    testWidgets('autre erreur : caméra indisponible', (tester) async {
      await tester.pumpApp(
        CameraErrorView(
          permissionDenied: false,
          onRetry: () {},
          onManualEntry: () {},
        ),
      );
      expect(find.text('Caméra indisponible'), findsOneWidget);
    });
  });

  test('fenêtre de lecture : carrée, centrée, bornée', () {
    final phone = scanWindowFor(const Size(400, 800));
    expect(phone.width, phone.height);
    expect(phone.center.dx, 200);
    expect(phone.width, closeTo(272, 0.01));
    expect(scanWindowFor(const Size(1200, 1600)).width, 340);
    expect(scanWindowFor(const Size(250, 400)).width, 200);
  });

  testWidgets('cadre de visée : s’affiche sans erreur', (tester) async {
    await tester.pumpApp(
      const ScanOverlay(window: Rect.fromLTWH(50, 100, 250, 250)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ScanOverlay), findsOneWidget);
  });
}
