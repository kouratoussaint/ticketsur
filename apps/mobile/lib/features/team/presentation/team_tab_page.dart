import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/team/domain/team.dart';
import 'package:ticketsur/features/team/presentation/invite_sheet.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Onglet Équipe (S16) : membres et invitations de l'organisation active.
class TeamTabPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final organization = ref.watch(activeOrganizationProvider);
    final isController = organization?.role == MemberRole.controller;
    final team = ref.watch(teamProvider);
    final members = team.value?.members ?? const <TeamMember>[];
    int count(MemberRole role) =>
        members.where((m) => m.active && m.role == role).length;
    final header = Column(
      // En-tête et chiffres dans une même colonne : la partie posée sur
      // l'en-tête reste touchable.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TikeoHeroHeader(
          title: l10n.teamHeroTitle,
          subtitle: organization?.name,
          illustration: TikeoIllustration.team,
        ),
        TikeoOverlapCard(
          child: StatStrip(
            key: const Key('team-stats'),
            items: [
              (
                value: '${members.where((m) => m.active).length}',
                label: l10n.teamStatMembers,
                color: null,
              ),
              (
                value: '${count(MemberRole.manager)}',
                label: l10n.teamStatManagers,
                color: null,
              ),
              (
                value: '${count(MemberRole.controller)}',
                label: l10n.teamStatControllers,
                color: null,
              ),
            ],
          ),
        ),
      ],
    );
    return Scaffold(
      floatingActionButton: isController || organization == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('team-invite'),
              heroTag: 'team-invite',
              onPressed: () => unawaited(showInviteSheet(context)),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(l10n.teamInvite),
            ),
      body: isController
          ? ListView(
              children: [
                TikeoHeroHeader(
                  title: l10n.teamHeroTitle,
                  subtitle: organization!.name,
                  illustration: TikeoIllustration.team,
                  overlap: 0,
                ),
                _ControllerInfo(organization: organization),
              ],
            )
          : switch (team) {
              AsyncData(:final value) => _TeamList(
                key: const ValueKey('team-data'),
                header: header,
                state: value,
                ownerView: organization?.role == MemberRole.owner,
                onRefresh: () => ref.read(teamProvider.notifier).reload(),
              ),
              AsyncError() => ListView(
                key: const ValueKey('team-error'),
                children: [
                  header,
                  const SizedBox(height: TicketSurSpacing.lg),
                  Center(
                    child: Column(
                      children: [
                        Text(l10n.setupLoadError, key: const Key('team-error')),
                        TextButton(
                          onPressed: () => ref.invalidate(teamProvider),
                          child: Text(l10n.orgRetry),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _ => ListView(
                key: const ValueKey('team-loading'),
                children: [
                  header,
                  for (var i = 0; i < 4; i++)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Shimmer(
                        child: SkeletonBox(height: 76, radius: 16),
                      ),
                    ),
                ],
              ),
            },
    );
  }
}

class _ControllerInfo extends StatelessWidget {
  const new({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('team-controller'),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.xl),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TikeoIllustrationView(TikeoIllustration.scanner),
              const SizedBox(height: TicketSurSpacing.lg),
              Text(
                l10n.teamControllerTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Text(
                l10n.teamControllerBody(organization.name),
                key: const Key('team-controller-info'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamList extends ConsumerWidget {
  const new({
    required this.header,
    required this.state,
    required this.ownerView,
    required this.onRefresh,
    super.key,
  });

  /// En-tête et chiffres, en haut de la liste.
  final Widget header;
  final TeamState state;
  final bool ownerView;
  final Future<void> Function() onRefresh;

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    Invitation invitation,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.teamRevokeTitle),
        content: Text(l10n.teamRevokeBody(invitation.codeHint)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.setupCancel),
          ),
          FilledButton(
            key: const Key('team-revoke-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.teamRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(teamProvider.notifier).revoke(invitation.id);
    } on TeamFailure catch (failure) {
      toast.error(teamFailureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider).value?.id;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Liste courte : tout est construit d'emblée.
        scrollCacheExtent: const ScrollCacheExtent.pixels(1500),
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          header,
          const SizedBox(height: TikeoSizes.cardGap),
          if (state.invitations.isNotEmpty) ...[
            _padded(
              SectionHeader(
                title: l10n.teamInvitationsTitle,
                icon: Icons.key_rounded,
              ),
            ),
            const SizedBox(height: 8),
            for (final (index, invitation) in state.invitations.indexed)
              _padded(
                FadeSlideIn(
                  key: ValueKey('inv-${invitation.id}'),
                  delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TikeoListRow(
                      key: Key('invitation-${invitation.id}'),
                      leading: _RoundIcon(
                        icon: Icons.key_rounded,
                        tint: roleTint(invitation.role, context.tints),
                      ),
                      title: l10n.teamInvitationLine(
                        roleLabel(l10n, invitation.role),
                        invitation.codeHint,
                      ),
                      lines: [
                        l10n.teamInvitationDetail(
                          formatLocalDateTime(invitation.expiresAt),
                          invitation.uses,
                          invitation.maxUses,
                        ),
                      ],
                      trailing: IconButton(
                        key: Key('invitation-revoke-${invitation.id}'),
                        tooltip: l10n.teamRevoke,
                        icon: const Icon(Icons.block_rounded),
                        onPressed: () =>
                            unawaited(_revoke(context, ref, invitation)),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: TikeoSizes.cardGap),
          ],
          _padded(
            SectionHeader(
              title: l10n.teamMembersCount(state.members.length),
              icon: Icons.groups_rounded,
            ),
          ),
          const SizedBox(height: 8),
          for (final (index, member) in state.members.indexed)
            _padded(
              FadeSlideIn(
                key: ValueKey('fade-member-${member.userId}'),
                delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MemberCard(
                    member: member,
                    isMe: member.userId == me,
                    editable:
                        member.userId != me &&
                        member.role != MemberRole.owner &&
                        (ownerView || member.role == MemberRole.controller),
                    ownerView: ownerView,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _padded(Widget child) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin),
  child: child,
);

/// Rond pastel avec une icône pleine.
class _RoundIcon extends StatelessWidget {
  const new({required this.icon, required this.tint});

  final IconData icon;
  final TikeoTint tint;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(color: tint.background, shape: BoxShape.circle),
    child: Icon(icon, size: 22, color: tint.icon),
  );
}

class _MemberCard extends StatelessWidget {
  const new({
    required this.member,
    required this.isMe,
    required this.editable,
    required this.ownerView,
  });

  final TeamMember member;
  final bool isMe;
  final bool editable;
  final bool ownerView;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = !member.active;
    final tint = roleTint(member.role, context.tints);
    final gray = context.tints.gray;
    return TikeoListRow(
      key: Key('member-${member.userId}'),
      onTap: editable
          ? () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              useSafeArea: true,
              builder: (_) =>
                  _MemberSheet(member: member, ownerView: ownerView),
            )
          : null,
      leading: CircleAvatar(
        radius: TikeoSizes.avatarList / 2,
        backgroundColor: muted ? gray.background : tint.background,
        foregroundColor: muted ? gray.text : tint.text,
        child: Text(
          initialOf(member.displayName),
          style: TikeoTextStyles.avatarInitials,
        ),
      ),
      title: isMe
          ? '${member.displayName} (${l10n.teamYou})'
          : member.displayName,
      lines: [?member.email],
      badge: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          TikeoPill(
            label: roleLabel(l10n, member.role),
            tint: tint,
            icon: roleIcon(member.role),
          ),
          if (muted)
            TikeoPill(
              label: l10n.teamInactive,
              tint: gray,
              icon: Icons.pause_circle_rounded,
            ),
        ],
      ),
      chevron: editable,
    );
  }
}

class _MemberSheet extends ConsumerStatefulWidget {
  const new({required this.member, required this.ownerView});

  final TeamMember member;
  final bool ownerView;

  @override
  ConsumerState<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends ConsumerState<_MemberSheet> {
  late MemberRole _role = widget.member.role;
  late bool _active = widget.member.active;
  bool _busy = false;
  TeamFailure? _failure;

  Future<void> _save() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref
          .read(teamProvider.notifier)
          .updateMember(widget.member.userId, role: _role, active: _active);
      if (!mounted) return;
      Navigator.of(context).pop();
      toast.success(l10n.memberSaved);
    } on TeamFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.lg,
        0,
        TicketSurSpacing.lg,
        TicketSurSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.member.displayName, style: theme.textTheme.titleLarge),
          if (widget.member.email case final email?)
            Text(email, style: theme.textTheme.bodySmall),
          const SizedBox(height: TicketSurSpacing.md),
          if (widget.ownerView) ...[
            Text(l10n.memberRoleLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: TicketSurSpacing.xs),
            SegmentedButton<MemberRole>(
              key: const Key('member-role'),
              segments: [
                ButtonSegment(
                  value: MemberRole.controller,
                  label: Text(l10n.roleController),
                ),
                ButtonSegment(
                  value: MemberRole.manager,
                  label: Text(l10n.roleManager),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (value) =>
                  setState(() => _role = value.first),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
          ],
          SwitchListTile(
            key: const Key('member-active'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.memberActiveLabel),
            subtitle: Text(l10n.memberActiveHelp),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          if (_failure case final failure?)
            Text(
              teamFailureMessage(l10n, failure),
              key: const Key('member-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoPrimaryButton(
            key: const Key('member-save'),
            busy: _busy,
            onPressed: () => unawaited(_save()),
            label: l10n.setupSave,
          ),
        ],
      ),
    );
  }
}
