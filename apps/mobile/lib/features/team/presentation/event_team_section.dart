import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/swipe.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/events/presentation/event_setup_sections.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/team/domain/team.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Affectations des membres à l'événement (S17), organisateurs uniquement.
class EventTeamSection extends ConsumerWidget {
  const new({required this.event, super.key});

  final TicketEvent event;

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    Assignment assignment,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.eventTeamRemoveTitle),
        content: Text(l10n.eventTeamRemoveBody(assignment.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.setupCancel),
          ),
          FilledButton(
            key: const Key('assignment-remove-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.eventTeamRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(eventTeamProvider(event.id).notifier)
          .unassign(assignment.id);
    } on TeamFailure catch (failure) {
      toast.error(teamFailureMessage(l10n, failure));
    }
  }

  /// Balayage : retrait immédiat, « Annuler » réaffecte à la même porte.
  Future<void> _swipeRemove(
    BuildContext context,
    WidgetRef ref,
    Assignment assignment,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final team = ref.read(eventTeamProvider(event.id).notifier);
    try {
      await team.unassignNow(assignment);
    } on TeamFailure catch (failure) {
      toast.error(teamFailureMessage(l10n, failure));
      return;
    }
    toast.info(
      l10n.eventTeamRemoved(assignment.displayName),
      action: SnackBarAction(
        key: const Key('assignment-undo'),
        label: l10n.favoriteUndo,
        onPressed: () => unawaited(
          team
              .assign(assignment.userId, assignment.checkpointId)
              .then<void>(
                (_) {},
                onError: (Object error) => toast.error(
                  error is TeamFailure
                      ? teamFailureMessage(l10n, error)
                      : l10n.setupLoadError,
                ),
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final assignments = ref.watch(eventTeamProvider(event.id));
    final editable = isConfigurable(event);
    final body = switch (assignments) {
      AsyncData(:final value) when value.isEmpty => Padding(
        key: const Key('event-team-empty'),
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Text(
          l10n.eventTeamEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      AsyncData(:final value) => Column(
        children: [
          for (final assignment in value)
            SwipeToAct(
              swipeKey: ValueKey('assignment-swipe-${assignment.id}'),
              icon: Icons.person_remove_rounded,
              label: l10n.eventTeamRemove,
              onSwiped: () => unawaited(_swipeRemove(context, ref, assignment)),
              child: ListTile(
                key: Key('assignment-${assignment.id}'),
                leading: CircleAvatar(
                  child: Text(initialOf(assignment.displayName)),
                ),
                title: Text(assignment.displayName),
                subtitle: Text(
                  [
                    assignment.checkpointName ?? l10n.eventTeamAllCheckpoints,
                    if (!assignment.memberActive) l10n.eventTeamMemberInactive,
                  ].join(' · '),
                ),
                // Retirer un accès reste possible même après la clôture.
                trailing: IconButton(
                  key: Key('assignment-remove-${assignment.id}'),
                  tooltip: l10n.eventTeamRemove,
                  icon: const Icon(Icons.person_remove_rounded),
                  onPressed: () => unawaited(_remove(context, ref, assignment)),
                ),
              ),
            ),
        ],
      ),
      AsyncError() => ListTile(
        title: Text(l10n.setupLoadError),
        trailing: TextButton(
          onPressed: () => ref.invalidate(eventTeamProvider(event.id)),
          child: Text(l10n.orgRetry),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(TicketSurSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
    return TikeoCard(
      key: const Key('event-team-section'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.md,
              TicketSurSpacing.sm,
              TicketSurSpacing.xs,
              0,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: context.tints.amber.background,
                  child: Icon(
                    Icons.groups_rounded,
                    size: 20,
                    color: context.tints.amber.icon,
                  ),
                ),
                const SizedBox(width: TicketSurSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.eventTeamTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (editable)
                  TextButton.icon(
                    key: const Key('assignment-add'),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      useSafeArea: true,
                      isScrollControlled: true,
                      builder: (_) => _AssignSheet(event: event),
                    ),
                    icon: const Icon(Icons.person_add_alt_rounded),
                    label: Text(l10n.setupAdd),
                  ),
              ],
            ),
          ),
          MotionSize(alignment: Alignment.topCenter, child: body),
          const SizedBox(height: TicketSurSpacing.xs),
        ],
      ),
    );
  }
}

class _AssignSheet extends ConsumerStatefulWidget {
  const new({required this.event});

  final TicketEvent event;

  @override
  ConsumerState<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends ConsumerState<_AssignSheet> {
  /// Membres cochés (sélection multiple), dans l'ordre d'appui.
  final Set<String> _userIds = {};
  String? _checkpointId; // null : toutes les portes
  bool _busy = false;
  TeamFailure? _failure;
  String? _partial;

  Future<void> _assign() async {
    if (_userIds.isEmpty || _busy) return;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() {
      _busy = true;
      _failure = null;
      _partial = null;
    });
    try {
      if (_userIds.length == 1) {
        await ref
            .read(eventTeamProvider(widget.event.id).notifier)
            .assign(_userIds.single, _checkpointId);
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final outcome = await ref
          .read(eventTeamProvider(widget.event.id).notifier)
          .assignMany(_userIds, _checkpointId);
      if (outcome.failed == 0) {
        toast.success(l10n.eventTeamAssignedMany(outcome.done));
        if (mounted) Navigator.of(context).pop();
      } else if (mounted) {
        setState(
          () => _partial = l10n.bulkPartial(
            outcome.done,
            outcome.done + outcome.failed,
          ),
        );
      }
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
    final members = [
      for (final m in ref.watch(teamProvider).value?.members ?? <TeamMember>[])
        if (m.active) m,
    ];
    final allCheckpoints =
        ref.watch(checkpointsProvider(widget.event.id)).value ??
        const <Checkpoint>[];
    final checkpoints = [
      for (final c in allCheckpoints)
        if (c.active) c,
    ];
    // Portes où chaque membre est déjà affecté.
    final assigned = <String, List<String>>{};
    for (final a
        in ref.watch(eventTeamProvider(widget.event.id)).value ??
            const <Assignment>[]) {
      (assigned[a.userId] ??= []).add(
        a.checkpointName ?? l10n.eventTeamAllCheckpoints,
      );
    }
    final allChosen =
        members.isNotEmpty && members.every((m) => _userIds.contains(m.userId));
    return Padding(
      padding: EdgeInsets.only(
        left: TicketSurSpacing.lg,
        right: TicketSurSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.eventTeamAssignTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: TicketSurSpacing.xs),
            if (members.isEmpty)
              Text(l10n.eventTeamNoMembers, key: const Key('assign-no-members'))
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.eventTeamChooseMembers,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('assign-all-members'),
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            if (allChosen) {
                              _userIds.clear();
                            } else {
                              _userIds.addAll([
                                for (final m in members) m.userId,
                              ]);
                            }
                          }),
                    child: Text(
                      allChosen ? l10n.eventTeamUncheckAll : l10n.selectionAll,
                    ),
                  ),
                ],
              ),
              for (final m in members)
                CheckboxListTile(
                  key: Key('assign-member-${m.userId}'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _userIds.contains(m.userId),
                  onChanged: _busy
                      ? null
                      : (_) => setState(() {
                          if (!_userIds.remove(m.userId)) {
                            _userIds.add(m.userId);
                          }
                        }),
                  title: Text(m.displayName, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      roleLabel(l10n, m.role),
                      if (assigned[m.userId] case final doors?)
                        l10n.eventTeamAlreadyAssigned(doors.join(', ')),
                    ].join(' · '),
                  ),
                ),
              const SizedBox(height: TicketSurSpacing.sm),
              DropdownButtonFormField<String?>(
                key: const Key('assign-checkpoint'),
                initialValue: _checkpointId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.eventTeamCheckpointLabel,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    child: Text(l10n.eventTeamAllCheckpoints),
                  ),
                  for (final c in checkpoints)
                    DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (value) => setState(() => _checkpointId = value),
              ),
              if (_failure case final failure?) ...[
                const SizedBox(height: TicketSurSpacing.sm),
                Text(
                  teamFailureMessage(l10n, failure),
                  key: const Key('assign-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              if (_partial case final message?) ...[
                const SizedBox(height: TicketSurSpacing.sm),
                Text(
                  message,
                  key: const Key('assign-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: TicketSurSpacing.lg),
              FilledButton(
                key: const Key('assign-submit'),
                onPressed: _userIds.isEmpty || _busy
                    ? null
                    : () => unawaited(_assign()),
                child: Text(
                  _userIds.length > 1
                      ? l10n.eventTeamAssignMany(_userIds.length)
                      : l10n.eventTeamAssign,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
