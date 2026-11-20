import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/dashboard/application/dashboard_providers.dart';
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/dashboard/domain/event_summary.dart';
import 'package:ticketsur/features/dashboard/presentation/event_dashboard_page.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/reports/presentation/report_files.dart'
    show summaryDayLabel, summaryHourLabel;
import 'package:ticketsur/features/reports/presentation/report_sheet.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Bilan d'après-événement : présence, affluence par heure et par jour,
/// entrées des pass, comparaison avec les derniers événements de la
/// structure (ADR 0025).
class EventSummaryPage extends ConsumerWidget {
  const new({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(eventSummaryProvider(eventId));
    final event = ref.watch(eventByIdProvider(eventId));
    final zone = event?.timezone ?? defaultEventTimeZone;
    final value = summary.value;
    final current = summary is AsyncData
        ? value?.comparison.where((e) => e.current).firstOrNull
        : null;
    final (Key listKey, List<Widget> content) = switch (summary) {
      AsyncData(:final value) => (
        const Key('summary-body'),
        _summarySections(context, summary: value, zone: zone),
      ),
      AsyncError(:final error) => (
        const Key('summary-error'),
        [
          const SizedBox(height: 32),
          TikeoIllustrationView(
            error == DashboardFailure.notFound
                ? TikeoIllustration.lock
                : TikeoIllustration.offline,
          ),
          const SizedBox(height: 16),
          Text(
            error == DashboardFailure.notFound
                ? l10n.dashboardErrorNotFound
                : l10n.summaryErrorLoad,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TikeoPrimaryButton(
            key: const Key('summary-retry'),
            onPressed: () => ref.invalidate(eventSummaryProvider(eventId)),
            icon: Icons.refresh_rounded,
            label: l10n.orgRetry,
          ),
        ],
      ),
      _ => (
        const Key('summary-loading'),
        [
          const SizedBox(height: TikeoSizes.cardGap),
          const Shimmer(
            child: Column(
              children: [
                SkeletonBox(height: 220, radius: TikeoRadii.card),
                SizedBox(height: TikeoSizes.cardGap),
                SkeletonBox(height: 160, radius: TikeoRadii.card),
              ],
            ),
          ),
        ],
      ),
    };
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(eventSummaryProvider(eventId).future),
        child: ListView(
          key: listKey,
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TikeoHeroHeader(
                  title: event?.title ?? l10n.summaryTitle,
                  titleKey: event == null
                      ? null
                      : const Key('summary-event-title'),
                  subtitle: event == null ? null : l10n.summaryTitle,
                  illustration: TikeoIllustration.stats,
                  onBack: () => context.popOr(AppRoutes.home),
                  overlap: value == null ? 0 : TikeoSizes.heroOverlap,
                  actions: [
                    if (event != null)
                      IconButton(
                        key: const Key('summary-report'),
                        tooltip: l10n.reportAction,
                        color: TicketSurColors.white,
                        onPressed: () =>
                            unawaited(showReportSheet(context, event)),
                        icon: const Icon(Icons.description_rounded),
                      ),
                  ],
                ),
                if (value != null && summary is AsyncData)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TikeoSizes.screenMargin,
                    ),
                    child: TikeoOverlapCard(
                      padding: const EdgeInsets.all(20),
                      child: _Headline(
                        summary: value,
                        current: current,
                        zone: zone,
                      ),
                    ),
                  ),
              ],
            ),
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

/// Taux d'entrée, personnes, moyenne, pass et plage horaire.
class _Headline extends StatelessWidget {
  const new({required this.summary, required this.current, required this.zone});

  final EventSummary summary;
  final ComparedEvent? current;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final others = summary.comparison.where((e) => !e.current).length;
    return Column(
      key: const Key('summary-headline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.summaryHeadline.toUpperCase(),
          style: TikeoTextStyles.overline.copyWith(
            color: context.tints.mint.text,
          ),
        ),
        if (current case final current?) ...[
          const SizedBox(height: 4),
          Text(
            formatPercent(current.attendance),
            key: const Key('summary-rate'),
            style: TikeoTextStyles.bigNumber.copyWith(
              color: context.tints.mint.text,
            ),
          ),
          Text(
            l10n.summaryPeopleLine(current.admitted, current.issued),
            key: const Key('summary-people'),
            style: theme.textTheme.bodyLarge,
          ),
        ],
        if (summary.averageOthers case final average?)
          Text(
            l10n.summaryAverageOthers(others, formatPercent(average)),
            key: const Key('summary-average'),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        if (summary.passEntries > 0)
          Text(
            l10n.summaryPassLine(summary.passEntries, summary.passTickets),
            key: const Key('summary-passes'),
          ),
        if ((summary.firstEntryAt, summary.lastEntryAt) case (
          final first?,
          final last?,
        ))
          Text(
            l10n.summarySpan(formatClock(zone, first), formatClock(zone, last)),
            key: const Key('summary-span'),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
      ],
    );
  }
}

List<Widget> _summarySections(
  BuildContext context, {
  required EventSummary summary,
  required String zone,
}) {
  final l10n = context.l10n;
  final peakEntries = summary.peak?.entries ?? 0;
  final multiDay = summary.days.length > 1;
  final tints = context.tints;
  return [
    const SizedBox(height: TikeoSizes.cardGap),
    if (summary.isEmpty)
      TintedBanner(
        key: const Key('summary-empty'),
        tint: tints.gray,
        icon: Icons.hourglass_empty_rounded,
        title: l10n.summaryEmpty,
      )
    else
      DashboardSectionCard(
        key: const Key('summary-hours'),
        icon: Icons.schedule_rounded,
        title: l10n.summaryHoursTitle,
        subtitle: switch (summary.peak) {
          final peak? => l10n.summaryPeak(
            summaryHourLabel(l10n, peak.at),
            peak.entries,
          ),
          null => null,
        },
        child: Column(
          children: [
            for (final hour in summary.hours)
              DashboardBarRow(
                key: Key('summary-hour-${_hourKey.format(hour.at)}'),
                label: [
                  if (multiDay) summaryDayLabel(hour.at),
                  summaryHourLabel(l10n, hour.at),
                ].join(' · '),
                trailing: formatCount(hour.entries),
                value: peakEntries == 0 ? 0 : hour.entries / peakEntries,
                color: hour.at == summary.peak?.at
                    ? tints.mint.icon
                    : tints.blue.icon,
              ),
          ],
        ),
      ),
    if (multiDay) ...[
      const SizedBox(height: TikeoSizes.cardGap),
      DashboardSectionCard(
        key: const Key('summary-days'),
        icon: Icons.calendar_month_rounded,
        title: l10n.summaryDaysTitle,
        child: Column(
          children: [
            for (final day in summary.days)
              ListTile(
                key: Key(
                  'summary-day-${DateFormat('yyyyMMdd').format(day.date)}',
                ),
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: tints.blue.background,
                  child: Icon(Icons.today_rounded, color: tints.blue.icon),
                ),
                title: Text(summaryDayLabel(day.date)),
                subtitle: Text(l10n.summaryDayLine(day.people, day.entries)),
              ),
          ],
        ),
      ),
    ],
    if (summary.comparison.length > 1) ...[
      const SizedBox(height: TikeoSizes.cardGap),
      DashboardSectionCard(
        key: const Key('summary-comparison'),
        icon: Icons.leaderboard_rounded,
        title: l10n.summaryCompareTitle,
        subtitle: l10n.summaryCompareHint,
        child: Column(
          children: [
            for (final compared in summary.comparison)
              DashboardBarRow(
                key: Key('summary-compare-${compared.id}'),
                label: compared.current
                    ? l10n.summaryThisEvent(compared.title)
                    : compared.title,
                trailing: formatPercent(compared.attendance),
                detail: [
                  DateFormat.yMMMd(appLocaleTag)
                      .format(wallTimeIn(zone, compared.startsAt)),
                  l10n.dashboardCategoryLine(
                    compared.admitted,
                    compared.issued,
                  ),
                ].join(' · '),
                value: compared.attendance,
                color: compared.current ? tints.mint.icon : tints.gray.icon,
              ),
          ],
        ),
      ),
    ],
  ];
}

final _hourKey = DateFormat('yyyyMMddHH');
