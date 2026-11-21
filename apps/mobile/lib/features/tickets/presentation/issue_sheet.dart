import 'dart:async';

import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/success_burst.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/billing_block_sheet.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/holder_fields.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_share.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ouvre l'émission de tickets (S11, S12).
Future<void> showIssueSheet(BuildContext context, TicketEvent event) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => IssueSheet(event: event),
    );

/// Choix de la catégorie et de la quantité, puis partage du lot.
class IssueSheet extends ConsumerStatefulWidget {
  const new({required this.event, super.key});

  final TicketEvent event;

  @override
  ConsumerState<IssueSheet> createState() => _IssueSheetState();
}

class _IssueSheetState extends ConsumerState<IssueSheet> {
  final _quantity = TextEditingController(text: '1');
  final _holder = HolderFieldsController();
  String? _categoryId;
  bool _busy = false;
  TicketFailure? _failure;
  List<TicketSecret>? _issued;

  int? get _count {
    final value = int.tryParse(_quantity.text);
    return value == null || value < 1 || value > maxBatchSize ? null : value;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _holder.dispose();
    super.dispose();
  }

  Future<void> _issue(TicketCategory category) async {
    final count = _count;
    if (count == null || _busy) return;
    // Un ticket seul peut porter un titulaire (facultatif).
    final holder = count == 1 ? _holder.read() : TicketHolder.none;
    if (holder == null) {
      setState(() {});
      return;
    }
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final actions = ref.read(ticketActionsProvider);
      final issued = holder.isEmpty
          ? await actions.issue(
              widget.event.id,
              category.id,
              count,
              categoryName: category.name,
              isInvitation: category.isInvitation,
            )
          : await actions.issueNamed(widget.event.id, [
              (categoryId: category.id, holder: holder),
            ]);
      if (mounted) setState(() => _issued = issued);
    } on TicketFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf(List<TicketSecret> issued) async {
    setState(() => _busy = true);
    try {
      await shareTicketsPdf(context, ref, event: widget.event, tickets: issued);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _quotaLabel(BuildContext context, TicketCategory category) =>
      switch (category.capacity) {
        null => context.l10n.issueUnlimited,
        final capacity => context.l10n.issueRemaining(
          capacity - category.issued,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final issued = _issued;
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
        child: issued == null ? _form(context) : _done(context, issued),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider(widget.event.id));
    final list = categories.value ?? const <TicketCategory>[];
    final selected =
        list.where((c) => c.id == _categoryId).firstOrNull ?? list.firstOrNull;
    return SingleChildScrollView(
      key: const ValueKey('issue-form'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.issueTitle, style: theme.textTheme.titleLarge),
          Text(widget.event.title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: TicketSurSpacing.sm),
          OutlinedButton.icon(
            key: const Key('issue-import'),
            onPressed: () async {
              // Routeur capturé avant de fermer la feuille.
              final router = GoRouter.of(context);
              final navigator = Navigator.of(context);
              if (!await billingAllows(
                ref,
                widget.event.id,
                BillingOption.import,
              )) {
                return;
              }
              navigator.pop();
              unawaited(router.push(AppRoutes.ticketImport(widget.event.id)));
            },
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(l10n.importEntry),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          if (categories.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (selected == null)
            Text(l10n.issueNoCategory, key: const Key('issue-no-category'))
          else ...[
            DropdownButtonFormField<String>(
              key: const Key('issue-category'),
              initialValue: selected.id,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.issueCategory),
              items: [
                for (final c in list)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      '${c.name} · ${_quotaLabel(context, c)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: TicketSurSpacing.md),
            TextField(
              key: const Key('issue-quantity'),
              controller: _quantity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.issueQuantity,
                helperText: l10n.issueQuantityHelp,
                errorText: _quantity.text.isNotEmpty && _count == null
                    ? l10n.issueQuantityError
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            Wrap(
              spacing: TicketSurSpacing.xs,
              children: [
                for (final n in const [1, 10, 50, 100, 500, 1000])
                  ActionChip(
                    key: Key('issue-quick-$n'),
                    label: Text('$n'),
                    onPressed: () => setState(() => _quantity.text = '$n'),
                  ),
              ],
            ),
            MotionSize(
              alignment: Alignment.topCenter,
              child: _count == 1
                  ? Padding(
                      key: const Key('issue-holder'),
                      padding: const EdgeInsets.only(top: TicketSurSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.holderOptional,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            l10n.holderOptionalHint,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: TicketSurSpacing.sm),
                          HolderFields(
                            controller: _holder,
                            onChanged: () {
                              if (_holder.problem != null) {
                                setState(() => _holder.problem = null);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            if (_failure case final failure?) ...[
              const SizedBox(height: TicketSurSpacing.sm),
              Text(
                ticketFailureMessage(l10n, failure),
                key: const Key('issue-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: TicketSurSpacing.lg),
            TikeoPrimaryButton(
              key: const Key('issue-submit'),
              busy: _busy,
              onPressed: _count == null
                  ? null
                  : () => unawaited(_issue(selected)),
              icon: Icons.add_card_rounded,
              label: l10n.issueSubmit(_count ?? 0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _done(BuildContext context, List<TicketSecret> issued) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('issue-done'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: SuccessBurst(size: 72)),
        const SizedBox(height: TicketSurSpacing.sm),
        Text(
          l10n.issueDoneTitle(issued.length),
          key: const Key('issue-done-title'),
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TicketSurSpacing.xs),
        Text(l10n.issueDoneBody, textAlign: TextAlign.center),
        const SizedBox(height: TicketSurSpacing.lg),
        TikeoPrimaryButton(
          key: const Key('issue-share-pdf'),
          busy: _busy,
          onPressed: () => unawaited(_sharePdf(issued)),
          icon: Icons.picture_as_pdf_rounded,
          label: l10n.issueSharePdf,
        ),
        const SizedBox(height: TicketSurSpacing.xs),
        OutlinedButton(
          key: const Key('issue-see'),
          onPressed: () {
            // Routeur capturé avant de fermer la feuille (son contexte
            // disparaît avec elle).
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            if (issued.length == 1) {
              final ticket = issued.single;
              unawaited(
                router.push(
                  AppRoutes.ticketDetail(widget.event.id, ticket.ticketId),
                  extra: TicketSummary(
                    id: ticket.ticketId,
                    reference: ticket.reference,
                    categoryName: ticket.categoryName,
                    isInvitation: ticket.isInvitation,
                    status: TicketStatus.issued,
                    issuedAt: DateTime.now().toUtc(),
                    holder: _holder.read() ?? TicketHolder.none,
                  ),
                ),
              );
            }
          },
          child: Text(l10n.issueSeeTickets),
        ),
      ],
    );
  }
}
