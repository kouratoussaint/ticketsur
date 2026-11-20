import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/duplicate_event_sheet.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/events/presentation/event_setup_sections.dart';
import 'package:ticketsur/features/events/presentation/event_status_chip.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/events/presentation/image_source_sheet.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/team/presentation/event_team_section.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Fiche d'un événement (S09) : informations, statut et actions.
class EventDetailPage extends ConsumerStatefulWidget {
  const new({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  EventStatus? _pending;
  bool _uploadingCover = false;

  Future<void> _changeCover(TicketEvent event) async {
    final l10n = context.l10n;
    final source = await showImageSourceSheet(context);
    if (source == null || !mounted) return;
    final toast = Toaster.of(context);
    final CoverImage? image;
    try {
      image = await ref.read(coverPickerProvider)(source);
    } on Object {
      toast.error(l10n.eventErrorCover);
      return;
    }
    if (image == null || !mounted) return;
    setState(() => _uploadingCover = true);
    try {
      await ref.read(eventsProvider.notifier).setCover(event.id, image);
      toast.success(l10n.eventCoverSaved);
    } on EventFailure catch (failure) {
      toast.error(eventFailureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _changeStatus(TicketEvent event, EventStatus target) async {
    final l10n = context.l10n;
    final destructive = isFinalTransition(target);
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(eventStatusStyle(target).glyph),
        title: Text(eventActionLabel(l10n, target, event.status)),
        content: Text(eventConfirmBody(l10n, target, event.status)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.eventConfirmBack),
          ),
          FilledButton(
            key: const Key('event-confirm'),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(eventActionLabel(l10n, target, event.status)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _pending = target);
    final toast = Toaster.of(context);
    try {
      final updated = await ref
          .read(eventsProvider.notifier)
          .changeStatus(event.id, target);
      toast.success(
        l10n.eventStatusChanged(eventStatusLabel(l10n, updated.status)),
      );
    } on EventFailure catch (failure) {
      toast.error(
        eventFailureMessage(l10n, failure),
        key: const Key('event-action-error'),
      );
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final events = ref.watch(eventsProvider);
    final event = ref.watch(eventByIdProvider(widget.eventId));
    final canManage = canManageEvents(ref.watch(activeOrganizationProvider));

    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: events.isLoading
              ? const CircularProgressIndicator()
              : Text(
                  l10n.eventNotFoundTitle,
                  key: const Key('event-not-found'),
                ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final offset = utcOffsetLabel(event.timezone, event.startsAt);
    final zoneLabel = timeZoneLabel(event.timezone);
    final canEditCover = canManage && event.status.isEditable;
    final place = [?event.venue, ?event.city].join(' · ');
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 280,
            foregroundColor: TicketSurColors.white,
            backgroundColor: TicketSurColors.navy,
            actions: [
              if (canManage)
                IconButton(
                  key: const Key('event-duplicate'),
                  tooltip: l10n.eventDuplicate,
                  color: TicketSurColors.white,
                  onPressed: () =>
                      unawaited(showDuplicateEventSheet(context, event)),
                  icon: const Icon(Icons.content_copy_rounded),
                ),
              if (canManage && event.status.isEditable)
                TextButton.icon(
                  key: const Key('event-edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: TicketSurColors.white,
                  ),
                  onPressed: () =>
                      unawaited(context.push(AppRoutes.editEvent(event.id))),
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(l10n.eventEdit),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(
                event: event,
                uploading: _uploadingCover,
                onChangeCover: canEditCover
                    ? () => unawaited(_changeCover(event))
                    : null,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(TicketSurSpacing.md),
            // Colonne plutôt que liste paresseuse : la fiche est courte et
            // toutes ses sections restent construites (formulaires, tests).
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canManage &&
                      event.status == EventStatus.draft &&
                      !event.readyToPublish) ...[
                    FadeSlideIn(
                      child: _CompleteCard(
                        event: event,
                        onAddCover: canEditCover
                            ? () => unawaited(_changeCover(event))
                            : null,
                      ),
                    ),
                    const SizedBox(height: TicketSurSpacing.md),
                  ],
                  if (canManage && event.status != EventStatus.draft) ...[
                    FadeSlideIn(
                      child: FilledButton.tonalIcon(
                        key: const Key('event-dashboard'),
                        onPressed: () => unawaited(
                          context.push(AppRoutes.eventDashboard(event.id)),
                        ),
                        icon: const Icon(Icons.insights_rounded),
                        label: Text(l10n.dashboardOpen),
                      ),
                    ),
                    const SizedBox(height: TicketSurSpacing.md),
                  ],
                  if (ref
                          .watch(scanPostsProvider)
                          .value
                          ?.any((post) => post.eventId == event.id) ??
                      false) ...[
                    FilledButton.icon(
                      key: const Key('event-control'),
                      onPressed: () => unawaited(
                        context.push(
                          '${AppRoutes.posts}?evenement=${event.id}',
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(l10n.eventControl),
                    ),
                    const SizedBox(height: TicketSurSpacing.md),
                  ],
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.schedule_rounded),
                            title: Text(l10n.eventDetailDates),
                            subtitle: Text(
                              '${formatEventRange(event)}\n'
                              '${l10n.eventTimeZoneLine(zoneLabel, offset)}',
                              key: const Key('event-dates'),
                            ),
                            isThreeLine: true,
                          ),
                          ListTile(
                            key: const Key('event-place'),
                            leading: const Icon(Icons.place_rounded),
                            title: Text(l10n.eventDetailVenue),
                            subtitle: Text(
                              [
                                if (place.isEmpty) l10n.eventNoVenue else place,
                                ?event.venueAddress,
                              ].join('\n'),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.people_outline_rounded),
                            title: Text(l10n.eventDetailCapacity),
                            subtitle: Text(
                              event.capacity == null
                                  ? l10n.eventNoCapacity
                                  : l10n.eventCapacityValue(event.capacity!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (event.description case final description?) ...[
                    const SizedBox(height: TicketSurSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 90),
                      child: Card(
                        key: const Key('event-description-card'),
                        child: Padding(
                          padding: const EdgeInsets.all(TicketSurSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.eventDetailDescription,
                                style: textTheme.titleMedium,
                              ),
                              const SizedBox(height: TicketSurSpacing.xs),
                              Text(description, style: textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: TicketSurSpacing.md),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(TicketSurSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.eventLifecycleTitle,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: TicketSurSpacing.xs),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                eventLifecycleHint(l10n, event.status),
                                key: ValueKey(event.status),
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            if (canManage &&
                                event.status.nextStatuses.isNotEmpty) ...[
                              const SizedBox(height: TicketSurSpacing.md),
                              for (final (index, target)
                                  in event.status.nextStatuses.indexed)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: TicketSurSpacing.xs,
                                  ),
                                  child: _ActionButton(
                                    key: Key('event-action-${target.wireName}'),
                                    primary: index == 0,
                                    destructive: isFinalTransition(target),
                                    busy: _pending == target,
                                    enabled: _pending == null,
                                    icon: eventStatusStyle(target).glyph,
                                    label: eventActionLabel(
                                      l10n,
                                      target,
                                      event.status,
                                    ),
                                    onPressed: () =>
                                        unawaited(_changeStatus(event, target)),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: TicketSurSpacing.md),
                  if (canManage &&
                      event.status != EventStatus.cancelled &&
                      event.status != EventStatus.archived) ...[
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: _PublicCard(event: event),
                    ),
                    const SizedBox(height: TicketSurSpacing.md),
                  ],
                  if (canManage) ...[
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: CategoriesSection(event: event),
                    ),
                    const SizedBox(height: TicketSurSpacing.md),
                  ],
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child: CheckpointsSection(
                      event: event,
                      canManage: canManage,
                    ),
                  ),
                  const SizedBox(height: TicketSurSpacing.md),
                  if (canManage)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 260),
                      child: EventTeamSection(event: event),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new({required this.event, required this.uploading, this.onChangeCover});

  final TicketEvent event;
  final bool uploading;
  final VoidCallback? onChangeCover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final white = textTheme.bodyMedium?.copyWith(color: TicketSurColors.white);
    return Stack(
      fit: StackFit.expand,
      children: [
        EventCover.forEvent(
          event,
          aspectRatio: 0.1,
          overlay: const CoverScrim(child: SizedBox.expand()),
        ),
        Positioned(
          left: TicketSurSpacing.md,
          right: TicketSurSpacing.md,
          bottom: TicketSurSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  EventStatusChip(
                    key: const Key('event-status'),
                    status: event.status,
                  ),
                  const SizedBox(width: TicketSurSpacing.xs),
                  Icon(
                    eventKindIcon(event.kind),
                    size: 16,
                    color: TicketSurColors.white,
                  ),
                  const SizedBox(width: TicketSurSpacing.xxs),
                  Text(eventKindLabel(l10n, event.kind), style: white),
                ],
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              Text(
                event.title,
                key: const Key('event-detail-title'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineSmall?.copyWith(
                  color: TicketSurColors.white,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.xxs),
              Text(formatEventRange(event), style: white),
              if (event.city case final city?)
                Text(city, key: const Key('event-city-line'), style: white),
            ],
          ),
        ),
        if (onChangeCover != null || uploading)
          Positioned(
            right: TicketSurSpacing.md,
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            child: uploading
                ? const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x99000000),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: TicketSurColors.white,
                        ),
                      ),
                    ),
                  )
                : FilledButton.tonalIcon(
                    key: const Key('event-change-cover'),
                    // Le thème impose une largeur pleine aux boutons.
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: onChangeCover,
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: Text(
                      event.coverPath == null
                          ? l10n.eventCoverAdd
                          : l10n.eventCoverChange,
                    ),
                  ),
          ),
      ],
    );
  }
}

/// Ce qu'il manque pour publier, avec un raccourci pour chaque élément.
class _CompleteCard extends StatelessWidget {
  const new({required this.event, this.onAddCover});

  final TicketEvent event;
  final VoidCallback? onAddCover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final ink = context.palette.warningText;
    return Container(
      key: const Key('event-complete'),
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.warningContainer,
        borderRadius: BorderRadius.circular(TicketSurRadii.md),
        border: Border.all(color: context.palette.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: ink),
              const SizedBox(width: TicketSurSpacing.sm),
              Expanded(
                child: Text(
                  l10n.eventToCompleteTitle,
                  style: textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          Wrap(
            spacing: TicketSurSpacing.sm,
            runSpacing: TicketSurSpacing.xs,
            children: [
              if (event.coverPath == null)
                ActionChip(
                  key: const Key('event-complete-cover'),
                  avatar: const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(l10n.eventMissingCover),
                  onPressed: onAddCover,
                ),
              if (event.city == null)
                ActionChip(
                  key: const Key('event-complete-city'),
                  avatar: const Icon(Icons.location_city_rounded),
                  label: Text(l10n.eventMissingCity),
                  onPressed: () =>
                      unawaited(context.push(AppRoutes.editEvent(event.id))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const new({
    required this.primary,
    required this.destructive,
    required this.busy,
    required this.enabled,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final bool primary;
  final bool destructive;
  final bool busy;
  final bool enabled;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final leading = busy
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon);
    final onTap = enabled ? onPressed : null;
    if (primary && !destructive) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: leading,
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: leading,
      label: Text(label),
      style: destructive
          ? OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
            )
          : null,
    );
  }
}

/// Visibilité dans l'Explorer public (refonte Tikéo, ADR 0012).
class _PublicCard extends ConsumerStatefulWidget {
  const new({required this.event});

  final TicketEvent event;

  @override
  ConsumerState<_PublicCard> createState() => _PublicCardState();
}

class _PublicCardState extends ConsumerState<_PublicCard> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(eventsProvider.notifier)
          .setPublic(widget.event.id, public: value);
    } on EventFailure catch (failure) {
      toast.error(eventFailureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final public = widget.event.isPublic;
    final blocked = widget.event.publicBlocked;
    return Card(
      key: const Key('event-public-card'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TicketSurSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: const Key('event-public'),
              value: public,
              onChanged: _busy || (blocked && !public)
                  ? null
                  : (value) => unawaited(_toggle(value)),
              secondary: Icon(
                public ? Icons.public_rounded : Icons.lock_outline_rounded,
              ),
              title: Text(l10n.eventPublicTitle),
              subtitle: Text(public ? l10n.eventPublicOn : l10n.eventPublicOff),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TicketSurSpacing.md,
                0,
                TicketSurSpacing.md,
                TicketSurSpacing.xs,
              ),
              child: Text(l10n.eventPublicHelp, style: textTheme.bodySmall),
            ),
            if (blocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  TicketSurSpacing.xs,
                  TicketSurSpacing.md,
                  TicketSurSpacing.xs,
                ),
                child: Text(
                  [
                    l10n.eventPublicBlocked,
                    ?widget.event.publicBlockedReason,
                  ].join(' '),
                  key: const Key('event-public-blocked'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
