import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/features/ticket_send/application/send_providers.dart';
import 'package:ticketsur/features/ticket_send/presentation/send_copy.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Envoi d'un ticket à son titulaire depuis sa fiche : WhatsApp, SMS ou
/// e-mail selon ses coordonnées. L'envoi n'est enregistré qu'une fois
/// confirmé par l'organisateur.
class TicketSendCard extends ConsumerStatefulWidget {
  const new({
    required this.event,
    required this.ticket,
    required this.onDelivered,
    super.key,
  });

  final TicketEvent event;
  final TicketSummary ticket;
  final ValueChanged<TicketDelivery> onDelivered;

  @override
  ConsumerState<TicketSendCard> createState() => _TicketSendCardState();
}

class _TicketSendCardState extends ConsumerState<TicketSendCard> {
  DeliveryChannel? _busy;

  Future<void> _send(DeliveryChannel channel) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = channel);
    try {
      final outcome = await openTicketSend(
        context,
        ref,
        event: widget.event,
        ticket: widget.ticket,
        channel: channel,
      );
      if (!mounted) return;
      if (sendOutcomeMessage(l10n, channel, outcome) case final message?) {
        toast.error(message);
        return;
      }
      // Plus d'indicateur d'attente pendant la question.
      setState(() => _busy = null);
      if (!await confirmSent(context, channel) || !mounted) return;
      final at = await ref
          .read(ticketActionsProvider)
          .recordDelivery(widget.ticket.id, channel);
      widget.onDelivered((channel: channel, at: at));
      toast.success(l10n.sendRecorded);
    } on TicketFailure catch (failure) {
      toast.error(ticketFailureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final holder = widget.ticket.holder;
    final channels = [
      for (final channel in DeliveryChannel.values)
        if (channel.reaches(holder)) channel,
    ];
    final last = widget.ticket.lastDelivery;
    return Card(
      key: const Key('ticket-send-card'),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.sendTitle, style: theme.textTheme.titleMedium),
            if (last != null)
              Text(
                l10n.sendLast(
                  channelLabel(l10n, last.channel),
                  formatLocalDateTime(last.at),
                ),
                key: const Key('ticket-last-delivery'),
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: TicketSurSpacing.sm),
            if (channels.isEmpty)
              Text(
                l10n.sendNoContact,
                key: const Key('ticket-send-no-contact'),
                style: theme.textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: [
                  for (final channel in channels)
                    FilledButton.tonalIcon(
                      key: Key('ticket-send-${channel.wireName}'),
                      // Le thème impose une largeur pleine aux boutons.
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: _busy == null
                          ? () => unawaited(_send(channel))
                          : null,
                      icon: _busy == channel
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(channelIcon(channel)),
                      label: Text(channelLabel(l10n, channel)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
