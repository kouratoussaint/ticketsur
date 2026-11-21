import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
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
import 'package:ticketsur/features/tickets/presentation/issue_sheet.dart';
import 'package:ticketsur/features/tickets/presentation/print_sheet.dart';
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

  Future<void> _sharePdf(TicketEvent event, {bool sheet = false}) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final ids = _validIds;
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

    final canIssueHere = event != null && canIssue(event);
    final header = TikeoHeroHeader(
      title: l10n.navTickets,
      subtitle: l10n.ticketsHeroSubtitle,
      illustration: TikeoIllustration.tickets,
      actions: [
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
                        onSelected: (id) => setState(() {
                          _categoryId = id;
                          _selection.clear();
                        }),
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
                                  onSelected: (_) => setState(() {
                                    _status = status;
                                    _selection.clear();
                                  }),
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

/// Onglet de statut actif : Menthe profonde (texte blanc), plus clair en
/// sombre.
Color _tabColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF00846F)
    : TicketSurColors.mintDeep;

/// Sélecteur d'événement : vignette et liste déroulante.
class _EventPicker extends StatelessWidget {
  const new({
    required this.event,
    required this.events,
    required this.onChanged,
  });

  final TicketEvent event;
  final List<TicketEvent> events;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        SizedBox(
          width: 64,
          height: 52,
          child: EventCover.forEvent(
            event,
            aspectRatio: 64 / 52,
            borderRadius: BorderRadius.circular(TikeoRadii.thumb),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: const Key('tickets-event'),
            initialValue: event.id,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.ticketsEventLabel,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            items: [
              for (final e in events)
                DropdownMenuItem(
                  value: e.id,
                  child: Text(
                    e.title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _NoEvent extends StatelessWidget {
  const new({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(TikeoSizes.screenMargin),
        child: Shimmer(child: SkeletonBox(height: 120, radius: 20)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(TicketSurSpacing.xl),
      child: FadeSlideIn(
        child: Column(
          children: [
            const TikeoIllustrationView(TikeoIllustration.noTickets),
            const SizedBox(height: TicketSurSpacing.lg),
            Text(
              l10n.ticketsNoEventTitle,
              key: const Key('tickets-no-event'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
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
        TikeoSizes.screenMargin,
        0,
        TikeoSizes.screenMargin,
        8,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              key: const Key('tickets-type-all'),
              label: Text(l10n.ticketsTypeAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: Key('tickets-type-${category.id}'),
                avatar: category.isInvitation
                    ? const Icon(Icons.card_giftcard_rounded, size: 18)
                    : category.name.toUpperCase().contains('VIP')
                    ? const Icon(Icons.workspace_premium_rounded, size: 18)
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

/// Tickets émis et entrés de l'événement, dans une carte.
class _Summary extends ConsumerWidget {
  const new({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider(eventId)).value;
    if (categories == null) return const SizedBox(height: TikeoSizes.cardGap);
    final issued = categories.fold(0, (sum, c) => sum + c.issued);
    final redeemed = categories.fold(0, (sum, c) => sum + c.redeemed);
    final tint = context.tints.blue;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TikeoSizes.screenMargin,
        TikeoSizes.cardGap,
        TikeoSizes.screenMargin,
        TikeoSizes.cardGap,
      ),
      child: TikeoCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_rounded,
                size: 22,
                color: tint.icon,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedCount(
                value: issued,
                builder: (context, shownIssued) => AnimatedCount(
                  value: redeemed,
                  builder: (context, shownRedeemed) => Text(
                    context.l10n.ticketsSummary(shownIssued, shownRedeemed),
                    key: const Key('tickets-summary'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste des tickets (sliver) : vide, erreur, chargement ou lignes.
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
    final unfiltered =
        query.status == null &&
        query.search.isEmpty &&
        query.categoryId == null;
    return switch (page) {
      AsyncData(:final value) when value.items.isEmpty => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 96),
          child: EmptyState(
            illustration: TikeoIllustration.noTickets,
            key: const ValueKey('empty'),
            icon: unfiltered
                ? Icons.confirmation_number_rounded
                : Icons.search_off_rounded,
            title: unfiltered ? l10n.ticketsEmpty : l10n.ticketsEmptyFilter,
            titleKey: const Key('tickets-empty'),
          ),
        ),
      ),
      AsyncData(:final value) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          TikeoSizes.screenMargin,
          0,
          TikeoSizes.screenMargin,
          96,
        ),
        sliver: SliverList.builder(
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TicketTile(
                eventId: query.eventId,
                ticket: ticket,
                selecting: selection.isNotEmpty,
                selected: selection.contains(ticket.id),
                onToggle: () => onToggle(ticket),
              ),
            );
          },
        ),
      ),
      AsyncError() => SliverToBoxAdapter(
        child: Center(
          key: const ValueKey('error'),
          child: TextButton(
            onPressed: () => ref.invalidate(ticketListProvider(query)),
            child: Text('${l10n.setupLoadError} ${l10n.orgRetry}'),
          ),
        ),
      ),
      _ => SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: TikeoSizes.screenMargin,
        ),
        sliver: SliverList.list(
          key: const ValueKey('loading'),
          children: [
            for (var i = 0; i < 5; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Shimmer(child: SkeletonBox(height: 84, radius: 16)),
              ),
          ],
        ),
      ),
    };
  }
}

/// Ligne d'un ticket : trait et pastille du statut, titulaire ou référence,
/// catégorie, dernière action ; appui long pour sélectionner.
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
    final tint = ticketStatusTint(ticket.status, context.tints);
    final style = ticketStatusStyle(ticket.status, context.tints);
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
    ].join(' · ');
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TikeoRadii.button),
        border: selected ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: TikeoListRow(
        key: Key('ticket-${ticket.id}'),
        stripe: style.color,
        leading: selecting
            ? Checkbox(
                key: Key('ticket-check-${ticket.id}'),
                value: selected,
                onChanged: (_) => onToggle(),
              )
            : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.background,
                  shape: BoxShape.circle,
                ),
                // Statut dans la pastille : ici, nominatif ou non.
                child: Icon(
                  ticket.holder.name == null
                      ? Icons.confirmation_number_rounded
                      : Icons.person_rounded,
                  color: tint.icon,
                ),
              ),
        // Ticket nominatif : le nom d'abord, la référence ensuite.
        title: ticket.holder.name ?? ticket.reference,
        lines: [summary, detail],
        badge: StatusChip(
          label: ticketStatusLabel(l10n, ticket.status),
          tone: StatusTone.neutral,
          tint: tint,
          icon: style.icon,
        ),
        chevron: !selecting,
        onLongPress: onToggle,
        onTap: selecting
            ? onToggle
            : () => context.push(
                AppRoutes.ticketDetail(eventId, ticket.id),
                extra: ticket,
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
