import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/presentation/audit_labels.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_events/application/admin_events_providers.dart';
import 'package:ticketsur/features/admin_events/domain/admin_events.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _when(DateTime instant) => formatDateAtTime(instant.toLocal());

String _channel(String channel) => switch (channel) {
  'whatsapp' => 'WhatsApp',
  'sms' => 'SMS',
  _ => 'E-mail',
};

/// Console : fiche d'un ticket (jamais le QR), annulation, titulaire.
class AdminTicketDetailPage extends ConsumerWidget {
  const new({required this.ticketId, super.key});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(adminTicketDetailProvider(ticketId));
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(detail.value?.reference ?? l10n.adminTicketsTitle),
      ),
      body: switch (detail) {
        AsyncData(:final value) => _Detail(ticket: value),
        AsyncError(:final error) => Center(
          child: Text(
            adminAccountsFailureMessage(l10n, error),
            key: const Key('ticket-admin-error'),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const new({required this.ticket});

  final AdminTicketDetail ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(adminMeProvider).value;
    final canTickets = me?.can(AdminPermission.tickets) ?? false;
    final editable = canTickets && ticket.status == TicketStatus.issued;
    final repository = ref.read(adminEventsRepositoryProvider);
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );

    Future<void> run(Future<String> Function() action) async {
      final toast = Toaster.of(context);
      try {
        toast.success(await action());
        ref
          ..invalidate(adminTicketDetailProvider(ticket.id))
          ..invalidate(adminEventDetailProvider(ticket.eventId));
      } on Object catch (error) {
        toast.error(adminAccountsFailureMessage(l10n, error));
      }
    }

    Future<void> editHolder() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminTicketsHolder,
        confirmLabel: l10n.profileSave,
        fields: [
          ActionField(
            name: 'name',
            label: l10n.adminAccountsName,
            initial: ticket.holderName,
            required: false,
          ),
          ActionField(
            name: 'phone',
            label: l10n.adminAccountsPhone,
            initial: ticket.holderPhone,
            keyboard: TextInputType.phone,
            required: false,
          ),
          ActionField(
            name: 'email',
            label: l10n.adminAccountsEmail,
            initial: ticket.holderEmail,
            keyboard: TextInputType.emailAddress,
            required: false,
          ),
        ],
      );
      if (result == null || !context.mounted) return;
      String? optional(String key) =>
          result.fields[key]!.isEmpty ? null : result.fields[key];
      await run(() async {
        await repository.setTicketHolder(
          ticket.id,
          name: optional('name'),
          phone: optional('phone'),
          email: optional('email'),
          reason: result.reason,
        );
        return l10n.adminTicketsHolderChanged;
      });
    }

    Future<void> revoke() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminTicketsRevoke,
        body: l10n.adminTicketsRevokeHint,
        confirmLabel: l10n.adminTicketsRevoke,
        notifyDefault: ticket.walletOwner == null
            ? null
            : me?.notifyUsers ?? false,
        destructive: true,
      );
      if (result == null || !context.mounted) return;
      await run(() async {
        await repository.revokeTicket(
          ticket.id,
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminTicketsRevoked;
      });
    }

    return SingleChildScrollView(
      key: const Key('ticket-admin-detail'),
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TikeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(ticket.reference, style: textTheme.titleLarge),
                if (ticket.eventNumber case final number?)
                  Text(l10n.adminTicketsNumber(number), style: muted),
                const SizedBox(height: TicketSurSpacing.xs),
                Wrap(
                  spacing: TicketSurSpacing.xxs,
                  runSpacing: TicketSurSpacing.xxs,
                  children: [
                    ConsoleTag(
                      key: const Key('ticket-admin-status'),
                      label: ticketStatusLabel(l10n, ticket.status),
                      danger: ticket.status == TicketStatus.revoked,
                    ),
                    ConsoleTag(label: ticket.categoryName, danger: false),
                  ],
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(
                  l10n.adminTicketsIssuedAt(_when(ticket.issuedAt)),
                  style: muted,
                ),
                if (ticket.revokedAt case final at?)
                  Text(l10n.adminTicketsRevokedAt(_when(at)), style: muted),
                if (ticket.firstEntryAt case final at?)
                  Text(
                    l10n.adminTicketsEntry(
                      _when(at),
                      ticket.firstEntryDoor ?? '—',
                      ticket.entriesUsed,
                    ),
                    style: muted,
                  ),
              ],
            ),
          ),
          if (editable) ...[
            const SizedBox(height: TicketSurSpacing.md),
            TikeoCard(
              key: const Key('ticket-admin-actions'),
              child: Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    key: const Key('ticket-admin-holder'),
                    onPressed: () => unawaited(editHolder()),
                    icon: const Icon(Icons.badge_rounded),
                    label: Text(l10n.adminTicketsHolder),
                  ),
                  FilledButton.icon(
                    key: const Key('ticket-admin-revoke'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () => unawaited(revoke()),
                    icon: const Icon(Icons.block_rounded),
                    label: Text(l10n.adminTicketsRevoke),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            key: const Key('ticket-admin-event'),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(ticket.eventTitle),
              subtitle: Text(
                '${ticket.organizationName} · ${_when(ticket.eventStartsAt)}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: ticket.eventId.isEmpty
                  ? null
                  : () => unawaited(
                      context.push(AppRoutes.consoleEvent(ticket.eventId)),
                    ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            key: const Key('ticket-admin-holder-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.adminTicketsHolder, style: textTheme.titleMedium),
                Text(ticket.holderName ?? l10n.adminTicketsNoHolder),
                if (ticket.holderPhone case final phone?) Text(phone),
                if (ticket.holderEmail case final email?) Text(email),
                if (ticket.walletOwner case final owner?)
                  Text(l10n.adminTicketsWallet(owner), style: muted),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.adminTicketsDeliveries, style: textTheme.titleMedium),
                if (ticket.deliveries.isEmpty)
                  Text(l10n.adminTicketsNoDelivery, style: muted),
                for (final delivery in ticket.deliveries)
                  Text(
                    '${_channel(delivery.channel)} · ${_when(delivery.sentAt)}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.adminAccountsHistory, style: textTheme.titleMedium),
                if (ticket.actions.isEmpty)
                  Text(l10n.adminEventsNoHistory, style: muted),
                for (final action in ticket.actions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded),
                    title: Text(auditActionLabel(l10n, action.action)),
                    subtitle: Text(
                      '${_when(action.at)} · ${action.by}\n'
                      '${l10n.adminAccountsReasonValue(action.reason)}',
                    ),
                    isThreeLine: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.xl),
        ],
      ),
    );
  }
}
