import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTeam)),
      floatingActionButton: isController || organization == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('team-invite'),
              heroTag: 'team-invite',
              onPressed: () => unawaited(showInviteSheet(context)),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(l10n.teamInvite),
            ),
      body: AnimatedSwitcher(
        duration: TicketSurMotion.reduced(context)
            ? Duration.zero
            : TicketSurMotion.medium,
        child: isController
            ? _ControllerInfo(organization: organization!)
            : switch (team) {
                AsyncData(:final value) => _TeamList(
                  key: const ValueKey('team-data'),
                  state: value,
                  ownerView: organization?.role == MemberRole.owner,
                  onRefresh: () => ref.read(teamProvider.notifier).reload(),
                ),
                AsyncError() => Center(
                  key: const ValueKey('team-error'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.setupLoadError, key: const Key('team-error')),
                      TextButton(
                        onPressed: () => ref.invalidate(teamProvider),
                        child: Text(l10n.orgRetry),
                      ),
                    ],
                  ),
                ),
                _ => const SkeletonList(key: ValueKey('team-loading')),
              },
      ),
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
    return Center(
      key: const ValueKey('team-controller'),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.xl),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
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
    required this.state,
    required this.ownerView,
    required this.onRefresh,
    super.key,
  });

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
    final theme = Theme.of(context);
    final me = ref.watch(currentUserProvider).value?.id;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TicketSurSpacing.md,
          TicketSurSpacing.xs,
          TicketSurSpacing.md,
          96,
        ),
        children: [
          if (state.invitations.isNotEmpty) ...[
            Text(l10n.teamInvitationsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: TicketSurSpacing.xs),
            for (final (index, invitation) in state.invitations.indexed)
              FadeSlideIn(
                key: ValueKey('inv-${invitation.id}'),
                delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
                child: Card(
                  child: ListTile(
                    key: Key('invitation-${invitation.id}'),
                    leading: const Icon(Icons.key_rounded),
                    title: Text(
                      l10n.teamInvitationLine(
                        roleLabel(l10n, invitation.role),
                        invitation.codeHint,
                      ),
                    ),
                    subtitle: Text(
                      l10n.teamInvitationDetail(
                        formatLocalDateTime(invitation.expiresAt),
                        invitation.uses,
                        invitation.maxUses,
                      ),
                    ),
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
            const SizedBox(height: TicketSurSpacing.md),
          ],
          Text(l10n.teamMembersTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: TicketSurSpacing.xs),
          for (final (index, member) in state.members.indexed)
            FadeSlideIn(
              key: ValueKey('fade-member-${member.userId}'),
              delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
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
        ],
      ),
    );
  }
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
    final theme = Theme.of(context);
    final muted = !member.active;
    return PressableScale(
      child: Card(
        key: Key('member-${member.userId}'),
        child: ListTile(
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
            backgroundColor: muted
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.primaryContainer,
            foregroundColor: muted
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onPrimaryContainer,
            child: Text(initialOf(member.displayName)),
          ),
          title: Text(
            isMe
                ? '${member.displayName} (${l10n.teamYou})'
                : member.displayName,
          ),
          subtitle: Text(
            [
              roleLabel(l10n, member.role),
              if (muted) l10n.teamInactive,
              ?member.email,
            ].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: editable ? const Icon(Icons.chevron_right_rounded) : null,
        ),
      ),
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
          FilledButton(
            key: const Key('member-save'),
            onPressed: _busy ? null : () => unawaited(_save()),
            child: Text(l10n.setupSave),
          ),
        ],
      ),
    );
  }
}
