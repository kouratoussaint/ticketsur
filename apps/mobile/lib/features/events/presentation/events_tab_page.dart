import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
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
          _ => const _Loading(key: ValueKey('events-loading')),
        },
      ),
    );
  }
}

/// En-tête de la liste des événements.
class _EventsHeader extends StatelessWidget {
  const new({this.overlap = 0});

  final double overlap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPop = Navigator.of(context).canPop();
    return TikeoHeroHeader(
      title: l10n.navEvents,
      subtitle: l10n.eventsHeroSubtitle,
      illustration: TikeoIllustration.calendar,
      onBack: canPop ? () => Navigator.of(context).maybePop() : null,
      overlap: overlap,
    );
  }
}

class _Loading extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const _EventsHeader(),
      Padding(
        padding: const EdgeInsets.all(TikeoSizes.screenMargin),
        child: Shimmer(
          child: Column(
            children: [
              for (var i = 0; i < 4; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SkeletonBox(height: 88, radius: 16),
                ),
            ],
          ),
        ),
      ),
    ],
  );
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
      return ListView(
        children: [
          const _EventsHeader(),
          _EmptyState(canManage: canManage),
        ],
      );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _EventsHeader(overlap: TikeoSizes.heroOverlap),
                TikeoOverlapCard(
                  padding: const EdgeInsets.all(12),
                  child: StatusTabs<EventsFilter>(
                    values: EventsFilter.values,
                    selected: filter,
                    labelOf: (value) => labels[value]!,
                    keyOf: (value) => Key('events-filter-${value.name}'),
                    onSelected: onFilter,
                  ),
                ),
                const SizedBox(height: TikeoSizes.cardGap),
              ],
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
                TikeoSizes.screenMargin,
                0,
                TikeoSizes.screenMargin,
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
                    child: SectionHeader(
                      key: Key('events-section-${phase.name}'),
                      title: l10n.eventsSectionTitle(
                        sectionTitles[phase]!,
                        count,
                      ),
                      icon: _phaseIcon(phase),
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

IconData _phaseIcon(EventPhase phase) => switch (phase) {
  EventPhase.current => Icons.play_circle_rounded,
  EventPhase.upcoming => Icons.event_rounded,
  EventPhase.draft => Icons.edit_note_rounded,
  EventPhase.past => Icons.history_rounded,
};

/// Ligne d'un événement : vignette, type, titre, date, lieu, statut.
class EventCard extends StatelessWidget {
  const new({required this.event, this.onTap, super.key});

  final TicketEvent event;

  /// Action au toucher ; par défaut, ouvre la fiche par-dessus la liste.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = !event.status.isActive;
    final place = [?event.venue, ?event.city].join(' · ');
    final start = wallTimeIn(event.timezone, event.startsAt);
    Widget thumb = SizedBox(
      width: 88,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          EventCover.forEvent(
            event,
            aspectRatio: 88 / 72,
            borderRadius: BorderRadius.circular(TikeoRadii.thumb),
          ),
          Positioned(left: 6, top: 6, child: _DateBlock(date: start)),
        ],
      ),
    );
    // Événements terminés : vignette désaturée.
    if (muted) {
      thumb = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.59, 0.11, 0, 0, //
          0.33, 0.59, 0.11, 0, 0, //
          0.33, 0.59, 0.11, 0, 0, //
          0, 0, 0, 1, 0, //
        ]),
        child: thumb,
      );
    }
    final incomplete =
        event.status == EventStatus.draft && !event.readyToPublish;
    return TikeoListRow(
      leading: thumb,
      title: event.title,
      subtitle: eventKindLabel(l10n, event.kind).toUpperCase(),
      lines: [formatEventRange(event), if (place.isNotEmpty) place],
      badge: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          EventStatusChip(status: event.status),
          if (incomplete)
            TikeoPill(
              key: Key('event-card-incomplete-${event.id}'),
              label: l10n.eventToCompleteTitle,
              tint: context.tints.amber,
              icon: Icons.info_rounded,
            ),
        ],
      ),
      onTap:
          onTap ??
          () => unawaited(context.push(AppRoutes.eventDetail(event.id))),
    );
  }
}

/// Pastille blanche posée sur la vignette : mois et jour.
class _DateBlock extends StatelessWidget {
  const new({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // Bleu nuit sur blanc (≥ 12:1).
    const ink = TicketSurColors.navy;
    return Container(
      width: 34,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: TicketSurColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat(
              'MMM',
              appLocaleTag,
            ).format(date).replaceAll('.', '').toUpperCase(),
            style: TikeoTextStyles.overline.copyWith(
              color: ink,
              fontSize: 9,
              letterSpacing: 0.4,
              height: 1.1,
            ),
          ),
          Text(
            '${date.day}',
            style: TikeoTextStyles.tileNumber.copyWith(
              color: ink,
              fontSize: 15,
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
    return Padding(
      padding: const EdgeInsets.all(TikeoSizes.screenMargin),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const TikeoIllustrationView(TikeoIllustration.noEvents),
          const SizedBox(height: 16),
          Text(
            l10n.eventsEmptyTitle,
            key: const Key('events-empty'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            canManage ? l10n.eventsEmptyBody : l10n.eventsEmptyControllerBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
    return ListView(
      children: [
        const _EventsHeader(),
        Padding(
          padding: const EdgeInsets.all(TikeoSizes.screenMargin),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const TikeoIllustrationView(TikeoIllustration.offline),
              const SizedBox(height: 16),
              Text(
                l10n.eventsLoadError,
                key: const Key('events-load-error'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TikeoPrimaryButton(
                key: const Key('events-retry'),
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                label: l10n.orgRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
