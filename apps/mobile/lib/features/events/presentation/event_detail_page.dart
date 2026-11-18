import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_status_chip.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
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

  Future<void> _changeStatus(TicketEvent event, EventStatus target) async {
    final l10n = context.l10n;
    final destructive = isFinalTransition(target);
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(eventStatusStyle(target).glyph),
        title: Text(eventActionLabel(l10n, target)),
        content: Text(eventConfirmBody(l10n, target)),
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
            child: Text(eventActionLabel(l10n, target)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _pending = target);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await ref
          .read(eventsProvider.notifier)
          .changeStatus(event.id, target);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.eventStatusChanged(eventStatusLabel(l10n, updated.status)),
          ),
        ),
      );
    } on EventFailure catch (failure) {
      messenger.showSnackBar(
        SnackBar(
          key: const Key('event-action-error'),
          content: Text(eventFailureMessage(l10n, failure)),
        ),
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
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (canManage && event.status.isEditable)
            TextButton.icon(
              key: const Key('event-edit'),
              onPressed: () =>
                  unawaited(context.push(AppRoutes.editEvent(event.id))),
              icon: const Icon(Icons.edit_rounded),
              label: Text(l10n.eventEdit),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          FadeSlideIn(child: _Header(event: event)),
          const SizedBox(height: TicketSurSpacing.md),
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
                    leading: const Icon(Icons.place_outlined),
                    title: Text(l10n.eventDetailVenue),
                    subtitle: Text(event.venue ?? l10n.eventNoVenue),
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
                    if (canManage && event.status.nextStatuses.isNotEmpty) ...[
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
                            label: eventActionLabel(l10n, target),
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
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TicketSurSpacing.md,
                      TicketSurSpacing.md,
                      TicketSurSpacing.md,
                      0,
                    ),
                    child: Text(
                      l10n.eventNextStepsTitle,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  for (final (icon, label) in [
                    (Icons.sell_outlined, l10n.eventNextCategories),
                    (Icons.door_front_door_outlined, l10n.eventNextCheckpoints),
                    (Icons.badge_outlined, l10n.eventNextTeam),
                  ])
                    ListTile(
                      enabled: false,
                      leading: Icon(icon),
                      title: Text(label),
                      trailing: Text(l10n.eventNextSoon),
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
  const new({required this.event});

  final TicketEvent event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TicketSurRadii.lg),
        // Dégradé de marque sombre : texte blanc lisible (≥ 7:1).
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TicketSurColors.navy, Color(0xFF0B4A8F)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventStatusChip(
              key: const Key('event-status'),
              status: event.status,
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            Text(
              event.title,
              key: const Key('event-detail-title'),
              style: textTheme.headlineSmall?.copyWith(
                color: TicketSurColors.white,
              ),
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(
              formatEventRange(event),
              style: textTheme.bodyMedium?.copyWith(
                color: TicketSurColors.white,
              ),
            ),
          ],
        ),
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
