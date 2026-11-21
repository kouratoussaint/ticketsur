import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';

/// Gestion des comptes ; surchargé dans `main.dart` et dans les tests.
final adminAccountsRepositoryProvider = Provider<AdminAccountsRepository>(
  (ref) => throw UnimplementedError(
    'adminAccountsRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Rôle et permissions de l'administrateur connecté (null : pas
/// administrateur).
final FutureProvider<AdminMe?> adminMeProvider =
    FutureProvider.autoDispose<AdminMe?>((ref) async {
      ref.watch(currentUserProvider.select((user) => user.value?.id));
      final admin = await ref.watch(isPlatformAdminProvider.future);
      if (!admin) return null;
      return await ref.read(adminAccountsRepositoryProvider).me();
    }, retry: (retryCount, error) => null);

/// Fiche d'un compte.
final FutureProviderFamily<AccountDetail, String> accountDetailProvider =
    FutureProvider.autoDispose.family<AccountDetail, String>(
      (ref, userId) => ref.read(adminAccountsRepositoryProvider).detail(userId),
      retry: (retryCount, error) => null,
    );

/// Administrateurs de la plateforme.
final FutureProvider<List<PlatformAdmin>> platformAdminsProvider =
    FutureProvider.autoDispose<List<PlatformAdmin>>(
      (ref) => ref.read(adminAccountsRepositoryProvider).platformAdmins(),
      retry: (retryCount, error) => null,
    );

/// Compte connecté : mot de passe provisoire à changer (faux sans compte
/// ou sans réseau : jamais bloquant par erreur).
final FutureProvider<bool> mustChangePasswordProvider =
    FutureProvider.autoDispose<bool>((ref) async {
      final user = ref.watch(currentUserProvider.select((u) => u.value?.id));
      if (user == null) return false;
      try {
        return await ref
            .read(adminAccountsRepositoryProvider)
            .mustChangePassword();
      } on Object {
        return false;
      }
    });
