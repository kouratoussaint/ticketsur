import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Début proposé pour une copie : même jour de la semaine et même heure,
/// une semaine après l'original, puis de semaine en semaine jusqu'à une date
/// à venir.
DateTime suggestedCopyStart(TicketEvent source, DateTime now) {
  var start = source.startsAt.add(const Duration(days: 7));
  while (!start.isAfter(now)) {
    start = start.add(const Duration(days: 7));
  }
  return start;
}

/// Feuille « Dupliquer l'événement » : titre et début de la copie (la durée
/// de l'original est gardée). Ouvre la copie une fois créée.
Future<void> showDuplicateEventSheet(
  BuildContext context,
  TicketEvent source,
) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _DuplicateSheet(source: source, parent: context),
);

class _DuplicateSheet extends ConsumerStatefulWidget {
  const new({required this.source, required this.parent});

  final TicketEvent source;

  /// Contexte de la page, pour ouvrir la copie après la fermeture.
  final BuildContext parent;

  @override
  ConsumerState<_DuplicateSheet> createState() => _DuplicateSheetState();
}

class _DuplicateSheetState extends ConsumerState<_DuplicateSheet> {
  late final TextEditingController _title = TextEditingController(
    text: context.l10n.eventDuplicateName(widget.source.title),
  );

  /// Début, en heure locale du fuseau de l'événement.
  late DateTime _start = wallTimeIn(
    widget.source.timezone,
    suggestedCopyStart(widget.source, DateTime.now().toUtc()),
  );
  bool _saving = false;

  Duration get _length =>
      widget.source.endsAt.difference(widget.source.startsAt);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 3),
    );
    if (picked == null) return;
    setState(
      () => _start = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _start.hour,
        _start.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (picked == null) return;
    setState(
      () => _start = DateTime(
        _start.year,
        _start.month,
        _start.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final title = _title.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    final startsAt = instantFromWallTime(widget.source.timezone, _start);
    try {
      final id = await ref
          .read(eventsProvider.notifier)
          .duplicate(
            widget.source,
            title: title,
            startsAt: startsAt,
            endsAt: startsAt.add(_length),
          );
      toast.success(l10n.eventDuplicated);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.parent.mounted) {
        unawaited(widget.parent.push(AppRoutes.eventDetail(id)));
      }
    } on Object {
      toast.error(l10n.eventDuplicateError);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TicketSurSpacing.lg,
          0,
          TicketSurSpacing.lg,
          TicketSurSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.eventDuplicateTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(l10n.eventDuplicateBody),
            const SizedBox(height: TicketSurSpacing.md),
            TextField(
              key: const Key('duplicate-title'),
              controller: _title,
              enabled: !_saving,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.eventDuplicateNameLabel,
              ),
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(l10n.eventDuplicateStart, style: theme.textTheme.titleSmall),
            const SizedBox(height: TicketSurSpacing.xs),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    key: const Key('duplicate-day'),
                    onPressed: _saving ? null : () => unawaited(_pickDay()),
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(formatEventDay(_start)),
                  ),
                ),
                const SizedBox(width: TicketSurSpacing.sm),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    key: const Key('duplicate-time'),
                    onPressed: _saving ? null : () => unawaited(_pickTime()),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(formatEventTime(_start)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(
              l10n.eventDuplicateKeepLength,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: TicketSurSpacing.lg),
            FilledButton.icon(
              key: const Key('duplicate-submit'),
              onPressed: _saving ? null : () => unawaited(_submit()),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.content_copy_rounded),
              label: Text(l10n.eventDuplicateSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
