import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/team/domain/team.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ouvre les détails d'une invitation (#5). [onRevoke] : révoquer (avec
/// confirmation), proposé tant que l'invitation est active.
Future<void> showInvitationDetailsSheet(
  BuildContext context, {
  required Invitation invitation,
  required Future<bool> Function() onRevoke,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) =>
      InvitationDetailsSheet(invitation: invitation, onRevoke: onRevoke),
);

String invitationStateLabel(AppLocalizations l10n, InvitationState state) =>
    switch (state) {
      InvitationState.active => l10n.invitationStateActive,
      InvitationState.expired => l10n.invitationStateExpired,
      InvitationState.revoked => l10n.invitationStateRevoked,
      InvitationState.exhausted => l10n.invitationStateExhausted,
    };

/// Détails d'une invitation : rôle, état, code masqué (œil pour l'afficher,
/// copier, partager), structure, auteur, dates, utilisations, personnes
/// qui l'ont utilisée. Le code n'est gardé que le temps de la feuille.
class InvitationDetailsSheet extends ConsumerStatefulWidget {
  const new({required this.invitation, required this.onRevoke, super.key});

  final Invitation invitation;

  /// Révoquer, avec confirmation ; vrai si c'est fait.
  final Future<bool> Function() onRevoke;

  @override
  ConsumerState<InvitationDetailsSheet> createState() =>
      _InvitationDetailsSheetState();
}

class _InvitationDetailsSheetState
    extends ConsumerState<InvitationDetailsSheet> {
  late final Future<InvitationDetails> _details = ref
      .read(teamRepositoryProvider)
      .invitationDetails(widget.invitation.id);

  /// Code en clair, seulement en mémoire, le temps de la feuille.
  String? _code;
  bool _visible = false;
  bool _busy = false;

  Future<String?> _ensureCode() async {
    if (_code case final code?) return code;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      final code = await ref
          .read(teamRepositoryProvider)
          .revealInvitationCode(widget.invitation.id);
      if (mounted) setState(() => _code = code);
      return code;
    } on TeamFailure catch (failure) {
      toast.error(teamFailureMessage(l10n, failure));
      return null;
    } on Object {
      toast.error(teamFailureMessage(l10n, TeamFailure.unknown));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle() async {
    if (_visible) {
      setState(() => _visible = false);
      return;
    }
    if (await _ensureCode() != null && mounted) {
      setState(() => _visible = true);
    }
  }

  Future<void> _copy() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final code = await _ensureCode();
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    toast.info(l10n.inviteCopied);
  }

  Future<void> _share(InvitationDetails details) async {
    final l10n = context.l10n;
    final share = ref.read(shareTextProvider);
    final code = await _ensureCode();
    if (code == null) return;
    await share(
      l10n.inviteShareText(
        details.organizationName,
        roleLabel(l10n, details.role).toLowerCase(),
        code,
        formatLocalDateTime(details.expiresAt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: FutureBuilder<InvitationDetails>(
        future: _details,
        builder: (context, snapshot) => SingleChildScrollView(
          key: const Key('invitation-details'),
          padding: const EdgeInsets.fromLTRB(
            TikeoSizes.screenMargin,
            0,
            TikeoSizes.screenMargin,
            TikeoSizes.screenMargin,
          ),
          child: switch (snapshot) {
            AsyncSnapshot(data: final InvitationDetails details?) => _content(
              context,
              details,
            ),
            AsyncSnapshot(:final error?) => Text(
              error is TeamFailure
                  ? teamFailureMessage(l10n, error)
                  : teamFailureMessage(l10n, TeamFailure.unknown),
              key: const Key('invitation-details-error'),
            ),
            _ => const Shimmer(
              child: SkeletonBox(height: 280, radius: TikeoRadii.card),
            ),
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, InvitationDetails details) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final active = details.state == InvitationState.active;
    final masked = 'TSI-••••-••••-${details.codeHint}';
    Widget row(String label, String value, {Key? key}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              key: key,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.invitationDetailsTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            TikeoPill(
              label: roleLabel(l10n, details.role),
              tint: roleTint(details.role, tints),
              icon: roleIcon(details.role),
            ),
            TikeoPill(
              key: Key('invitation-state-${details.state.name}'),
              label: invitationStateLabel(l10n, details.state),
              tint: active ? tints.green : tints.gray,
            ),
          ],
        ),
        const SizedBox(height: TikeoSizes.cardGap),
        TikeoCard(
          key: const Key('invitation-code-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.invitationCodeLabel, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _visible ? _code! : masked,
                      key: const Key('invitation-code'),
                      style: TikeoTextStyles.ticketNumber.copyWith(
                        fontSize: 20,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (active && details.codeAvailable && _busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (active && details.codeAvailable)
                    IconButton(
                      key: const Key('invitation-code-eye'),
                      tooltip: _visible
                          ? l10n.invitationCodeHide
                          : l10n.invitationCodeShow,
                      onPressed: () => unawaited(_toggle()),
                      icon: Icon(
                        _visible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                ],
              ),
              if (!details.codeAvailable)
                Text(
                  l10n.invitationCodeUnavailable,
                  key: const Key('invitation-code-unavailable'),
                  style: theme.textTheme.bodySmall,
                )
              else if (!active)
                Text(
                  l10n.invitationErrorInactive,
                  style: theme.textTheme.bodySmall,
                )
              else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('invitation-code-copy'),
                        onPressed: _busy ? null : () => unawaited(_copy()),
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(l10n.inviteCopy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('invitation-code-share'),
                        onPressed: _busy
                            ? null
                            : () => unawaited(_share(details)),
                        icon: const Icon(Icons.share_rounded),
                        label: Text(l10n.inviteShare),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: TikeoSizes.cardGap),
        TikeoCard(
          child: Column(
            children: [
              row(l10n.invitationStructure, details.organizationName),
              if (details.createdByName case final name?)
                row(l10n.invitationCreatedBy, name),
              row(
                l10n.invitationCreatedAt,
                formatLocalDateTime(details.createdAt),
              ),
              row(
                l10n.invitationValidUntil,
                formatLocalDateTime(details.expiresAt),
              ),
              row(
                l10n.invitationUses,
                '${details.uses} / ${details.maxUses}',
                key: const Key('invitation-uses'),
              ),
            ],
          ),
        ),
        if (details.usedBy.isNotEmpty) ...[
          const SizedBox(height: TikeoSizes.cardGap),
          Text(l10n.invitationUsedBy, style: theme.textTheme.titleSmall),
          for (final person in details.usedBy)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 18, color: tints.blue.icon),
                  const SizedBox(width: 8),
                  Expanded(child: Text(person.name)),
                  Text(
                    formatLocalDateTime(person.at),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: TikeoSizes.cardGap),
        if (active)
          TikeoDangerButton(
            key: const Key('invitation-revoke'),
            icon: Icons.block_rounded,
            label: l10n.invitationRevoke,
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await widget.onRevoke() && navigator.mounted) {
                navigator.pop();
              }
            },
          ),
        TextButton(
          key: const Key('invitation-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.photoClose),
        ),
      ],
    );
  }
}
