import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/organizations/presentation/organization_switcher.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Accueil connecté (S06 provisoire) : bannière de bienvenue, prochain
/// événement et modules à venir.
class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final email = ref.watch(currentUserProvider).value?.email;
    final organization = ref.watch(activeOrganizationProvider);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          children: [
            FadeSlideIn(
              child: _WelcomeBanner(
                title: organization?.name ?? l10n.homeGreeting,
                subtitle: [
                  if (organization != null) roleLabel(l10n, organization.role),
                  ?email,
                ].join(' · '),
                onSwitch: () => showOrganizationSwitcher(context),
                switchLabel: l10n.orgSwitchAction,
              ),
            ),
            const SizedBox(height: TicketSurSpacing.lg),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Text(l10n.homeNextEventTitle, style: textTheme.titleLarge),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            const FadeSlideIn(
              delay: Duration(milliseconds: 100),
              child: _NextEvent(),
            ),
            const _ControlShortcut(),
            const SizedBox(height: TicketSurSpacing.lg),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Text(l10n.homeQuickTitle, style: textTheme.titleLarge),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            const FadeSlideIn(
              delay: Duration(milliseconds: 140),
              child: _QuickActions(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const new({
    required this.title,
    required this.onSwitch,
    required this.switchLabel,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onSwitch;
  final String switchLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TicketSurRadii.lg),
        // Dégradé de marque sombre : texte blanc lisible partout (≥ 7:1).
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TicketSurColors.navy, Color(0xFF0B4A8F)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: const Key('home-org-name'),
                    style: textTheme.titleLarge?.copyWith(
                      color: TicketSurColors.white,
                    ),
                  ),
                  if (subtitle case final text? when text.isNotEmpty) ...[
                    const SizedBox(height: TicketSurSpacing.xs),
                    Text(
                      text,
                      key: const Key('home-signed-in-as'),
                      style: textTheme.bodyMedium?.copyWith(
                        color: TicketSurColors.white,
                      ),
                    ),
                  ],
                  const SizedBox(height: TicketSurSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('home-switch-org'),
                    onPressed: onSwitch,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(switchLabel),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      foregroundColor: TicketSurColors.white,
                      side: const BorderSide(color: TicketSurColors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TicketSurSpacing.md),
            Image.asset(
              'assets/branding/TicketSur_Icone_Android.png',
              width: 64,
              height: 64,
              excludeFromSemantics: true,
            ),
          ],
        ),
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

/// Prochain événement actif, ou invitation à en créer un.
class _NextEvent extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(eventsProvider);
    final canManage = canManageEvents(ref.watch(activeOrganizationProvider));
    final next = events.value?.where((e) => e.status.isActive).firstOrNull;
    final child = switch (events) {
      AsyncData() when next != null => Column(
        key: ValueKey('home-next-${next.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EventCard(
            key: const Key('home-next-event'),
            event: next,
            // Ouvre la fiche dans l'onglet Événements (Retour : liste, puis
            // Accueil grâce à l'historique des onglets).
            onTap: () => context.go(AppRoutes.eventDetail(next.id)),
          ),
          if (canManage && next.status != EventStatus.draft)
            Padding(
              padding: const EdgeInsets.only(top: TicketSurSpacing.sm),
              child: Card(
                key: const Key('home-dashboard'),
                child: ListTile(
                  leading: const Icon(Icons.insights_rounded),
                  title: Text(l10n.homeDashboard),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.eventDashboard(next.id)),
                ),
              ),
            ),
        ],
      ),
      AsyncData() => Card(
        key: const Key('home-no-event'),
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.event_available_rounded),
              const SizedBox(width: TicketSurSpacing.sm),
              Expanded(child: Text(l10n.homeNoEventBody)),
              TextButton(
                key: const Key('home-event-action'),
                onPressed: () => context.go(
                  canManage ? AppRoutes.newEvent : AppRoutes.events,
                ),
                child: Text(
                  canManage ? l10n.homeCreateEvent : l10n.homeSeeEvents,
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

/// Actions rapides de l'organisateur (S06).
class _QuickActions extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = [
      (
        'quick-new-event',
        Icons.add_circle_outline_rounded,
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
    return Row(
      children: [
        for (final (index, (key, icon, label, route)) in actions.indexed) ...[
          if (index > 0) const SizedBox(width: TicketSurSpacing.sm),
          Expanded(
            child: PressableScale(
              child: Card(
                key: Key(key),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.go(route),
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: TicketSurSpacing.xs),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.labelLarge,
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
    );
  }
}
