import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Saisie d'un titulaire : nom, téléphone, e-mail.
class HolderFieldsController {
  new([TicketHolder initial = TicketHolder.none])
    : name = TextEditingController(text: initial.name),
      phone = TextEditingController(text: initial.phone),
      email = TextEditingController(text: initial.email);

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;

  /// Problème de saisie affiché sous le champ concerné.
  HolderProblem? problem;

  /// Titulaire normalisé, ou `null` (et [problem] renseigné) si invalide.
  TicketHolder? read() {
    final result = validateHolder(
      name: name.text,
      phone: phone.text,
      email: email.text,
    );
    problem = result.problem;
    return result.holder;
  }

  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
  }
}

/// Champs du titulaire.
class HolderFields extends StatelessWidget {
  const new({required this.controller, this.onChanged, super.key});

  final HolderFieldsController controller;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final problem = controller.problem;
    String? error(HolderProblem field) =>
        problem == field ? holderProblemMessage(l10n, field) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('holder-name'),
          controller: controller.name,
          textCapitalization: TextCapitalization.words,
          maxLength: holderNameMaxLength,
          decoration: InputDecoration(
            labelText: l10n.holderName,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            errorText: error(HolderProblem.nameTooLong),
            counterText: '',
          ),
          onChanged: (_) => onChanged?.call(),
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        TextField(
          key: const Key('holder-phone'),
          controller: controller.phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.holderPhone,
            helperText: l10n.holderPhoneHelp,
            prefixIcon: const Icon(Icons.phone_rounded),
            errorText: error(HolderProblem.phoneInvalid),
          ),
          onChanged: (_) => onChanged?.call(),
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        TextField(
          key: const Key('holder-email'),
          controller: controller.email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.holderEmail,
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            errorText: error(HolderProblem.emailInvalid),
          ),
          onChanged: (_) => onChanged?.call(),
        ),
      ],
    );
  }
}

/// Ouvre la modification du titulaire d'un ticket ; renvoie le titulaire
/// enregistré, ou `null` si l'utilisateur renonce.
Future<TicketHolder?> showHolderSheet(
  BuildContext context, {
  required String eventId,
  required TicketSummary ticket,
}) => showModalBottomSheet<TicketHolder>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  useRootNavigator: true,
  builder: (_) => _HolderSheet(eventId: eventId, ticket: ticket),
);

class _HolderSheet extends ConsumerStatefulWidget {
  const new({required this.eventId, required this.ticket});

  final String eventId;
  final TicketSummary ticket;

  @override
  ConsumerState<_HolderSheet> createState() => _HolderSheetState();
}

class _HolderSheetState extends ConsumerState<_HolderSheet> {
  late final HolderFieldsController _fields = HolderFieldsController(
    widget.ticket.holder,
  );
  bool _busy = false;
  TicketFailure? _failure;

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final holder = _fields.read();
    setState(() => _failure = null);
    if (holder == null || _busy) return;
    setState(() => _busy = true);
    final toast = Toaster.of(context);
    final l10n = context.l10n;
    try {
      final saved = await ref
          .read(ticketActionsProvider)
          .setHolder(widget.eventId, widget.ticket.id, holder);
      if (!mounted) return;
      toast.success(l10n.holderSaved);
      Navigator.of(context).pop(saved);
    } on TicketFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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
            Text(l10n.holderEdit, style: theme.textTheme.titleLarge),
            Text(widget.ticket.reference, style: theme.textTheme.bodyMedium),
            const SizedBox(height: TicketSurSpacing.md),
            HolderFields(
              controller: _fields,
              onChanged: () {
                if (_fields.problem != null) {
                  setState(() => _fields.problem = null);
                }
              },
            ),
            if (_failure case final failure?) ...[
              const SizedBox(height: TicketSurSpacing.sm),
              Text(
                ticketFailureMessage(l10n, failure),
                key: const Key('holder-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: TicketSurSpacing.lg),
            FilledButton.icon(
              key: const Key('holder-save'),
              onPressed: _busy ? null : () => unawaited(_save()),
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(l10n.holderSave),
            ),
          ],
        ),
      ),
    );
  }
}
