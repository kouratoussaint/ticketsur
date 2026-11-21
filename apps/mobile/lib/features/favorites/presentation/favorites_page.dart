import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/selection.dart';
import 'package:ticketsur/design_system/components/swipe.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/favorites/application/favorites_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Période affichée dans « Mes favoris ».
enum FavoritesPeriod { upcoming, past, all }

/// Tri de « Mes favoris » : plus proches de maintenant, ou plus récents
/// d'abord.
enum FavoritesSort { nearest, recent }

/// Filtres de « Mes favoris » (#15).
@immutable
final class FavoritesFilter {
  const new({
    this.text = '',
    this.period,
    this.kind,
    this.city,
    this.sort = FavoritesSort.nearest,
  });

  final String text;

  /// Null : « À venir » s'il y en a, sinon « Tous ».
  final FavoritesPeriod? period;
  final EventKind? kind;
  final String? city;
  final FavoritesSort sort;

  bool get narrowed =>
      text.trim().isNotEmpty ||
      kind != null ||
      city != null ||
      sort != FavoritesSort.nearest;

  FavoritesFilter copyWith({
    String? text,
    FavoritesPeriod? period,
    EventKind? Function()? kind,
    String? Function()? city,
    FavoritesSort? sort,
  }) => FavoritesFilter(
    text: text ?? this.text,
    period: period ?? this.period,
    kind: kind == null ? this.kind : kind(),
    city: city == null ? this.city : city(),
    sort: sort ?? this.sort,
  );
}

/// Favoris visibles avec [filter] à l'instant [now] ; [period] : période
/// effective.
List<PublicEventSummary> filterFavorites(
  List<PublicEventSummary> favorites, {
  required FavoritesFilter filter,
  required FavoritesPeriod period,
  required DateTime now,
}) {
  final needle = _fold(filter.text.trim());
  final list = [
    for (final e in favorites)
      if (switch (period) {
            FavoritesPeriod.upcoming => !e.endsAt.isBefore(now),
            FavoritesPeriod.past => e.endsAt.isBefore(now),
            FavoritesPeriod.all => true,
          } &&
          (filter.kind == null || e.kind == filter.kind) &&
          (filter.city == null || e.city == filter.city) &&
          (needle.isEmpty ||
              _fold(
                '${e.title} ${e.venue ?? ''} ${e.city ?? ''} '
                '${e.organizationName}',
              ).contains(needle)))
        e,
  ];
  int distance(PublicEventSummary e) =>
      e.startsAt.difference(now).inMinutes.abs();
  return list..sort(
    (a, b) => switch (filter.sort) {
      FavoritesSort.nearest => distance(a).compareTo(distance(b)),
      FavoritesSort.recent => b.startsAt.compareTo(a.startsAt),
    },
  );
}

/// Minuscules sans accents, pour la recherche.
String _fold(String text) {
  const from = 'àâäáãçéèêëíìîïñóòôöõúùûüÿ';
  const to = 'aaaaaceeeeiiiinooooouuuuy';
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final char in lower.split('')) {
    final i = from.indexOf(char);
    out.write(i < 0 ? char : to[i]);
  }
  return out.toString();
}

/// Événements mis en favori sur cet appareil (#15) : en-tête avec recherche
/// et filtres, puces À venir / Passés / Tous, types, ville, tri ; cartes
/// d'Explorer, cœur rouge pour retirer (avec « Annuler »).
class FavoritesPage extends ConsumerStatefulWidget {
  const new({this.showBack = true, super.key});

  /// Faux dans l'onglet Favoris (pas de flèche de retour).
  final bool showBack;

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final _search = TextEditingController();
  FavoritesFilter _filter = const FavoritesFilter();

  /// Sélection multiple (appui long) : favoris choisis, par identifiant.
  final Set<String> _selection = {};

  bool get _selecting => _selection.isNotEmpty;

  void _toggle(String id) => setState(() {
    if (!_selection.remove(id)) _selection.add(id);
  });

  void _clearSelection() => setState(_selection.clear);

  /// Retire les favoris choisis ; « Annuler » les remet.
  Future<void> _removeSelected() => _remove({..._selection});

  /// Retire des favoris ; « Annuler » les remet.
  Future<void> _remove(Set<String> ids) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final favorites = ref.read(favoritesProvider.notifier);
    final removed = await favorites.removeMany(ids);
    if (!mounted) return;
    _clearSelection();
    toast.info(
      l10n.favoritesBulkRemoved(removed.length),
      action: SnackBarAction(
        key: const Key('favorites-bulk-undo'),
        label: l10n.favoriteUndo,
        onPressed: () => unawaited(favorites.restore(removed)),
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _update(FavoritesFilter filter) => setState(() => _filter = filter);

  Future<void> _openFilters(List<String> cities) async {
    final result = await showModalBottomSheet<FavoritesFilter>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _FavoritesFilterSheet(filter: _filter, cities: cities),
    );
    if (result != null && mounted) _update(result);
  }

  void _reset() {
    _search.clear();
    _update(FavoritesFilter(period: _filter.period));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final favorites = ref.watch(favoritesProvider);
    final now = ref.watch(catalogClockProvider)().toUtc();
    final upcomingCount = favorites
        .where((e) => !e.endsAt.isBefore(now))
        .length;
    final pastCount = favorites.length - upcomingCount;
    final period =
        _filter.period ??
        (upcomingCount > 0 ? FavoritesPeriod.upcoming : FavoritesPeriod.all);
    final cities = {
      for (final e in favorites)
        if (e.city case final city? when city.isNotEmpty) city,
    }.toList()..sort();
    final kinds = {for (final e in favorites) e.kind}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final visible = filterFavorites(
      favorites,
      filter: _filter,
      period: period,
      now: now,
    );
    final filterCount =
        (_filter.city != null ? 1 : 0) +
        (_filter.sort != FavoritesSort.nearest ? 1 : 0);
    const margin = EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin);
    Widget periodChip(
      FavoritesPeriod value,
      String label,
      int count,
      Key key,
    ) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: key,
        label: Text(l10n.favoritesPeriodLabel(label, count)),
        selected: period == value,
        onSelected: (_) => _update(_filter.copyWith(period: value)),
      ),
    );

    // Une sélection ne garde que les favoris encore présents.
    _selection.removeWhere((id) => !favorites.any((e) => e.id == id));
    return PopScope(
      // Retour : quitte d'abord la sélection.
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: _selecting
            ? SelectionAppBar(
                key: const Key('favorites-selection-bar'),
                count: _selection.length,
                onClose: _clearSelection,
                onSelectAll: () => setState(
                  () => _selection.addAll([for (final e in visible) e.id]),
                ),
              )
            : null,
        bottomNavigationBar: _selecting
            ? SelectionActionBar(
                key: const Key('favorites-selection-actions'),
                actions: [
                  SelectionAction(
                    key: const Key('favorites-bulk-remove'),
                    icon: Icons.heart_broken_rounded,
                    label: l10n.favoritesBulkRemove,
                    danger: true,
                    onPressed: () => unawaited(_removeSelected()),
                  ),
                ],
              )
            : null,
        body: ListView(
          key: const Key('favorites-list'),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          children: [
            if (!_selecting)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TikeoHeroHeader(
                    title: l10n.favoritesTitle,
                    subtitle: l10n.favoritesHeroSubtitle(favorites.length),
                    onBack: widget.showBack ? () => context.pop() : null,
                    actions: [
                      if (cities.isNotEmpty)
                        CityPillButton(
                          buttonKey: const Key('favorites-city'),
                          city: _filter.city,
                          onPressed: () => unawaited(_openFilters(cities)),
                        ),
                    ],
                  ),
                  TikeoOverlapCard(
                    padding: const EdgeInsets.all(12),
                    child: TikeoSearchBar(
                      fieldKey: const Key('favorites-search'),
                      filterKey: const Key('favorites-filters'),
                      controller: _search,
                      hint: l10n.favoritesSearchHint,
                      semanticLabel: l10n.favoritesSearchHint,
                      onChanged: (text) =>
                          _update(_filter.copyWith(text: text)),
                      onFilter: () => unawaited(_openFilters(cities)),
                      filterTooltip: l10n.favoritesFilters,
                      filterCount: filterCount,
                    ),
                  ),
                ],
              ),
            if (favorites.isEmpty)
              Padding(
                padding: const EdgeInsets.all(TikeoSizes.screenMargin),
                child: EmptyState(
                  icon: Icons.favorite_rounded,
                  illustration: TikeoIllustration.noEvents,
                  title: l10n.favoritesEmptyTitle,
                  titleKey: const Key('favorites-empty'),
                  body: l10n.favoritesEmptyBody,
                  actionLabel: l10n.favoritesExplore,
                  actionKey: const Key('favorites-explore'),
                  onAction: () => context.go(AppRoutes.explore),
                ),
              )
            else ...[
              const SizedBox(height: TikeoSizes.cardGap),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: margin,
                child: Row(
                  children: [
                    periodChip(
                      FavoritesPeriod.upcoming,
                      l10n.favoritesUpcoming,
                      upcomingCount,
                      const Key('favorites-upcoming'),
                    ),
                    periodChip(
                      FavoritesPeriod.past,
                      l10n.favoritesPast,
                      pastCount,
                      const Key('favorites-past'),
                    ),
                    periodChip(
                      FavoritesPeriod.all,
                      l10n.exploreAll,
                      favorites.length,
                      const Key('favorites-all'),
                    ),
                  ],
                ),
              ),
              if (kinds.length > 1) ...[
                const SizedBox(height: TikeoSizes.cardGap),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: margin,
                  child: Row(
                    children: [
                      KindFilterChip(
                        key: const Key('favorites-kind-all'),
                        label: l10n.exploreAll,
                        icon: Icons.apps_rounded,
                        selected: _filter.kind == null,
                        onTap: () =>
                            _update(_filter.copyWith(kind: () => null)),
                      ),
                      for (final kind in kinds)
                        KindFilterChip(
                          key: Key('favorites-kind-${kind.wireName}'),
                          label: exploreKindLabel(l10n, kind),
                          icon: eventKindIcon(kind),
                          selected: _filter.kind == kind,
                          onTap: () => _update(
                            _filter.copyWith(
                              kind: () => _filter.kind == kind ? null : kind,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: TikeoSizes.cardGap),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(TikeoSizes.screenMargin),
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    illustration: TikeoIllustration.noResults,
                    title: l10n.favoritesNoMatchTitle,
                    titleKey: const Key('favorites-no-match'),
                    body: l10n.favoritesNoMatchBody,
                    actionLabel: _filter.narrowed
                        ? l10n.exploreResetFilters
                        : null,
                    actionKey: const Key('favorites-reset'),
                    onAction: _filter.narrowed ? _reset : null,
                  ),
                )
              else ...[
                Padding(
                  padding: margin,
                  child: Text(
                    l10n.exploreCount(visible.length),
                    key: const Key('favorites-count'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                for (final event in visible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TikeoSizes.screenMargin,
                      0,
                      TikeoSizes.screenMargin,
                      8,
                    ),
                    child: SwipeToAct(
                      swipeKey: ValueKey('favorite-swipe-${event.id}'),
                      icon: Icons.heart_broken_rounded,
                      label: l10n.favoritesBulkRemove,
                      // En sélection, le balayage est coupé (cases à cocher).
                      enabled: !_selecting,
                      onSwiped: () => unawaited(_remove({event.id})),
                      child: PublicEventTile(
                        event: event,
                        favoritesList: true,
                        selecting: _selecting,
                        selected: _selection.contains(event.id),
                        onToggle: () => _toggle(event.id),
                      ),
                    ),
                  ),
                if (!_selecting && visible.length > 1)
                  Padding(
                    padding: margin,
                    child: Text(
                      l10n.favoritesSelectionHint,
                      key: const Key('favorites-selection-hint'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Tri et ville.
class _FavoritesFilterSheet extends StatefulWidget {
  const new({required this.filter, required this.cities});

  final FavoritesFilter filter;
  final List<String> cities;

  @override
  State<_FavoritesFilterSheet> createState() => _FavoritesFilterSheetState();
}

class _FavoritesFilterSheetState extends State<_FavoritesFilterSheet> {
  late FavoritesSort _sort = widget.filter.sort;
  late String? _city = widget.filter.city;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('favorites-filter-sheet'),
        padding: const EdgeInsets.fromLTRB(
          TikeoSizes.screenMargin,
          0,
          TikeoSizes.screenMargin,
          TikeoSizes.screenMargin,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.favoritesFilters, style: theme.textTheme.titleLarge),
            const SizedBox(height: TikeoSizes.cardGap),
            Text(l10n.favoritesSortTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<FavoritesSort>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: FavoritesSort.nearest,
                  label: Text(
                    l10n.favoritesSortNearest,
                    key: const Key('favorites-sort-nearest'),
                  ),
                ),
                ButtonSegment(
                  value: FavoritesSort.recent,
                  label: Text(
                    l10n.favoritesSortRecent,
                    key: const Key('favorites-sort-recent'),
                  ),
                ),
              ],
              selected: {_sort},
              onSelectionChanged: (value) =>
                  setState(() => _sort = value.single),
            ),
            if (widget.cities.isNotEmpty) ...[
              const SizedBox(height: TikeoSizes.cardGap),
              Text(l10n.exploreCityTitle, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('favorites-city-all'),
                    label: Text(l10n.exploreAllCities),
                    selected: _city == null,
                    onSelected: (_) => setState(() => _city = null),
                  ),
                  for (final city in widget.cities)
                    ChoiceChip(
                      key: Key('favorites-city-$city'),
                      label: Text(city),
                      selected: _city == city,
                      onSelected: (_) => setState(() => _city = city),
                    ),
                ],
              ),
            ],
            const SizedBox(height: TikeoSizes.sectionGap),
            FilledButton(
              key: const Key('favorites-filters-apply'),
              onPressed: () => Navigator.of(context)
                  .pop(widget.filter.copyWith(sort: _sort, city: () => _city)),
              child: Text(l10n.favoritesApply),
            ),
          ],
        ),
      ),
    );
  }
}
