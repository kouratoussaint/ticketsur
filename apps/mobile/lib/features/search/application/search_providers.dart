import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/search/domain/search.dart';

/// Recherche globale ; surchargé dans `main.dart` et dans les tests.
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => throw UnimplementedError(
    'searchRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Résultats pour une recherche dans la structure active.
final FutureProviderFamily<PromoterSearchResult, String>
promoterSearchProvider = FutureProvider.autoDispose
    .family<PromoterSearchResult, String>((ref, query) {
      final organization = ref.watch(activeOrganizationProvider);
      if (organization == null || query.trim().length < minSearchLength) {
        return Future.value(const PromoterSearchResult());
      }
      return ref
          .read(searchRepositoryProvider)
          .search(organization.id, query.trim());
    });
