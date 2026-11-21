import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
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
    final tint = ticketStatusTint(ticket.status, context.tints);
    final statusIcon = ticketStatusStyle(ticket.status, context.tints).icon;
    const pad = EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin);
    return Scaffold(
      // Tout est construit d'emblée (fiche courte) : défilement simple.
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête et ticket dans une même colonne : la partie posée sur
              // l'en-tête reste touchable.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TikeoHeroHeader(
                    title: l10n.ticketDetailTitle,
                    subtitle: event.title,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  TikeoOverlapCard(
                    padding: const EdgeInsets.all(8),
                    child: FadeSlideIn(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          // Carte à l'écran (portrait, QR en grand).
                          // L'image et le PDF partagés utilisent le
                          // modèle de la catégorie.
                          child: RepaintBoundary(
                            child: ColoredBox(
                              color: TicketSurColors.surfaceLight,
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  TicketSurSpacing.sm,
                                ),
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
                  ),
                ],
              ),
              const SizedBox(height: TikeoSizes.cardGap),
              Padding(
                padding: pad,
                child: TintedBanner(
                  key: const Key('ticket-status'),
                  tint: tint,
                  icon: statusIcon,
                  title: ticketStatusLabel(l10n, ticket.status),
                  body: status,
                ),
              ),
              const SizedBox(height: TikeoSizes.cardGap),
              Padding(
                padding: pad,
                child: _HolderCard(
                  ticket: ticket,
                  onEdit: ticket.status == TicketStatus.issued && !_busy
                      ? () => unawaited(_editHolder(ticket))
                      : null,
                ),
              ),
              if (ticket.status == TicketStatus.issued)
                Padding(
                  padding: pad,
                  child: TicketSendCard(
                    event: event,
                    ticket: ticket,
                    onDelivered: (delivery) =>
                        setState(() => _ticket = ticket.withDelivery(delivery)),
                  ),
                ),
              const SizedBox(height: TikeoSizes.cardGap),
              if (!revoked && token == null)
                Padding(
                  padding: pad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TikeoPrimaryButton(
                        key: const Key('ticket-show-qr'),
                        busy: _busy,
                        onPressed: () => unawaited(
                          _run(
                            () => ref.read(ticketActionsProvider).export([
                              ticket.id,
                            ]),
                          ),
                        ),
                        icon: Icons.qr_code_2_rounded,
                        label: l10n.ticketShowQr,
                      ),
                      const SizedBox(height: TicketSurSpacing.xs),
                      Text(
                        l10n.ticketShowQrHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              if (token != null && secret != null)
                Padding(
                  padding: pad,
                  child: Row(
                    children: [
                      Expanded(
                        child: TikeoPrimaryButton(
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
                          icon: Icons.image_rounded,
                          label: l10n.ticketShareImage,
                        ),
                      ),
                      const SizedBox(width: TicketSurSpacing.xs),
                      Expanded(
                        child: SizedBox(
                          height: TikeoSizes.primaryButton,
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
                      ),
                    ],
                  ),
                ),
              if (ticket.status == TicketStatus.issued) ...[
                const SizedBox(height: TikeoSizes.sectionGap - 4),
                Padding(
                  padding: pad,
                  child: TikeoDangerButton(
                    key: const Key('ticket-revoke'),
                    onPressed: _busy ? null : () => unawaited(_revoke(ticket)),
                    icon: Icons.block_rounded,
                    label: l10n.ticketRevoke,
                  ),
                ),
              ],
            ],
          ),
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
    final tint = context.tints.blue;
    final theme = Theme.of(context);
    return TikeoCard(
      key: const Key('ticket-holder-card'),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Container(
            width: TikeoSizes.settingsIconCircle,
            height: TikeoSizes.settingsIconCircle,
            decoration: BoxDecoration(
              color: tint.background,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.badge_rounded, size: 22, color: tint.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holder.name ??
                      (holder.isEmpty ? l10n.holderNone : l10n.holderTitle),
                  key: const Key('ticket-holder-name'),
                  style: theme.textTheme.titleMedium,
                ),
                if (contact.isNotEmpty)
                  Text(
                    contact,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              key: const Key('ticket-holder-edit'),
              tooltip: holder.isEmpty ? l10n.holderAdd : l10n.holderEdit,
              onPressed: onEdit,
              icon: Icon(
                holder.isEmpty
                    ? Icons.person_add_alt_1_rounded
                    : Icons.edit_rounded,
              ),
            ),
        ],
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
