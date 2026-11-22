import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/selection.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/announcements/presentation/announcement_banner.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/burkina_cities.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/catalog/presentation/featured_card.dart';
import 'package:ticketsur/features/catalog/presentation/filter_sheet.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/favorites/presentation/favorite_button.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Explorer : les événements publics, sans compte (refonte Tikéo, étape B).
class ExplorePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  late final _search = TextEditingController(
    text: ref.read(catalogQueryProvider).search,
  );
  Timer? _debounce;

  /// Retour dans l'app : nouvel essai tout de suite si l'Explorer est
  /// hors ligne.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(ref.read(catalogResultsProvider.notifier).retryNow()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) ref.read(catalogQueryProvider.notifier).search(text);
    });
  }

  void _update(CatalogQuery query) =>
      ref.read(catalogQueryProvider.notifier).update(query);

  Future<void> _pickCity(CatalogQuery query) async {
    final picked = await showModalBottomSheet<({String? city})>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CitySheet(selected: query.city),
    );
    if (picked == null) return;
    _update(
      picked.city == null
          ? query.copyWith(clearCity: true)
          : query.copyWith(city: picked.city),
    );
  }

  Future<void> _openFilters(CatalogQuery query) async {
    final next = await showFilterSheet(context, query);
    if (next != null) _update(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = ref.watch(catalogQueryProvider);
    final results = ref.watch(catalogResultsProvider);
    final filters = query.filterCount;
    const margin = EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin);

    final savedAt = ref.read(catalogResultsProvider.notifier).savedAt;
    final body = switch (results) {
      AsyncData(:final value) => [
        if (savedAt != null) _OfflineBanner(savedAt: savedAt),
        ..._results(
          context,
          events: value,
          query: query,
          hasMore: ref.read(catalogResultsProvider.notifier).hasMore,
          onMore: () =>
              unawaited(ref.read(catalogResultsProvider.notifier).loadMore()),
          onReset: () {
            _search.clear();
            _update(const CatalogQuery());
          },
        ),
      ],
      // Erreur, y compris pendant les nouveaux essais automatiques.
      AsyncValue(:final error?) => [
        _Message(
          key: const Key('explore-error'),
          icon: Icons.wifi_off_rounded,
          illustration: TikeoIllustration.offline,
          title: error == CatalogFailure.network
              ? l10n.exploreErrorNetwork
              : l10n.exploreErrorLoad,
          action: l10n.exploreRetry,
          onAction: () => ref.invalidate(catalogResultsProvider),
        ),
      ],
      _ => [
        const Padding(
          padding: margin,
          child: Shimmer(
            child: SkeletonBox(
              height: TikeoSizes.featuredCardHeight,
              radius: TikeoRadii.card,
            ),
          ),
        ),
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.fromLTRB(
              TikeoSizes.screenMargin,
              TikeoSizes.cardGap,
              TikeoSizes.screenMargin,
              0,
            ),
            child: Shimmer(
              child: SkeletonBox(height: 96, radius: TikeoRadii.button),
            ),
          ),
      ],
    };

    // Retour : géré par la coque (double appui pour quitter).
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(featuredEventsProvider);
          return ref.refresh(catalogResultsProvider.future);
        },
        child: ListView(
          key: const Key('explore-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          children: [
            // En-tête et recherche dans une même colonne : la partie de la
            // carte posée sur l'en-tête reste touchable.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TikeoHeroHeader(
                  title: l10n.exploreHeroTitle,
                  subtitle: l10n.exploreHeroSubtitle,
                  actions: [
                    CityPillButton(
                      city: query.city,
                      onPressed: () => unawaited(_pickCity(query)),
                    ),
                  ],
                ),
                TikeoOverlapCard(
                  padding: const EdgeInsets.all(12),
                  child: TikeoSearchBar(
                    fieldKey: const Key('explore-search'),
                    filterKey: const Key('explore-filters'),
                    controller: _search,
                    hint: l10n.exploreSearchHint,
                    semanticLabel: l10n.exploreSearchLabel,
                    onChanged: _onSearch,
                    onSubmitted: (text) {
                      _debounce?.cancel();
                      ref.read(catalogQueryProvider.notifier).search(text);
                    },
                    suffix: ListenableBuilder(
                      listenable: _search,
                      builder: (context, _) => _search.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: l10n.filtersClear,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                _debounce?.cancel();
                                ref
                                    .read(catalogQueryProvider.notifier)
                                    .search('');
                              },
                            ),
                    ),
                    onFilter: () => unawaited(_openFilters(query)),
                    filterTooltip: l10n.exploreFilters,
                    filterCount: filters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: margin,
              child: Row(
                children: [
                  KindFilterChip(
                    key: const Key('explore-kind-all'),
                    label: l10n.exploreAll,
                    icon: Icons.apps_rounded,
                    selected: query.kinds.isEmpty,
                    onTap: () => _update(query.copyWith(kinds: const {})),
                  ),
                  for (final kind in exploreKinds)
                    KindFilterChip(
                      key: Key('explore-kind-${kind.wireName}'),
                      label: exploreKindLabel(l10n, kind),
                      icon: eventKindIcon(kind),
                      selected: query.kinds.contains(kind),
                      onTap: () => _update(
                        query.copyWith(
                          kinds: query.kinds.contains(kind)
                              ? ({...query.kinds}..remove(kind))
                              : {kind},
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            const AnnouncementBanner(
              padding: EdgeInsets.fromLTRB(
                TikeoSizes.screenMargin,
                0,
                TikeoSizes.screenMargin,
                TikeoSizes.cardGap,
              ),
            ),
            ...body,
          ],
        ),
      ),
    );
  }

  /// Résultats : « À la une » (sans filtre), titre et compteur, liste,
  /// « Voir plus » ; ou un message s'il n'y a rien.
  List<Widget> _results(
    BuildContext context, {
    required List<PublicEventSummary> events,
    required CatalogQuery query,
    required bool hasMore,
    required VoidCallback onMore,
    required VoidCallback onReset,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (events.isEmpty) {
      return [
        _Message(
          key: const Key('explore-empty'),
          icon: Icons.event_busy_rounded,
          illustration: TikeoIllustration.noResults,
          title: l10n.exploreEmptyTitle,
          body: query.narrowed || query.city != null
              ? l10n.exploreEmptyBody
              : l10n.exploreEmptyCatalogBody,
          action: query.narrowed ? l10n.exploreResetFilters : null,
          onAction: query.narrowed ? onReset : null,
        ),
      ];
    }
    // « À la une » : choisis par l'administrateur (ADR 0028), à part de la
    // liste, qui reste complète.
    final rest = events;
    final heading = query.narrowed
        ? l10n.exploreResults
        : query.city == null
        ? l10n.exploreUpcoming
        : l10n.exploreUpcomingIn(query.city!);
    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin),
      child: child,
    );
    return [
      if (!query.narrowed) const FeaturedSection(),
      padded(
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(heading, style: theme.textTheme.titleLarge)),
            Text(
              l10n.exploreCount(events.length),
              key: const Key('explore-count'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      for (final event in rest) ...[
        padded(PublicEventTile(event: event)),
        const SizedBox(height: 8),
      ],
      if (hasMore)
        padded(
          OutlinedButton(
            key: const Key('explore-more'),
            onPressed: onMore,
            child: Text(l10n.exploreMore),
          ),
        ),
    ];
  }
}

/// « Hors ligne, mis à jour il y a … » au-dessus des résultats gardés sur
/// l'appareil ; la durée avance d'elle-même.
class _OfflineBanner extends ConsumerStatefulWidget {
  const new({required this.savedAt});

  final DateTime savedAt;

  @override
  ConsumerState<_OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<_OfflineBanner> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = ref.read(catalogClockProvider)();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TikeoSizes.screenMargin,
        0,
        TikeoSizes.screenMargin,
        TikeoSizes.cardGap,
      ),
      child: TintedBanner(
        key: const Key('explore-offline'),
        tint: context.tints.amber,
        icon: Icons.cloud_off_rounded,
        title: l10n.exploreOffline(timeAgo(l10n, widget.savedAt, now)),
        body: l10n.exploreOfflineBody,
      ),
    );
  }
}

/// Ville choisie, en pastille claire sur l'en-tête.
class CityPillButton extends StatelessWidget {
  const new({
    required this.city,
    required this.onPressed,
    this.buttonKey = const Key('explore-city'),
    super.key,
  });

  final String? city;
  final VoidCallback onPressed;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    const white = TicketSurColors.white;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Material(
        color: white.withValues(alpha: 0.12),
        shape: StadiumBorder(
          side: BorderSide(color: white.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: buttonKey,
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 18,
                    color: TicketSurColors.mint,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      city ?? context.l10n.exploreAllCities,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: white),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.expand_more_rounded, size: 20, color: white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filtre de type : 72 × 64 au moins, icône 26, libellé 13 / 700 ; actif en
/// dégradé menthe.
class KindFilterChip extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = selected
        ? TicketSurColors.navy
        : (dark ? theme.colorScheme.onSurface : TicketSurColors.navy);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: PressableScale(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: selected ? TikeoColors.mintGradient : null,
              color: selected ? null : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(TikeoRadii.button),
              border: selected
                  ? null
                  : Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: selected && !dark ? TikeoShadows.mintGlow : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.circular(TikeoRadii.button),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: TikeoSizes.kindFilter.width,
                    minHeight: TikeoSizes.kindFilter.height,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 26, color: ink),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontVariations: const [FontVariation.weight(700)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne d'un événement public (Explorer, favoris) : vignette avec le type,
/// titre, date, lieu, prix et cœur.
class PublicEventTile extends StatelessWidget {
  const new({
    required this.event,
    this.favoritesList = false,
    this.onToggle,
    this.selecting = false,
    this.selected = false,
    super.key,
  });

  final PublicEventSummary event;

  /// Dans « Mes favoris » : cœur rouge plein, retrait avec « Annuler ».
  final bool favoritesList;

  /// Sélection multiple (Mes favoris) : appui long, puis appui en sélection.
  final VoidCallback? onToggle;

  /// Mode sélection : case à cocher à la place du cœur.
  final bool selecting;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final price = summaryPrice(l10n, event);
    final place = summaryPlace(event);
    // Vignette 128 × 80 ; un peu plus petite sur un écran étroit, pour
    // laisser la place au titre.
    final width = MediaQuery.sizeOf(context).width < 380 ? 104.0 : 128.0;
    final row = TikeoListRow(
      key: Key('public-event-${event.id}'),
      leading: SizedBox(
        width: width,
        height: width * 80 / 128,
        child: EventCover(
          kind: event.kind,
          url: event.coverUrl,
          aspectRatio: 128 / 80,
          borderRadius: BorderRadius.circular(14),
          overlay: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: KindOnPhotoPill(
                label: eventKindTag(l10n, event.kind),
                color: eventKindColor(event.kind),
              ),
            ),
          ),
        ),
      ),
      title: event.title,
      lines: [summaryWhen(event), if (place.isNotEmpty) place],
      badge: price == null
          ? null
          : TikeoPill(label: price, tint: context.tints.mint),
      trailing: selecting
          ? Checkbox(
              key: Key('favorite-check-${event.id}'),
              value: selected,
              onChanged: (_) => onToggle?.call(),
            )
          : FavoriteButton(
              event: event,
              selectedColor: favoritesList ? context.tints.red.icon : null,
              undoable: favoritesList,
            ),
      chevron: !selecting,
      onLongPress: onToggle,
      onTap: selecting
          ? onToggle
          : () => unawaited(context.push(AppRoutes.publicEvent(event.id))),
    );
    return onToggle == null
        ? row
        : SelectableFrame(selected: selecting && selected, child: row);
  }
}

/// Sur-titre d'une carte : « CONCERT ».
String exploreKindTag(AppLocalizations l10n, EventKind kind) =>
    eventKindTag(l10n, kind).toUpperCase();

/// Libellé singulier d'une catégorie.
String eventKindTag(AppLocalizations l10n, EventKind kind) => switch (kind) {
  EventKind.concert => l10n.eventKindConcert,
  EventKind.conference => l10n.eventKindConference,
  EventKind.worship => l10n.eventKindWorship,
  EventKind.sport => l10n.eventKindSport,
  EventKind.wedding => l10n.eventKindWedding,
  EventKind.training => l10n.eventKindTraining,
  EventKind.gala => l10n.eventKindGala,
  EventKind.other => l10n.eventKindOther,
};

class _Message extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    this.illustration,
    this.body,
    this.action,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final TikeoIllustration? illustration;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: TicketSurSpacing.xl,
      vertical: TicketSurSpacing.lg,
    ),
    child: EmptyState(
      icon: icon,
      illustration: illustration,
      title: title,
      body: body,
      actionLabel: action,
      onAction: onAction,
    ),
  );
}

class _CitySheet extends StatelessWidget {
  const new({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget tile(String? city) => ListTile(
      key: Key('city-${city ?? 'all'}'),
      title: Text(city ?? l10n.exploreAllCities),
      trailing: city == selected
          ? Icon(Icons.check_rounded, color: context.palette.accentText)
          : null,
      selected: city == selected,
      onTap: () => Navigator.of(context).pop((city: city)),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.md,
              0,
              TicketSurSpacing.md,
              TicketSurSpacing.xs,
            ),
            child: Text(
              l10n.exploreCityTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                tile(null),
                for (final city in burkinaCities) tile(city),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
