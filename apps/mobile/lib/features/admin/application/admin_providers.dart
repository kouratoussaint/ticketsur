import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';

/// Console d'administration ; surchargé dans `main.dart` et dans les tests.
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => throw UnimplementedError(
    'adminRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Le compte connecté est-il administrateur de la plateforme ? Relu à chaque
/// changement de compte ; `false` en cas d'échec (l'entrée reste cachée, et
/// le serveur refuse de toute façon).
final FutureProvider<bool> isPlatformAdminProvider =
    FutureProvider.autoDispose<bool>((ref) async {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return false;
      try {
        return await ref.read(adminRepositoryProvider).isPlatformAdmin();
      } on AdminFailure {
        return false;
      }
    });

/// Chiffres de la plateforme.
final FutureProvider<AdminOverview> adminOverviewProvider =
    FutureProvider.autoDispose<AdminOverview>(
      (ref) => ref.read(adminRepositoryProvider).overview(),
      retry: (retryCount, error) => null,
    );

/// Courbes des 30 derniers jours.
final FutureProvider<List<DailyStat>> adminDailyStatsProvider =
    FutureProvider.autoDispose<List<DailyStat>>(
      (ref) => ref.read(adminRepositoryProvider).dailyStats(),
      retry: (retryCount, error) => null,
    );
