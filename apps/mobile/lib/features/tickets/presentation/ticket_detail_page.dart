import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_card.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_share.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Fiche d'un billet (S13, S15) : QR, partage, annulation.
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

  /// Billet transmis par la liste (absent après un redémarrage).
  final TicketSummary? initial;

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  final GlobalKey _boundary = GlobalKey();
  late TicketSummary? _ticket = widget.initial;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } on TicketFailure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(ticketFailureMessage(l10n, failure))),
      );
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
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == TicketStatus.revoked
                ? l10n.ticketRevoked
                : l10n.ticketAlreadyRedeemed,
          ),
        ),
      );
    });
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
                  // Cadre opaque capturé avec la carte : une image à coins
                  // transparents s'affiche avec des coins noirs dans
                  // certaines messageries.
                  child: RepaintBoundary(
                    key: _boundary,
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
                  ticketStatusStyle(ticket.status).icon,
                  color: ticketStatusStyle(ticket.status).color,
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
                                  boundaryKey: _boundary,
                                  event: event,
                                  reference: ticket.reference,
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
