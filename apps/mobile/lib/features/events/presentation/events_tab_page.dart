import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_status_chip.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Filtres de la liste des événements (S07).
enum EventsFilter {
  /// À venir et en cours (brouillons compris).
  active,

  /// Brouillons.
  drafts,

  /// Publiés ou en cours.
  published,

  /// Clôturés, annulés, archivés.
  done,

  /// Tous.
  all;

  /// Vrai si [event] passe le filtre.
  bool accepts(TicketEvent event) => switch (this) {
    active => event.status.isActive,
    drafts => event.status == EventStatus.draft,
    published =>
      event.status == EventStatus.published ||
          event.status == EventStatus.inProgress,
    done => !event.status.isActive,
    all => true,
  };
}

/// Vrai si l'utilisateur peut créer et gérer des événements.
bool canManageEvents(Organization? organization) =>
    organization != null && organization.role != MemberRole.controller;

/// Onglet Événements (S07) : liste filtrée, création.
class EventsTabPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<EventsTabPage> createState() => _EventsTabPageState();
}

class _EventsTabPageState extends ConsumerState<EventsTabPage> {
  EventsFilter _filter = EventsFilter.active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final events = ref.watch(eventsProvider);
    final canManage = canManageEvents(ref.watch(activeOrganizationProvider));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navEvents)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              key: const Key('events-new'),
              heroTag: 'events-new',
              onPressed: () => unawaited(context.push(AppRoutes.newEvent)),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.eventsNew),
            )
          : null,
      body: AnimatedSwitcher(
        duration: TicketSurMotion.reduced(context)
            ? Duration.zero
            : TicketSurMotion.medium,
        child: switch (events) {
          AsyncData(:final value) => _EventsList(
            key: const ValueKey('events-data'),
            events: value,
            filter: _filter,
            canManage: canManage,
            onFilter: (filter) => setState(() => _filter = filter),
            onRefresh: () => ref.read(eventsProvider.notifier).reload(),
          ),
          AsyncError() => _LoadError(
            key: const ValueKey('events-error'),
            onRetry: () => ref.invalidate(eventsProvider),
          ),
          _ => const Center(
            key: ValueKey('events-loading'),
            child: CircularProgressIndicator(),
          ),
        },
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  const new({
    required this.events,
    required this.filter,
    required this.canManage,
    required this.onFilter,
    required this.onRefresh,
    super.key,
  });

  final List<TicketEvent> events;
  final EventsFilter filter;
  final bool canManage;
  final ValueChanged<EventsFilter> onFilter;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (events.isEmpty) {
      return _EmptyState(canManage: canManage);
    }
    final visible = events.where(filter.accepts).toList();
    final labels = {
      EventsFilter.active: l10n.eventsFilterActive,
      EventsFilter.drafts: l10n.eventsFilterDrafts,
      EventsFilter.published: l10n.eventsFilterPublished,
      EventsFilter.done: l10n.eventsFilterDone,
      EventsFilter.all: l10n.eventsFilterAll,
    };
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                TicketSurSpacing.md,
                TicketSurSpacing.xs,
                TicketSurSpacing.md,
                TicketSurSpacing.sm,
              ),
              child: Row(
                children: [
                  for (final MapEntry(key: value, value: label)
                      in labels.entries)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: TicketSurSpacing.xs,
                      ),
                      child: ChoiceChip(
                        key: Key('events-filter-${value.name}'),
                        label: Text(label),
                        selected: value == filter,
                        onSelected: (_) => onFilter(value),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(TicketSurSpacing.lg),
                  child: Text(
                    l10n.eventsFilterEmpty,
                    key: const Key('events-filter-empty'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              // Espace sous la dernière carte pour le bouton flottant.
              padding: const EdgeInsets.fromLTRB(
                TicketSurSpacing.md,
                0,
                TicketSurSpacing.md,
                96,
              ),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: TicketSurSpacing.sm),
                itemBuilder: (context, index) => FadeSlideIn(
                  key: ValueKey('${filter.name}-${visible[index].id}'),
                  delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                  child: EventCard(
                    key: Key('event-card-${visible[index].id}'),
                    event: visible[index],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte d'un événement dans la liste.
class EventCard extends StatelessWidget {
  const new({required this.event, this.onTap, super.key});

  final TicketEvent event;

  /// Action au toucher ; par défaut, ouvre la fiche par-dessus la liste.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final start = wallTimeIn(event.timezone, event.startsAt);
    final muted = !event.status.isActive;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            onTap ??
            () => unawaited(context.push(AppRoutes.eventDetail(event.id))),
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBlock(date: start, muted: muted),
              const SizedBox(width: TicketSurSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: TicketSurSpacing.xxs),
                    Text(formatEventRange(event), style: textTheme.bodySmall),
                    if (event.venue case final venue?) ...[
                      const SizedBox(height: TicketSurSpacing.xxs),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: TicketSurSpacing.xxs),
                          Expanded(
                            child: Text(
                              venue,
                              style: textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: TicketSurSpacing.xs),
                    EventStatusChip(status: event.status),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const new({required this.date, required this.muted});

  final DateTime date;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Texte blanc sur bleu nuit (≥ 12:1) ; gris ardoise pour le passé (≥ 6:1).
    final background = muted ? const Color(0xFF52627A) : TicketSurColors.navy;
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: TicketSurSpacing.xs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TicketSurRadii.sm),
      ),
      child: Column(
        children: [
          Text(
            DateFormat(
              'MMM',
              'fr',
            ).format(date).replaceAll('.', '').toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: TicketSurColors.white,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            '${date.day}',
            style: textTheme.headlineSmall?.copyWith(
              color: TicketSurColors.white,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const new({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TicketSurSpacing.xl),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.event_available_rounded,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              Text(
                l10n.eventsEmptyTitle,
                key: const Key('events-empty'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Text(
                canManage
                    ? l10n.eventsEmptyBody
                    : l10n.eventsEmptyControllerBody,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const new({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: TicketSurSpacing.md),
            Text(
              l10n.eventsLoadError,
              key: const Key('events-load-error'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TicketSurSpacing.md),
            FilledButton.tonal(
              key: const Key('events-retry'),
              onPressed: onRetry,
              child: Text(l10n.orgRetry),
            ),
          ],
        ),
      ),
    );
  }
}
