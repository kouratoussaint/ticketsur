import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/features/announcements/presentation/announcement_banner.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/burkina_cities.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/catalog/presentation/filter_sheet.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
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

  @override
  void dispose() {
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
    final theme = Theme.of(context);
    final query = ref.watch(catalogQueryProvider);
    final results = ref.watch(catalogResultsProvider);
    final filters = query.filterCount;

    // Retour : géré par la coque (double appui pour quitter).
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: theme.colorScheme.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  TicketSurSpacing.sm,
                  TicketSurSpacing.md,
                  TicketSurSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const TikeoLogo(height: 34),
                        const SizedBox(width: TicketSurSpacing.sm),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              key: const Key('explore-city'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TicketSurSpacing.sm,
                                ),
                              ),
                              onPressed: () => unawaited(_pickCity(query)),
                              icon: const Icon(Icons.place_rounded, size: 18),
                              label: Text(
                                query.city ?? l10n.exploreAllCities,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TicketSurSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('explore-search'),
                            controller: _search,
                            onChanged: _onSearch,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (text) {
                              _debounce?.cancel();
                              ref
                                  .read(catalogQueryProvider.notifier)
                                  .search(text);
                            },
                            decoration: InputDecoration(
                              hintText: l10n.exploreSearchHint,
                              semanticCounterText: l10n.exploreSearchLabel,
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _search.text.isEmpty
                                  ? null
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
                          ),
                        ),
                        const SizedBox(width: TicketSurSpacing.xs),
                        Badge(
                          isLabelVisible: filters > 0,
                          label: Text('$filters'),
                          child: IconButton.filled(
                            key: const Key('explore-filters'),
                            tooltip: l10n.exploreFilters,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(52, 52),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  TicketSurRadii.sm,
                                ),
                              ),
                            ),
                            onPressed: () => unawaited(_openFilters(query)),
                            icon: const Icon(Icons.tune_rounded),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 60,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: TicketSurSpacing.md,
                  vertical: TicketSurSpacing.xs,
                ),
                child: Row(
                  children: [
                    _KindChip(
                      key: const Key('explore-kind-all'),
                      label: l10n.exploreAll,
                      selected: query.kinds.isEmpty,
                      onTap: () => _update(query.copyWith(kinds: const {})),
                    ),
                    for (final kind in exploreKinds)
                      _KindChip(
                        key: Key('explore-kind-${kind.wireName}'),
                        label: exploreKindLabel(l10n, kind),
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
            ),
            const AnnouncementBanner(
              padding: EdgeInsets.fromLTRB(
                TicketSurSpacing.md,
                0,
                TicketSurSpacing.md,
                TicketSurSpacing.xs,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(catalogResultsProvider.future),
                child: switch (results) {
                  AsyncData(:final value) => _ResultList(
                    events: value,
                    query: query,
                    hasMore: ref.read(catalogResultsProvider.notifier).hasMore,
                    onMore: () => unawaited(
                      ref.read(catalogResultsProvider.notifier).loadMore(),
                    ),
                    onReset: () {
                      _search.clear();
                      _update(const CatalogQuery());
                    },
                  ),
                  AsyncError(:final error) => _Message(
                    key: const Key('explore-error'),
                    icon: Icons.wifi_off_rounded,
                    title: error == CatalogFailure.network
                        ? l10n.exploreErrorNetwork
                        : l10n.exploreErrorLoad,
                    action: l10n.exploreRetry,
                    onAction: () => ref.invalidate(catalogResultsProvider),
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: TicketSurSpacing.xs),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      shape: const StadiumBorder(),
      selectedColor: TicketSurColors.mint,
      labelStyle: TextStyle(
        color: selected
            ? TicketSurColors.navy
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
}

class _ResultList extends StatelessWidget {
  const new({
    required this.events,
    required this.query,
    required this.hasMore,
    required this.onMore,
    required this.onReset,
  });

  final List<PublicEventSummary> events;
  final CatalogQuery query;
  final bool hasMore;
  final VoidCallback onMore;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (events.isEmpty) {
      return _Message(
        key: const Key('explore-empty'),
        icon: Icons.event_busy_rounded,
        title: l10n.exploreEmptyTitle,
        body: query.narrowed || query.city != null
            ? l10n.exploreEmptyBody
            : l10n.exploreEmptyCatalogBody,
        action: query.narrowed ? l10n.exploreResetFilters : null,
        onAction: query.narrowed ? onReset : null,
      );
    }
    final featured = query.narrowed ? null : events.first;
    final rest = featured == null ? events : events.skip(1).toList();
    final heading = query.narrowed
        ? l10n.exploreResults
        : query.city == null
        ? l10n.exploreUpcoming
        : l10n.exploreUpcomingIn(query.city!);
    return ListView(
      key: const Key('explore-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        TicketSurSpacing.xs,
        TicketSurSpacing.md,
        TicketSurSpacing.lg,
      ),
      children: [
        if (featured != null) ...[
          _FeaturedCard(event: featured),
          const SizedBox(height: TicketSurSpacing.md),
        ],
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
        const SizedBox(height: TicketSurSpacing.sm),
        for (final event in rest) ...[
          PublicEventTile(event: event),
          const SizedBox(height: TicketSurSpacing.sm),
        ],
        if (hasMore)
          OutlinedButton(
            key: const Key('explore-more'),
            onPressed: onMore,
            child: Text(l10n.exploreMore),
          ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const new({required this.event});

  final PublicEventSummary event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    const white = TicketSurColors.white;
    final price = summaryPrice(l10n, event);
    return Card(
      key: const Key('explore-featured'),
      color: TicketSurColors.navy,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TicketSurRadii.lg),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.publicEvent(event.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EventCover(
              kind: event.kind,
              url: event.coverUrl,
              aspectRatio: 2,
              overlay: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(TicketSurSpacing.xs),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0x99022445),
                          shape: BoxShape.circle,
                        ),
                        child: FavoriteButton(
                          event: event,
                          color: TicketSurColors.white,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(TicketSurSpacing.sm),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: TicketSurColors.spark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Text(
                            l10n.exploreFeatured.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: TicketSurColors.navy,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TicketSurSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: textTheme.titleLarge?.copyWith(color: white),
                  ),
                  const SizedBox(height: TicketSurSpacing.xxs),
                  Text(
                    '${summaryWhen(event)} · ${summaryPlace(event)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFC9D6E3),
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(height: TicketSurSpacing.xxs),
                    Text(
                      price,
                      style: textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF7CF0D8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne d'un événement public (Explorer, favoris), avec son cœur.
class PublicEventTile extends StatelessWidget {
  const new({required this.event, super.key});

  final PublicEventSummary event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final muted = context.palette.mutedText;
    final start = wallTimeIn(event.timezone, event.startsAt);
    final price = summaryPrice(l10n, event);
    return Card(
      key: Key('public-event-${event.id}'),
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TicketSurRadii.md),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.publicEvent(event.id)),
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: exploreKindColor(event.kind),
                    borderRadius: BorderRadius.circular(TicketSurRadii.sm),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('dd', appLocaleTag).format(start),
                        style: textTheme.headlineSmall?.copyWith(
                          color: TicketSurColors.white,
                          height: 1,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM',
                          appLocaleTag,
                        ).format(start).replaceAll('.', '').toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: TicketSurColors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: TicketSurSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exploreKindTag(l10n, event.kind),
                      style: textTheme.labelSmall?.copyWith(
                        color: context.palette.accentText,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(event.title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      summaryWhen(event),
                      style: textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    Text(
                      summaryPlace(event),
                      style: textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    if (price != null)
                      Text(
                        price,
                        style: textTheme.labelMedium?.copyWith(
                          color: context.palette.accentText,
                        ),
                      ),
                  ],
                ),
              ),
              FavoriteButton(event: event),
            ],
          ),
        ),
      ),
    );
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
    this.body,
    this.action,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TicketSurSpacing.xl),
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: TicketSurSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (body case final text?) ...[
          const SizedBox(height: TicketSurSpacing.xs),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (action case final label?) ...[
          const SizedBox(height: TicketSurSpacing.md),
          Center(
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Text(label),
            ),
          ),
        ],
      ],
    );
  }
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
