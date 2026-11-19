import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/organizations/presentation/organization_switcher.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/profile/domain/profile.dart';
import 'package:ticketsur/features/profile/presentation/account_sheets.dart';
import 'package:ticketsur/features/profile/presentation/appearance_card.dart';
import 'package:ticketsur/features/profile/presentation/feedback_settings_card.dart';
import 'package:ticketsur/features/profile/presentation/user_avatar.dart';
import 'package:ticketsur/features/support/application/support_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Profil (S28) : identité modifiable, organisation, sécurité, réglages,
/// suppression du compte, déconnexion.
class ProfilePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final email = ref.watch(currentUserProvider).value?.email ?? '';
    final profile = ref.watch(profileProvider);
    final organization = ref.watch(activeOrganizationProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          await ref.read(organizationsProvider.notifier).reload();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                child: _IdentityCard(email: email, profile: profile),
              ),
              if (profile.value?.deletionDueAt case final due?) ...[
                const SizedBox(height: TicketSurSpacing.md),
                FadeSlideIn(child: _DeletionBanner(due: due)),
              ],
              const SizedBox(height: TicketSurSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 40),
                child: organization != null
                    ? _OrganizationCard(organization: organization)
                    : const _PromoterCard(),
              ),
              const SizedBox(height: TicketSurSpacing.md),
              const _ConsoleEntry(),
              const FadeSlideIn(
                delay: Duration(milliseconds: 60),
                child: _SupportCard(),
              ),
              const SizedBox(height: TicketSurSpacing.md),
              const FadeSlideIn(
                delay: Duration(milliseconds: 80),
                child: _SecurityCard(),
              ),
              const SizedBox(height: TicketSurSpacing.md),
              const FadeSlideIn(
                delay: Duration(milliseconds: 100),
                child: AppearanceCard(),
              ),
              const SizedBox(height: TicketSurSpacing.md),
              const FadeSlideIn(
                delay: Duration(milliseconds: 120),
                child: FeedbackSettingsCard(),
              ),
              const SizedBox(height: TicketSurSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(l10n.profileAbout),
                    subtitle: Text('${l10n.appName} — ${l10n.appSlogan}'),
                  ),
                ),
              ),
              const SizedBox(height: TicketSurSpacing.md),
              if (profile.value case final loaded?
                  when loaded.deletionRequestedAt == null)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _DangerCard(),
                ),
              const SizedBox(height: TicketSurSpacing.xl),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
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
              const SizedBox(height: TicketSurSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compte classique (sans structure) : devenir promoteur, ou rejoindre
/// l'équipe d'un promoteur avec un code.
class _PromoterCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      key: const Key('profile-promoter'),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.profilePromoterTitle, style: textTheme.titleMedium),
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(l10n.profilePromoterBody),
            const SizedBox(height: TicketSurSpacing.md),
            FilledButton.icon(
              key: const Key('profile-become-promoter'),
              onPressed: () =>
                  unawaited(context.push(AppRoutes.newOrganization)),
              icon: const Icon(Icons.campaign_rounded),
              label: Text(l10n.profilePromoterAction),
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            OutlinedButton.icon(
              key: const Key('profile-join'),
              onPressed: () =>
                  unawaited(context.push(AppRoutes.joinOrganization)),
              icon: const Icon(Icons.key_rounded),
              label: Text(l10n.profileJoinAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entrée de la console, pour les seuls administrateurs de la plateforme.
class _ConsoleEntry extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final admin = ref.watch(isPlatformAdminProvider).value ?? false;
    return MotionSize(
      child: !admin
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: TicketSurSpacing.md),
              child: Card(
                key: const Key('profile-console'),
                child: ListTile(
                  leading: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: context.palette.accentText,
                  ),
                  title: Text(l10n.consoleTitle),
                  subtitle: Text(l10n.consoleEntrySubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => unawaited(context.push(AppRoutes.console)),
                ),
              ),
            ),
    );
  }
}

/// Aide et support, avec le nombre de réponses non lues.
class _SupportCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unread = ref.watch(supportUnreadProvider);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('profile-support'),
      child: ListTile(
        leading: Icon(
          Icons.support_agent_rounded,
          color: context.palette.accentText,
        ),
        title: Text(l10n.supportEntryTitle),
        subtitle: Text(
          unread > 0 ? l10n.supportUnread(unread) : l10n.supportEntrySubtitle,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unread > 0)
              Badge.count(
                key: const Key('profile-support-unread'),
                count: unread,
                backgroundColor: scheme.error,
                textColor: scheme.onError,
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () => unawaited(context.push(AppRoutes.support)),
      ),
    );
  }
}

/// En-tête : photo, nom, adresse, téléphone, « Modifier le profil ».
class _IdentityCard extends ConsumerWidget {
  const new({required this.email, required this.profile});

  final String email;
  final AsyncValue<UserProfile> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final white = textTheme.bodyMedium?.copyWith(color: TicketSurColors.white);
    final loaded = profile.value;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TicketSurRadii.lg),
        // Dégradé de marque sombre : texte blanc lisible (≥ 7:1).
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TicketSurColors.navy, TicketSurColors.navyLight],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'profile-avatar',
                  child: UserAvatar(
                    radius: 34,
                    initials: loaded?.initials ?? initialsOf(email),
                    url: loaded?.avatarUrl,
                  ),
                ),
                const SizedBox(width: TicketSurSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loaded != null)
                        Text(
                          loaded.displayName,
                          key: const Key('profile-name'),
                          style: textTheme.titleLarge?.copyWith(
                            color: TicketSurColors.white,
                          ),
                        )
                      else if (profile.isLoading)
                        const SkeletonBox(width: 140, height: 22)
                      else
                        Text(l10n.profileLoadError, style: white),
                      const SizedBox(height: TicketSurSpacing.xxs),
                      Text(
                        email,
                        key: const Key('profile-email'),
                        style: white,
                      ),
                      if (loaded?.phone case final phone?)
                        Text(
                          formatPhone(phone),
                          key: const Key('profile-phone'),
                          style: white,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.md),
            if (profile.hasError && loaded == null)
              FilledButton.tonal(
                key: const Key('profile-retry'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => ref.invalidate(profileProvider),
                child: Text(l10n.orgRetry),
              )
            else
              FilledButton.tonalIcon(
                key: const Key('profile-edit'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: loaded == null
                    ? null
                    : () => unawaited(context.push(AppRoutes.editProfile)),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(l10n.profileEdit),
              ),
          ],
        ),
      ),
    );
  }
}

/// Organisation active : logo, rôle, ville ; modifier, changer, quitter.
class _OrganizationCard extends ConsumerWidget {
  const new({required this.organization});

  final Organization organization;

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: Text(l10n.orgLeaveTitle(organization.name)),
        content: Text(l10n.orgLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            key: const Key('org-leave-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.orgLeave),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final toast = Toaster.of(context);
    try {
      await ref.read(organizationsProvider.notifier).leave(organization.id);
      toast.success(l10n.orgLeft(organization.name));
    } on OrganizationFailure catch (failure) {
      toast.error(organizationFailureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final isOwner = organization.role == MemberRole.owner;
    return Card(
      key: const Key('profile-org'),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.orgCardTitle, style: textTheme.titleMedium),
            const SizedBox(height: TicketSurSpacing.sm),
            Row(
              children: [
                UserAvatar(
                  radius: 24,
                  initials: initialsOf(organization.name),
                  url: organization.logoUrl,
                ),
                const SizedBox(width: TicketSurSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organization.name,
                        key: const Key('profile-org-name'),
                        style: textTheme.titleSmall,
                      ),
                      Text(
                        [
                          roleLabel(l10n, organization.role),
                          ?organization.city,
                        ].join(' · '),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            Wrap(
              spacing: TicketSurSpacing.xs,
              runSpacing: TicketSurSpacing.xs,
              children: [
                if (isOwner)
                  ActionChip(
                    key: const Key('profile-edit-org'),
                    avatar: const Icon(Icons.storefront_outlined, size: 18),
                    label: Text(l10n.orgEdit),
                    onPressed: () =>
                        unawaited(context.push(AppRoutes.editOrganization)),
                  ),
                ActionChip(
                  key: const Key('profile-switch-org'),
                  avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(l10n.orgSwitchAction),
                  onPressed: () => showOrganizationSwitcher(context),
                ),
                ActionChip(
                  key: const Key('profile-leave-org'),
                  avatar: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(l10n.orgLeave),
                  onPressed: () => unawaited(_leave(context, ref)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mot de passe, adresse e-mail, sessions.
class _SecurityCard extends ConsumerWidget {
  const new();

  Future<void> _signOutEverywhere(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.devices_rounded),
        title: Text(l10n.profileSignOutEverywhere),
        content: Text(l10n.profileSignOutEverywhereBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            key: const Key('sign-out-everywhere-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.profileConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(authRepositoryProvider).signOutEverywhere();
      if (context.mounted) context.go(AppRoutes.welcome);
    } on AuthFailure catch (failure) {
      if (context.mounted) {
        Toaster.of(context).error(authFailureMessage(l10n, failure));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      key: const Key('profile-security'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              0,
            ),
            child: Text(
              l10n.profileSecurityTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            key: const Key('profile-change-password'),
            leading: const Icon(Icons.password_rounded),
            title: Text(l10n.profileChangePassword),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => unawaited(showChangePasswordSheet(context)),
          ),
          ListTile(
            key: const Key('profile-change-email'),
            leading: const Icon(Icons.alternate_email_rounded),
            title: Text(l10n.profileChangeEmail),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => unawaited(showChangeEmailSheet(context)),
          ),
          ListTile(
            key: const Key('profile-sign-out-everywhere'),
            leading: const Icon(Icons.devices_rounded),
            title: Text(l10n.profileSignOutEverywhere),
            onTap: () => unawaited(_signOutEverywhere(context, ref)),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
        ],
      ),
    );
  }
}

/// Suppression du compte.
class _DangerCard extends ConsumerWidget {
  Future<void> _request(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    final toast = Toaster.of(context);
    try {
      await ref.read(profileProvider.notifier).requestDeletion(requested: true);
      toast.info(l10n.profileDeletionRequested);
    } on ProfileFailure {
      toast.error(l10n.profileErrorUnknown);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('profile-danger'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              0,
            ),
            child: Text(
              l10n.profileDangerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            key: const Key('profile-delete-account'),
            leading: Icon(Icons.delete_forever_rounded, color: scheme.error),
            title: Text(
              l10n.profileDeleteAccount,
              style: TextStyle(color: scheme.error),
            ),
            onTap: () => unawaited(_request(context, ref)),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
        ],
      ),
    );
  }
}

/// Confirmation par saisie du mot « SUPPRIMER ».
class _DeleteAccountDialog extends StatefulWidget {
  const new();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _word = TextEditingController();

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final matches = _word.text.trim().toUpperCase() == l10n.profileDeleteWord;
    return AlertDialog(
      icon: Icon(Icons.delete_forever_rounded, color: scheme.error),
      title: Text(l10n.profileDeleteAccount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.profileDeleteBody),
          const SizedBox(height: TicketSurSpacing.md),
          TextField(
            key: const Key('delete-word'),
            controller: _word,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: l10n.profileDeleteWord),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.profileCancel),
        ),
        FilledButton(
          key: const Key('delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.profileDeleteConfirm),
        ),
      ],
    );
  }
}

/// Bandeau : suppression programmée, avec annulation.
class _DeletionBanner extends ConsumerWidget {
  const new({required this.due});

  final DateTime due;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final date = DateFormat.yMMMMd('fr').format(due.toLocal());
    return Card(
      key: const Key('profile-deletion-pending'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profileDeletionPending(date),
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            FilledButton.tonal(
              key: const Key('profile-deletion-cancel'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () async {
                final toast = Toaster.of(context);
                try {
                  await ref
                      .read(profileProvider.notifier)
                      .requestDeletion(requested: false);
                  toast.success(l10n.profileDeletionCancelled);
                } on ProfileFailure {
                  toast.error(l10n.profileErrorUnknown);
                }
              },
              child: Text(l10n.profileDeletionCancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// « +22670123456 » → « +226 70 12 34 56 » ; les autres numéros
/// internationaux sont affichés tels quels.
String formatPhone(String phone) {
  final match = RegExp(r'^\+226(\d{8})$').firstMatch(phone);
  if (match == null) return phone;
  final d = match.group(1)!;
  return '+226 ${d.substring(0, 2)} ${d.substring(2, 4)} '
      '${d.substring(4, 6)} ${d.substring(6, 8)}';
}
