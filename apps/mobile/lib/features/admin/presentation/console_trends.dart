import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/widgets/tabular_figures.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/l10n/l10n.dart';

String dailyMetricLabel(AppLocalizations l10n, DailyMetric metric) =>
    switch (metric) {
      DailyMetric.accounts => l10n.consoleTrendAccounts,
      DailyMetric.organizations => l10n.consoleTrendOrganizations,
      DailyMetric.events => l10n.consoleTrendEvents,
      DailyMetric.tickets => l10n.consoleTrendTickets,
      DailyMetric.entries => l10n.consoleTrendEntries,
    };

/// Vue d'ensemble : courbe des 30 derniers jours, une mesure à la fois.
class ConsoleTrendsCard extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleTrendsCard> createState() => _ConsoleTrendsCardState();
}

class _ConsoleTrendsCardState extends ConsumerState<ConsoleTrendsCard> {
  DailyMetric _metric = DailyMetric.accounts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final stats = ref.watch(adminDailyStatsProvider);
    return TikeoCard(
      key: const Key('console-trends'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.consoleTrendsTitle, style: textTheme.titleMedium),
          const SizedBox(height: TicketSurSpacing.sm),
          Wrap(
            spacing: TicketSurSpacing.xs,
            runSpacing: TicketSurSpacing.xs,
            children: [
              for (final metric in DailyMetric.values)
                ChoiceChip(
                  key: Key('console-trend-${metric.name}'),
                  label: Text(dailyMetricLabel(l10n, metric)),
                  selected: metric == _metric,
                  onSelected: (_) => setState(() => _metric = metric),
                ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.md),
          switch (stats) {
            AsyncData(:final value) when value.isNotEmpty => _Chart(
              stats: value,
              metric: _metric,
            ),
            AsyncData() => const SizedBox.shrink(),
            AsyncError() => Row(
              key: const Key('console-trends-error'),
              children: [
                Expanded(child: Text(l10n.consoleTrendsError)),
                TextButton(
                  onPressed: () => ref.invalidate(adminDailyStatsProvider),
                  child: Text(l10n.consoleRetry),
                ),
              ],
            ),
            _ => const SizedBox(
              height: 140,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const new({required this.stats, required this.metric});

  final List<DailyStat> stats;
  final DailyMetric metric;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final values = [for (final s in stats) s.valueOf(metric)];
    final total = values.fold<int>(0, (a, b) => a + b);
    final today = values.last;
    final number = NumberFormat.decimalPattern(appLocaleTag);
    final day = DateFormat.MMMd(appLocaleTag);
    final color = context.tints.mint.icon;
    final label = dailyMetricLabel(l10n, metric);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TabularFigures(
                child: Text(
                  l10n.consoleTrendTotal(total, stats.length),
                  key: const Key('console-trend-total'),
                  style: textTheme.titleSmall,
                ),
              ),
            ),
            Flexible(
              child: Text(
                l10n.consoleTrendToday(number.format(today)),
                key: const Key('console-trend-today'),
                textAlign: TextAlign.end,
                style: textTheme.bodySmall?.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        Semantics(
          label: l10n.consoleTrendSemantics(label, total, stats.length),
          child: ExcludeSemantics(
            child: SizedBox(
              key: const Key('console-trend-chart'),
              height: 120,
              child: CustomPaint(
                painter: _BarsPainter(
                  values: values,
                  color: color,
                  baseline: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: TicketSurSpacing.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                day.format(stats.first.day),
                style: textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: TicketSurSpacing.xs),
            Flexible(
              child: Text(
                day.format(stats.last.day),
                style: textTheme.bodySmall,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Barres d'une série quotidienne, la plus haute à pleine hauteur.
class _BarsPainter extends CustomPainter {
  new({required this.values, required this.color, required this.baseline});

  final List<int> values;
  final Color color;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = baseline
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      line,
    );
    if (values.isEmpty) return;
    final top = values.reduce((a, b) => a > b ? a : b);
    if (top == 0) return;
    final slot = size.width / values.length;
    final width = (slot * 0.7).clamp(1.0, 14.0);
    final bar = Paint()..color = color;
    for (final (index, value) in values.indexed) {
      if (value == 0) continue;
      final height = (size.height - 2) * value / top;
      final left = slot * index + (slot - width) / 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, size.height - 1 - height, width, height),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        bar,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values || old.color != color || old.baseline != baseline;
}
