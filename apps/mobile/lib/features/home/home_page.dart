import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/announcements/presentation/announcement_banner.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/dashboard/application/dashboard_providers.dart';
import 'package:ticketsur/features/dashboard/presentation/event_dashboard_page.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/events/presentation/event_status_chip.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/home/first_steps_card.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/organizations/presentation/organization_switcher.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Accueil promoteur (direction artistique « Nuit et Menthe », ADR 0026) :
/// en-tête héros avec la salutation, carte de la structure active, actions
/// rapides, chiffres des événements, événement du moment avec ses entrées,
/// puis les autres événements et les premiers pas.
class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin),
      child: child,
    );
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(eventsProvider);
          await ref.read(eventsProvider.future);
        },
        child: ListView(
          // Écran court et borné : tout est construit d'emblée.
          scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          children: [
            // En-tête et carte dans une même colonne : la partie de la
            // carte posée sur l'en-tête reste touchable.
            const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(),
                TikeoOverlapCard(
                  child: FadeSlideIn(child: _OrganizationCard()),
                ),
              ],
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            padded(const AnnouncementBanner()),
            padded(
              const FadeSlideIn(
                delay: Duration(milliseconds: 40),
                child: _QuickActions(),
              ),
            ),
            padded(const _ControlShortcut()),
            const SizedBox(height: TikeoSizes.sectionGap - 12),
            padded(
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: SectionHeader(
                  title: l10n.homeNextEventTitle,
                  icon: Icons.event_rounded,
                ),
              ),
            ),
            const SizedBox(height: 8),
            padded(
              const FadeSlideIn(
                delay: Duration(milliseconds: 160),
                child: _NextEvent(),
              ),
            ),
            padded(
              const FadeSlideIn(
                delay: Duration(milliseconds: 180),
                child: _EventCounts(),
              ),
            ),
            const SizedBox(height: TikeoSizes.sectionGap - 12),
            padded(
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: SectionHeader(
                  title: l10n.homeMyEventsTitle,
                  icon: Icons.calendar_month_rounded,
                  actionLabel: l10n.homeSeeAll,
                  actionKey: const Key('home-all-events'),
                  onAction: () => context.go(AppRoutes.events),
                ),
              ),
            ),
            padded(
              const FadeSlideIn(
                delay: Duration(milliseconds: 240),
                child: _OtherEvents(),
              ),
            ),
            // Après les événements : visible d'emblée tant qu'il y en a
            // peu (nouveau promoteur), sans repousser le reste ensuite.
            padded(const FirstStepsCard()),
          ],
        ),
      ),
    );
  }
}

/// En-tête héros : logo, avatar (vers le Profil), « Bonjour Awa ».
class _Header extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(profileProvider).value;
    final firstName = profile?.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .firstOrNull;
    return TikeoHeroHeader(
      title: firstName == null || firstName.isEmpty
          ? l10n.homeHelloPlain
          : l10n.homeHello(firstName),
      titleKey: const Key('home-hello'),
      subtitle: l10n.homeHeroSubtitle,
      actions: [
        Semantics(
          button: true,
          label: l10n.homeProfileLabel,
          child: ExcludeSemantics(
            child: PressableScale(
              child: InkResponse(
                key: const Key('home-avatar'),
                radius: 26,
                onTap: () => context.go(AppRoutes.profile),
                child: CircleAvatar(
                  radius: TikeoSizes.avatarHeader / 2,
                  backgroundColor: TikeoColors.avatarMintPale,
                  child: Text(
                    profile?.initials ?? '?',
                    style: TikeoTextStyles.avatarInitials.copyWith(
                      color: TicketSurColors.navy,
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

/// Carte de la structure active, posée sur l'en-tête : touchez pour en
/// changer.
class _OrganizationCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tint = context.tints.mint;
    final email = ref.watch(currentUserProvider).value?.email;
    final organization = ref.watch(activeOrganizationProvider);
    final subtitle = [
      if (organization != null) roleLabel(l10n, organization.role),
      ?email,
    ].join(' · ');
    return Semantics(
      button: true,
      hint: l10n.orgSwitchAction,
      child: InkWell(
        key: const Key('home-switch-org'),
        borderRadius: BorderRadius.circular(TikeoRadii.tile),
        onTap: () => showOrganizationSwitcher(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Container(
                width: TikeoSizes.settingsIconCircle,
                height: TikeoSizes.settingsIconCircle,
                decoration: BoxDecoration(
                  color: tint.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.storefront_rounded, color: tint.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.homeOrgHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      organization?.name ?? l10n.homeGreeting,
                      key: const Key('home-org-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        key: const Key('home-signed-in-as'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Actions rapides : créer un événement (principale), émettre, inviter.
/// Trois par ligne : à quatre, les libellés seraient coupés sur un écran de
/// 360 (le contrôle a sa propre carte, juste dessous).
class _QuickActions extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = [
      (
        'quick-new-event',
        Icons.add_rounded,
        l10n.homeQuickNewEvent,
        () => unawaited(context.push(AppRoutes.newEvent)),
      ),
      (
        'quick-issue',
        Icons.confirmation_number_rounded,
        l10n.homeQuickIssue,
        () => context.go(AppRoutes.tickets),
      ),
      (
        'quick-invite',
        Icons.person_add_alt_1_rounded,
        l10n.homeQuickInvite,
        () => context.go(AppRoutes.team),
      ),
    ];
    // Largeur d'une tuile : 3 par ligne, marges de 16, espaces de 8,
    // padding intérieur de 4 de chaque côté.
    final tileWidth =
        (MediaQuery.sizeOf(context).width - 2 * TikeoSizes.screenMargin - 16) /
            3 -
        8;
    final labelSize = QuickActionTile.compactLabel(tileWidth) ? 12.0 : 14.0;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, (key, icon, label, onTap)) in actions.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: QuickActionTile(
                key: Key(key),
                icon: icon,
                label: label,
                primary: index == 0,
                labelSize: labelSize,
                onTap: onTap,
              ),
            ),
          ],
        ],
      ),
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
              padding: const EdgeInsets.only(top: TikeoSizes.cardGap),
              child: SettingsRow(
                key: const Key('home-control'),
                icon: Icons.qr_code_scanner_rounded,
                tint: context.tints.violet,
                title: l10n.homeControlTitle,
                subtitle: l10n.homeControlBody(count),
                onTap: () => unawaited(context.push(AppRoutes.posts)),
              ),
            ),
    );
  }
}

/// Chiffres des événements de la structure : tous, en cours, à venir,
/// brouillons. Touchez pour ouvrir la liste.
class _EventCounts extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tints = context.tints;
    final events = ref.watch(eventsProvider).value;
    if (events == null || events.isEmpty) {
      return const SizedBox(width: double.infinity);
    }
    int count(EventStatus status) =>
        events.where((e) => e.status == status).length;
    final tiles = [
      (
        'home-tile-events',
        tints.mint,
        Icons.event_rounded,
        events.length,
        l10n.homeTileEvents,
      ),
      (
        'home-tile-live',
        tints.violet,
        Icons.sensors_rounded,
        count(EventStatus.inProgress),
        l10n.homeTileLive,
      ),
      (
        'home-tile-upcoming',
        tints.blue,
        Icons.schedule_rounded,
        count(EventStatus.published),
        l10n.homeTileUpcoming,
      ),
      (
        'home-tile-drafts',
        tints.amber,
        Icons.edit_note_rounded,
        count(EventStatus.draft),
        l10n.homeTileDrafts,
      ),
    ];
    // Deux par ligne : à quatre, « Événements » et « Brouillons » seraient
    // coupés au milieu du mot.
    Widget tile(int index) {
      final (key, tint, icon, value, label) = tiles[index];
      return Expanded(
        child: StatTile(
          key: Key(key),
          tint: tint,
          icon: icon,
          value: formatCount(value),
          label: label,
          onTap: () => context.go(AppRoutes.events),
        ),
      );
    }

    Widget row(int first) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tile(first), const SizedBox(width: 8), tile(first + 1)],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: TikeoSizes.cardGap),
      child: Column(children: [row(0), const SizedBox(height: 8), row(2)]),
    );
  }
}

/// Événement du moment : celui en cours, sinon le prochain actif.
TicketEvent? _currentEvent(List<TicketEvent> events) {
  final active = events.where((e) => e.status.isActive);
  return active.where((e) => e.status == EventStatus.inProgress).firstOrNull ??
      active.firstOrNull;
}

/// Carte héros de l'événement du moment, ou invitation à en créer un.
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
      AsyncData() => TikeoCard(
        key: const Key('home-no-event'),
        child: Column(
          children: [
            const TikeoIllustrationView(TikeoIllustration.noEvents),
            const SizedBox(height: 8),
            Text(
              l10n.homeNoEventBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('home-event-action'),
              onPressed: () => canManage
                  ? unawaited(context.push(AppRoutes.newEvent))
                  : context.go(AppRoutes.events),
              child: Text(
                canManage ? l10n.homeCreateEvent : l10n.homeSeeEvents,
              ),
            ),
          ],
        ),
      ),
      AsyncError() => TikeoCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.cloud_off_rounded),
          title: Text(l10n.eventsLoadError),
          trailing: TextButton(
            onPressed: () => ref.invalidate(eventsProvider),
            child: Text(l10n.orgRetry),
          ),
        ),
      ),
      _ => const Shimmer(
        child: SkeletonBox(height: TikeoSizes.heroCardHeight, radius: 24),
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

class _EventHero extends ConsumerWidget {
  const new({required this.event, required this.showStats, super.key});

  final TicketEvent event;
  final bool showStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final place = [?event.venue, ?event.city].join(' · ');
    // Chiffres du même fournisseur que le tableau de bord : l'ouvrir ne
    // relance pas une seconde lecture.
    final tickets = showStats
        ? ref.watch(dashboardProvider(event.id)).data?.tickets
        : null;
    return HeroEventCard(
      key: const Key('home-next-event'),
      title: event.title,
      image: switch (event.coverUrl) {
        final url? => Image(
          image: networkImage(url, thumbnail: true),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
        null => null,
      },
      badges: [EventStatusChip(status: event.status)],
      overline: eventKindLabel(l10n, event.kind),
      lines: [
        (icon: Icons.schedule_rounded, text: formatEventRange(event)),
        if (place.isNotEmpty) (icon: Icons.place_rounded, text: place),
      ],
      stats: [
        if (tickets != null) ...[
          (
            value: formatCount(tickets.admitted),
            label: l10n.homeStatAdmitted,
            color: TicketSurColors.mint,
          ),
          (
            value: formatCount(tickets.issued),
            label: l10n.homeStatIssued,
            color: null,
          ),
          (
            value: formatPercent(tickets.attendance),
            label: l10n.homeStatAttendance,
            color: null,
          ),
        ],
      ],
      statKeys: const [
        Key('home-stat-admitted'),
        Key('home-stat-issued'),
        Key('home-stat-attendance'),
      ],
      actionLabel: showStats ? l10n.homeDashboard : null,
      actionIcon: Icons.insights_rounded,
      actionKey: const Key('home-dashboard'),
      onAction: () =>
          unawaited(context.push(AppRoutes.eventDashboard(event.id))),
      // Fiche empilée au-dessus de l'Accueil : Retour y revient.
      onTap: () => unawaited(context.push(AppRoutes.eventDetail(event.id))),
    );
  }
}

/// Les autres événements de la structure (trois au plus).
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
            padding: const EdgeInsets.only(top: 8),
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
    final start = wallTimeIn(event.timezone, event.startsAt);
    final day = DateFormat.MMMEd(appLocaleTag).format(start);
    return TikeoListRow(
      key: Key('home-event-${event.id}'),
      leading: SizedBox(
        width: 64,
        height: 52,
        child: EventCover.forEvent(
          event,
          aspectRatio: 64 / 52,
          borderRadius: BorderRadius.circular(TikeoRadii.thumb),
        ),
      ),
      title: event.title,
      lines: [
        [day, formatEventTime(start), ?event.city].join(' · '),
      ],
      badge: EventStatusChip(status: event.status),
      onTap: () => unawaited(context.push(AppRoutes.eventDetail(event.id))),
    );
  }
}
