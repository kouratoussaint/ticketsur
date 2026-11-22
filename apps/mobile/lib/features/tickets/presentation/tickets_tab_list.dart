// Partie de `tickets_tab_page.dart` (découpage du lot 4-9) :
// liste des tickets.
part of 'tickets_tab_page.dart';

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
        query.categoryId == null &&
        query.batchId == null;
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
      if (ticket.batchNumber case final n?) l10n.batchLabel(n),
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
