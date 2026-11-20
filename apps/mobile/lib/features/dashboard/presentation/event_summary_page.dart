import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.summaryTitle),
            if (event != null)
              Text(
                event.title,
                key: const Key('summary-event-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          if (event != null)
            IconButton(
              key: const Key('summary-report'),
              tooltip: l10n.reportAction,
              onPressed: () => unawaited(showReportSheet(context, event)),
              icon: const Icon(Icons.description_rounded),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(eventSummaryProvider(eventId).future),
        child: switch (summary) {
          AsyncData(:final value) => _SummaryBody(summary: value, zone: zone),
          AsyncError(:final error) => ListView(
            key: const Key('summary-error'),
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            children: [
              Text(
                error == DashboardFailure.notFound
                    ? l10n.dashboardErrorNotFound
                    : l10n.summaryErrorLoad,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TicketSurSpacing.md),
              Center(
                child: FilledButton.tonal(
                  key: const Key('summary-retry'),
                  onPressed: () =>
                      ref.invalidate(eventSummaryProvider(eventId)),
                  child: Text(l10n.orgRetry),
                ),
              ),
            ],
          ),
          _ => ListView(
            key: const Key('summary-loading'),
            padding: const EdgeInsets.all(TicketSurSpacing.md),
            children: const [
              SkeletonBox(height: 140, radius: TicketSurRadii.lg),
              SizedBox(height: TicketSurSpacing.md),
              SkeletonBox(height: 220, radius: TicketSurRadii.md),
            ],
          ),
        },
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const new({required this.summary, required this.zone});

  final EventSummary summary;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = summary.comparison.where((e) => e.current).firstOrNull;
    final peakEntries = summary.peak?.entries ?? 0;
    final multiDay = summary.days.length > 1;
    final others = summary.comparison.where((e) => !e.current).length;
    return ListView(
      key: const Key('summary-body'),
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      children: [
        DashboardSectionCard(
          key: const Key('summary-headline'),
          title: l10n.summaryHeadline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (current != null) ...[
                Text(
                  formatPercent(current.attendance),
                  key: const Key('summary-rate'),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: context.palette.accentText,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  l10n.summaryPeopleLine(current.admitted, current.issued),
                  key: const Key('summary-people'),
                ),
              ],
              if (summary.averageOthers case final average?)
                Text(
                  l10n.summaryAverageOthers(others, formatPercent(average)),
                  key: const Key('summary-average'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (summary.passEntries > 0)
                Text(
                  l10n.summaryPassLine(
                    summary.passEntries,
                    summary.passTickets,
                  ),
                  key: const Key('summary-passes'),
                ),
              if ((summary.firstEntryAt, summary.lastEntryAt) case (
                final first?,
                final last?,
              ))
                Text(
                  l10n.summarySpan(
                    formatClock(zone, first),
                    formatClock(zone, last),
                  ),
                  key: const Key('summary-span'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const SizedBox(height: TicketSurSpacing.md),
        if (summary.isEmpty)
          Card(
            key: const Key('summary-empty'),
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.hourglass_empty_rounded),
              title: Text(l10n.summaryEmpty),
            ),
          )
        else
          DashboardSectionCard(
            key: const Key('summary-hours'),
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
                        ? Theme.of(context).colorScheme.primary
                        : context.palette.accentText,
                  ),
              ],
            ),
          ),
        if (multiDay) ...[
          const SizedBox(height: TicketSurSpacing.md),
          DashboardSectionCard(
            key: const Key('summary-days'),
            title: l10n.summaryDaysTitle,
            child: Column(
              children: [
                for (final day in summary.days)
                  ListTile(
                    key: Key(
                      'summary-day-${DateFormat('yyyyMMdd').format(day.date)}',
                    ),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.today_rounded),
                    title: Text(summaryDayLabel(day.date)),
                    subtitle: Text(
                      l10n.summaryDayLine(day.people, day.entries),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (summary.comparison.length > 1) ...[
          const SizedBox(height: TicketSurSpacing.md),
          DashboardSectionCard(
            key: const Key('summary-comparison'),
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
                    color: compared.current
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

final _hourKey = DateFormat('yyyyMMddHH');
