// Partie de `event_dashboard_page.dart` (découpage du lot 4-9) :
// courbe des entrées.
part of 'event_dashboard_page.dart';

class _TimelineCard extends StatelessWidget {
  const new({required this.data, required this.zone});

  final EventDashboard data;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final buckets = data.timeline;
    final step = data.stepMinutes;
    return DashboardSectionCard(
      key: const Key('dashboard-timeline'),
      icon: Icons.bar_chart_rounded,
      title: l10n.dashboardTimelineTitle,
      subtitle: step == null
          ? null
          : step < 60
          ? l10n.dashboardTimelineStepMinutes(step)
          : l10n.dashboardTimelineStepHours(step ~/ 60),
      child: buckets.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(
                vertical: TicketSurSpacing.md,
              ),
              child: Text(
                l10n.dashboardTimelineEmpty,
                key: const Key('dashboard-timeline-empty'),
                style: textTheme.bodyMedium,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TimelineChart(buckets: buckets, zone: zone),
                const SizedBox(height: TicketSurSpacing.sm),
                Wrap(
                  spacing: TicketSurSpacing.md,
                  runSpacing: TicketSurSpacing.xxs,
                  children: [
                    _Legend(
                      color: TicketSurColors.success,
                      label: l10n.dashboardLegendAdmitted,
                    ),
                    _Legend(
                      color: TicketSurColors.error,
                      label: l10n.dashboardLegendRefused,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _TimelineChart extends StatelessWidget {
  const new({required this.buckets, required this.zone});

  final List<TimelineBucket> buckets;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final peak = buckets.fold<int>(0, (m, b) => math.max(m, b.total));
    final first = formatClock(zone, buckets.first.at);
    final last = formatClock(zone, buckets.last.at);
    final accepted = buckets.fold<int>(0, (s, b) => s + b.accepted);
    final refused = buckets.fold<int>(0, (s, b) => s + b.refused);
    return Semantics(
      label: l10n.dashboardTimelineSemantics(accepted, refused, first, last),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(formatCount(peak), style: textTheme.labelSmall),
          ),
          SizedBox(
            height: 120,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: TicketSurMotion.reduced(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, grow, _) => CustomPaint(
                key: const Key('dashboard-timeline-chart'),
                size: Size.infinite,
                painter: _BarsPainter(
                  buckets: buckets,
                  peak: peak,
                  grow: grow,
                  grid: scheme.outlineVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(first, style: textTheme.labelSmall),
              if (buckets.length > 1) Text(last, style: textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  const new({
    required this.buckets,
    required this.peak,
    required this.grow,
    required this.grid,
  });

  final List<TimelineBucket> buckets;
  final int peak;
  final double grow;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas
      ..drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        gridPaint,
      )
      ..drawLine(Offset.zero, Offset(size.width, 0), gridPaint);
    if (peak == 0 || buckets.isEmpty) return;

    final slot = size.width / buckets.length;
    final gap = math.min(4, slot * 0.25).toDouble();
    final barWidth = math.max(1, slot - gap).toDouble();
    final accepted = Paint()..color = TicketSurColors.success;
    final refused = Paint()..color = TicketSurColors.error;
    const radius = Radius.circular(3);
    for (final (index, bucket) in buckets.indexed) {
      if (bucket.total == 0) continue;
      final left = index * slot + gap / 2;
      final total = size.height * bucket.total / peak * grow;
      final acceptedHeight = total * bucket.accepted / bucket.total;
      final top = size.height - total;
      // Refus au-dessus, entrées en bas.
      if (bucket.refused > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, top, barWidth, total - acceptedHeight),
            topLeft: radius,
            topRight: radius,
          ),
          refused,
        );
      }
      if (bucket.accepted > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              left,
              size.height - acceptedHeight,
              barWidth,
              acceptedHeight,
            ),
            topLeft: bucket.refused == 0 ? radius : Radius.zero,
            topRight: bucket.refused == 0 ? radius : Radius.zero,
          ),
          accepted,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.buckets != buckets ||
      old.peak != peak ||
      old.grow != grow ||
      old.grid != grid;
}

class _Legend extends StatelessWidget {
  const new({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: const SizedBox.square(dimension: 10),
      ),
      const SizedBox(width: TicketSurSpacing.xxs),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

// -----------------------------------------------------------------------------
// Refus, catégories, portes, contrôleurs
// -----------------------------------------------------------------------------
