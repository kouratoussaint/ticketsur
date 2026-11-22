import 'dart:async';
import 'dart:math' show min;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/app/remembered_filters.dart';
import 'package:ticketsur/features/catalog/application/catalog_cache.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
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

/// Derniers résultats gardés sur l'appareil (Explorer sans réseau).
final catalogCacheProvider = Provider<CatalogCache>(
  (ref) => CatalogCache(ref.watch(sharedPreferencesProvider)),
);

/// Délais des nouveaux essais quand l'Explorer est hors ligne (le dernier
/// se répète). Remplaçable en test.
final catalogRetryDelaysProvider = Provider<List<Duration>>(
  (ref) => const [
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
  ],
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

/// Résultats de l'Explorer, page par page. Sans réseau, la dernière
/// première page reçue pour la même recherche est relue sur l'appareil
/// ([savedAt] non nul) et un nouvel essai est fait régulièrement, sans
/// effacer l'écran.
class CatalogResults extends AsyncNotifier<List<PublicEventSummary>> {
  bool _exhausted = false;
  bool _loadingMore = false;
  DateTime? _savedAt;
  Timer? _retry;
  int _attempts = 0;
  bool _retrying = false;

  /// Encore des résultats à charger (jamais hors ligne).
  bool get hasMore => !_exhausted && _savedAt == null;

  /// Non nul : résultats relus sur l'appareil, reçus à cette heure.
  DateTime? get savedAt => _savedAt;

  @override
  Future<List<PublicEventSummary>> build() async {
    final query = ref.watch(catalogQueryProvider);
    _exhausted = false;
    _savedAt = null;
    ref.onDispose(() => _retry?.cancel());
    final now = ref.read(catalogClockProvider)();
    try {
      final page = await ref
          .read(catalogRepositoryProvider)
          .search(query, now: now);
      _exhausted = page.length < catalogPageSize;
      _attempts = 0;
      await ref.read(catalogCacheProvider).saveResults(query, page, now);
      return page;
    } on CatalogFailure catch (failure) {
      if (failure != CatalogFailure.network) rethrow;
      final cached = ref.read(catalogCacheProvider).results(query, now: now);
      if (cached == null) rethrow;
      _savedAt = cached.savedAt;
      _scheduleRetry();
      return cached.events;
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    final delays = ref.read(catalogRetryDelaysProvider);
    final delay = delays[min(_attempts, delays.length - 1)];
    _attempts++;
    _retry = Timer(delay, () => unawaited(retryNow()));
  }

  /// Hors ligne : réessaie tout de suite (retour dans l'app, minuterie).
  /// Au retour du réseau, la liste et « À la une » sont remplacées sans
  /// passer par le chargement ; sinon un nouvel essai est programmé.
  Future<void> retryNow() async {
    if (_savedAt == null || _retrying) return;
    _retry?.cancel();
    _retrying = true;
    final query = ref.read(catalogQueryProvider);
    final now = ref.read(catalogClockProvider)();
    try {
      final page = await ref
          .read(catalogRepositoryProvider)
          .search(query, now: now);
      // Recherche changée entre-temps : `build` s'en charge.
      if (!ref.mounted || ref.read(catalogQueryProvider) != query) return;
      await ref.read(catalogCacheProvider).saveResults(query, page, now);
      if (!ref.mounted) return;
      _savedAt = null;
      _attempts = 0;
      _exhausted = page.length < catalogPageSize;
      state = AsyncData(page);
      ref.invalidate(featuredEventsProvider);
    } on CatalogFailure {
      if (ref.mounted && _savedAt != null) _scheduleRetry();
    } finally {
      _retrying = false;
    }
  }

  /// Charge la page suivante (sans effet si tout est chargé).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !hasMore || _loadingMore) return;
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

/// Événements « À la une » d'Explorer : sans réseau, la dernière liste
/// reçue ; un autre échec : rien n'est affiché.
final FutureProvider<List<PublicEventSummary>> featuredEventsProvider =
    FutureProvider.autoDispose<List<PublicEventSummary>>((ref) async {
      final cache = ref.read(catalogCacheProvider);
      final now = ref.read(catalogClockProvider)();
      try {
        final events = await ref.read(catalogRepositoryProvider).featured();
        await cache.saveFeatured(events, now);
        return events;
      } on CatalogFailure catch (failure) {
        if (failure != CatalogFailure.network) rethrow;
        return cache.featured(now: now)?.events ?? (throw failure);
      }
    }, retry: (retryCount, error) => null);

/// Fiche publique d'un événement.
/// Page publique d'une structure (ADR 0045).
final FutureProviderFamily<PublicOrganization, String>
publicOrganizationProvider = FutureProvider.autoDispose
    .family<PublicOrganization, String>(
      (ref, id) => ref.read(catalogRepositoryProvider).organization(id),
      retry: (retryCount, error) => null,
    );

final FutureProviderFamily<PublicEventDetail, String> publicEventProvider =
    FutureProvider.autoDispose.family<PublicEventDetail, String>(
      (ref, id) => ref.read(catalogRepositoryProvider).event(id),
    );
