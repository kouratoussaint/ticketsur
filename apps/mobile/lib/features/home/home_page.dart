import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Accueil connecté (S06 provisoire) : bannière de bienvenue et modules à
/// venir. Le tableau de bord d'organisateur arrive en Phase 2.
class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final email = ref.watch(currentUserProvider).value?.email;
    final textTheme = Theme.of(context).textTheme;
    final upcoming = [
      (Icons.event_rounded, l10n.eventsSoonTitle, l10n.eventsSoonBody, '2'),
      (Icons.groups_rounded, l10n.teamSoonTitle, l10n.teamSoonBody, '2'),
      (
        Icons.confirmation_number_rounded,
        l10n.ticketsSoonTitle,
        l10n.ticketsSoonBody,
        '3',
      ),
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
                title: l10n.homeGreeting,
                subtitle: email == null ? null : l10n.homeSignedInAs(email),
              ),
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
  const new({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

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
                    style: textTheme.titleLarge?.copyWith(
                      color: TicketSurColors.white,
                    ),
                  ),
                  if (subtitle case final text?) ...[
                    const SizedBox(height: TicketSurSpacing.xs),
                    Text(
                      text,
                      key: const Key('home-signed-in-as'),
                      style: textTheme.bodyMedium?.copyWith(
                        color: TicketSurColors.white,
                      ),
                    ),
                  ],
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
