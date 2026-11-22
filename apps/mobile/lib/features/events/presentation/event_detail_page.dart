import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/confirm.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/audience/presentation/audience_cards.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/presentation/event_billing_page.dart';
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
import 'package:ticketsur/features/events/presentation/photo_viewer.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/team/presentation/event_team_section.dart';
import 'package:ticketsur/l10n/l10n.dart';

part 'event_detail_widgets.dart';

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
    final confirmed = await confirmAction(
      context,
      icon: eventStatusStyle(target).glyph,
      title: eventActionLabel(l10n, target, event.status),
      body: eventConfirmBody(l10n, target, event.status),
      cancelLabel: l10n.eventConfirmBack,
      confirmLabel: eventActionLabel(l10n, target, event.status),
      danger: destructive,
      confirmKey: const Key('event-confirm'),
    );
    if (!confirmed || !mounted) return;
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
    final tints = context.tints;
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
            // Sélection du texte sur le contenu seulement : la photo garde
            // son appui (photo en grand).
            sliver: SliverToBoxAdapter(
              child: SelectionArea(
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
                        child: TikeoPrimaryButton(
                          key: const Key('event-dashboard'),
                          onPressed: () => unawaited(
                            context.push(AppRoutes.eventDashboard(event.id)),
                          ),
                          icon: Icons.insights_rounded,
                          label: l10n.dashboardOpen,
                        ),
                      ),
                      const SizedBox(height: TicketSurSpacing.md),
                    ],
                    if (ref
                            .watch(scanPostsProvider)
                            .value
                            ?.any((post) => post.eventId == event.id) ??
                        false) ...[
                      TikeoDarkButton(
                        key: const Key('event-control'),
                        onPressed: () => unawaited(
                          context.push(
                            '${AppRoutes.posts}?evenement=${event.id}',
                          ),
                        ),
                        icon: Icons.qr_code_scanner_rounded,
                        label: l10n.eventControl,
                      ),
                      const SizedBox(height: TicketSurSpacing.md),
                    ],
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: TikeoCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.calendar_month_rounded,
                              tint: tints.mint,
                              title: l10n.eventDetailDates,
                              body: Text(
                                '${formatEventRange(event)}\n'
                                '${l10n.eventTimeZoneLine(zoneLabel, offset)}',
                                key: const Key('event-dates'),
                              ),
                            ),
                            _InfoRow(
                              key: const Key('event-place'),
                              icon: Icons.place_rounded,
                              tint: tints.salmon,
                              title: l10n.eventDetailVenue,
                              body: Text(
                                [
                                  if (place.isEmpty)
                                    l10n.eventNoVenue
                                  else
                                    place,
                                  ?event.venueAddress,
                                ].join('\n'),
                              ),
                            ),
                            _InfoRow(
                              icon: Icons.people_alt_rounded,
                              tint: tints.amber,
                              title: l10n.eventDetailCapacity,
                              body: Text(
                                event.capacity == null
                                    ? l10n.eventNoCapacity
                                    : l10n.eventCapacityValue(event.capacity!),
                              ),
                              divider: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (canManage && event.status != EventStatus.draft) ...[
                      const SizedBox(height: TicketSurSpacing.md),
                      EventViewsCard(event: event),
                    ],
                    if (canManage) ...[
                      const SizedBox(height: TicketSurSpacing.md),
                      TikeoCard(
                        padding: const EdgeInsets.all(4),
                        child: SettingsRow(
                          key: const Key('event-billing'),
                          icon: Icons.account_balance_wallet_rounded,
                          tint: tints.amber,
                          title: l10n.billingEventTitle,
                          subtitle: switch (ref.watch(
                            eventBillingProvider(event.id),
                          )) {
                            AsyncValue(value: final EventBilling billing) =>
                              eventBillingSummary(l10n, billing),
                            _ => null,
                          },
                          onTap: () => unawaited(
                            context.push(AppRoutes.eventBilling(event.id)),
                          ),
                        ),
                      ),
                    ],
                    if (event.description case final description?) ...[
                      const SizedBox(height: TicketSurSpacing.md),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 90),
                        child: TikeoCard(
                          key: const Key('event-description-card'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SectionHeader(
                                title: l10n.eventDetailDescription,
                                icon: Icons.notes_rounded,
                              ),
                              const SizedBox(height: TicketSurSpacing.xs),
                              Text(description, style: textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: TicketSurSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: TikeoCard(
                        key: const Key('event-lifecycle'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionHeader(
                              title: l10n.eventLifecycleTitle,
                              icon: Icons.flag_rounded,
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
          ),
        ],
      ),
    );
  }
}
