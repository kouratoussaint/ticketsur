import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_tools/application/admin_tools_providers.dart';
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Entrée de la recherche globale, en haut de la console.
class ConsoleSearchEntry extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => TikeoCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      key: const Key('console-search'),
      leading: const Icon(Icons.search_rounded),
      title: Text(context.l10n.consoleSearchHint),
      onTap: () => unawaited(context.push(AppRoutes.consoleSearch)),
    ),
  );
}

/// Recherche globale : comptes, structures, événements, tickets.
class ConsoleSearchPage extends ConsumerStatefulWidget {
  const new({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<ConsoleSearchPage> createState() => _ConsoleSearchPageState();
}

class _ConsoleSearchPageState extends ConsumerState<ConsoleSearchPage> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery.trim();
  bool _tooShort = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? _]) {
    final query = _controller.text.trim();
    setState(() {
      _tooShort = query.length < 2 || query.length > 60;
      _query = _tooShort ? '' : query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = _query.isEmpty
        ? null
        : ref.watch(consoleSearchProvider(_query));
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleSearchTitle)),
      body: ListView(
        key: const Key('console-search-list'),
        padding: const EdgeInsets.all(TikeoSizes.screenMargin),
        children: [
          Row(
            children: [
              Expanded(
                child: TikeoSearchBar(
                  fieldKey: const Key('console-search-field'),
                  hint: l10n.consoleSearchHint,
                  controller: _controller,
                  onSubmitted: _submit,
                ),
              ),
              const SizedBox(width: TicketSurSpacing.xs),
              IconButton.filled(
                key: const Key('console-search-submit'),
                tooltip: l10n.consoleSearchTitle,
                onPressed: _submit,
                icon: const Icon(Icons.search_rounded),
              ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.md),
          if (_tooShort)
            Text(
              l10n.consoleSearchTooShort,
              key: const Key('console-search-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else
            switch (result) {
              null => Text(
                l10n.consoleSearchIdle,
                key: const Key('console-search-idle'),
              ),
              AsyncData(:final value) when value.isEmpty => Text(
                l10n.consoleSearchEmpty,
                key: const Key('console-search-empty'),
              ),
              AsyncData(:final value) => _Results(result: value),
              AsyncError(:final error) => Text(
                adminAccountsFailureMessage(l10n, error),
                key: const Key('console-search-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const new({required this.result});

  final GlobalSearchResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.palette.mutedText);
    void open(String path) => unawaited(context.push(path));

    Widget section(
      String key,
      String title,
      IconData icon,
      List<Widget> rows,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: TicketSurSpacing.md),
      child: Column(
        key: Key('console-search-$key'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, icon: icon),
          const SizedBox(height: TicketSurSpacing.xs),
          TikeoCard(
            padding: EdgeInsets.zero,
            child: Column(children: rows),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.accounts.isNotEmpty)
          section('accounts', l10n.consoleNavAccounts, Icons.person_rounded, [
            for (final account in result.accounts)
              ListTile(
                key: Key('console-search-account-${account.id}'),
                title: Text(account.name),
                subtitle: Text(
                  [
                    ?account.email,
                    if (account.deleted)
                      l10n.consoleAccountDeleted
                    else if (!account.active)
                      l10n.consoleAccountDisabled,
                  ].join(' · '),
                  style: muted,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => open(AppRoutes.consoleAccount(account.id)),
              ),
          ]),
        if (result.organizations.isNotEmpty)
          section(
            'organizations',
            l10n.consoleNavOrganizations,
            Icons.apartment_rounded,
            [
              for (final org in result.organizations)
                ListTile(
                  key: Key('console-search-organization-${org.id}'),
                  title: Text(org.name),
                  subtitle: Text(
                    [
                      ?org.ownerName,
                      if (org.closed)
                        l10n.adminOrgsClosedTag
                      else if (!org.active)
                        l10n.consoleSuspended,
                    ].join(' · '),
                    style: muted,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => open(AppRoutes.consoleOrganization(org.id)),
                ),
            ],
          ),
        if (result.events.isNotEmpty)
          section('events', l10n.consoleNavEvents, Icons.event_rounded, [
            for (final event in result.events)
              ListTile(
                key: Key('console-search-event-${event.id}'),
                title: Text(event.title),
                subtitle: Text(
                  [
                    eventStatusLabel(l10n, event.status),
                    if (event.startsAt case final at?)
                      formatDateAtTime(at.toLocal()),
                    ?event.organizationName,
                  ].join(' · '),
                  style: muted,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => open(AppRoutes.consoleEvent(event.id)),
              ),
          ]),
        if (result.tickets.isNotEmpty)
          section(
            'tickets',
            l10n.consoleNavTickets,
            Icons.confirmation_number_rounded,
            [
              for (final ticket in result.tickets)
                ListTile(
                  key: Key('console-search-ticket-${ticket.id}'),
                  title: Text(ticket.reference),
                  subtitle: Text(
                    [
                      ticketStatusLabel(l10n, ticket.status),
                      ?ticket.holderName,
                      ?ticket.eventTitle,
                    ].join(' · '),
                    style: muted,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => open(AppRoutes.consoleTicket(ticket.id)),
                ),
            ],
          ),
      ],
    );
  }
}
