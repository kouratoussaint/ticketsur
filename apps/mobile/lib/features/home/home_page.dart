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
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';
import 'package:ticketsur/features/announcements/presentation/announcement_banner.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/dashboard/application/dashboard_providers.dart';
import 'package:ticketsur/features/dashboard/presentation/event_dashboard_page.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_status_chip.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/organizations/presentation/organization_switcher.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Accueil organisateur (Tikéo) : salutation, actions rapides, événement du
/// moment avec ses chiffres d'entrée, puis les autres événements.
class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(eventsProvider);
            await ref.read(eventsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(TicketSurSpacing.md),
            children: [
              const FadeSlideIn(child: _Header()),
              const SizedBox(height: TicketSurSpacing.lg),
              const AnnouncementBanner(
                padding: EdgeInsets.only(bottom: TicketSurSpacing.md),
              ),
              const FadeSlideIn(
                delay: Duration(milliseconds: 60),
                child: _QuickActions(),
              ),
              const _ControlShortcut(),
              const SizedBox(height: TicketSurSpacing.lg),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  l10n.homeNextEventTitle,
                  style: textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              const FadeSlideIn(
                delay: Duration(milliseconds: 100),
                child: _NextEvent(),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.homeMyEventsTitle,
                        style: textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      key: const Key('home-all-events'),
                      onPressed: () => context.go(AppRoutes.events),
                      child: Text(l10n.homeSeeAll),
                    ),
                  ],
                ),
              ),
              const FadeSlideIn(
                delay: Duration(milliseconds: 140),
                child: _OtherEvents(),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Bonjour Awa », organisation active (touchez pour changer) et avatar.
class _Header extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final email = ref.watch(currentUserProvider).value?.email;
    final organization = ref.watch(activeOrganizationProvider);
    final profile = ref.watch(profileProvider).value;
    final firstName = profile?.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .firstOrNull;
    final subtitle = [
      if (organization != null) roleLabel(l10n, organization.role),
      ?email,
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName == null || firstName.isEmpty
                    ? l10n.homeHelloPlain
                    : l10n.homeHello(firstName),
                key: const Key('home-hello'),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.xxs),
              Semantics(
                button: true,
                hint: l10n.orgSwitchAction,
                child: InkWell(
                  key: const Key('home-switch-org'),
                  borderRadius: BorderRadius.circular(TicketSurRadii.sm),
                  onTap: () => showOrganizationSwitcher(context),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            organization?.name ?? l10n.homeGreeting,
                            key: const Key('home-org-name'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: context.palette.accentText,
                            ),
                          ),
                        ),
                        const SizedBox(width: TicketSurSpacing.xxs),
                        Icon(
                          Icons.unfold_more_rounded,
                          size: 20,
                          color: context.palette.accentText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  key: const Key('home-signed-in-as'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.mutedText,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: TicketSurSpacing.sm),
        Semantics(
          button: true,
          label: l10n.homeProfileLabel,
          child: ExcludeSemantics(
            child: PressableScale(
              child: InkResponse(
                key: const Key('home-avatar'),
                radius: 28,
                onTap: () => context.go(AppRoutes.profile),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: TicketSurColors.mint,
                  foregroundColor: TicketSurColors.navy,
                  child: Text(
                    profile?.initials ?? '?',
                    style: textTheme.titleMedium?.copyWith(
                      color: TicketSurColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Raccourci vers le contrôle des entrées, si l'utilisateur est affecté
/// à au moins une porte (§12.2 : accès direct contextualisé).
class _ControlShortcut extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(scanPostsProvider).value?.length ?? 0;
    return MotionSize(
      child: count == 0
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: TicketSurSpacing.sm),
              child: Card(
                key: const Key('home-control'),
                child: ListTile(
                  leading: const Icon(Icons.qr_code_scanner_rounded),
                  title: Text(l10n.homeControlTitle),
                  subtitle: Text(l10n.homeControlBody(count)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => unawaited(context.push(AppRoutes.posts)),
                ),
              ),
            ),
    );
  }
}

/// Événement du moment : celui en cours, sinon le prochain actif.
TicketEvent? _currentEvent(List<TicketEvent> events) {
  final active = events.where((e) => e.status.isActive);
  return active.where((e) => e.status == EventStatus.inProgress).firstOrNull ??
      active.firstOrNull;
}

/// Carte bleu nuit de l'événement du moment, ou invitation à en créer un.
class _NextEvent extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(eventsProvider);
    final canManage = canManageEvents(ref.watch(activeOrganizationProvider));
    final next = switch (events) {
      AsyncData(:final value) => _currentEvent(value),
      _ => null,
    };
    final child = switch (events) {
      AsyncData() when next != null => _EventHero(
        key: ValueKey('home-next-${next.id}'),
        event: next,
        showStats: canManage && next.status != EventStatus.draft,
      ),
      AsyncData() => Card(
        key: const Key('home-no-event'),
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available_rounded),
                  const SizedBox(width: TicketSurSpacing.sm),
                  Expanded(child: Text(l10n.homeNoEventBody)),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('home-event-action'),
                  onPressed: () => canManage
                      ? unawaited(context.push(AppRoutes.newEvent))
                      : context.go(AppRoutes.events),
                  child: Text(
                    canManage ? l10n.homeCreateEvent : l10n.homeSeeEvents,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      AsyncError() => Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off_rounded),
          title: Text(l10n.eventsLoadError),
          trailing: TextButton(
            onPressed: () => ref.invalidate(eventsProvider),
            child: Text(l10n.orgRetry),
          ),
        ),
      ),
      _ => const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator()),
      ),
    };
    return AnimatedSwitcher(
      duration: TicketSurMotion.reduced(context)
          ? Duration.zero
          : TicketSurMotion.medium,
      child: child,
    );
  }
}

class _EventHero extends StatelessWidget {
  const new({required this.event, required this.showStats, super.key});

  final TicketEvent event;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    const white = TicketSurColors.white;
    final place = [?event.venue, ?event.city].join(' · ');
    final info = textTheme.bodyMedium?.copyWith(color: white);
    return PressableScale(
      child: Material(
        key: const Key('home-next-event'),
        borderRadius: BorderRadius.circular(TicketSurRadii.lg),
        clipBehavior: Clip.antiAlias,
        color: TicketSurColors.navy,
        child: Ink(
          // Dégradé de marque sombre : texte blanc lisible partout (≥ 7:1).
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [TicketSurColors.navy, TicketSurColors.navyLight],
            ),
          ),
          child: InkWell(
            // Fiche empilée au-dessus de l'Accueil : Retour y revient.
            onTap: () =>
                unawaited(context.push(AppRoutes.eventDetail(event.id))),
            child: Padding(
              padding: const EdgeInsets.all(TicketSurSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      EventStatusChip(status: event.status),
                      const Spacer(),
                      Text(
                        eventKindLabel(l10n, event.kind).toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: TicketSurColors.mint,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(color: white),
                  ),
                  const SizedBox(height: TicketSurSpacing.xs),
                  _HeroLine(
                    icon: Icons.schedule_rounded,
                    text: formatEventRange(event),
                    style: info,
                  ),
                  if (place.isNotEmpty)
                    _HeroLine(
                      icon: Icons.place_outlined,
                      text: place,
                      style: info,
                    ),
                  if (showStats) _HeroStats(eventId: event.id),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroLine extends StatelessWidget {
  const new({required this.icon, required this.text, this.style});

  final IconData icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: TicketSurSpacing.xxs),
    child: Row(
      children: [
        Icon(icon, size: 16, color: TicketSurColors.mint),
        const SizedBox(width: TicketSurSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    ),
  );
}

/// Entrés, émis et présence de l'événement du moment, puis le lien vers le
/// tableau de bord. Les chiffres viennent du même fournisseur que le tableau
/// de bord : l'ouvrir ne relance pas une seconde lecture.
class _HeroStats extends ConsumerWidget {
  const new({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final tickets = ref.watch(dashboardProvider(eventId)).data?.tickets;
    const white = TicketSurColors.white;
    Widget stat(String value, String label, Key key) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            key: key,
            maxLines: 1,
            style: textTheme.headlineSmall?.copyWith(
              color: white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: textTheme.bodySmall?.copyWith(color: white)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MotionSize(
          child: tickets == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: TicketSurSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          stat(
                            formatCount(tickets.admitted),
                            l10n.homeStatAdmitted,
                            const Key('home-stat-admitted'),
                          ),
                          stat(
                            formatCount(tickets.issued),
                            l10n.homeStatIssued,
                            const Key('home-stat-issued'),
                          ),
                          stat(
                            formatPercent(tickets.attendance),
                            l10n.homeStatAttendance,
                            const Key('home-stat-attendance'),
                          ),
                        ],
                      ),
                      const SizedBox(height: TicketSurSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: tickets.attendance.clamp(0, 1).toDouble(),
                          minHeight: 8,
                          color: TicketSurColors.mint,
                          backgroundColor: white.withValues(alpha: 0.18),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        Material(
          color: white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(TicketSurRadii.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('home-dashboard'),
            onTap: () =>
                unawaited(context.push(AppRoutes.eventDashboard(eventId))),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TicketSurSpacing.md,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: TicketSurColors.mint,
                    ),
                    const SizedBox(width: TicketSurSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.homeDashboard,
                        style: textTheme.labelLarge?.copyWith(color: white),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Les autres événements de l'organisation (trois au plus).
class _OtherEvents extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).value ?? const <TicketEvent>[];
    final current = _currentEvent(events);
    final others = events.where((e) => e.id != current?.id).take(3).toList();
    return Column(
      children: [
        for (final event in others)
          Padding(
            padding: const EdgeInsets.only(top: TicketSurSpacing.sm),
            child: _EventRow(event: event),
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const new({required this.event});

  final TicketEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final start = wallTimeIn(event.timezone, event.startsAt);
    final muted = !event.status.isActive;
    final ink = muted ? context.palette.mutedText : context.palette.accentText;
    return PressableScale(
      child: Card(
        key: Key('home-event-${event.id}'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => unawaited(context.push(AppRoutes.eventDetail(event.id))),
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(
                    vertical: TicketSurSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(TicketSurRadii.sm),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat(
                          'MMM',
                          'fr',
                        ).format(start).replaceAll('.', '').toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(color: ink),
                      ),
                      Text(
                        '${start.day}',
                        style: textTheme.titleLarge?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TicketSurSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: TicketSurSpacing.xxs),
                      Text(
                        [formatEventTime(start), ?event.city].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: context.palette.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TicketSurSpacing.xs),
                EventStatusChip(status: event.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Actions rapides de l'organisateur : la première, en menthe, crée un
/// événement.
class _QuickActions extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final actions = [
      (
        'quick-new-event',
        Icons.add_rounded,
        l10n.homeQuickNewEvent,
        AppRoutes.newEvent,
      ),
      (
        'quick-issue',
        Icons.confirmation_number_outlined,
        l10n.homeQuickIssue,
        AppRoutes.tickets,
      ),
      (
        'quick-invite',
        Icons.person_add_alt_1_outlined,
        l10n.homeQuickInvite,
        AppRoutes.team,
      ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, (key, icon, label, route)) in actions.indexed) ...[
            if (index > 0) const SizedBox(width: TicketSurSpacing.sm),
            Expanded(
              child: PressableScale(
                child: Material(
                  key: Key(key),
                  color: index == 0
                      ? TicketSurColors.mint
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(TicketSurRadii.md),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    // Création : page empilée ; Tickets et Équipe : onglets.
                    onTap: () => route == AppRoutes.newEvent
                        ? unawaited(context.push(route))
                        : context.go(route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: TicketSurSpacing.md,
                        horizontal: TicketSurSpacing.xs,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            icon,
                            size: 28,
                            color: index == 0
                                ? TicketSurColors.navy
                                : context.palette.accentText,
                          ),
                          const SizedBox(height: TicketSurSpacing.xs),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: index == 0
                                      ? TicketSurColors.navy
                                      : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
