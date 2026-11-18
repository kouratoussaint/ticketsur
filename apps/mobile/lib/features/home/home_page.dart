import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/organizations/presentation/organization_switcher.dart';
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
    final upcoming = [
      (
        Icons.qr_code_scanner_rounded,
        l10n.scanSoonTitle,
        l10n.scanSoonBody,
        '5',
      ),
    ];
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
            const SizedBox(height: TicketSurSpacing.lg),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Text(l10n.homeNextTitle, style: textTheme.titleLarge),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            for (final (index, (icon, title, body, phase)) in upcoming.indexed)
              FadeSlideIn(
                delay: Duration(milliseconds: 140 + 60 * index),
                child: _UpcomingCard(
                  icon: icon,
                  title: title,
                  body: body,
                  badge: l10n.phaseBadge(phase),
                ),
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
      AsyncData() when next != null => EventCard(
        key: const Key('home-next-event'),
        event: next,
        // Ouvre la fiche dans l'onglet Événements (Retour : liste, puis
        // Accueil grâce à l'historique des onglets).
        onTap: () => context.go(AppRoutes.eventDetail(next.id)),
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

class _UpcomingCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.body,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String body;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: TicketSurSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: textTheme.titleMedium),
                      ),
                      Text(
                        badge,
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TicketSurSpacing.xxs),
                  Text(
                    body,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
