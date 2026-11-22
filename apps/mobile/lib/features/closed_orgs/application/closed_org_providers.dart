import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/closed_orgs/domain/closed_org.dart';

/// Dépôt des structures fermées (Supabase au démarrage, faux en test).
final closedOrgRepositoryProvider = Provider<ClosedOrgRepository>(
  (ref) => throw UnimplementedError(
    'closedOrgRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Structures fermées du compte connecté (vide sans compte).
final FutureProvider<List<ClosedOrganization>> closedOrganizationsProvider =
    FutureProvider.autoDispose<List<ClosedOrganization>>((ref) async {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return const [];
      return await ref.read(closedOrgRepositoryProvider).list();
    }, retry: (retryCount, error) => null);

/// Une structure fermée et ses événements.
final FutureProviderFamily<ClosedOrganizationDetail, String>
closedOrganizationProvider = FutureProvider.autoDispose
    .family<ClosedOrganizationDetail, String>(
      (ref, id) => ref.read(closedOrgRepositoryProvider).detail(id),
      retry: (retryCount, error) => null,
    );
