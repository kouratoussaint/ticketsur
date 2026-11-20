import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/animated_count.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/features/ticket_send/presentation/send_copy.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/issue_sheet.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_share.dart';
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

  /// Type de ticket choisi (catégorie) ; `null` : tous les types.
  String? _categoryId;
  Timer? _debounce;

  /// Sélection multiple (appui long) : tickets choisis, par identifiant.
  final Map<String, TicketSummary> _selection = {};
  bool _busy = false;

  bool get _selecting => _selection.isNotEmpty;

  void _toggle(TicketSummary ticket) => setState(() {
    if (_selection.remove(ticket.id) == null) _selection[ticket.id] = ticket;
  });

  void _clearSelection() => setState(_selection.clear);

  void _selectAll(TicketQuery query) {
    final items = ref.read(ticketListProvider(query)).value?.items ?? const [];
    setState(() {
      for (final t in items) {
        _selection[t.id] = t;
      }
    });
  }

  List<String> get _validIds => [
    for (final t in _selection.values)
      if (t.status == TicketStatus.issued) t.id,
  ];

  Future<void> _sharePdf(TicketEvent event) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final ids = _validIds;
    if (ids.isEmpty) {
      toast.info(l10n.ticketsBulkNothingValid);
      return;
    }
    setState(() => _busy = true);
    try {
      final secrets = await ref.read(ticketActionsProvider).ensureSecrets(ids);
      if (!mounted) return;
      await shareTicketsPdf(
        context,
        ref,
        event: event,
        tickets: [for (final id in ids) ?secrets[id]],
      );
      _clearSelection();
    } on Object {
      toast.error(l10n.ticketsBulkError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(TicketEvent event) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final ids = _validIds;
    if (ids.isEmpty) {
      toast.info(l10n.ticketsBulkNothingValid);
      return;
    }
    final reason = await showBulkRevokeSheet(context, count: ids.length);
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final count = await ref
          .read(ticketActionsProvider)
          .revokeMany(event.id, ids, reason: reason.isEmpty ? null : reason);
      toast.success(l10n.ticketsBulkRevoked(count));
      _clearSelection();
    } on Object {
      toast.error(l10n.ticketsBulkError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
    final query = event == null
        ? null
        : (
            eventId: event.id,
            status: _status,
            search: _search,
            categoryId: _categoryId,
          );

    return PopScope(
      // Retour : quitte d'abord la sélection.
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: _selecting && event != null && query != null
            ? AppBar(
                key: const Key('tickets-selection-bar'),
                leading: IconButton(
                  key: const Key('selection-close'),
                  tooltip: l10n.selectionClose,
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close_rounded),
                ),
                title: Text(l10n.selectionCount(_selection.length)),
                actions: [
                  IconButton(
                    key: const Key('selection-all'),
                    tooltip: l10n.selectionAll,
                    onPressed: _busy ? null : () => _selectAll(query),
                    icon: const Icon(Icons.select_all_rounded),
                  ),
                  IconButton(
                    key: const Key('tickets-bulk-pdf'),
                    tooltip: l10n.ticketsBulkPdf,
                    onPressed: _busy ? null : () => unawaited(_sharePdf(event)),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                  ),
                  IconButton(
                    key: const Key('tickets-bulk-revoke'),
                    tooltip: l10n.ticketsBulkRevoke,
                    onPressed: _busy ? null : () => unawaited(_revoke(event)),
                    icon: const Icon(Icons.block_rounded),
                  ),
                ],
              )
            : AppBar(
                title: Text(l10n.navTickets),
                actions: [
                  if (event != null && canIssue(event))
                    IconButton(
                      key: const Key('tickets-send'),
                      tooltip: l10n.sendBatchTitle,
                      onPressed: () => unawaited(
                        context.push(AppRoutes.ticketSend(event.id)),
                      ),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  if (event != null && canIssue(event))
                    IconButton(
                      key: const Key('tickets-import'),
                      tooltip: l10n.importEntry,
                      onPressed: () => unawaited(
                        context.push(AppRoutes.ticketImport(event.id)),
                      ),
                      icon: const Icon(Icons.upload_file_rounded),
                    ),
                ],
              ),
        floatingActionButton: event != null && canIssue(event) && !_selecting
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
                            child: Text(
                              e.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (id) {
                        setState(() {
                          _categoryId = null;
                          _selection.clear();
                        });
                        ref.read(selectedTicketEventProvider.notifier).eventId =
                            id;
                      },
                    ),
                  ),
                  _Summary(eventId: event.id),
                  _TypeChips(
                    eventId: event.id,
                    selected: _categoryId,
                    onSelected: (id) => setState(() {
                      _categoryId = id;
                      _selection.clear();
                    }),
                  ),
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
                              key: Key(
                                'tickets-filter-${status?.name ?? 'all'}',
                              ),
                              label: Text(label),
                              selected: _status == status,
                              onSelected: (_) => setState(() {
                                _status = status;
                                _selection.clear();
                              }),
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
                      query: query!,
                      selection: _selection.keys.toSet(),
                      onToggle: _toggle,
                    ),
                  ),
                ],
              ),
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

/// Regroupement par type de ticket : une pastille par catégorie, avec le
/// nombre de tickets émis.
class _TypeChips extends ConsumerWidget {
  const new({
    required this.eventId,
    required this.selected,
    required this.onSelected,
  });

  final String eventId;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider(eventId)).value ?? const [];
    if (categories.length < 2) return const SizedBox.shrink();
    return SingleChildScrollView(
      key: const Key('tickets-types'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        TicketSurSpacing.xs,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: TicketSurSpacing.xs),
            child: FilterChip(
              key: const Key('tickets-type-all'),
              label: Text(l10n.ticketsTypeAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: TicketSurSpacing.xs),
              child: FilterChip(
                key: Key('tickets-type-${category.id}'),
                avatar: category.isInvitation
                    ? const Icon(Icons.card_giftcard_rounded, size: 18)
                    : null,
                label: Text(
                  l10n.ticketsTypeCount(category.name, category.issued),
                ),
                selected: selected == category.id,
                onSelected: (_) => onSelected(category.id),
              ),
            ),
        ],
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
  const new({
    required this.query,
    required this.selection,
    required this.onToggle,
  });

  final TicketQuery query;
  final Set<String> selection;
  final ValueChanged<TicketSummary> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final page = ref.watch(ticketListProvider(query));
    return AnimatedSwitcher(
      duration: TicketSurMotion.reduced(context)
          ? Duration.zero
          : TicketSurMotion.medium,
      child: switch (page) {
        AsyncData(:final value) when value.items.isEmpty => EmptyState(
          key: const ValueKey('empty'),
          icon:
              query.status == null &&
                  query.search.isEmpty &&
                  query.categoryId == null
              ? Icons.confirmation_number_rounded
              : Icons.search_off_rounded,
          title:
              query.status == null &&
                  query.search.isEmpty &&
                  query.categoryId == null
              ? l10n.ticketsEmpty
              : l10n.ticketsEmptyFilter,
          titleKey: const Key('tickets-empty'),
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
              return _TicketTile(
                eventId: query.eventId,
                ticket: ticket,
                selecting: selection.isNotEmpty,
                selected: selection.contains(ticket.id),
                onToggle: () => onToggle(ticket),
              );
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
  const new({
    required this.eventId,
    required this.ticket,
    required this.selecting,
    required this.selected,
    required this.onToggle,
  });

  final String eventId;
  final TicketSummary ticket;
  final bool selecting;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = ticketStatusStyle(ticket.status, context.palette);
    final detail = switch (ticket) {
      TicketSummary(status: TicketStatus.redeemed, :final redeemedAt?) =>
        l10n.ticketRedeemedAt(
          formatLocalDateTime(redeemedAt),
          ticket.redeemedCheckpoint ?? '',
        ),
      TicketSummary(status: TicketStatus.revoked, :final revokedAt?) =>
        l10n.ticketRevokedAt(formatLocalDateTime(revokedAt)),
      TicketSummary(lastDelivery: (:final channel, :final at)?) =>
        l10n.ticketSentVia(
          channelLabel(l10n, channel),
          formatLocalDateTime(at),
        ),
      _ => l10n.ticketIssuedAt(formatLocalDateTime(ticket.issuedAt)),
    };
    final summary = [
      if (ticket.holder.name != null) ticket.reference,
      if (ticket.isInvitation)
        l10n.ticketInvitationOf(ticket.categoryName)
      else
        ticket.categoryName,
      ticketStatusLabel(l10n, ticket.status),
    ].join(' · ');
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      child: Card(
        key: Key('ticket-${ticket.id}'),
        color: selected ? scheme.secondaryContainer : null,
        child: ListTile(
          selected: selected,
          onLongPress: onToggle,
          leading: selecting
              ? Checkbox(
                  key: Key('ticket-check-${ticket.id}'),
                  value: selected,
                  onChanged: (_) => onToggle(),
                )
              : Icon(style.icon, color: style.color),
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
          trailing: selecting ? null : const Icon(Icons.chevron_right_rounded),
          onTap: selecting
              ? onToggle
              : () => context.push(
                  AppRoutes.ticketDetail(eventId, ticket.id),
                  extra: ticket,
                ),
        ),
      ),
    );
  }
}

/// Confirmation d'annulation groupée, avec motif facultatif. Renvoie le
/// motif (éventuellement vide), ou `null` si l'on renonce.
Future<String?> showBulkRevokeSheet(
  BuildContext context, {
  required int count,
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _BulkRevokeSheet(count: count),
);

class _BulkRevokeSheet extends StatefulWidget {
  const new({required this.count});

  final int count;

  @override
  State<_BulkRevokeSheet> createState() => _BulkRevokeSheetState();
}

class _BulkRevokeSheetState extends State<_BulkRevokeSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TicketSurSpacing.lg,
          0,
          TicketSurSpacing.lg,
          TicketSurSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.ticketsBulkRevokeTitle(widget.count),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            Text(l10n.ticketsBulkRevokeBody),
            const SizedBox(height: TicketSurSpacing.md),
            TextField(
              key: const Key('tickets-bulk-reason'),
              controller: _reason,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.ticketRevokeReason),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            FilledButton(
              key: const Key('tickets-bulk-revoke-confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
              child: Text(l10n.ticketsBulkRevokeTitle(widget.count)),
            ),
          ],
        ),
      ),
    );
  }
}
