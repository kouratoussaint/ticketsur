import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Accueil après connexion. Provisoire : le choix d'organisation (S05) et
/// les espaces organisateur (S06) et contrôleur (S20) arrivent en Phase 2.
class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider).value;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TicketSurSpacing.lg),
          children: [
            if (user?.email case final email?)
              Text(
                l10n.homeSignedInAs(email),
                key: const Key('home-signed-in-as'),
                style: textTheme.titleMedium,
              ),
            const SizedBox(height: TicketSurSpacing.md),
            Text(l10n.homeComingSoon, style: textTheme.bodyLarge),
            const SizedBox(height: TicketSurSpacing.xl),
            OutlinedButton.icon(
              key: const Key('home-sign-out'),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.homeSignOut),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go(AppRoutes.welcome);
              },
            ),
          ],
        ),
      ),
    );
  }
}
