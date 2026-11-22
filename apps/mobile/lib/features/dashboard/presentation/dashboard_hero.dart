// Partie de `event_dashboard_page.dart` (découpage du lot 4-9) :
// bandeau « En direct », taux d'entrée et indicateurs.
part of 'event_dashboard_page.dart';

class _LiveBar extends StatelessWidget {
  const new({required this.data, required this.zone, required this.stale});

  final EventDashboard data;
  final String zone;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final time = formatClock(zone, data.serverTime, seconds: true);
    final (key, color, label) = stale
        ? (
            const Key('dashboard-stale'),
            TicketSurColors.warning,
            l10n.dashboardStale,
          )
        : data.scanWindowOpen
        ? (
            const Key('dashboard-live'),
            TicketSurColors.success,
            l10n.dashboardLive,
          )
        : (
            const Key('dashboard-closed'),
            Theme.of(context).colorScheme.outline,
            l10n.dashboardClosed,
          );
    final tint = stale
        ? context.tints.amber
        : data.scanWindowOpen
        ? context.tints.live
        : context.tints.gray;
    return Semantics(
      liveRegion: true,
      child: Row(
        key: key,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: tint.background,
              borderRadius: BorderRadius.circular(TikeoRadii.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(
                    color: stale ? color : tint.icon,
                    pulsing: !stale && data.scanWindowOpen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TikeoTextStyles.chip.copyWith(color: tint.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(
            child: Text(
              stale
                  ? l10n.dashboardStaleBody(time)
                  : l10n.dashboardUpdatedAt(time),
              key: const Key('dashboard-updated-at'),
              style: textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const new({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.pulsing && !TicketSurMotion.reduced(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          CustomPaint(painter: _DotPainter(widget.color, _controller.value)),
    ),
  );
}

class _DotPainter extends CustomPainter {
  const new(this.color, this.progress);

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (progress > 0) {
      canvas.drawCircle(
        center,
        4 + 5 * progress,
        Paint()..color = color.withValues(alpha: 0.35 * (1 - progress)),
      );
    }
    canvas.drawCircle(center, 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DotPainter old) =>
      old.color != color || old.progress != progress;
}

// -----------------------------------------------------------------------------
// Taux d'entrée
// -----------------------------------------------------------------------------

class _AttendanceHero extends StatelessWidget {
  const new({required this.data});

  final EventDashboard data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;
    final tickets = data.tickets;
    return Row(
      key: const Key('dashboard-hero'),
      children: [
        _AttendanceRing(value: tickets.attendance),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardAttendance.toUpperCase(),
                style: TikeoTextStyles.overline.copyWith(
                  color: context.tints.mint.text,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedCount(
                value: tickets.admitted,
                builder: (context, value) => Text(
                  l10n.dashboardAdmittedCount(value),
                  key: const Key('dashboard-admitted'),
                  style: TikeoTextStyles.tileNumber.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                l10n.dashboardIssuedOf(tickets.issued),
                key: const Key('dashboard-issued'),
                style: textTheme.bodyMedium?.copyWith(color: muted),
              ),
              if (data.capacity case final capacity?) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.dashboardCapacityLine(l10n.eventCapacityValue(capacity)),
                  style: textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
              if (tickets.invitations > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard_rounded,
                      size: 16,
                      color: context.tints.salmon.icon,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.dashboardInvitations(
                          tickets.invitationsAdmitted,
                          tickets.invitations,
                        ),
                        key: const Key('dashboard-invitations'),
                        style: textTheme.bodySmall?.copyWith(
                          color: context.tints.salmon.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceRing extends StatelessWidget {
  const new({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = TicketSurMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => SizedBox.square(
        dimension: 96,
        child: CustomPaint(
          painter: _RingPainter(
            current,
            track: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: Text(
              formatPercent(current),
              key: const Key('dashboard-percent'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const new(this.value, {required this.track});

  final double value;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (value <= 0) return;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1).toDouble(),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = TicketSurColors.mint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track;
}

// -----------------------------------------------------------------------------
// Indicateurs
// -----------------------------------------------------------------------------

class _Kpi {
  const new({
    required this.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final Key key;
  final IconData icon;
  final String label;
  final int value;
  final TikeoTint tint;
}

/// Tuiles de chiffres teintées, deux par ligne (quatre sur un grand écran).
class _KpiGrid extends StatelessWidget {
  const new({required this.items});

  final List<_Kpi> items;

  @override
  Widget build(BuildContext context) {
    Widget tile(_Kpi item) => AnimatedCount(
      key: item.key,
      value: item.value,
      builder: (context, value) => StatTile(
        tint: item.tint,
        icon: item.icon,
        value: formatCount(value),
        label: item.label,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = TikeoSizes.cardGap;
        final perRow = constraints.maxWidth >= 560 ? 4 : 2;
        return Column(
          children: [
            for (var start = 0; start < items.length; start += perRow) ...[
              if (start > 0) const SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, item)
                        in items.skip(start).take(perRow).indexed) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(child: tile(item)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Chronologie
// -----------------------------------------------------------------------------
