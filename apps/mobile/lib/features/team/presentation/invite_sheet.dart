import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/success_burst.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/team/domain/team.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ouvre la création d'invitation (ORG-02).
Future<void> showInviteSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const InviteSheet(),
    );

/// Choix du rôle, de la validité et du nombre d'utilisations, puis affichage
/// du code à partager.
class InviteSheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<InviteSheet> {
  MemberRole _role = MemberRole.controller;
  int _days = 7;
  int _uses = 1;
  bool _busy = false;
  TeamFailure? _failure;
  CreatedInvitation? _created;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final created = await ref
          .read(teamProvider.notifier)
          .invite(_role, validDays: _days, maxUses: _uses);
      if (mounted) setState(() => _created = created);
    } on TeamFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    return Padding(
      padding: EdgeInsets.only(
        left: TicketSurSpacing.lg,
        right: TicketSurSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.lg,
      ),
      child: AnimatedSwitcher(
        duration: TicketSurMotion.reduced(context)
            ? Duration.zero
            : TicketSurMotion.medium,
        child: created == null ? _form(context) : _CodeView(created: created),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isOwner =
        ref.watch(activeOrganizationProvider)?.role == MemberRole.owner;
    return SingleChildScrollView(
      key: const ValueKey('invite-form'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.inviteTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: TicketSurSpacing.md),
          Text(l10n.inviteRoleLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: TicketSurSpacing.xs),
          SegmentedButton<MemberRole>(
            key: const Key('invite-role'),
            segments: [
              ButtonSegment(
                value: MemberRole.controller,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(l10n.roleController),
              ),
              if (isOwner)
                ButtonSegment(
                  value: MemberRole.manager,
                  icon: const Icon(Icons.manage_accounts_rounded),
                  label: Text(l10n.roleManager),
                ),
            ],
            selected: {_role},
            onSelectionChanged: (value) => setState(() => _role = value.first),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          Text(
            _role == MemberRole.manager
                ? l10n.inviteRoleManagerHelp
                : l10n.inviteRoleControllerHelp,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: TicketSurSpacing.md),
          Text(l10n.inviteValidity, style: theme.textTheme.titleSmall),
          Wrap(
            spacing: TicketSurSpacing.xs,
            children: [
              for (final days in const [1, 7, 30])
                ChoiceChip(
                  key: Key('invite-days-$days'),
                  label: Text(l10n.inviteDays(days)),
                  selected: _days == days,
                  onSelected: (_) => setState(() => _days = days),
                ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.sm),
          Text(l10n.inviteUses, style: theme.textTheme.titleSmall),
          Wrap(
            spacing: TicketSurSpacing.xs,
            children: [
              for (final uses in const [1, 5, 20])
                ChoiceChip(
                  key: Key('invite-uses-$uses'),
                  label: Text(l10n.inviteUsesCount(uses)),
                  selected: _uses == uses,
                  onSelected: (_) => setState(() => _uses = uses),
                ),
            ],
          ),
          if (_failure case final failure?) ...[
            const SizedBox(height: TicketSurSpacing.sm),
            Text(
              teamFailureMessage(l10n, failure),
              key: const Key('invite-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: TicketSurSpacing.lg),
          FilledButton.icon(
            key: const Key('invite-create'),
            onPressed: _busy ? null : () => unawaited(_create()),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.key_rounded),
            label: Text(l10n.inviteCreate),
          ),
        ],
      ),
    );
  }
}

class _CodeView extends ConsumerWidget {
  const new({required this.created});

  final CreatedInvitation created;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final organization = ref.watch(activeOrganizationProvider);
    final date = formatLocalDateTime(created.invitation.expiresAt);
    final message = l10n.inviteShareText(
      organization?.name ?? '',
      roleLabel(l10n, created.invitation.role).toLowerCase(),
      created.code,
      date,
    );
    return SingleChildScrollView(
      key: const ValueKey('invite-code'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: SuccessBurst(size: 56)),
          Text(
            l10n.inviteCodeTitle,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TicketSurSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(TicketSurRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: TicketSurSpacing.lg,
                horizontal: TicketSurSpacing.sm,
              ),
              child: FittedBox(
                child: SelectableText(
                  created.code,
                  key: const Key('invite-code-text'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.sm),
          Text(
            '${roleLabel(l10n, created.invitation.role)} · '
            '${l10n.inviteUsesCount(created.invitation.maxUses)} · '
            '${l10n.inviteCodeValid(date)}',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_off_rounded,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: TicketSurSpacing.xxs),
              Flexible(
                child: Text(
                  l10n.inviteCodeHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.lg),
          FilledButton.icon(
            key: const Key('invite-share'),
            onPressed: () => unawaited(ref.read(shareTextProvider)(message)),
            icon: const Icon(Icons.share_rounded),
            label: Text(l10n.inviteShare),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          OutlinedButton.icon(
            key: const Key('invite-copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: created.code));
              if (context.mounted) {
                Toaster.of(context).success(l10n.inviteCopied);
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(l10n.inviteCopy),
          ),
          TextButton(
            key: const Key('invite-done'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.inviteDone),
          ),
        ],
      ),
    );
  }
}
