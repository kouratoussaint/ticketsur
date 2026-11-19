import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Porte de l'espace connecté : attend la liste des structures. Sans
/// structure, c'est un compte classique (Explorer, Favoris, Profil) : la
/// coque choisit ses onglets (`AppShell.tabsFor`).
class OrganizationGate extends ConsumerWidget {
  const new({required this.child, super.key});

  /// Espace connecté (barre de navigation).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider);
    final content = switch (organizations) {
      AsyncData() => KeyedSubtree(
        key: const ValueKey('gate-shell'),
        child: child,
      ),
      AsyncError() => const _LoadError(key: ValueKey('gate-error')),
      _ => const _Loading(key: ValueKey('gate-loading')),
    };
    return AnimatedSwitcher(
      duration: TicketSurMotion.reduced(context)
          ? Duration.zero
          : TicketSurMotion.medium,
      switchInCurve: TicketSurMotion.enter,
      switchOutCurve: TicketSurMotion.exit,
      child: content,
    );
  }
}

class _Loading extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: TicketSurSpacing.md),
            Text(context.l10n.orgLoading),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: TicketSurSpacing.md),
              Text(l10n.orgLoadError, textAlign: TextAlign.center),
              const SizedBox(height: TicketSurSpacing.lg),
              FilledButton.icon(
                key: const Key('gate-retry'),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.orgRetry),
                onPressed: () =>
                    ref.read(organizationsProvider.notifier).reload(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
