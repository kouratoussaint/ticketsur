import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/animated_count.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/dashboard/application/dashboard_providers.dart';
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/reports/presentation/report_sheet.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Tableau de bord en direct d'un événement (DASH-01, S19).
///
/// Actualisé toutes les 15 secondes tant que l'écran est visible et
/// l'application au premier plan, et à la demande (glisser vers le bas ou
/// bouton). Un échec n'efface jamais les chiffres : ils restent affichés,
/// marqués « Non actualisé » avec l'heure du serveur de leur calcul.
class EventDashboardPage extends ConsumerStatefulWidget {
  const new({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<EventDashboardPage> createState() => _EventDashboardPageState();
}

class _EventDashboardPageState extends ConsumerState<EventDashboardPage> {
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
  bool _foreground = true;

  DashboardController get _controller =>
      ref.read(dashboardProvider(widget.eventId).notifier);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onShow: () {
        _foreground = true;
        unawaited(_controller.refresh());
      },
      onHide: () => _foreground = false,
    );
    _timer = Timer.periodic(ref.read(dashboardRefreshIntervalProvider), (_) {
      if (_foreground && mounted) unawaited(_controller.refresh());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(dashboardProvider(widget.eventId));
    final event = ref.watch(eventByIdProvider(widget.eventId));
    final zone = event?.timezone ?? defaultEventTimeZone;
    final data = state.data;
    const white = TicketSurColors.white;
    final header = TikeoHeroHeader(
      title: event?.title ?? l10n.dashboardTitle,
      titleKey: event == null ? null : const Key('dashboard-event-title'),
      subtitle: event == null ? null : l10n.dashboardTitle,
      onBack: () => context.popOr(AppRoutes.home),
      overlap: data == null ? 0 : TikeoSizes.heroOverlap,
      actions: [
        IconButton(
          key: const Key('dashboard-summary'),
          tooltip: l10n.summaryTitle,
          color: white,
          onPressed: () =>
              unawaited(context.push(AppRoutes.eventSummary(widget.eventId))),
          icon: const Icon(Icons.insights_rounded),
        ),
        if (event != null)
          IconButton(
            key: const Key('dashboard-report'),
            tooltip: l10n.reportAction,
            color: white,
            onPressed: () => unawaited(showReportSheet(context, event)),
            icon: const Icon(Icons.description_rounded),
          ),
        IconButton(
          key: const Key('dashboard-refresh'),
          tooltip: l10n.dashboardRefresh,
          color: white,
          onPressed: state.loading
              ? null
              : () => unawaited(_controller.refresh()),
          icon: state.loading && data != null
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TicketSurColors.mint,
                  ),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    );
    final top = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (data != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TikeoSizes.screenMargin,
            ),
            child: TikeoOverlapCard(
              padding: const EdgeInsets.all(20),
              child: _AttendanceHero(data: data),
            ),
          ),
      ],
    );
    final (Key? listKey, List<Widget> content) = switch (data) {
      null when state.failure != null => (
        null,
        [
          _ErrorView(
            failure: state.failure!,
            onRetry: () => unawaited(_controller.refresh()),
          ),
        ],
      ),
      null => (const Key('dashboard-loading'), [const _LoadingView()]),
      final EventDashboard data => (
        const Key('dashboard-body'),
        _dashboardSections(context, data: data, zone: zone, stale: state.stale),
      ),
    };
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _controller.refresh,
        child: ListView(
          key: listKey,
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          children: [
            top,
            for (final child in content)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TikeoSizes.screenMargin,
                ),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: TikeoSizes.cardGap),
    child: Shimmer(
      child: Column(
        children: [
          SkeletonBox(height: 160, radius: TikeoRadii.card),
          SizedBox(height: TikeoSizes.cardGap),
          SkeletonBox(height: 88, radius: TikeoRadii.tile),
          SizedBox(height: TikeoSizes.cardGap),
          SkeletonBox(height: 180, radius: TikeoRadii.card),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final DashboardFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notFound = failure == DashboardFailure.notFound;
    return Column(
      children: [
        const SizedBox(height: 32),
        TikeoIllustrationView(
          notFound ? TikeoIllustration.lock : TikeoIllustration.offline,
        ),
        const SizedBox(height: 16),
        Text(
          notFound ? l10n.dashboardErrorNotFound : l10n.dashboardErrorLoad,
          key: const Key('dashboard-error'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (!notFound) ...[
          const SizedBox(height: 16),
          TikeoPrimaryButton(
            key: const Key('dashboard-retry'),
            onPressed: onRetry,
            icon: Icons.refresh_rounded,
            label: l10n.orgRetry,
          ),
        ],
      ],
    );
  }
}

List<Widget> _dashboardSections(
  BuildContext context, {
  required EventDashboard data,
  required String zone,
  required bool stale,
}) {
  final l10n = context.l10n;
  final tints = context.tints;
  final tickets = data.tickets;
  final scans = data.scans;
  const gap = SizedBox(height: TikeoSizes.cardGap);
  return [
    gap,
    _LiveBar(data: data, zone: zone, stale: stale),
    gap,
    FadeSlideIn(
      delay: const Duration(milliseconds: 40),
      child: _KpiGrid(
        items: [
          _Kpi(
            key: const Key('dashboard-kpi-admitted'),
            icon: Icons.how_to_reg_rounded,
            label: l10n.dashboardKpiAdmitted,
            value: tickets.admitted,
            tint: tints.green,
          ),
          _Kpi(
            key: const Key('dashboard-kpi-remaining'),
            icon: Icons.hourglass_bottom_rounded,
            label: l10n.dashboardKpiRemaining,
            value: tickets.remaining,
            tint: tints.blue,
          ),
          _Kpi(
            key: const Key('dashboard-kpi-refused'),
            icon: Icons.block_rounded,
            label: l10n.dashboardKpiRefused,
            value: scans.refused,
            tint: scans.refused > 0 ? tints.red : tints.gray,
          ),
          _Kpi(
            key: const Key('dashboard-kpi-rate'),
            icon: Icons.speed_rounded,
            label: l10n.dashboardKpiRate(scans.recentMinutes),
            value: scans.recentAccepted,
            tint: tints.violet,
          ),
        ],
      ),
    ),
    // Pass à plusieurs entrées : « Entrés » compte des personnes, les
    // tentatives acceptées comptent des entrées.
    if (scans.accepted > tickets.admitted) ...[
      const SizedBox(height: 8),
      Text(
        l10n.dashboardEntriesNote(scans.accepted),
        key: const Key('dashboard-entries-note'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
    if (tickets.issued == 0) ...[
      gap,
      TintedBanner(
        key: const Key('dashboard-no-tickets'),
        tint: tints.blue,
        icon: Icons.confirmation_number_rounded,
        title: l10n.dashboardNoTickets,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => context.go(AppRoutes.tickets),
          child: Text(l10n.dashboardIssueTickets),
        ),
      ),
    ],
    gap,
    FadeSlideIn(
      delay: const Duration(milliseconds: 80),
      child: _TimelineCard(data: data, zone: zone),
    ),
    if (scans.refusals.isNotEmpty) ...[
      gap,
      FadeSlideIn(
        delay: const Duration(milliseconds: 120),
        child: _RefusalsCard(scans: scans),
      ),
    ],
    if (data.categories.isNotEmpty) ...[
      gap,
      FadeSlideIn(
        delay: const Duration(milliseconds: 160),
        child: _CategoriesCard(categories: data.categories),
      ),
    ],
    if (data.checkpoints.isNotEmpty) ...[
      gap,
      FadeSlideIn(
        delay: const Duration(milliseconds: 200),
        child: _CheckpointsCard(checkpoints: data.checkpoints, zone: zone),
      ),
    ],
    if (data.controllers.isNotEmpty) ...[
      gap,
      FadeSlideIn(
        delay: const Duration(milliseconds: 240),
        child: _ControllersCard(controllers: data.controllers, zone: zone),
      ),
    ],
    if (tickets.revoked > 0 || tickets.expired > 0) ...[
      gap,
      Text(
        l10n.dashboardRevokedExpired(tickets.revoked, tickets.expired),
        key: const Key('dashboard-revoked-expired'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  ];
}

// -----------------------------------------------------------------------------
// État de la connexion et heure des chiffres
// -----------------------------------------------------------------------------

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
                Row(
                  children: [
                    _Legend(
                      color: TicketSurColors.success,
                      label: l10n.dashboardLegendAdmitted,
                    ),
                    const SizedBox(width: TicketSurSpacing.md),
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
              Text(trailing, style: textTheme.labelLarge),
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

NumberFormat get _count => NumberFormat.decimalPattern(appLocaleTag);

/// Nombre avec séparateur de milliers français (« 1 250 »).
String formatCount(int value) => _count.format(value);

/// Pourcentage arrondi (« 42 % »), espace insécable avant le signe.
String formatPercent(double ratio) => '${(ratio.clamp(0, 1) * 100).round()} %';

/// Heure murale `HH:mm` (ou `HH:mm:ss`) de [instant] dans [zone].
/// L'heure du téléphone n'est jamais utilisée.
String formatClock(String zone, DateTime instant, {bool seconds = false}) {
  final local = wallTimeIn(zone, instant);
  String two(int value) => value.toString().padLeft(2, '0');
  final hm = '${two(local.hour)}:${two(local.minute)}';
  if (!seconds) return hm;
  // wallTimeIn tronque à la minute : les secondes ne dépendent pas du fuseau
  // (décalages entiers en minutes).
  return '$hm:${two(instant.toUtc().second)}';
}
