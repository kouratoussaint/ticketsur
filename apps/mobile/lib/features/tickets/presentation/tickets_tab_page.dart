import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/animated_count.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/issue_sheet.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Événements dont on peut consulter les tickets (tout sauf les brouillons).
List<TicketEvent> ticketableEvents(List<TicketEvent> events) => [
  for (final e in events)
    if (e.status != EventStatus.draft) e,
];

/// L'émission n'est possible que pour un événement publié ou en cours.
bool canIssue(TicketEvent event) =>
    event.status == EventStatus.published ||
    event.status == EventStatus.inProgress;

/// Onglet Tickets (S14) : tickets de l'événement choisi, émission.
class TicketsTabPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<TicketsTabPage> createState() => _TicketsTabPageState();
}

class _TicketsTabPageState extends ConsumerState<TicketsTabPage> {
  TicketStatus? _status;
  String _search = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final organization = ref.watch(activeOrganizationProvider);
    if (!canManageEvents(organization)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navTickets)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.xl),
            child: Text(
              l10n.ticketsControllerBody,
              key: const Key('tickets-controller'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final events = ticketableEvents(ref.watch(eventsProvider).value ?? []);
    final selectedId = ref.watch(selectedTicketEventProvider);
    final event =
        events.where((e) => e.id == selectedId).firstOrNull ??
        events.where(canIssue).firstOrNull ??
        events.firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTickets)),
      floatingActionButton: event != null && canIssue(event)
          ? FloatingActionButton.extended(
              key: const Key('tickets-issue'),
              heroTag: 'tickets-issue',
              onPressed: () => showIssueSheet(context, event),
              icon: const Icon(Icons.add_card_rounded),
              label: Text(l10n.ticketsIssue),
            )
          : null,
      body: event == null
          ? _NoEvent(loading: ref.watch(eventsProvider).isLoading)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TicketSurSpacing.md,
                    TicketSurSpacing.xs,
                    TicketSurSpacing.md,
                    0,
                  ),
                  child: DropdownButtonFormField<String>(
                    key: const Key('tickets-event'),
                    initialValue: event.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.ticketsEventLabel,
                      prefixIcon: const Icon(Icons.event_rounded),
                    ),
                    items: [
                      for (final e in events)
                        DropdownMenuItem(
                          value: e.id,
                          child: Text(e.title, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (id) =>
                        ref.read(selectedTicketEventProvider.notifier).eventId =
                            id,
                  ),
                ),
                _Summary(eventId: event.id),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TicketSurSpacing.md,
                  ),
                  child: Row(
                    children: [
                      for (final (status, label) in [
                        (null, l10n.ticketsFilterAll),
                        (TicketStatus.issued, l10n.ticketsFilterValid),
                        (TicketStatus.redeemed, l10n.ticketsFilterRedeemed),
                        (TicketStatus.revoked, l10n.ticketsFilterRevoked),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(
                            right: TicketSurSpacing.xs,
                          ),
                          child: ChoiceChip(
                            key: Key('tickets-filter-${status?.name ?? 'all'}'),
                            label: Text(label),
                            selected: _status == status,
                            onSelected: (_) => setState(() => _status = status),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TicketSurSpacing.md,
                    TicketSurSpacing.xs,
                    TicketSurSpacing.md,
                    TicketSurSpacing.xs,
                  ),
                  child: TextField(
                    key: const Key('tickets-search'),
                    onChanged: _onSearch,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: l10n.ticketsSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: _TicketList(
                    query: (
                      eventId: event.id,
                      status: _status,
                      search: _search,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _NoEvent extends StatelessWidget {
  const new({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) return const SkeletonList(count: 3);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.xl),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.confirmation_number_rounded,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              Text(
                l10n.ticketsNoEventTitle,
                key: const Key('tickets-no-event'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Text(l10n.ticketsNoEventBody, textAlign: TextAlign.center),
              const SizedBox(height: TicketSurSpacing.md),
              FilledButton.tonal(
                onPressed: () => context.go(AppRoutes.events),
                child: Text(l10n.ticketsGoEvents),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const new({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider(eventId)).value;
    if (categories == null) return const SizedBox(height: TicketSurSpacing.sm);
    final issued = categories.fold(0, (sum, c) => sum + c.issued);
    final redeemed = categories.fold(0, (sum, c) => sum + c.redeemed);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TicketSurSpacing.md,
        vertical: TicketSurSpacing.sm,
      ),
      child: AnimatedCount(
        value: issued,
        builder: (context, shownIssued) => AnimatedCount(
          value: redeemed,
          builder: (context, shownRedeemed) => Text(
            context.l10n.ticketsSummary(shownIssued, shownRedeemed),
            key: const Key('tickets-summary'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ),
    );
  }
}

class _TicketList extends ConsumerWidget {
  const new({required this.query});

  final TicketQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final page = ref.watch(ticketListProvider(query));
    return AnimatedSwitcher(
      duration: TicketSurMotion.reduced(context)
          ? Duration.zero
          : TicketSurMotion.medium,
      child: switch (page) {
        AsyncData(:final value) when value.items.isEmpty => Center(
          key: const ValueKey('empty'),
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            child: Text(
              query.status == null && query.search.isEmpty
                  ? l10n.ticketsEmpty
                  : l10n.ticketsEmptyFilter,
              key: const Key('tickets-empty'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AsyncData(:final value) => RefreshIndicator(
          key: const ValueKey('data'),
          onRefresh: () async => ref.invalidate(ticketListProvider(query)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.md,
              0,
              TicketSurSpacing.md,
              96,
            ),
            itemCount: value.items.length + 1,
            itemBuilder: (context, index) {
              if (index == value.items.length) {
                return Padding(
                  padding: const EdgeInsets.all(TicketSurSpacing.sm),
                  child: Column(
                    children: [
                      Text(
                        l10n.ticketsCount(value.items.length, value.total),
                        key: const Key('tickets-count'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (value.items.length < value.total)
                        TextButton(
                          key: const Key('tickets-more'),
                          onPressed: () => ref
                              .read(ticketListProvider(query).notifier)
                              .loadMore(),
                          child: Text(l10n.ticketsLoadMore),
                        ),
                    ],
                  ),
                );
              }
              final ticket = value.items[index];
              return _TicketTile(eventId: query.eventId, ticket: ticket);
            },
          ),
        ),
        AsyncError() => Center(
          key: const ValueKey('error'),
          child: TextButton(
            onPressed: () => ref.invalidate(ticketListProvider(query)),
            child: Text('${l10n.setupLoadError} ${l10n.orgRetry}'),
          ),
        ),
        _ => const SkeletonList(key: ValueKey('loading'), count: 5),
      },
    );
  }
}

class _TicketTile extends StatelessWidget {
  const new({required this.eventId, required this.ticket});

  final String eventId;
  final TicketSummary ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = ticketStatusStyle(ticket.status);
    final detail = switch (ticket) {
      TicketSummary(status: TicketStatus.redeemed, :final redeemedAt?) =>
        l10n.ticketRedeemedAt(
          formatLocalDateTime(redeemedAt),
          ticket.redeemedCheckpoint ?? '',
        ),
      TicketSummary(status: TicketStatus.revoked, :final revokedAt?) =>
        l10n.ticketRevokedAt(formatLocalDateTime(revokedAt)),
      _ => l10n.ticketIssuedAt(formatLocalDateTime(ticket.issuedAt)),
    };
    final summary = [
      if (ticket.holder.name != null) ticket.reference,
      ticket.categoryName,
      ticketStatusLabel(l10n, ticket.status),
    ].join(' · ');
    return PressableScale(
      child: Card(
        key: Key('ticket-${ticket.id}'),
        child: ListTile(
          leading: Icon(style.icon, color: style.color),
          // Ticket nominatif : le nom d'abord, la référence ensuite.
          title: Text(
            ticket.holder.name ?? ticket.reference,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: ticket.holder.name == null ? 1 : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          subtitle: Text('$summary\n$detail'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(
            AppRoutes.ticketDetail(eventId, ticket.id),
            extra: ticket,
          ),
        ),
      ),
    );
  }
}
