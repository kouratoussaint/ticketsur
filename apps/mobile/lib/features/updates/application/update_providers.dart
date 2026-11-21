import 'dart:ffi' show Abi;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/app/build_info.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/updates/domain/update_checker.dart';

/// Source des versions ; surchargée dans `main.dart` et dans les tests.
final updateCheckerProvider = Provider<UpdateChecker>(
  (ref) => throw UnimplementedError(
    'updateCheckerProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Build de l'application installée (surchargé dans les tests).
final installedBuildProvider = Provider<int>((ref) => appBuild);

/// Heure courante (surchargée dans les tests).
final updateClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

const _lastCheckKey = 'updates.last_check';
const _latestKey = 'updates.latest';

/// Délai entre deux vérifications automatiques.
const updateCheckInterval = Duration(hours: 12);

/// Vérification de ce lancement déjà faite (une par lancement de l'app).
final class _LaunchCheck {
  bool done = false;
}

final _launchCheckProvider = Provider<_LaunchCheck>((ref) => _LaunchCheck());

/// Build plus récent disponible, sinon `null`. Vérifie à chaque lancement
/// de l'application (#9), puis au plus toutes les 12 heures (résultat gardé
/// dans les préférences) ; `force` passe outre. Sans réseau : silencieux.
class AvailableUpdate extends AsyncNotifier<int?> {
  @override
  Future<int?> build() {
    final launch = ref.read(_launchCheckProvider);
    final force = !launch.done;
    launch.done = true;
    return _check(force: force, silent: force);
  }

  /// « Rechercher une mise à jour ».
  Future<void> checkNow() async {
    state = const AsyncLoading();
    state = AsyncData(await _check(force: true));
  }

  Future<int?> _check({required bool force, bool silent = false}) async {
    final installed = ref.read(installedBuildProvider);
    if (installed <= 0) return null; // Développement : rien à comparer.
    final preferences = ref.read(sharedPreferencesProvider);
    final now = ref.read(updateClockProvider)();
    final last = DateTime.tryParse(preferences.getString(_lastCheckKey) ?? '');
    var latest = preferences.getInt(_latestKey);
    if (force ||
        latest == null ||
        last == null ||
        now.difference(last) >= updateCheckInterval) {
      int? fetched;
      try {
        fetched = await ref.read(updateCheckerProvider).latestBuild();
      } on Object {
        // Hors ligne : on garde la dernière réponse connue.
        if (!silent) rethrow;
      }
      if (fetched != null) {
        latest = fetched;
        await preferences.setInt(_latestKey, fetched);
        await preferences.setString(_lastCheckKey, now.toIso8601String());
      }
    }
    return latest != null && latest > installed ? latest : null;
  }
}

final AsyncNotifierProvider<AvailableUpdate, int?> availableUpdateProvider =
    AsyncNotifierProvider<AvailableUpdate, int?>(AvailableUpdate.new);

/// Heure de la dernière vérification réussie (« À propos »).
final lastUpdateCheckProvider = Provider<DateTime?>((ref) {
  ref.watch(availableUpdateProvider);
  return DateTime.tryParse(
    ref.read(sharedPreferencesProvider).getString(_lastCheckKey) ?? '',
  )?.toLocal();
});

/// Lien permanent de la dernière APK, selon le processeur du téléphone.
String latestApkUrl() {
  final file = Abi.current() == Abi.androidArm
      ? 'Tikeo-armeabi-v7a.apk'
      : 'Tikeo-arm64-v8a.apk';
  return 'https://github.com/kouratoussaint/ticketsur/releases/latest/download/$file';
}
