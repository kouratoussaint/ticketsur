import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/security/data/supabase_device_security_repository.dart';
import 'package:ticketsur/features/security/domain/security.dart';
import 'package:ticketsur/features/updates/application/update_providers.dart';

/// Appareils connectés ; surchargé dans `main.dart` et dans les tests.
final deviceSecurityRepositoryProvider = Provider<DeviceSecurityRepository>(
  (ref) => throw UnimplementedError(
    'deviceSecurityRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Empreinte ou code du téléphone ; remplacé dans les tests.
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => const LocalAuthBiometricService(),
);

/// Nom de l'appareil (marque et modèle), sans identifiant ; remplacé dans
/// les tests.
final deviceIdentityProvider = FutureProvider<DeviceIdentity>((ref) async {
  final build = ref.watch(installedBuildProvider);
  try {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final maker = info.manufacturer.trim();
      final model = info.model.trim();
      final label =
          model.toLowerCase().startsWith(maker.toLowerCase()) || maker.isEmpty
          ? model
          : '${maker[0].toUpperCase()}${maker.substring(1)} $model';
      return DeviceIdentity(label: label, platform: 'android', appBuild: build);
    }
    if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      return DeviceIdentity(
        label: info.model,
        platform: 'ios',
        appBuild: build,
      );
    }
  } on Object {
    // Nom inconnu : on garde un libellé générique.
  }
  return DeviceIdentity(label: 'Appareil', platform: 'other', appBuild: build);
});

/// Appareils connectés du compte (page « Appareils connectés »).
final FutureProvider<List<ConnectedDevice>> connectedDevicesProvider =
    FutureProvider.autoDispose<List<ConnectedDevice>>(
      (ref) => ref.watch(deviceSecurityRepositoryProvider).devices(),
    );

/// Vrai juste après une déconnexion décidée depuis un autre appareil :
/// l'app l'annonce une fois.
class RemoteSignOutNotice extends Notifier<bool> {
  @override
  bool build() => false;

  void raise() => state = true;

  void clear() => state = false;
}

final remoteSignOutNoticeProvider = NotifierProvider<RemoteSignOutNotice, bool>(
  RemoteSignOutNotice.new,
);

/// Inscrit l'appareil à l'ouverture de la coque connectée puis à chaque
/// retour au premier plan (au plus une fois par minute) ; si l'appareil a
/// été déconnecté à distance, ferme la session ici aussi.
final Provider<void> deviceRegistrationProvider = Provider.autoDispose<void>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return;
  DateTime? last;
  var busy = false;
  Future<void> register() async {
    final now = DateTime.now();
    if (busy || (last != null && now.difference(last!).inSeconds < 60)) {
      return;
    }
    busy = true;
    last = now;
    try {
      final device = await ref.read(deviceIdentityProvider.future);
      await ref.read(deviceSecurityRepositoryProvider).register(device);
    } on DeviceFailure catch (failure) {
      if (failure == DeviceFailure.sessionRevoked) {
        ref.read(remoteSignOutNoticeProvider.notifier).raise();
        try {
          await signOutToExplore(
            ref.read(routerProvider),
            ref.read(authRepositoryProvider).signOut,
          );
        } on Object {
          // Session déjà fermée côté serveur : rien à faire de plus.
        }
      }
    } on Object {
      // Sans réseau : nouvel essai au prochain retour au premier plan.
    } finally {
      busy = false;
    }
  }

  final listener = AppLifecycleListener(onResume: () => unawaited(register()));
  ref.onDispose(listener.dispose);
  unawaited(register());
});

/// Verrouillage par empreinte activé sur cet appareil.
class AppLockSetting extends Notifier<bool> {
  static const key = 'security.app_lock';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  bool build() => _prefs.getBool(key) ?? false;

  Future<void> set({required bool enabled}) async {
    state = enabled;
    await _prefs.setBool(key, enabled);
  }
}

final appLockSettingProvider = NotifierProvider<AppLockSetting, bool>(
  AppLockSetting.new,
);

/// Temps passé hors de l'app au-delà duquel elle se verrouille.
final appLockDelayProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 1),
);

/// L'app est verrouillée (écran de déverrouillage par-dessus tout).
class AppLocked extends Notifier<bool> {
  @override
  bool build() => false;

  void lock() => state = true;

  void unlock() => state = false;
}

final appLockedProvider = NotifierProvider<AppLocked, bool>(AppLocked.new);
