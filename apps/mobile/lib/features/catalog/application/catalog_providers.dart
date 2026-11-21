import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/app/remembered_filters.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dépôt du catalogue (Supabase au démarrage, faux en test).
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => throw UnimplementedError(
    'catalogRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Heure courante (remplaçable en test).
final catalogClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Ouvre un lien hors de l'app (WhatsApp) ; `false` si rien ne peut l'ouvrir.
final externalLinkProvider = Provider<Future<bool> Function(Uri uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Critères choisis dans l'Explorer.
class CatalogQueryController extends Notifier<CatalogQuery> {
  /// Ville choisie, mémorisée sur l'appareil (même sans compte).
  static const cityFilter = 'explore.city';

  @override
  CatalogQuery build() => CatalogQuery(
    city: ref.read(rememberedFiltersProvider).read(cityFilter, device: true),
  );

  void update(CatalogQuery query) {
    if (query.city != state.city) {
      ref
          .read(rememberedFiltersProvider)
          .write(cityFilter, query.city, device: true);
    }
    state = query;
  }

  void search(String text) => state = state.copyWith(search: text);
}

final NotifierProvider<CatalogQueryController, CatalogQuery>
catalogQueryProvider = NotifierProvider<CatalogQueryController, CatalogQuery>(
  CatalogQueryController.new,
);

/// Nombre d'événements chargés par page.
const catalogPageSize = 30;

/// Résultats de l'Explorer, page par page.
class CatalogResults extends AsyncNotifier<List<PublicEventSummary>> {
  bool _exhausted = false;
  bool _loadingMore = false;

  /// Encore des résultats à charger.
  bool get hasMore => !_exhausted;

  @override
  Future<List<PublicEventSummary>> build() async {
    final query = ref.watch(catalogQueryProvider);
    _exhausted = false;
    final page = await ref
        .read(catalogRepositoryProvider)
        .search(query, now: ref.read(catalogClockProvider)());
    _exhausted = page.length < catalogPageSize;
    return page;
  }

  /// Charge la page suivante (sans effet si tout est chargé).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || _exhausted || _loadingMore) return;
    _loadingMore = true;
    try {
      final page = await ref
          .read(catalogRepositoryProvider)
          .search(
            ref.read(catalogQueryProvider),
            now: ref.read(catalogClockProvider)(),
            offset: current.length,
          );
      if (!ref.mounted) return;
      _exhausted = page.length < catalogPageSize;
      state = AsyncData([...current, ...page]);
    } finally {
      _loadingMore = false;
    }
  }
}

final AsyncNotifierProvider<CatalogResults, List<PublicEventSummary>>
catalogResultsProvider =
    AsyncNotifierProvider<CatalogResults, List<PublicEventSummary>>(
      CatalogResults.new,
    );

/// Événements « À la une » d'Explorer (un échec : rien n'est affiché).
final FutureProvider<List<PublicEventSummary>> featuredEventsProvider =
    FutureProvider.autoDispose<List<PublicEventSummary>>(
      (ref) => ref.read(catalogRepositoryProvider).featured(),
      retry: (retryCount, error) => null,
    );

/// Fiche publique d'un événement.
final FutureProviderFamily<PublicEventDetail, String> publicEventProvider =
    FutureProvider.autoDispose.family<PublicEventDetail, String>(
      (ref, id) => ref.read(catalogRepositoryProvider).event(id),
    );
