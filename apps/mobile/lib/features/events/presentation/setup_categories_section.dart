// Partie de `event_setup_sections.dart` (découpage du lot 4-9) :
// section des catégories.
part of 'event_setup_sections.dart';

/// Catégories de tickets d'un événement, avec quotas et compteurs.
class CategoriesSection extends ConsumerWidget {
  const new({required this.event, super.key});

  final TicketEvent event;

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref, [
    TicketCategory? category,
  ]) async {
    final l10n = context.l10n;
    final controller = ref.read(categoriesProvider(event.id).notifier);
    final toast = Toaster.of(context);
    final result = await showSetupSheet(
      context,
      title: category == null ? l10n.categoryNewTitle : l10n.categoryEditTitle,
      nameLabel: l10n.categoryNameLabel,
      nameHint: l10n.categoryNameHint,
      initialName: category?.name ?? '',
      withCapacity: true,
      initialCapacity: category?.capacity,
      initialInvitation: category?.isInvitation ?? false,
      withPrice: true,
      initialPrice: category?.indicativePrice,
      withEntries: true,
      initialEntryPolicy: category?.entryPolicy ?? EntryPolicy.single,
      initialMaxEntries: category?.maxEntries,
      // Règle figée dès qu'un ticket de la catégorie est entré.
      entriesLocked: (category?.redeemed ?? 0) > 0,
      submitLabel: category == null ? l10n.setupAdd : l10n.setupSave,
      onSubmit: (values) => category == null
          ? controller.create(
              values.name,
              values.capacity,
              isInvitation: values.invitation,
              price: values.price,
              entryPolicy: values.entryPolicy,
              maxEntries: values.maxEntries,
            )
          : controller.edit(
              category.id,
              values.name,
              values.capacity,
              isInvitation: values.invitation,
              price: values.price,
              previousPrice: category.indicativePrice,
              entryPolicy: values.entryPolicy,
              maxEntries: values.maxEntries,
              previousPolicy: category.entryPolicy,
              previousMax: category.maxEntries,
            ),
      onDelete: category == null ? null : () => controller.delete(category.id),
      deleteTitle: l10n.categoryDeleteTitle,
      deleteBody: category == null
          ? null
          : l10n.categoryDeleteBody(category.name),
    );
    if (result == null) return;
    toast.success(
      result == SetupSheetResult.deleted
          ? l10n.categoryDeleted
          : l10n.categorySaved,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider(event.id));
    final editable = isConfigurable(event);
    return TikeoCard(
      key: const Key('categories-section'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: l10n.categoriesTitle,
            icon: Icons.confirmation_number_rounded,
            tint: context.tints.blue,
            addKey: const Key('category-add'),
            onAdd: editable ? () => unawaited(_openSheet(context, ref)) : null,
          ),
          _sectionBody(
            context,
            categories,
            empty: l10n.categoriesEmpty,
            emptyKey: 'categories-empty',
            onRetry: () => ref.invalidate(categoriesProvider(event.id)),
            builder: (items) {
              final issued = items.fold(0, (sum, c) => sum + c.issued);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final category in items)
                    _CategoryTile(
                      key: Key('category-${category.id}'),
                      category: category,
                      onTap: editable
                          ? () => unawaited(_openSheet(context, ref, category))
                          : null,
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TicketSurSpacing.xs,
                      ),
                      child: TextButton.icon(
                        key: const Key('categories-templates'),
                        onPressed: () => unawaited(
                          context.push(AppRoutes.ticketTemplates(event.id)),
                        ),
                        icon: const Icon(Icons.style_rounded),
                        label: Text(l10n.templatesEntry),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TicketSurSpacing.md,
                      0,
                      TicketSurSpacing.md,
                      TicketSurSpacing.md,
                    ),
                    child: AnimatedCount(
                      value: issued,
                      builder: (context, shown) => Text(
                        event.capacity == null
                            ? l10n.categoriesTotalUnlimited(shown)
                            : l10n.categoriesTotal(shown, event.capacity!),
                        key: const Key('categories-total'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const new({required this.category, this.onTap, super.key});

  final TicketCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fill = category.fill;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TicketSurSpacing.md,
          vertical: TicketSurSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _CategoryIcon(category: category),
                const SizedBox(width: TicketSurSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: theme.textTheme.titleSmall),
                      if (category.isInvitation)
                        Text(
                          l10n.categoryInvitationBadge,
                          key: Key('category-invitation-${category.id}'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.palette.accentText,
                          ),
                        ),
                      if (passBadge(l10n, category) case final badge?)
                        Text(
                          badge,
                          key: Key('category-pass-${category.id}'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.palette.accentText,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: TicketSurSpacing.xs),
                Flexible(
                  child: Text(
                    category.capacity == null
                        ? l10n.categoryNoQuota
                        : l10n.categoryQuota(category.capacity!),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            if (fill != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fill),
                duration: TicketSurMotion.reduced(context)
                    ? Duration.zero
                    : TicketSurMotion.page,
                curve: TicketSurMotion.standard,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: value, minHeight: 6),
                ),
              ),
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(
              l10n.categoryCounts(category.issued, category.redeemed),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mention « pass » d'une catégorie à plusieurs entrées, `null` sinon.
String? passBadge(AppLocalizations l10n, TicketCategory category) =>
    switch (category.entryPolicy) {
      EntryPolicy.single => null,
      EntryPolicy.perDay => l10n.categoryPassDaily,
      EntryPolicy.limited => l10n.categoryPassEntries(
        category.maxEntries ?? minPassEntries,
      ),
    };

// ---------------------------------------------------------------------------
// Portes (S21, EVT-04)
// ---------------------------------------------------------------------------

/// Rond de la catégorie : VIP dorée, invitations saumon, sinon bleue.
class _CategoryIcon extends StatelessWidget {
  const new({required this.category});

  final TicketCategory category;

  @override
  Widget build(BuildContext context) {
    final tints = context.tints;
    final vip = category.name.toUpperCase().contains('VIP');
    final (tint, icon) = category.isInvitation
        ? (tints.salmon, Icons.card_giftcard_rounded)
        : vip
        ? (tints.vip, Icons.workspace_premium_rounded)
        : (tints.blue, Icons.confirmation_number_rounded);
    return CircleAvatar(
      radius: 20,
      backgroundColor: tint.background,
      child: Icon(icon, size: 20, color: tint.icon),
    );
  }
}
