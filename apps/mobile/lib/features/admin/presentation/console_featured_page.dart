import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Liste « À la une » de la console.
final FutureProvider<List<FeaturedEntry>> adminFeaturedProvider =
    FutureProvider.autoDispose<List<FeaturedEntry>>(
      (ref) => ref.read(adminRepositoryProvider).featuredEvents(),
      retry: (retryCount, error) => null,
    );

String _day(DateTime instant) => formatDateAtTime(instant.toLocal());

/// Console · À la une (#3, ADR 0028) : liste ordonnée (monter, descendre,
/// retirer), période de mise en avant, ajout d'un événement public à venir.
/// Sans sélection en cours, Explorer montre les 5 prochains événements.
class ConsoleFeaturedPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleFeaturedPage> createState() =>
      _ConsoleFeaturedPageState();
}

class _ConsoleFeaturedPageState extends ConsumerState<ConsoleFeaturedPage> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action, String done) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref
        ..invalidate(adminFeaturedProvider)
        ..invalidate(featuredEventsProvider);
      if (done.isNotEmpty) toast.success(done);
    } on Object catch (error) {
      toast.error(
        error == AdminFailure.network || error == AdminFailure.unknown
            ? l10n.consoleActionError
            : consoleFailureMessage(l10n, error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final l10n = context.l10n;
    final event = await showModalBottomSheet<AdminPublicEvent>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _PickEventSheet(),
    );
    if (event == null || !mounted) return;
    await _act(
      () => ref.read(adminRepositoryProvider).addFeatured(event.id),
      l10n.featuredAdded,
    );
  }

  Future<void> _period(FeaturedEntry entry) async {
    final l10n = context.l10n;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: entry.eventEndsAt.toLocal().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: entry.startsAt.toLocal(),
        end: entry.endsAt.toLocal(),
      ),
      helpText: l10n.featuredPeriod,
    );
    if (range == null || !mounted) return;
    // Jusqu'à la fin du dernier jour choisi, sans dépasser l'événement.
    final end = range.end.add(const Duration(days: 1));
    await _act(
      () => ref
          .read(adminRepositoryProvider)
          .setFeaturedPeriod(
            entry.id,
            range.start,
            end.isAfter(entry.eventEndsAt) ? entry.eventEndsAt : end,
          ),
      l10n.featuredPeriodSaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final featured = ref.watch(adminFeaturedProvider);
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.featuredTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('featured-add'),
        onPressed: _busy ? null : () => unawaited(_add()),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.featuredAdd),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminFeaturedProvider.future),
        child: ListView(
          key: const Key('featured-page'),
          padding: EdgeInsets.fromLTRB(
            TikeoSizes.screenMargin,
            TikeoSizes.cardGap,
            TikeoSizes.screenMargin,
            MediaQuery.paddingOf(context).bottom + 96,
          ),
          children: [
            TintedBanner(
              tint: tints.blue,
              icon: Icons.info_rounded,
              title: l10n.featuredHint,
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            ...switch (featured) {
              AsyncValue(:final List<FeaturedEntry> value) when value.isEmpty =>
                [
                  TikeoCard(
                    child: Text(
                      l10n.featuredEmpty,
                      key: const Key('featured-empty'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              AsyncValue(:final List<FeaturedEntry> value) => [
                for (final (i, entry) in value.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TikeoCard(
                      key: Key('featured-${entry.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: tints.mint.background,
                                child: Text(
                                  '${i + 1}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: tints.mint.text,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              TikeoPill(
                                label: entry.live
                                    ? l10n.featuredLive
                                    : entry.listed
                                    ? l10n.featuredWaiting
                                    : l10n.featuredEnded,
                                tint: entry.live
                                    ? tints.green
                                    : entry.listed
                                    ? tints.amber
                                    : tints.gray,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              eventKindLabel(l10n, entry.kind),
                              entry.organizationName,
                              ?entry.city,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            l10n.featuredPeriodLine(
                              _day(entry.startsAt),
                              _day(entry.endsAt),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                key: Key('featured-up-${entry.id}'),
                                tooltip: l10n.featuredUp,
                                onPressed: _busy || i == 0
                                    ? null
                                    : () => unawaited(
                                        _act(
                                          () => ref
                                              .read(adminRepositoryProvider)
                                              .moveFeatured(entry.id, -1),
                                          '',
                                        ),
                                      ),
                                icon: const Icon(Icons.arrow_upward_rounded),
                              ),
                              IconButton(
                                key: Key('featured-down-${entry.id}'),
                                tooltip: l10n.featuredDown,
                                onPressed: _busy || i == value.length - 1
                                    ? null
                                    : () => unawaited(
                                        _act(
                                          () => ref
                                              .read(adminRepositoryProvider)
                                              .moveFeatured(entry.id, 1),
                                          '',
                                        ),
                                      ),
                                icon: const Icon(Icons.arrow_downward_rounded),
                              ),
                              IconButton(
                                key: Key('featured-period-${entry.id}'),
                                tooltip: l10n.featuredPeriod,
                                onPressed: _busy || !entry.listed
                                    ? null
                                    : () => unawaited(_period(entry)),
                                icon: const Icon(Icons.date_range_rounded),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                key: Key('featured-remove-${entry.id}'),
                                onPressed: _busy
                                    ? null
                                    : () => unawaited(
                                        _act(
                                          () => ref
                                              .read(adminRepositoryProvider)
                                              .removeFeatured(entry.id),
                                          l10n.featuredRemoved,
                                        ),
                                      ),
                                icon: const Icon(Icons.close_rounded),
                                label: Text(l10n.featuredRemove),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              AsyncValue(:final error?) => [
                TintedBanner(
                  tint: tints.red,
                  icon: Icons.cloud_off_rounded,
                  title: consoleFailureMessage(l10n, error),
                ),
              ],
              _ => [
                const Shimmer(
                  child: SkeletonBox(height: 160, radius: TikeoRadii.card),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}

/// Choix d'un événement public à venir (recherche du catalogue).
class _PickEventSheet extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_PickEventSheet> createState() => _PickEventSheetState();
}

class _PickEventSheetState extends ConsumerState<_PickEventSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final repository = ref.watch(adminRepositoryProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TikeoSizes.screenMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.featuredPick, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ConsoleSearchField(
                key: const Key('featured-search'),
                hint: l10n.consoleSearchEvents,
                initial: _search,
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<AdminPublicEvent>>(
                  key: ValueKey(_search),
                  future: repository.publicEvents(search: _search),
                  builder: (context, snapshot) {
                    final events = [
                      for (final event
                          in snapshot.data ?? const <AdminPublicEvent>[])
                        if (event.listed) event,
                    ];
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (events.isEmpty) {
                      return Text(
                        l10n.featuredPickEmpty,
                        key: const Key('featured-pick-empty'),
                      );
                    }
                    return ListView(
                      children: [
                        for (final event in events)
                          ListTile(
                            key: Key('featured-pick-${event.id}'),
                            title: Text(event.title),
                            subtitle: Text(
                              '${event.organizationName} · '
                              '${_day(event.startsAt)}',
                            ),
                            trailing: const Icon(Icons.add_circle_rounded),
                            onTap: () => Navigator.of(context).pop(event),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
