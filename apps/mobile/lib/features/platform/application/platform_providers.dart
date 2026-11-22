import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/platform/domain/platform_status.dart';

/// Surchargé dans `main.dart` et les tests.
final platformRepositoryProvider = Provider<PlatformRepository>(
  (ref) => throw UnimplementedError(
    'platformRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// État public de la plateforme, relu à chaque écran qui l'affiche. Un
/// échec ne bloque rien : l'app se comporte comme sans maintenance.
final FutureProvider<PlatformStatus> platformStatusProvider =
    FutureProvider.autoDispose<PlatformStatus>(
      (ref) => ref.read(platformRepositoryProvider).status(),
      retry: (retryCount, error) => null,
    );
