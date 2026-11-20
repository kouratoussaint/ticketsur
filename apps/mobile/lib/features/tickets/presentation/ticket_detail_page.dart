import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/features/ticket_send/presentation/ticket_send_card.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/holder_fields.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_card.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_share.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Fiche d'un ticket (S13, S15) : QR, partage, annulation.
///
/// Le QR n'est jamais chargé d'office : hors session d'émission, il faut
/// le demander, et la demande est journalisée côté serveur.
class TicketDetailPage extends ConsumerStatefulWidget {
  const new({
    required this.eventId,
    required this.ticketId,
    this.initial,
    super.key,
  });

  final String eventId;
  final String ticketId;

  /// Ticket transmis par la liste (absent après un redémarrage).
  final TicketSummary? initial;

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  late TicketSummary? _ticket = widget.initial;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } on TicketFailure catch (failure) {
      toast.error(ticketFailureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(TicketSummary ticket) async {
    final l10n = context.l10n;
    // null : annulé ; chaîne (éventuellement vide) : motif confirmé.
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _RevokeDialog(reference: ticket.reference),
    );
    if (text == null || !mounted) return;
    final toast = Toaster.of(context);
    await _run(() async {
      final status = await ref
          .read(ticketActionsProvider)
          .revoke(
            widget.eventId,
            ticket.id,
            reason: text.isEmpty ? null : text,
          );
      if (!mounted) return;
      setState(() => _ticket = ticket.withStatus(status));
      if (status == TicketStatus.revoked) {
        toast.success(l10n.ticketRevoked);
      } else {
        toast.error(l10n.ticketAlreadyRedeemed);
      }
    });
  }

  Future<void> _editHolder(TicketSummary ticket) async {
    final saved = await showHolderSheet(
      context,
      eventId: widget.eventId,
      ticket: ticket,
    );
    if (saved != null && mounted) {
      setState(() => _ticket = ticket.withHolder(saved));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ticket = _ticket;
    final event = ref.watch(eventByIdProvider(widget.eventId));
    final secret = ref.watch(
      ticketSecretsProvider.select((map) => map[widget.ticketId]),
    );
    if (ticket == null || event == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.ticketDetailTitle)),
        body: Center(child: Text(l10n.ticketErrorNotFound)),
      );
    }
    final revoked = ticket.status == TicketStatus.revoked;
    final token = revoked ? null : secret?.token;
    final status = switch (ticket) {
      TicketSummary(status: TicketStatus.redeemed, :final redeemedAt?) =>
        l10n.ticketRedeemedAt(
          formatLocalDateTime(redeemedAt),
          ticket.redeemedCheckpoint ?? '',
        ),
      TicketSummary(status: TicketStatus.revoked, :final revokedAt?) =>
        l10n.ticketRevokedAt(formatLocalDateTime(revokedAt)),
      _ => l10n.ticketIssuedAt(formatLocalDateTime(ticket.issuedAt)),
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ticketDetailTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  // Carte à l'écran (portrait, QR en grand). L'image et le
                  // PDF partagés utilisent le modèle de la catégorie.
                  child: RepaintBoundary(
                    child: ColoredBox(
                      color: TicketSurColors.surfaceLight,
                      child: Padding(
                        padding: const EdgeInsets.all(TicketSurSpacing.sm),
                        child: TicketCard(
                          event: event,
                          reference: ticket.reference,
                          categoryName: ticket.categoryName,
                          token: token,
                          status: ticket.status,
                          invitation: ticket.isInvitation,
                          holderName: ticket.holder.name,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: TicketSurSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ticketStatusStyle(ticket.status, context.tints).icon,
                  color: ticketStatusStyle(ticket.status, context.tints).color,
                ),
                const SizedBox(width: TicketSurSpacing.xs),
                Flexible(
                  child: Text(
                    '${ticketStatusLabel(l10n, ticket.status)} · $status',
                    key: const Key('ticket-status'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            _HolderCard(
              ticket: ticket,
              onEdit: ticket.status == TicketStatus.issued && !_busy
                  ? () => unawaited(_editHolder(ticket))
                  : null,
            ),
            if (ticket.status == TicketStatus.issued)
              TicketSendCard(
                event: event,
                ticket: ticket,
                onDelivered: (delivery) =>
                    setState(() => _ticket = ticket.withDelivery(delivery)),
              ),
            const SizedBox(height: TicketSurSpacing.md),
            if (!revoked && token == null) ...[
              FilledButton.icon(
                key: const Key('ticket-show-qr'),
                onPressed: _busy
                    ? null
                    : () => unawaited(
                        _run(
                          () => ref.read(ticketActionsProvider).export([
                            ticket.id,
                          ]),
                        ),
                      ),
                icon: const Icon(Icons.qr_code_2_rounded),
                label: Text(l10n.ticketShowQr),
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Text(
                l10n.ticketShowQrHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (token != null && secret != null)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('ticket-share-image'),
                      onPressed: _busy
                          ? null
                          : () => unawaited(
                              _run(
                                () => shareTicketImage(
                                  context,
                                  ref,
                                  event: event,
                                  ticket: secret.withHolderName(
                                    ticket.holder.name,
                                  ),
                                ),
                              ),
                            ),
                      icon: const Icon(Icons.image_rounded),
                      label: Text(l10n.ticketShareImage),
                    ),
                  ),
                  const SizedBox(width: TicketSurSpacing.xs),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('ticket-share-pdf'),
                      onPressed: _busy
                          ? null
                          : () => unawaited(
                              _run(
                                () => shareTicketsPdf(
                                  context,
                                  ref,
                                  event: event,
                                  tickets: [secret],
                                ),
                              ),
                            ),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(l10n.ticketSharePdf),
                    ),
                  ),
                ],
              ),
            if (ticket.status == TicketStatus.issued) ...[
              const SizedBox(height: TicketSurSpacing.lg),
              TextButton.icon(
                key: const Key('ticket-revoke'),
                onPressed: _busy ? null : () => unawaited(_revoke(ticket)),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.block_rounded),
                label: Text(l10n.ticketRevoke),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Titulaire du ticket, modifiable tant que le ticket est valable.
class _HolderCard extends StatelessWidget {
  const new({required this.ticket, this.onEdit});

  final TicketSummary ticket;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final holder = ticket.holder;
    final contact = [?holder.phone, ?holder.email].join(' · ');
    return Card(
      key: const Key('ticket-holder-card'),
      child: ListTile(
        leading: const Icon(Icons.badge_rounded),
        title: Text(
          holder.name ?? (holder.isEmpty ? l10n.holderNone : l10n.holderTitle),
          key: const Key('ticket-holder-name'),
        ),
        subtitle: contact.isEmpty ? null : Text(contact),
        trailing: onEdit == null
            ? null
            : IconButton(
                key: const Key('ticket-holder-edit'),
                tooltip: holder.isEmpty ? l10n.holderAdd : l10n.holderEdit,
                onPressed: onEdit,
                icon: Icon(
                  holder.isEmpty
                      ? Icons.person_add_alt_1_rounded
                      : Icons.edit_rounded,
                ),
              ),
      ),
    );
  }
}

class _RevokeDialog extends StatefulWidget {
  const new({required this.reference});

  final String reference;

  @override
  State<_RevokeDialog> createState() => _RevokeDialogState();
}

class _RevokeDialogState extends State<_RevokeDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: const Icon(Icons.block_rounded),
      title: Text(l10n.ticketRevokeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.ticketRevokeBody(widget.reference)),
          const SizedBox(height: TicketSurSpacing.sm),
          TextField(
            key: const Key('ticket-revoke-reason'),
            controller: _reason,
            maxLength: 200,
            decoration: InputDecoration(labelText: l10n.ticketRevokeReason),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.setupCancel),
        ),
        FilledButton(
          key: const Key('ticket-revoke-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          child: Text(l10n.ticketRevoke),
        ),
      ],
    );
  }
}
