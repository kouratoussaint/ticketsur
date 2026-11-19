import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/ticket_send/application/send_providers.dart';
import 'package:ticketsur/features/ticket_send/presentation/send_copy.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Tickets lus par paquet ; une série dépassant ce nombre se poursuit en
/// rouvrant l'écran (les tickets envoyés n'y reviennent pas).
const int _batchSize = 200;

/// Jetons relus d'avance (un seul ré-export audité par paquet).
const int _prefetch = 20;

enum _Phase { loading, error, ready, opening, confirm, done }

/// Envoi en série (lot 2) : les tickets valables, jamais envoyés, dont le
/// titulaire est joignable par le canal choisi, un par un. Pour chacun,
/// l'application d'envoi s'ouvre préremplie ; l'organisateur envoie, revient
/// et confirme. Seuls les envois confirmés sont enregistrés.
class TicketSendPage extends ConsumerStatefulWidget {
  const new({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<TicketSendPage> createState() => _TicketSendPageState();
}

class _TicketSendPageState extends ConsumerState<TicketSendPage> {
  DeliveryChannel _channel = DeliveryChannel.whatsapp;
  List<TicketSummary> _queue = const [];
  int _index = 0;
  int _sent = 0;
  int _skipped = 0;
  _Phase _phase = _Phase.loading;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _message = null;
    });
    try {
      final page = await ref
          .read(ticketRepositoryProvider)
          .list(
            widget.eventId,
            status: TicketStatus.issued,
            undelivered: true,
            limit: _batchSize,
          );
      if (!mounted) return;
      setState(() {
        // Liste servie du plus récent au plus ancien : envoi dans l'ordre
        // d'émission (celui de la liste importée).
        _queue = [
          for (final ticket in page.items.reversed)
            if (_channel.reaches(ticket.holder)) ticket,
        ];
        _index = 0;
        _sent = 0;
        _skipped = 0;
        _phase = _Phase.ready;
      });
    } on TicketFailure {
      if (mounted) setState(() => _phase = _Phase.error);
    }
  }

  void _selectChannel(DeliveryChannel channel) {
    if (channel == _channel) return;
    setState(() => _channel = channel);
    unawaited(_load());
  }

  Future<void> _open() async {
    final event = ref.read(eventByIdProvider(widget.eventId));
    if (event == null) return;
    final l10n = context.l10n;
    final ticket = _queue[_index];
    setState(() {
      _phase = _Phase.opening;
      _message = null;
    });
    try {
      await ref.read(ticketActionsProvider).ensureSecrets([
        for (final t in _queue.skip(_index).take(_prefetch)) t.id,
      ]);
      if (!mounted) return;
      final outcome = await openTicketSend(
        context,
        ref,
        event: event,
        ticket: ticket,
        channel: _channel,
      );
      if (!mounted) return;
      final message = sendOutcomeMessage(l10n, _channel, outcome);
      setState(() {
        _phase = message == null ? _Phase.confirm : _Phase.ready;
        _message = message;
      });
    } on TicketFailure catch (failure) {
      if (mounted) {
        setState(() {
          _phase = _Phase.ready;
          _message = ticketFailureMessage(l10n, failure);
        });
      }
    }
  }

  Future<void> _confirm() async {
    final l10n = context.l10n;
    final ticket = _queue[_index];
    setState(() => _phase = _Phase.opening);
    try {
      await ref.read(ticketActionsProvider).recordDelivery(ticket.id, _channel);
      if (!mounted) return;
      _sent++;
      _next();
    } on TicketFailure catch (failure) {
      if (mounted) {
        setState(() {
          _phase = _Phase.confirm;
          _message = ticketFailureMessage(l10n, failure);
        });
      }
    }
  }

  void _skip() {
    _skipped++;
    _next();
  }

  void _next() {
    setState(() {
      _index++;
      _message = null;
      _phase = _index >= _queue.length ? _Phase.done : _Phase.ready;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final event = ref.watch(eventByIdProvider(widget.eventId));
    final busy = _phase == _Phase.opening || _phase == _Phase.loading;
    final started = _index > 0 || _phase == _Phase.confirm;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sendBatchTitle),
            if (event != null)
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          Text(l10n.sendBatchIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: TicketSurSpacing.md),
          SegmentedButton<DeliveryChannel>(
            key: const Key('send-channel'),
            segments: [
              for (final channel in DeliveryChannel.values)
                ButtonSegment(
                  value: channel,
                  icon: Icon(channelIcon(channel)),
                  label: Text(
                    channelLabel(l10n, channel),
                    key: Key('send-channel-${channel.wireName}'),
                  ),
                ),
            ],
            selected: {_channel},
            onSelectionChanged: busy || (started && _phase != _Phase.done)
                ? null
                : (selection) => _selectChannel(selection.single),
          ),
          const SizedBox(height: TicketSurSpacing.lg),
          switch (_phase) {
            _Phase.loading => const Center(child: CircularProgressIndicator()),
            _Phase.error => Column(
              children: [
                Text(l10n.sendBatchLoadError, textAlign: TextAlign.center),
                TextButton(
                  key: const Key('send-retry-load'),
                  onPressed: () => unawaited(_load()),
                  child: Text(l10n.orgRetry),
                ),
              ],
            ),
            _Phase.done => _Done(
              sent: _sent,
              skipped: _skipped,
              onClose: () => context.popOr(AppRoutes.tickets),
            ),
            _ when _queue.isEmpty => _Empty(channel: _channel),
            _ => FadeSlideIn(
              key: ValueKey(_queue[_index].id),
              child: _Current(
                ticket: _queue[_index],
                channel: _channel,
                index: _index,
                total: _queue.length,
                sent: _sent,
                skipped: _skipped,
                awaitingConfirm: _phase == _Phase.confirm,
                busy: _phase == _Phase.opening,
                message: _message,
                onOpen: () => unawaited(_open()),
                onConfirm: () => unawaited(_confirm()),
                onSkip: _skip,
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _Current extends StatelessWidget {
  const new({
    required this.ticket,
    required this.channel,
    required this.index,
    required this.total,
    required this.sent,
    required this.skipped,
    required this.awaitingConfirm,
    required this.busy,
    required this.onOpen,
    required this.onConfirm,
    required this.onSkip,
    this.message,
  });

  final TicketSummary ticket;
  final DeliveryChannel channel;
  final int index;
  final int total;
  final int sent;
  final int skipped;
  final bool awaitingConfirm;
  final bool busy;
  final String? message;
  final VoidCallback onOpen;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final holder = ticket.holder;
    final contact = channel == DeliveryChannel.email
        ? holder.email
        : holder.phone;
    const spinner = SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.sendBatchProgress(index + 1, total),
                key: const Key('send-progress'),
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              l10n.sendBatchStats(sent, skipped),
              key: const Key('send-stats'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: TicketSurSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: index / total, minHeight: 6),
        ),
        const SizedBox(height: TicketSurSpacing.md),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.all(TicketSurSpacing.md),
            leading: CircleAvatar(child: Icon(channelIcon(channel))),
            title: Text(
              holder.name ?? ticket.reference,
              key: const Key('send-current-name'),
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              [
                ?contact,
                [
                  ticket.reference,
                  if (ticket.isInvitation)
                    l10n.ticketInvitationOf(ticket.categoryName)
                  else
                    ticket.categoryName,
                ].join(' · '),
              ].join('\n'),
            ),
          ),
        ),
        if (message case final text?) ...[
          const SizedBox(height: TicketSurSpacing.sm),
          Text(
            text,
            key: const Key('send-message'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: TicketSurSpacing.lg),
        if (awaitingConfirm) ...[
          Text(
            l10n.sendConfirmTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: TicketSurSpacing.sm),
          FilledButton.icon(
            key: const Key('send-confirm'),
            onPressed: busy ? null : onConfirm,
            icon: busy ? spinner : const Icon(Icons.check_rounded),
            label: Text(l10n.sendBatchNext),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          OutlinedButton.icon(
            key: const Key('send-reopen'),
            onPressed: busy ? null : onOpen,
            icon: Icon(channelIcon(channel)),
            label: Text(l10n.sendBatchRetry),
          ),
        ] else
          FilledButton.icon(
            key: const Key('send-open'),
            onPressed: busy ? null : onOpen,
            icon: busy ? spinner : Icon(channelIcon(channel)),
            label: Text(l10n.sendBatchSend(channelLabel(l10n, channel))),
          ),
        TextButton(
          key: const Key('send-skip'),
          onPressed: busy ? null : onSkip,
          child: Text(l10n.sendBatchSkip),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const new({required this.channel});

  final DeliveryChannel channel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      key: const Key('send-empty'),
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 48,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        Text(
          l10n.sendBatchEmptyTitle(channelLabel(l10n, channel)),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: TicketSurSpacing.xs),
        Text(
          channel == DeliveryChannel.email
              ? l10n.sendBatchEmptyEmail
              : l10n.sendBatchEmptyPhone,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const new({required this.sent, required this.skipped, required this.onClose});

  final int sent;
  final int skipped;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      key: const Key('send-done'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.task_alt_rounded,
          size: 56,
          color: TicketSurColors.successStrong,
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        Text(
          l10n.sendBatchDoneTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        Text(
          l10n.sendBatchStats(sent, skipped),
          key: const Key('send-done-stats'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TicketSurSpacing.lg),
        FilledButton(
          key: const Key('send-close'),
          onPressed: onClose,
          child: Text(l10n.sendBatchClose),
        ),
      ],
    );
  }
}
