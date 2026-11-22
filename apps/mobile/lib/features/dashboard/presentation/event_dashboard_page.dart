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

part 'dashboard_hero.dart';
part 'dashboard_timeline.dart';
part 'dashboard_cards.dart';

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
          TikeoOverlapCard(
            padding: const EdgeInsets.all(20),
            child: _AttendanceHero(data: data),
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
    final notInPack = failure == DashboardFailure.notInPack;
    return Column(
      children: [
        const SizedBox(height: 32),
        TikeoIllustrationView(
          notFound || notInPack
              ? TikeoIllustration.lock
              : TikeoIllustration.offline,
        ),
        const SizedBox(height: 16),
        Text(
          notInPack
              ? l10n.billingDashboardNotInPack
              : notFound
              ? l10n.dashboardErrorNotFound
              : l10n.dashboardErrorLoad,
          key: const Key('dashboard-error'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (notInPack) ...[
          const SizedBox(height: 16),
          TikeoPrimaryButton(
            key: const Key('dashboard-see-packs'),
            onPressed: () => unawaited(context.push(AppRoutes.billingPacks)),
            icon: Icons.workspace_premium_rounded,
            label: l10n.billingBlockSeePacks,
          ),
        ] else if (!notFound) ...[
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
