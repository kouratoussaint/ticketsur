// Partie de `event_setup_sections.dart` (découpage du lot 4-9) :
// section des portes.
part of 'event_setup_sections.dart';

/// Portes de contrôle d'un événement.
class CheckpointsSection extends ConsumerWidget {
  const new({required this.event, required this.canManage, super.key});

  final TicketEvent event;
  final bool canManage;

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref, [
    Checkpoint? checkpoint,
  ]) async {
    final l10n = context.l10n;
    final controller = ref.read(checkpointsProvider(event.id).notifier);
    final toast = Toaster.of(context);
    final result = await showSetupSheet(
      context,
      title: checkpoint == null
          ? l10n.checkpointNewTitle
          : l10n.checkpointEditTitle,
      nameLabel: l10n.categoryNameLabel,
      nameHint: l10n.checkpointNameHint,
      initialName: checkpoint?.name ?? '',
      withCapacity: false,
      submitLabel: checkpoint == null ? l10n.setupAdd : l10n.setupSave,
      onSubmit: (values) => checkpoint == null
          ? controller.create(values.name)
          : controller.edit(
              checkpoint.id,
              values.name,
              active: checkpoint.active,
            ),
    );
    if (result != null) {
      toast.success(l10n.checkpointSaved);
    }
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    Checkpoint checkpoint, {
    required bool active,
  }) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    if (!active) {
      final colors = Theme.of(context).colorScheme;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.door_front_door_rounded),
          title: Text(l10n.checkpointDeactivateTitle),
          content: Text(l10n.checkpointDeactivateBody(checkpoint.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.setupCancel),
            ),
            FilledButton(
              key: const Key('checkpoint-deactivate-confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.checkpointDeactivate),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await ref
          .read(checkpointsProvider(event.id).notifier)
          .edit(checkpoint.id, checkpoint.name, active: active);
    } on SetupFailure catch (failure) {
      toast.error(setupFailureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final checkpoints = ref.watch(checkpointsProvider(event.id));
    final editable = canManage && isConfigurable(event);
    return TikeoCard(
      key: const Key('checkpoints-section'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: l10n.checkpointsTitle,
            icon: Icons.door_front_door_rounded,
            tint: context.tints.violet,
            addKey: const Key('checkpoint-add'),
            onAdd: editable ? () => unawaited(_openSheet(context, ref)) : null,
          ),
          _sectionBody(
            context,
            checkpoints,
            empty: l10n.checkpointsEmpty,
            emptyKey: 'checkpoints-empty',
            onRetry: () => ref.invalidate(checkpointsProvider(event.id)),
            builder: (items) => Column(
              children: [
                for (final checkpoint in items)
                  ListTile(
                    key: Key('checkpoint-${checkpoint.id}'),
                    leading: Icon(
                      checkpoint.active
                          ? Icons.door_front_door_rounded
                          : Icons.no_meeting_room_rounded,
                    ),
                    title: Text(checkpoint.name),
                    subtitle: Text(
                      checkpoint.active
                          ? l10n.checkpointActive
                          : l10n.checkpointInactive,
                    ),
                    onTap: editable
                        ? () => unawaited(_openSheet(context, ref, checkpoint))
                        : null,
                    trailing: editable
                        ? Switch(
                            key: Key('checkpoint-active-${checkpoint.id}'),
                            value: checkpoint.active,
                            onChanged: (value) => unawaited(
                              _toggle(context, ref, checkpoint, active: value),
                            ),
                          )
                        : null,
                  ),
                const SizedBox(height: TicketSurSpacing.xs),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feuille de saisie commune (nom + quota facultatif)
// ---------------------------------------------------------------------------
