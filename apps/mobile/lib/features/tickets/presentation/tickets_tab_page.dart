import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/remembered_filters.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/animated_count.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/status_chip.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/billing_block_sheet.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/features/ticket_send/presentation/send_copy.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/batches_sheet.dart';
import 'package:ticketsur/features/tickets/presentation/issue_sheet.dart';
import 'package:ticketsur/features/tickets/presentation/print_sheet.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_share.dart';
import 'package:ticketsur/l10n/l10n.dart';

part 'tickets_tab_header.dart';
part 'tickets_tab_list.dart';
part 'tickets_bulk_revoke.dart';

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
  /// Statut affiché (mémorisé).
  late TicketStatus? _status = enumByName(
    TicketStatus.values,
    ref.read(rememberedFiltersProvider).read('tickets.status'),
  );
  String _search = '';

  /// Type de ticket choisi (catégorie) ; `null` : tous les types. Mémorisé
  /// avec son événement (`événement:type`).
  late String? _categoryId = _rememberedCategory(
    ref.read(selectedTicketEventProvider),
  );

  String? _rememberedCategory(String? eventId) {
    final saved = ref.read(rememberedFiltersProvider).read('tickets.type');
    if (eventId == null || saved == null) return null;
    final (event, type) = switch (saved.split(':')) {
      [final e, final t] => (e, t),
      _ => ('', ''),
    };
    return event == eventId ? type : null;
  }

  void _rememberCategory(String eventId, String? categoryId) => ref
      .read(rememberedFiltersProvider)
      .write(
        'tickets.type',
        categoryId == null ? null : '$eventId:$categoryId',
      );
  Timer? _debounce;

  /// Lot de génération affiché ; `null` : tous les lots.
  TicketBatch? _batch;

  /// Sélection multiple (appui long) : tickets choisis, par identifiant,
  /// avec leur statut.
  final Map<String, TicketStatus> _selection = {};
  bool _busy = false;

  bool get _selecting => _selection.isNotEmpty;

  void _toggle(TicketSummary ticket) => setState(() {
    if (_selection.remove(ticket.id) == null) {
      _selection[ticket.id] = ticket.status;
    }
  });

  void _clearSelection() => setState(_selection.clear);

  /// Tout sélectionner : le lot entier quand un lot est affiché (même les
  /// tickets pas encore chargés), sinon les tickets chargés.
  Future<void> _selectAll(TicketQuery query) async {
    if (_batch case final batch?) {
      await _selectBatch(batch);
      return;
    }
    final items = ref.read(ticketListProvider(query)).value?.items ?? const [];
    setState(() {
      for (final t in items) {
        _selection[t.id] = t.status;
      }
    });
  }

  /// Tickets d'un lot, lus sur le serveur (identifiant et statut).
  Future<List<(String, TicketStatus)>?> _batchTickets(TicketBatch batch) async {
    final toast = Toaster.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      return await ref.read(ticketRepositoryProvider).batchTickets(batch.id);
    } on Object {
      toast.error(l10n.batchesError);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectBatch(TicketBatch batch) async {
    final tickets = await _batchTickets(batch);
    if (tickets == null || !mounted) return;
    setState(() {
      _batch = batch;
      for (final (id, status) in tickets) {
        _selection[id] = status;
      }
    });
  }

  Future<void> _openBatches(TicketEvent event) async {
    final picked = await showBatchesSheet(context, event.id);
    if (picked == null || !mounted) return;
    final (batch, action) = picked;
    switch (action) {
      case BatchAction.view:
        setState(() {
          _batch = batch;
          _selection.clear();
        });
      case BatchAction.select:
        _selection.clear();
        await _selectBatch(batch);
      case BatchAction.print:
        final tickets = await _batchTickets(batch);
        if (tickets == null || !mounted) return;
        await _sharePdf(
          event,
          sheet: true,
          ids: [
            for (final (id, status) in tickets)
              if (status == TicketStatus.issued) id,
          ],
        );
    }
  }

  List<String> get _validIds => [
    for (final MapEntry(key: id, value: status) in _selection.entries)
      if (status == TicketStatus.issued) id,
  ];

  /// PDF ou planche A4 des tickets valables de la sélection (ou de [ids]).
  Future<void> _sharePdf(
    TicketEvent event, {
    bool sheet = false,
    List<String>? ids,
  }) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final fromSelection = ids == null;
    ids ??= _validIds;
    if (ids.isEmpty) {
      toast.info(l10n.ticketsBulkNothingValid);
      return;
    }
    if (sheet &&
        !await billingAllows(ref, event.id, BillingOption.printSheet)) {
      return;
    }
    int? perPage;
    if (sheet) {
      if (!mounted) return;
      // Nombre de tickets par feuille A4 (#4).
      perPage = await showPrintSheet(context, count: ids.length);
      if (perPage == null || !mounted) return;
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
        sheet: sheet,
        perPage: perPage,
      );
      if (fromSelection) _clearSelection();
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
    // Demande de l'Accueil (« Entrés », « Émis ») : statut posé, type remis
    // à « tous ».
    ref.listen(ticketsStatusRequestProvider, (previous, next) {
      if (next == null) return;
      setState(() {
        _status = next.value;
        _categoryId = null;
      });
    });
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
    // Type mémorisé qui n'existe plus (catégorie supprimée) : tous les types.
    final categories = event == null
        ? null
        : ref.watch(categoriesProvider(event.id)).value;
    final categoryId =
        categories != null &&
            _categoryId != null &&
            !categories.any((c) => c.id == _categoryId)
        ? null
        : _categoryId;
    final query = event == null
        ? null
        : (
            eventId: event.id,
            status: _status,
            search: _search,
            categoryId: categoryId,
            batchId: _batch?.id,
          );

    final canIssueHere = event != null && canIssue(event);
    final header = TikeoHeroHeader(
      title: l10n.navTickets,
      subtitle: l10n.ticketsHeroSubtitle,
      illustration: TikeoIllustration.tickets,
      actions: [
        if (event != null)
          IconButton(
            key: const Key('tickets-batches'),
            tooltip: l10n.batchesTitle,
            color: TicketSurColors.white,
            onPressed: _busy ? null : () => unawaited(_openBatches(event)),
            icon: const Icon(Icons.layers_rounded),
          ),
        if (canIssueHere)
          IconButton(
            key: const Key('tickets-send'),
            tooltip: l10n.sendBatchTitle,
            color: TicketSurColors.white,
            onPressed: () => unawaited(
              pushIfBillingAllows(
                context,
                ref,
                event.id,
                BillingOption.bulkSend,
                AppRoutes.ticketSend(event.id),
              ),
            ),
            icon: const Icon(Icons.send_rounded),
          ),
        if (canIssueHere)
          IconButton(
            key: const Key('tickets-import'),
            tooltip: l10n.importEntry,
            color: TicketSurColors.white,
            onPressed: () => unawaited(
              pushIfBillingAllows(
                context,
                ref,
                event.id,
                BillingOption.import,
                AppRoutes.ticketImport(event.id),
              ),
            ),
            icon: const Icon(Icons.upload_file_rounded),
          ),
      ],
    );

    final picker = event == null
        ? const SizedBox.shrink()
        : _EventPicker(
            event: event,
            events: events,
            onChanged: (id) {
              setState(() {
                _categoryId = null;
                _batch = null;
                _selection.clear();
              });
              ref.read(selectedTicketEventProvider.notifier).eventId = id;
            },
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
                    onPressed: _busy
                        ? null
                        : () => unawaited(_selectAll(query)),
                    icon: const Icon(Icons.select_all_rounded),
                  ),
                  IconButton(
                    key: const Key('tickets-bulk-pdf'),
                    tooltip: l10n.ticketsBulkPdf,
                    onPressed: _busy ? null : () => unawaited(_sharePdf(event)),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                  ),
                  IconButton(
                    key: const Key('tickets-bulk-sheet'),
                    tooltip: l10n.ticketsBulkSheet,
                    onPressed: _busy
                        ? null
                        : () => unawaited(_sharePdf(event, sheet: true)),
                    icon: const Icon(Icons.print_rounded),
                  ),
                  IconButton(
                    key: const Key('tickets-bulk-revoke'),
                    tooltip: l10n.ticketsBulkRevoke,
                    onPressed: _busy ? null : () => unawaited(_revoke(event)),
                    icon: const Icon(Icons.block_rounded),
                  ),
                ],
              )
            : null,
        floatingActionButton: canIssueHere && !_selecting
            ? FloatingActionButton.extended(
                key: const Key('tickets-issue'),
                heroTag: 'tickets-issue',
                onPressed: () => showIssueSheet(context, event),
                icon: const Icon(Icons.add_card_rounded),
                label: Text(l10n.ticketsIssue),
              )
            : null,
        body: event == null || query == null
            ? ListView(
                children: [
                  header,
                  _NoEvent(loading: ref.watch(eventsProvider).isLoading),
                ],
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(ticketListProvider(query)),
                child: CustomScrollView(
                  // En-tête haut : les premières lignes sont construites
                  // d'emblée (lecture d'écran, tests).
                  scrollCacheExtent: const ScrollCacheExtent.pixels(1500),
                  slivers: [
                    SliverToBoxAdapter(
                      // En-tête et sélecteur dans une même colonne : la partie
                      // de la carte posée sur l'en-tête reste touchable.
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_selecting)
                            // Sélection : barre en haut, sélecteur gardé.
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                TikeoSizes.screenMargin,
                                TikeoSizes.cardGap,
                                TikeoSizes.screenMargin,
                                0,
                              ),
                              child: TikeoCard(
                                padding: const EdgeInsets.all(12),
                                child: picker,
                              ),
                            )
                          else ...[
                            header,
                            TikeoOverlapCard(
                              padding: const EdgeInsets.all(12),
                              child: picker,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(child: _Summary(eventId: event.id)),
                    SliverToBoxAdapter(
                      child: _TypeChips(
                        eventId: event.id,
                        selected: _categoryId,
                        onSelected: (id) {
                          _rememberCategory(event.id, id);
                          setState(() {
                            _categoryId = id;
                            _selection.clear();
                          });
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TikeoSizes.screenMargin,
                        ),
                        child: Row(
                          children: [
                            if (_batch case final batch?)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InputChip(
                                  key: const Key('tickets-batch-filter'),
                                  avatar: const Icon(
                                    Icons.layers_rounded,
                                    size: 18,
                                  ),
                                  label: Text(l10n.batchLabel(batch.number)),
                                  onPressed: _busy
                                      ? null
                                      : () => unawaited(_openBatches(event)),
                                  onDeleted: _busy
                                      ? null
                                      : () => setState(() {
                                          _batch = null;
                                          _selection.clear();
                                        }),
                                  deleteButtonTooltipMessage: l10n.batchClear,
                                ),
                              ),
                            for (final (status, label) in [
                              (null, l10n.ticketsFilterAll),
                              (TicketStatus.issued, l10n.ticketsFilterValid),
                              (
                                TicketStatus.redeemed,
                                l10n.ticketsFilterRedeemed,
                              ),
                              (TicketStatus.revoked, l10n.ticketsFilterRevoked),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  key: Key(
                                    'tickets-filter-${status?.name ?? 'all'}',
                                  ),
                                  label: Text(label),
                                  selected: _status == status,
                                  showCheckmark: false,
                                  shape: const StadiumBorder(),
                                  selectedColor: _tabColor(context),
                                  labelStyle: TextStyle(
                                    color: _status == status
                                        ? TicketSurColors.white
                                        : null,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  onSelected: (_) {
                                    ref
                                        .read(rememberedFiltersProvider)
                                        .write('tickets.status', status?.name);
                                    setState(() {
                                      _status = status;
                                      _selection.clear();
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        TikeoSizes.screenMargin,
                        8,
                        TikeoSizes.screenMargin,
                        8,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: TikeoSearchBar(
                          fieldKey: const Key('tickets-search'),
                          hint: l10n.ticketsSearchHint,
                          onChanged: _onSearch,
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                    ),
                    _TicketList(
                      query: query,
                      selection: _selection.keys.toSet(),
                      onToggle: _toggle,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
