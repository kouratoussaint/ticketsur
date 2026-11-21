import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_events/application/admin_events_providers.dart';
import 'package:ticketsur/features/admin_events/domain/admin_events.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

/// Console : retrouver un ticket sur toute la plateforme (référence, nom ou
/// téléphone du titulaire). Jamais le QR.
class ConsoleTicketsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleTicketsPage> createState() => _ConsoleTicketsPageState();
}

class _ConsoleTicketsPageState extends ConsumerState<ConsoleTicketsPage> {
  final _query = TextEditingController();
  List<AdminTicketRow>? _results;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final l10n = context.l10n;
    final text = _query.text.trim();
    if (text.length < 3) {
      setState(() => _error = l10n.adminTicketsErrorSearch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await ref
          .read(adminEventsRepositoryProvider)
          .findTickets(text);
      if (mounted) setState(() => _results = rows);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = adminAccountsFailureMessage(l10n, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.palette.mutedText);
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleNavTickets)),
      body: ListView(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          TextField(
            key: const Key('console-ticket-search'),
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => unawaited(_find()),
            decoration: InputDecoration(
              labelText: l10n.adminTicketsSearch,
              errorText: _error,
              suffixIcon: IconButton(
                key: const Key('console-ticket-find'),
                tooltip: l10n.adminTicketsSearch,
                onPressed: _busy ? null : () => unawaited(_find()),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          Text(l10n.adminTicketsSearchHint, style: muted),
          const SizedBox(height: TicketSurSpacing.sm),
          if (_results case final results?)
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.lg),
                child: Text(
                  l10n.consoleEmpty,
                  key: const Key('console-ticket-none'),
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final ticket in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: TicketSurSpacing.xs),
                  child: TikeoCard(
                    key: Key('console-ticket-${ticket.id}'),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.confirmation_number_rounded),
                      title: Text(
                        [ticket.reference, ?ticket.holderName].join(' · '),
                      ),
                      subtitle: Text(
                        [
                          ticket.eventTitle,
                          _day(ticket.startsAt),
                          ticket.organizationName,
                          ticket.categoryName,
                        ].join(' · '),
                      ),
                      trailing: ConsoleTag(
                        label: ticketStatusLabel(l10n, ticket.status),
                        danger: ticket.status == TicketStatus.revoked,
                      ),
                      onTap: () => unawaited(
                        context.push(AppRoutes.consoleTicket(ticket.id)),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
