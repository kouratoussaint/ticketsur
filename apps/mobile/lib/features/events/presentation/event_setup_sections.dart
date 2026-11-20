import 'dart:async';

import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/animated_count.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Message d'un échec de configuration.
String setupFailureMessage(AppLocalizations l10n, SetupFailure failure) =>
    switch (failure) {
      SetupFailure.notFound => l10n.setupErrorNotFound,
      SetupFailure.nameInvalid => l10n.setupErrorName,
      SetupFailure.nameTaken => l10n.setupErrorNameTaken,
      SetupFailure.capacityInvalid => l10n.setupErrorCapacity,
      SetupFailure.capacityBelowIssued => l10n.setupErrorCapacityBelowIssued,
      SetupFailure.hasTickets => l10n.setupErrorHasTickets,
      SetupFailure.locked => l10n.setupErrorLocked,
      SetupFailure.network => l10n.eventErrorNetwork,
      SetupFailure.unknown => l10n.eventErrorUnknown,
    };

/// Vrai si la structure de l'événement (catégories, portes) est modifiable.
bool isConfigurable(TicketEvent event) =>
    event.status != EventStatus.closed &&
    event.status != EventStatus.archived &&
    event.status != EventStatus.cancelled;

/// En-tête de section : titre et bouton « Ajouter ».
class _SectionHeader extends StatelessWidget {
  const new({required this.title, this.onAdd, this.addKey});

  final String title;
  final VoidCallback? onAdd;
  final Key? addKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        TicketSurSpacing.sm,
        TicketSurSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (onAdd != null)
            TextButton.icon(
              key: addKey,
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.setupAdd),
            ),
        ],
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const new({required this.text, this.onRetry, super.key});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(context.l10n.orgRetry)),
        ],
      ),
    );
  }
}

Widget _sectionBody<T>(
  BuildContext context,
  AsyncValue<List<T>> value, {
  required String empty,
  required String emptyKey,
  required VoidCallback onRetry,
  required Widget Function(List<T> items) builder,
}) {
  final child = switch (value) {
    AsyncData(:final value) when value.isEmpty => _SectionMessage(
      key: Key(emptyKey),
      text: empty,
    ),
    AsyncData(:final value) => builder(value),
    AsyncError() => _SectionMessage(
      key: const ValueKey('error'),
      text: context.l10n.setupLoadError,
      onRetry: onRetry,
    ),
    _ => const Padding(
      key: ValueKey('loading'),
      padding: EdgeInsets.all(TicketSurSpacing.md),
      child: Center(child: CircularProgressIndicator()),
    ),
  };
  return MotionSize(alignment: Alignment.topCenter, child: child);
}

// ---------------------------------------------------------------------------
// Catégories (S10, EVT-03)
// ---------------------------------------------------------------------------

/// Catégories de tickets d'un événement, avec quotas et compteurs.
class CategoriesSection extends ConsumerWidget {
  const new({required this.event, super.key});

  final TicketEvent event;

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref, [
    TicketCategory? category,
  ]) async {
    final l10n = context.l10n;
    final controller = ref.read(categoriesProvider(event.id).notifier);
    final toast = Toaster.of(context);
    final result = await showSetupSheet(
      context,
      title: category == null ? l10n.categoryNewTitle : l10n.categoryEditTitle,
      nameLabel: l10n.categoryNameLabel,
      nameHint: l10n.categoryNameHint,
      initialName: category?.name ?? '',
      withCapacity: true,
      initialCapacity: category?.capacity,
      initialInvitation: category?.isInvitation ?? false,
      withPrice: true,
      initialPrice: category?.indicativePrice,
      submitLabel: category == null ? l10n.setupAdd : l10n.setupSave,
      onSubmit: (values) => category == null
          ? controller.create(
              values.name,
              values.capacity,
              isInvitation: values.invitation,
              price: values.price,
            )
          : controller.edit(
              category.id,
              values.name,
              values.capacity,
              isInvitation: values.invitation,
              price: values.price,
              previousPrice: category.indicativePrice,
            ),
      onDelete: category == null ? null : () => controller.delete(category.id),
      deleteTitle: l10n.categoryDeleteTitle,
      deleteBody: category == null
          ? null
          : l10n.categoryDeleteBody(category.name),
    );
    if (result == null) return;
    toast.success(
      result == SetupSheetResult.deleted
          ? l10n.categoryDeleted
          : l10n.categorySaved,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider(event.id));
    final editable = isConfigurable(event);
    return Card(
      key: const Key('categories-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: l10n.categoriesTitle,
            addKey: const Key('category-add'),
            onAdd: editable ? () => unawaited(_openSheet(context, ref)) : null,
          ),
          _sectionBody(
            context,
            categories,
            empty: l10n.categoriesEmpty,
            emptyKey: 'categories-empty',
            onRetry: () => ref.invalidate(categoriesProvider(event.id)),
            builder: (items) {
              final issued = items.fold(0, (sum, c) => sum + c.issued);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final category in items)
                    _CategoryTile(
                      key: Key('category-${category.id}'),
                      category: category,
                      onTap: editable
                          ? () => unawaited(_openSheet(context, ref, category))
                          : null,
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TicketSurSpacing.xs,
                      ),
                      child: TextButton.icon(
                        key: const Key('categories-templates'),
                        onPressed: () => unawaited(
                          context.push(AppRoutes.ticketTemplates(event.id)),
                        ),
                        icon: const Icon(Icons.style_rounded),
                        label: Text(l10n.templatesEntry),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TicketSurSpacing.md,
                      0,
                      TicketSurSpacing.md,
                      TicketSurSpacing.md,
                    ),
                    child: AnimatedCount(
                      value: issued,
                      builder: (context, shown) => Text(
                        event.capacity == null
                            ? l10n.categoriesTotalUnlimited(shown)
                            : l10n.categoriesTotal(shown, event.capacity!),
                        key: const Key('categories-total'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const new({required this.category, this.onTap, super.key});

  final TicketCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fill = category.fill;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TicketSurSpacing.md,
          vertical: TicketSurSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  category.isInvitation
                      ? Icons.mail_outline_rounded
                      : Icons.sell_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: TicketSurSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: theme.textTheme.titleSmall),
                      if (category.isInvitation)
                        Text(
                          l10n.categoryInvitationBadge,
                          key: Key('category-invitation-${category.id}'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.palette.accentText,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: TicketSurSpacing.xs),
                Text(
                  category.capacity == null
                      ? l10n.categoryNoQuota
                      : l10n.categoryQuota(category.capacity!),
                  style: theme.textTheme.labelMedium,
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            if (fill != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fill),
                duration: TicketSurMotion.reduced(context)
                    ? Duration.zero
                    : TicketSurMotion.page,
                curve: TicketSurMotion.standard,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: value, minHeight: 6),
                ),
              ),
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(
              l10n.categoryCounts(category.issued, category.redeemed),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Portes (S21, EVT-04)
// ---------------------------------------------------------------------------

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
    return Card(
      key: const Key('checkpoints-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: l10n.checkpointsTitle,
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

/// Issue d'une feuille de saisie.
enum SetupSheetResult {
  /// Élément créé ou modifié.
  saved,

  /// Élément supprimé.
  deleted,
}

/// Valeurs saisies dans la feuille.
typedef SetupValues = ({
  String name,
  int? capacity,
  bool invitation,
  int? price,
});

/// Ouvre la feuille de saisie. [onSubmit] et [onDelete] lèvent une
/// [SetupFailure] en cas de refus ; la feuille reste alors ouverte et
/// affiche le message.
Future<SetupSheetResult?> showSetupSheet(
  BuildContext context, {
  required String title,
  required String nameLabel,
  required String nameHint,
  required String initialName,
  required bool withCapacity,
  required String submitLabel,
  required Future<void> Function(SetupValues values) onSubmit,
  int? initialCapacity,
  bool? initialInvitation,
  bool withPrice = false,
  int? initialPrice,
  Future<void> Function()? onDelete,
  String? deleteTitle,
  String? deleteBody,
}) => showModalBottomSheet<SetupSheetResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _SetupSheet(
    title: title,
    nameLabel: nameLabel,
    nameHint: nameHint,
    initialName: initialName,
    withCapacity: withCapacity,
    initialCapacity: initialCapacity,
    initialInvitation: initialInvitation,
    withPrice: withPrice,
    initialPrice: initialPrice,
    submitLabel: submitLabel,
    onSubmit: onSubmit,
    onDelete: onDelete,
    deleteTitle: deleteTitle,
    deleteBody: deleteBody,
  ),
);

class _SetupSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.nameLabel,
    required this.nameHint,
    required this.initialName,
    required this.withCapacity,
    required this.submitLabel,
    required this.onSubmit,
    this.initialCapacity,
    this.initialInvitation,
    this.withPrice = false,
    this.initialPrice,
    this.onDelete,
    this.deleteTitle,
    this.deleteBody,
  });

  final String title;
  final String nameLabel;
  final String nameHint;
  final String initialName;
  final bool withCapacity;
  final int? initialCapacity;

  /// `null` : pas de choix « invitation » (portes).
  final bool? initialInvitation;

  /// Champ « prix indicatif » (catégories).
  final bool withPrice;
  final int? initialPrice;
  final String submitLabel;
  final Future<void> Function(SetupValues values) onSubmit;
  final Future<void> Function()? onDelete;
  final String? deleteTitle;
  final String? deleteBody;

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _capacity = TextEditingController(
    text: widget.initialCapacity?.toString() ?? '',
  );
  late final _price = TextEditingController(
    text: widget.initialPrice?.toString() ?? '',
  );
  late bool _invitation = widget.initialInvitation ?? false;
  bool _busy = false;
  SetupFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() action,
    SetupSheetResult result,
  ) async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(result);
    } on SetupFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    final text = _capacity.text.trim();
    final price = _price.text.trim();
    await _run(
      () => widget.onSubmit((
        name: _name.text,
        capacity: text.isEmpty ? null : int.parse(text),
        invitation: _invitation,
        price: !widget.withPrice || _invitation || price.isEmpty
            ? null
            : int.parse(price),
      )),
      SetupSheetResult.saved,
    );
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.deleteTitle ?? ''),
        content: Text(widget.deleteBody ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.setupCancel),
          ),
          FilledButton(
            key: const Key('setup-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.categoryDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(widget.onDelete!, SetupSheetResult.deleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: TicketSurSpacing.lg,
        right: TicketSurSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: TicketSurSpacing.md),
            AnimatedSize(
              duration: TicketSurMotion.medium,
              child: _failure == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(
                        bottom: TicketSurSpacing.sm,
                      ),
                      child: Text(
                        setupFailureMessage(l10n, _failure!),
                        key: const Key('setup-error'),
                        style: TextStyle(color: colors.error),
                      ),
                    ),
            ),
            TextFormField(
              key: const Key('setup-name'),
              controller: _name,
              autofocus: widget.initialName.isEmpty,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: widget.withCapacity
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: widget.withCapacity
                  ? null
                  : (_) => unawaited(_submit()),
              decoration: InputDecoration(
                labelText: widget.nameLabel,
                hintText: widget.nameHint,
              ),
              validator: (value) {
                final length = (value ?? '').trim().length;
                return length < 1 || length > 60 ? l10n.setupErrorName : null;
              },
            ),
            if (widget.withCapacity) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              TextFormField(
                key: const Key('setup-capacity'),
                controller: _capacity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.categoryQuotaLabel,
                  helperText: l10n.categoryQuotaHelp,
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  final number = int.tryParse(text);
                  return number == null || number < 1 || number > 1000000
                      ? l10n.setupErrorCapacity
                      : null;
                },
              ),
            ],
            if (widget.initialInvitation != null)
              SwitchListTile(
                key: const Key('setup-invitation'),
                contentPadding: EdgeInsets.zero,
                value: _invitation,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _invitation = value),
                title: Text(l10n.categoryInvitationLabel),
                subtitle: Text(l10n.categoryInvitationHelp),
              ),
            if (widget.withPrice && !_invitation) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              TextFormField(
                key: const Key('setup-price'),
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.categoryPriceLabel,
                  helperText: l10n.categoryPriceHelp,
                  suffixText: 'FCFA',
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  final number = int.tryParse(text);
                  return number == null || number > 10000000
                      ? l10n.categoryPriceError
                      : null;
                },
              ),
            ],
            const SizedBox(height: TicketSurSpacing.lg),
            FilledButton(
              key: const Key('setup-submit'),
              onPressed: _busy ? null : () => unawaited(_submit()),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(widget.submitLabel),
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              TextButton.icon(
                key: const Key('setup-delete'),
                onPressed: _busy ? null : () => unawaited(_delete()),
                style: TextButton.styleFrom(foregroundColor: colors.error),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.categoryDelete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
