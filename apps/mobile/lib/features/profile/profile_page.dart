import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/organizations/presentation/organization_switcher.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Profil (S28 provisoire) : compte, à propos, déconnexion.
class ProfilePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider).value;
    final email = user?.email ?? '';
    final organization = ref.watch(activeOrganizationProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          FadeSlideIn(
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(TicketSurSpacing.md),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  child: Text(
                    email.isEmpty ? '?' : email.characters.first.toUpperCase(),
                    style: textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
                title: Text(email, key: const Key('profile-email')),
                subtitle: Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: TicketSurSpacing.xxs),
                    Text(l10n.profileAccountActive),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          if (organization != null)
            FadeSlideIn(
              delay: const Duration(milliseconds: 40),
              child: Card(
                child: ListTile(
                  key: const Key('profile-org'),
                  leading: const Icon(Icons.apartment_rounded),
                  title: Text(organization.name),
                  subtitle: Text(
                    '${l10n.orgActiveLabel} · '
                    '${roleLabel(l10n, organization.role)}',
                  ),
                  trailing: TextButton(
                    key: const Key('profile-switch-org'),
                    onPressed: () => showOrganizationSwitcher(context),
                    child: Text(l10n.orgSwitchAction),
                  ),
                ),
              ),
            ),
          const SizedBox(height: TicketSurSpacing.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.profileAbout),
                subtitle: Text('${l10n.appName} — ${l10n.appSlogan}'),
              ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.xl),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: OutlinedButton.icon(
              key: const Key('profile-sign-out'),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.homeSignOut),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go(AppRoutes.welcome);
              },
            ),
          ),
        ],
      ),
    );
  }
}
