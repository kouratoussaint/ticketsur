import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/support/domain/support.dart';

/// Support ; surchargé dans `main.dart` et dans les tests.
final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => throw UnimplementedError(
    'supportRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Demandes de l'utilisateur connecté (vide sans compte).
final FutureProvider<List<SupportRequest>> mySupportRequestsProvider =
    FutureProvider.autoDispose<List<SupportRequest>>((ref) async {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return const [];
      return await ref.read(supportRepositoryProvider).myRequests();
    }, retry: (retryCount, error) => null);

/// Nombre de demandes avec une réponse non lue.
final Provider<int> supportUnreadProvider = Provider.autoDispose<int>(
  (ref) =>
      ref
          .watch(mySupportRequestsProvider)
          .value
          ?.where((r) => r.unread)
          .length ??
      0,
);

/// Fil d'une demande.
final FutureProviderFamily<List<SupportMessage>, String> supportThreadProvider =
    FutureProvider.autoDispose.family<List<SupportMessage>, String>(
      (ref, id) => ref.read(supportRepositoryProvider).thread(id),
      retry: (retryCount, error) => null,
    );

/// Console : compteurs du support.
final FutureProvider<SupportCounts> supportCountsProvider =
    FutureProvider.autoDispose<SupportCounts>(
      (ref) => ref.read(supportRepositoryProvider).adminCounts(),
      retry: (retryCount, error) => null,
    );
