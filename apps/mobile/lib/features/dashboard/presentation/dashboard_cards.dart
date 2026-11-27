// Partie de `event_dashboard_page.dart` (découpage du lot 4-9) :
// cartes de détail (refus, catégories, portes, contrôleurs).
part of 'event_dashboard_page.dart';

class _RefusalsCard extends StatelessWidget {
  const new({required this.scans});

  final ScanCounts scans;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final refusals = scans.refusals;
    final peak = refusals.first.value;
    return DashboardSectionCard(
      key: const Key('dashboard-refusals'),
      icon: Icons.block_rounded,
      title: l10n.dashboardRefusalsTitle,
      child: Column(
        children: [
          for (final MapEntry(key: result, value: count) in refusals)
            DashboardBarRow(
              key: Key('dashboard-refusal-${result.wireName}'),
              label: result == ScanResult.unavailable
                  ? l10n.dashboardOtherReason
                  : verdictReason(l10n, result),
              trailing: formatCount(count),
              value: count / peak,
              color: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  const new({required this.categories});

  final List<CategoryStats> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DashboardSectionCard(
      key: const Key('dashboard-categories'),
      icon: Icons.confirmation_number_rounded,
      title: l10n.dashboardCategoriesTitle,
      child: Column(
        children: [
          for (final category in categories)
            DashboardBarRow(
              key: Key('dashboard-category-${category.id}'),
              label: category.name,
              trailing: formatPercent(category.attendance),
              detail: [
                if (category.isInvitation) l10n.categoryInvitationBadge,
                l10n.dashboardCategoryLine(category.admitted, category.issued),
                if (category.capacity case final quota?)
                  l10n.dashboardQuota(quota),
              ].join(' · '),
              value: category.attendance,
              // Invitations en orange vif, comme sur le ticket.
              color: category.isInvitation
                  ? TicketSurColors.spark
                  : context.palette.accentText,
            ),
        ],
      ),
    );
  }
}

class _CheckpointsCard extends StatelessWidget {
  const new({required this.checkpoints, required this.zone});

  final List<CheckpointStats> checkpoints;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return DashboardSectionCard(
      key: const Key('dashboard-checkpoints'),
      icon: Icons.door_front_door_rounded,
      title: l10n.dashboardCheckpointsTitle,
      child: Column(
        children: [
          for (final checkpoint in checkpoints)
            ListTile(
              key: Key('dashboard-checkpoint-${checkpoint.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.door_front_door_rounded,
                color: checkpoint.active ? scheme.primary : scheme.outline,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      checkpoint.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!checkpoint.active) ...[
                    const SizedBox(width: TicketSurSpacing.xs),
                    _Badge(label: l10n.dashboardCheckpointInactive),
                  ],
                ],
              ),
              subtitle: Text(
                [
                  l10n.dashboardCheckpointLine(
                    checkpoint.admitted,
                    checkpoint.refused,
                  ),
                  if (checkpoint.lastAt case final at?)
                    l10n.dashboardLastScan(formatClock(zone, at))
                  else
                    l10n.dashboardNoScan,
                ].join('\n'),
              ),
              isThreeLine: true,
            ),
        ],
      ),
    );
  }
}

class _ControllersCard extends StatelessWidget {
  const new({required this.controllers, required this.zone});

  final List<ControllerStats> controllers;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DashboardSectionCard(
      key: const Key('dashboard-controllers'),
      icon: Icons.badge_rounded,
      title: l10n.dashboardControllersTitle,
      child: Column(
        children: [
          for (final controller in controllers)
            ListTile(
              key: Key('dashboard-controller-${controller.userId}'),
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Text(
                  controller.displayName.isEmpty
                      ? '?'
                      : controller.displayName.characters.first.toUpperCase(),
                ),
              ),
              title: Text(controller.displayName),
              subtitle: Text(
                [
                  l10n.dashboardCheckpointLine(
                    controller.accepted,
                    controller.refused,
                  ),
                  if (controller.lastAt case final at?)
                    l10n.dashboardLastScan(formatClock(zone, at)),
                ].join(' · '),
              ),
            ),
        ],
      ),
    );
  }
}

class DashboardSectionCard extends StatelessWidget {
  const new({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TikeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon case final glyph?) ...[
                Icon(glyph, size: 22, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          if (subtitle case final text?)
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: TicketSurSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class DashboardBarRow extends StatelessWidget {
  const new({
    required this.label,
    required this.trailing,
    required this.value,
    required this.color,
    this.detail,
    super.key,
  });

  final String label;
  final String trailing;
  final String? detail;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TicketSurSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  trailing,
                  textAlign: TextAlign.end,
                  style: textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.xxs),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
            duration: TicketSurMotion.reduced(context)
                ? Duration.zero
                : const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, current, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current,
                minHeight: 8,
                color: color,
                backgroundColor: track,
              ),
            ),
          ),
          if (detail case final text?) ...[
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(text, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(TicketSurRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TicketSurSpacing.xs,
          vertical: 2,
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Formats
// -----------------------------------------------------------------------------

/// Recettes probables et pertes probables évitées (ADR 0056), sur les prix
/// indicatifs des catégories.
class _MoneyCard extends StatelessWidget {
  const new({required this.money});

  final DashboardMoney money;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    final rows = [
      for (final c in money.categories)
        if (!c.isInvitation &&
            c.price != null &&
            (c.admitted > 0 || c.refused > 0))
          c,
    ];
    final peak = rows.fold<int>(
      0,
      (top, c) => math.max(top, (c.revenue ?? 0) + (c.avoided ?? 0)),
    );
    final notes = [
      l10n.dashboardMoneyBasis(money.revenueTickets, money.avoidedTickets),
      if (money.revenueUnpriced > 0)
        l10n.dashboardMoneyRevenueUnpriced(money.revenueUnpriced),
      if (money.avoidedUnpriced > 0)
        l10n.dashboardMoneyAvoidedUnpriced(money.avoidedUnpriced),
      if (money.unknownRefusals > 0)
        l10n.dashboardMoneyUnknown(money.unknownRefusals),
    ];
    return DashboardSectionCard(
      key: const Key('dashboard-money'),
      icon: Icons.payments_rounded,
      title: l10n.dashboardMoneyTitle,
      subtitle: l10n.dashboardMoneySubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (money.unpriced)
            Padding(
              padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
              child: TintedBanner(
                key: const Key('dashboard-money-no-price'),
                tint: tints.amber,
                icon: Icons.sell_rounded,
                title: l10n.dashboardMoneyNoPrice,
              ),
            ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatTile(
                    key: const Key('dashboard-money-revenue'),
                    tint: tints.green,
                    icon: Icons.trending_up_rounded,
                    value: formatFcfa(l10n, money.revenue),
                    label: l10n.dashboardMoneyRevenue,
                  ),
                ),
                const SizedBox(width: TikeoSizes.cardGap),
                Expanded(
                  child: StatTile(
                    key: const Key('dashboard-money-avoided'),
                    tint: tints.amber,
                    icon: Icons.shield_rounded,
                    value: formatFcfa(l10n, money.avoided),
                    label: l10n.dashboardMoneyAvoided,
                  ),
                ),
              ],
            ),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: TicketSurSpacing.sm),
            for (final c in rows)
              DashboardBarRow(
                key: Key('dashboard-money-category-${c.id}'),
                label: c.name,
                trailing: formatFcfa(l10n, c.revenue ?? 0),
                detail: [
                  l10n.dashboardMoneyCategoryEntries(
                    c.admitted,
                    formatFcfa(l10n, c.price!),
                  ),
                  if (c.refused > 0)
                    l10n.dashboardMoneyCategoryAvoided(
                      c.refused,
                      formatFcfa(l10n, c.avoided ?? 0),
                    ),
                ].join(' · '),
                value: peak == 0
                    ? 0
                    : ((c.revenue ?? 0) + (c.avoided ?? 0)) / peak,
                color: context.palette.accentText,
              ),
          ],
          for (final note in notes) ...[
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(note, style: muted),
          ],
        ],
      ),
    );
  }
}
