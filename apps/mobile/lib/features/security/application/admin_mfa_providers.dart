import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/security/domain/admin_mfa.dart';

/// Double authentification ; surchargé dans `main.dart` et dans les tests.
final adminMfaRepositoryProvider = Provider<AdminMfaRepository>(
  (ref) => throw UnimplementedError(
    'adminMfaRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// État de la double authentification du compte connecté (administrateurs).
final FutureProvider<AdminMfaStatus> adminMfaStatusProvider =
    FutureProvider.autoDispose<AdminMfaStatus>((ref) {
      ref.watch(currentUserProvider.select((user) => user.value?.id));
      return ref.read(adminMfaRepositoryProvider).status();
    }, retry: (retryCount, error) => null);
