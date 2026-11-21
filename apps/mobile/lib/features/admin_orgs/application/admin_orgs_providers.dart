import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/admin_orgs/domain/admin_orgs.dart';

/// Structures depuis la console ; surchargé dans `main.dart` et les tests.
final adminOrgsRepositoryProvider = Provider<AdminOrgsRepository>(
  (ref) => throw UnimplementedError(
    'adminOrgsRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Fiche d'une structure.
final FutureProviderFamily<OrganizationDetail, String>
organizationDetailProvider = FutureProvider.autoDispose
    .family<OrganizationDetail, String>(
      (ref, id) => ref.read(adminOrgsRepositoryProvider).detail(id),
      retry: (retryCount, error) => null,
    );

/// Corbeille de la console.
final FutureProvider<List<TrashItem>> consoleTrashProvider =
    FutureProvider.autoDispose<List<TrashItem>>(
      (ref) => ref.read(adminOrgsRepositoryProvider).trash(),
      retry: (retryCount, error) => null,
    );
