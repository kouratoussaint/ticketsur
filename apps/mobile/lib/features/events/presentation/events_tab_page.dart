import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/events/presentation/event_status_chip.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Filtres de la liste des événements (S07).
enum EventsFilter {
  /// Tous, regroupés : en cours, à venir, brouillons, passés.
  all,

  /// En cours (contrôle démarré, ou publié et déjà commencé).
  current,

  /// À venir (publiés, pas encore commencés).
  upcoming,

  /// Brouillons pas encore terminés.
  drafts,

  /// Passés : terminés, clôturés, annulés ou archivés.
  past;

  /// Vrai si [event] passe le filtre à l'instant [now].
  bool accepts(TicketEvent event, DateTime now) => switch (this) {
    all => true,
    current => eventPhaseAt(event, now) == EventPhase.current,
    upcoming => eventPhaseAt(event, now) == EventPhase.upcoming,
    drafts => eventPhaseAt(event, now) == EventPhase.draft,
    past => eventPhaseAt(event, now) == EventPhase.past,
  };
}

/// Moment d'un événement vu par le promoteur.
enum EventPhase { current, upcoming, draft, past }

/// Moment de [event] à [now] : le statut d'abord (contrôle en cours,
/// clôturé…), puis les dates.
EventPhase eventPhaseAt(TicketEvent event, DateTime now) =>
    switch (event.status) {
      EventStatus.inProgress => EventPhase.current,
      EventStatus.closed ||
      EventStatus.archived ||
      EventStatus.cancelled => EventPhase.past,
      _ when event.endsAt.isBefore(now) => EventPhase.past,
      EventStatus.draft => EventPhase.draft,
      EventStatus.published when !event.startsAt.isAfter(now) =>
        EventPhase.current,
      EventStatus.published => EventPhase.upcoming,
    };

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
  EventsFilter _filter = EventsFilter.all;

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
          _ => const SkeletonList(key: ValueKey('events-loading')),
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
    final now = DateTime.now().toUtc();
    final visible = events.where((e) => filter.accepts(e, now)).toList();
    final labels = {
      EventsFilter.all: l10n.eventsFilterAll,
      EventsFilter.current: l10n.eventsFilterCurrent,
      EventsFilter.upcoming: l10n.eventsFilterActive,
      EventsFilter.drafts: l10n.eventsFilterDrafts,
      EventsFilter.past: l10n.eventsFilterDone,
    };
    final sectionTitles = {
      EventPhase.current: l10n.eventsFilterCurrent,
      EventPhase.upcoming: l10n.eventsFilterActive,
      EventPhase.draft: l10n.eventsFilterDrafts,
      EventPhase.past: l10n.eventsFilterDone,
    };
    // « Tous » : sections dans l'ordre En cours, À venir, Brouillons, Passés.
    final entries = <Object>[];
    if (filter == EventsFilter.all) {
      for (final phase in EventPhase.values) {
        final group = [
          for (final e in visible)
            if (eventPhaseAt(e, now) == phase) e,
        ];
        if (group.isEmpty) continue;
        entries
          ..add((phase, group.length))
          ..addAll(group);
      }
    } else {
      entries.addAll(visible);
    }
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
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: TicketSurSpacing.sm),
                itemBuilder: (context, index) => switch (entries[index]) {
                  (final EventPhase phase, final int count) => Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : TicketSurSpacing.md,
                    ),
                    child: Text(
                      l10n.eventsSectionTitle(sectionTitles[phase]!, count),
                      key: Key('events-section-${phase.name}'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  final TicketEvent event => FadeSlideIn(
                    key: ValueKey('${filter.name}-${event.id}'),
                    delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                    child: EventCard(
                      key: Key('event-card-${event.id}'),
                      event: event,
                    ),
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte d'un événement : photo de couverture, date, statut, titre, lieu.
class EventCard extends StatelessWidget {
  const new({required this.event, this.onTap, super.key});

  final TicketEvent event;

  /// Action au toucher ; par défaut, ouvre la fiche par-dessus la liste.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final start = wallTimeIn(event.timezone, event.startsAt);
    final muted = !event.status.isActive;
    final place = [?event.venue, ?event.city].join(' · ');
    final cover = EventCover.forEvent(
      event,
      aspectRatio: 2.4,
      overlay: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateBlock(date: start, muted: muted),
            const Spacer(),
            EventStatusChip(status: event.status),
          ],
        ),
      ),
    );
    return PressableScale(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              onTap ??
              () => unawaited(context.push(AppRoutes.eventDetail(event.id))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Événements terminés : photo désaturée.
              if (muted)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.33, 0.59, 0.11, 0, 0, //
                    0.33, 0.59, 0.11, 0, 0, //
                    0.33, 0.59, 0.11, 0, 0, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: cover,
                )
              else
                cover,
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  TicketSurSpacing.sm,
                  TicketSurSpacing.md,
                  TicketSurSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventKindLabel(l10n, event.kind).toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: context.palette.accentText,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: TicketSurSpacing.xxs),
                    Text(
                      event.title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: TicketSurSpacing.xxs),
                    _InfoLine(
                      icon: Icons.schedule_rounded,
                      text: formatEventRange(event),
                    ),
                    if (place.isNotEmpty)
                      _InfoLine(icon: Icons.place_rounded, text: place),
                    if (event.status == EventStatus.draft &&
                        !event.readyToPublish)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: TicketSurSpacing.xs,
                        ),
                        child: Row(
                          key: Key('event-card-incomplete-${event.id}'),
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: context.palette.warningText,
                            ),
                            const SizedBox(width: TicketSurSpacing.xxs),
                            Expanded(
                              child: Text(
                                l10n.eventToCompleteTitle,
                                style: textTheme.bodySmall?.copyWith(
                                  color: context.palette.warningText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: TicketSurSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: TicketSurSpacing.xxs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille blanche posée sur la photo : mois et jour.
class _DateBlock extends StatelessWidget {
  const new({required this.date, required this.muted});

  final DateTime date;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Bleu nuit sur blanc (≥ 12:1) ; gris ardoise pour le passé (≥ 6:1).
    final ink = muted ? const Color(0xFF52627A) : TicketSurColors.navy;
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: TicketSurSpacing.xxs),
      decoration: BoxDecoration(
        color: TicketSurColors.white,
        borderRadius: BorderRadius.circular(TicketSurRadii.sm),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      // Hauteur du contenu seulement : sinon le bloc s'étire sur la photo.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat(
              'MMM',
              'fr',
            ).format(date).replaceAll('.', '').toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: ink,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            '${date.day}',
            style: textTheme.headlineSmall?.copyWith(
              color: ink,
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
    return EmptyState(
      icon: Icons.event_available_rounded,
      title: l10n.eventsEmptyTitle,
      titleKey: const Key('events-empty'),
      body: canManage ? l10n.eventsEmptyBody : l10n.eventsEmptyControllerBody,
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
