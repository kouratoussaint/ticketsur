import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/organizations/presentation/organization_switcher.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/profile/domain/profile.dart';
import 'package:ticketsur/features/profile/presentation/account_sheets.dart';
import 'package:ticketsur/features/profile/presentation/user_avatar.dart';
import 'package:ticketsur/features/support/application/support_providers.dart';
import 'package:ticketsur/features/updates/presentation/update_banner.dart';
import 'package:ticketsur/features/wallet/application/wallet_providers.dart';
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
    final tints = context.tints;
    Widget padded(Widget child, {int delay = 0}) => Padding(
      padding: const EdgeInsets.fromLTRB(
        TikeoSizes.screenMargin,
        0,
        TikeoSizes.screenMargin,
        TikeoSizes.cardGap,
      ),
      child: FadeSlideIn(
        delay: Duration(milliseconds: delay),
        child: child,
      ),
    );
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          await ref.read(organizationsProvider.notifier).reload();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête et identité dans une même colonne : la partie posée
              // sur l'en-tête reste touchable.
              TikeoHeroHeader(title: l10n.profileHeroTitle),
              TikeoOverlapCard(
                child: FadeSlideIn(
                  child: _IdentityCard(email: email, profile: profile),
                ),
              ),
              const SizedBox(height: TikeoSizes.cardGap),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: TikeoSizes.screenMargin,
                ),
                child: UpdateBanner(),
              ),
              if (profile.value?.deletionDueAt case final due?)
                padded(_DeletionBanner(due: due)),
              padded(
                organization != null
                    ? _OrganizationCard(organization: organization)
                    : const _PromoterCard(),
                delay: 40,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: TikeoSizes.screenMargin,
                ),
                child: _ConsoleEntry(),
              ),
              padded(
                TikeoCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      if (organization != null)
                        SettingsRow(
                          key: const Key('profile-wallet'),
                          icon: Icons.confirmation_number_rounded,
                          tint: tints.blue,
                          title: l10n.walletTitle,
                          subtitle: l10n.walletEntrySubtitle,
                          onTap: () =>
                              unawaited(context.push(AppRoutes.wallet)),
                        ),
                      const _SupportCard(),
                      SettingsRow(
                        key: const Key('profile-settings'),
                        icon: Icons.settings_rounded,
                        tint: tints.gray,
                        title: l10n.settingsTitle,
                        subtitle: l10n.settingsEntrySubtitle,
                        onTap: () =>
                            unawaited(context.push(AppRoutes.settings)),
                      ),
                      SettingsRow(
                        key: const Key('profile-about'),
                        icon: Icons.info_rounded,
                        tint: tints.blue,
                        title: l10n.aboutTitle,
                        subtitle: l10n.aboutHint,
                        onTap: () => unawaited(context.push(AppRoutes.about)),
                      ),
                    ],
                  ),
                ),
                delay: 60,
              ),
              padded(const _SecurityCard(), delay: 80),
              if (profile.value case final loaded?
                  when loaded.deletionRequestedAt == null)
                padded(_DangerCard(), delay: 100),
              padded(
                TikeoDangerButton(
                  key: const Key('profile-sign-out'),
                  icon: Icons.logout_rounded,
                  label: l10n.homeSignOut,
                  onPressed: () async {
                    // Ce téléphone ne reçoit plus les messages du compte.
                    await ref.read(pushSyncProvider.notifier).beforeSignOut();
                    // Tickets gardés sur l'appareil : oubliés à la déconnexion.
                    if (ref.read(currentUserProvider).value?.id
                        case final userId?) {
                      await ref
                          .read(walletProvider.notifier)
                          .forgetDevice(userId);
                    }
                    if (!context.mounted) return;
                    await signOutToExplore(
                      GoRouter.of(context),
                      ref.read(authRepositoryProvider).signOut,
                    );
                  },
                ),
                delay: 120,
              ),
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
    return TikeoCard(
      key: const Key('profile-promoter'),
      child: Padding(
        padding: EdgeInsets.zero,
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
              child: TikeoCard(
                padding: EdgeInsets.zero,
                child: SettingsRow(
                  key: const Key('profile-console'),
                  icon: Icons.admin_panel_settings_rounded,
                  tint: context.tints.violet,
                  title: l10n.consoleTitle,
                  subtitle: l10n.consoleEntrySubtitle,
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
    return SettingsRow(
      key: const Key('profile-support'),
      icon: Icons.support_agent_rounded,
      tint: context.tints.salmon,
      title: l10n.supportEntryTitle,
      subtitle: unread > 0
          ? l10n.supportUnread(unread)
          : l10n.supportEntrySubtitle,
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
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
      onTap: () => unawaited(context.push(AppRoutes.support)),
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final muted = textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final loaded = profile.value;
    void edit() => unawaited(context.push(AppRoutes.editProfile));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Avatar de 88 et badge crayon menthe de 28.
            SizedBox.square(
              dimension: TikeoSizes.avatarProfile,
              child: Stack(
                children: [
                  Hero(
                    tag: 'profile-avatar',
                    child: UserAvatar(
                      radius: TikeoSizes.avatarProfile / 2,
                      initials: loaded?.initials ?? initialsOf(email),
                      url: loaded?.avatarUrl,
                    ),
                  ),
                  if (loaded != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Semantics(
                        button: true,
                        label: l10n.profileEdit,
                        child: ExcludeSemantics(
                          child: InkResponse(
                            onTap: edit,
                            radius: 24,
                            child: Container(
                              width: TikeoSizes.avatarBadge,
                              height: TikeoSizes.avatarBadge,
                              decoration: BoxDecoration(
                                color: TicketSurColors.mint,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      theme.cardTheme.color ??
                                      TicketSurColors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: TicketSurColors.navy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
                      style: textTheme.titleLarge,
                    )
                  else if (profile.isLoading)
                    const SkeletonBox(width: 140, height: 22)
                  else
                    Text(l10n.profileLoadError, style: muted),
                  const SizedBox(height: TicketSurSpacing.xxs),
                  Text(email, key: const Key('profile-email'), style: muted),
                  if (loaded?.phone case final phone?)
                    Text(
                      formatPhone(phone),
                      key: const Key('profile-phone'),
                      style: muted,
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
            onPressed: () => ref.invalidate(profileProvider),
            child: Text(l10n.orgRetry),
          )
        else
          OutlinedButton.icon(
            key: const Key('profile-edit'),
            onPressed: loaded == null ? null : edit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(l10n.profileEdit),
          ),
      ],
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
    final tints = context.tints;
    return TikeoCard(
      key: const Key('profile-org'),
      child: Padding(
        padding: EdgeInsets.zero,
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
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TikeoPill(
                            label: roleLabel(l10n, organization.role),
                            tint: roleTint(organization.role, context.tints),
                            icon: roleIcon(organization.role),
                          ),
                          if (organization.city case final city?)
                            Text(city, style: textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            if (isOwner)
              SettingsRow(
                key: const Key('profile-edit-org'),
                icon: Icons.storefront_rounded,
                tint: tints.mint,
                title: l10n.orgEdit,
                onTap: () =>
                    unawaited(context.push(AppRoutes.editOrganization)),
              ),
            if (isOwner)
              SettingsRow(
                key: const Key('profile-journal'),
                icon: Icons.history_rounded,
                tint: tints.violet,
                title: l10n.journalTitle,
                onTap: () => unawaited(context.push(AppRoutes.journal)),
              ),
            if (isOwner)
              SettingsRow(
                key: const Key('profile-billing'),
                icon: Icons.account_balance_wallet_rounded,
                tint: tints.amber,
                title: l10n.billingMyPackTitle,
                subtitle: l10n.billingProfileHint,
                onTap: () => unawaited(context.push(AppRoutes.billing)),
              ),
            SettingsRow(
              key: const Key('profile-switch-org'),
              icon: Icons.swap_horiz_rounded,
              tint: tints.blue,
              title: l10n.orgSwitchAction,
              onTap: () => showOrganizationSwitcher(context),
            ),
            SettingsRow(
              key: const Key('profile-leave-org'),
              icon: Icons.logout_rounded,
              tint: tints.red,
              title: l10n.orgLeave,
              trailing: const SizedBox.shrink(),
              onTap: () => unawaited(_leave(context, ref)),
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
      await signOutToExplore(
        GoRouter.of(context),
        ref.read(authRepositoryProvider).signOutEverywhere,
      );
    } on AuthFailure catch (failure) {
      if (context.mounted) {
        Toaster.of(context).error(authFailureMessage(l10n, failure));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tints = context.tints;
    return TikeoCard(
      key: const Key('profile-security'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.profileSecurityTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SettingsRow(
            key: const Key('profile-change-password'),
            icon: Icons.password_rounded,
            tint: tints.blue,
            title: l10n.profileChangePassword,
            onTap: () => unawaited(showChangePasswordSheet(context)),
          ),
          SettingsRow(
            key: const Key('profile-change-email'),
            icon: Icons.alternate_email_rounded,
            tint: tints.mint,
            title: l10n.profileChangeEmail,
            onTap: () => unawaited(showChangeEmailSheet(context)),
          ),
          SettingsRow(
            key: const Key('profile-sign-out-everywhere'),
            icon: Icons.devices_rounded,
            tint: tints.amber,
            title: l10n.profileSignOutEverywhere,
            trailing: const SizedBox.shrink(),
            onTap: () => unawaited(_signOutEverywhere(context, ref)),
          ),
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
    final tint = context.tints.red;
    return TikeoCard(
      key: const Key('profile-danger'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.profileDangerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SettingsRow(
            key: const Key('profile-delete-account'),
            icon: Icons.delete_forever_rounded,
            tint: tint,
            title: l10n.profileDeleteAccount,
            trailing: const SizedBox.shrink(),
            onTap: () => unawaited(_request(context, ref)),
          ),
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
    final tint = context.tints.red;
    final date = DateFormat.yMMMMd(appLocaleTag).format(due.toLocal());
    return Card(
      key: const Key('profile-deletion-pending'),
      color: tint.background,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profileDeletionPending(date),
              style: TextStyle(color: tint.text),
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
