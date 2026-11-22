// Partie de `tickets_tab_page.dart` (découpage du lot 4-9) :
// choix de l'événement, types et résumé.
part of 'tickets_tab_page.dart';

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
