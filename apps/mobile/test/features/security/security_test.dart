import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/security/application/security_providers.dart';
import 'package:ticketsur/features/security/data/supabase_device_security_repository.dart';
import 'package:ticketsur/features/security/domain/security.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_device_security.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'awa@kwabo.bf');

  test('erreurs serveur traduites', () {
    supabase.PostgrestException error(String message) =>
        supabase.PostgrestException(message: message);
    expect(
      mapDeviceError(error('session_revoked')),
      DeviceFailure.sessionRevoked,
    );
    expect(mapDeviceError(error('device_current')), DeviceFailure.current);
    expect(mapDeviceError(error('device_not_found')), DeviceFailure.notFound);
    expect(mapDeviceError(error('autre')), DeviceFailure.unknown);
  });

  late FakeAuthRepository auth;
  late FakeDeviceSecurityRepository devices;
  late FakeBiometricService biometric;

  setUp(() {
    auth = FakeAuthRepository(user: user);
    devices = FakeDeviceSecurityRepository(
      devices: [
        connectedDevice(id: 'here', current: true),
        connectedDevice(id: 's2', label: 'Samsung A15'),
        connectedDevice(id: 's3', label: null, platform: null),
      ],
    );
    biometric = FakeBiometricService();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> preferences = const {},
    String? path,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await appOverrides(
            auth: auth,
            devices: devices,
            biometric: biometric,
            preferences: preferences,
          ),
          appLockDelayProvider.overrideWithValue(Duration.zero),
        ],
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (path != null) {
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
      await tester.pumpAndSettle();
    }
  }

  group('appareils connectés', () {
    testWidgets('appareil inscrit à l’ouverture de la session', (tester) async {
      await pumpApp(tester);
      expect(devices.registered.single.label, 'Tecno Spark 10');
      expect(devices.registered.single.appBuild, 139);
    });

    testWidgets('liste : cet appareil d’abord ; en déconnecter un', (
      tester,
    ) async {
      await pumpApp(tester, path: AppRoutes.devices);
      expect(find.byKey(const Key('device-current')), findsOneWidget);
      expect(find.text('Samsung A15'), findsOneWidget);
      expect(find.text('Appareil non identifié'), findsOneWidget);
      // Pas de bouton sur l'appareil en cours.
      expect(find.byKey(const Key('device-revoke-here')), findsNothing);

      await tester.tap(find.byKey(const Key('device-revoke-s2')));
      await tester.pumpAndSettle();
      expect(find.text('Déconnecter « Samsung A15 » ?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('device-revoke-confirm')));
      await tester.pumpAndSettle();
      expect(devices.calls, ['revoke s2']);
      expect(find.text('Samsung A15'), findsNothing);
      expect(find.text('« Samsung A15 » est déconnecté.'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('devices-revoke-others')),
      );
      await tester.tap(find.byKey(const Key('devices-revoke-others')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('devices-revoke-others-confirm')));
      await tester.pumpAndSettle();
      expect(devices.calls.last, 'others');
      expect(find.text('1 appareil déconnecté.'), findsOneWidget);
      expect(find.byKey(const Key('devices-only-this')), findsOneWidget);
    });

    testWidgets('profil → appareils connectés', (tester) async {
      await pumpApp(tester, path: AppRoutes.profile);
      final row = find.byKey(const Key('profile-devices'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('devices-list')), findsOneWidget);
    });

    testWidgets('déconnecté à distance : session fermée ici aussi', (
      tester,
    ) async {
      devices.nextRegisterFailure = DeviceFailure.sessionRevoked;
      await pumpApp(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNull);
      expect(find.byKey(const Key('remote-sign-out')), findsOneWidget);
      expect(find.byKey(const Key('explore-list')), findsOneWidget);
    });
  });

  group('verrouillage par empreinte', () {
    testWidgets('activé : verrouillé au lancement, empreinte demandée', (
      tester,
    ) async {
      await pumpApp(tester, preferences: {AppLockSetting.key: true});
      expect(biometric.prompts, 1);
      // Empreinte reconnue : l'app s'ouvre.
      expect(find.byKey(const Key('app-lock')), findsNothing);
    });

    testWidgets('empreinte refusée : reste verrouillé, déconnexion possible', (
      tester,
    ) async {
      biometric.succeed = false;
      await pumpApp(tester, preferences: {AppLockSetting.key: true});
      expect(find.byKey(const Key('app-lock')), findsOneWidget);
      expect(
        find.text('Non reconnu. Réessayez, ou déconnectez-vous.'),
        findsOneWidget,
      );
      biometric.succeed = true;
      await tester.tap(find.byKey(const Key('app-lock-unlock')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app-lock')), findsNothing);
    });

    testWidgets('verrouillé : se déconnecter mène à Explorer', (tester) async {
      biometric.succeed = false;
      await pumpApp(tester, preferences: {AppLockSetting.key: true});
      await tester.tap(find.byKey(const Key('app-lock-sign-out')));
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNull);
      expect(find.byKey(const Key('app-lock')), findsNothing);
      expect(find.byKey(const Key('explore-list')), findsOneWidget);
    });

    testWidgets('retour dans l’app après un passage en arrière-plan', (
      tester,
    ) async {
      await pumpApp(tester, preferences: {AppLockSetting.key: true});
      biometric.succeed = false;
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app-lock')), findsOneWidget);
      expect(biometric.prompts, 2);
    });

    testWidgets('désactivé : jamais verrouillé', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(const Key('app-lock')), findsNothing);
      expect(biometric.prompts, 0);
    });

    testWidgets('activer depuis le profil : empreinte demandée d’abord', (
      tester,
    ) async {
      await pumpApp(tester, path: AppRoutes.profile);
      final row = find.byKey(const Key('profile-app-lock-switch'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();

      biometric.available = false;
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(
        find.text("Aucune empreinte ni code n'est configuré sur ce téléphone."),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(row).value, isFalse);

      biometric.available = true;
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(biometric.prompts, 1);
      expect(tester.widget<Switch>(row).value, isTrue);
      expect(find.byKey(const Key('app-lock')), findsNothing);

      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(row).value, isFalse);
    });
  });
}
