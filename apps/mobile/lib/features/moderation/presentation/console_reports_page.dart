import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/moderation/application/moderation_providers.dart';
import 'package:ticketsur/features/moderation/domain/moderation.dart';
import 'package:ticketsur/features/moderation/presentation/report_sheet.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _when(DateTime instant) => formatDateAtTime(instant.toLocal());

/// Console : signalements regroupés par contenu (ADR 0050). « À traiter »
/// (les plus signalés d'abord) ou « Traités ».
class ConsoleReportsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleReportsPage> createState() => _ConsoleReportsPageState();
}

class _ConsoleReportsPageState extends ConsumerState<ConsoleReportsPage> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(moderationRepositoryProvider);
    final openCount = ref.watch(openReportsCountProvider).value ?? 0;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleReportsTitle)),
      body: ConsolePagedList<ReportGroup>(
        key: ValueKey(('reports', _open)),
        load: (offset, _) async =>
            (await repository.reports(open: _open, offset: offset)).items,
        header: Padding(
          padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: const Key('console-reports-open'),
                label: Text(l10n.consoleReportsOpen(openCount)),
                selected: _open,
                onSelected: (_) => setState(() => _open = true),
              ),
              ChoiceChip(
                key: const Key('console-reports-handled'),
                label: Text(l10n.consoleReportsHandled),
                selected: !_open,
                onSelected: (_) => setState(() => _open = false),
              ),
            ],
          ),
        ),
        itemBuilder: (context, group, reload) => _ReportCard(
          group: group,
          onChanged: () {
            ref.invalidate(openReportsCountProvider);
            reload();
          },
        ),
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const new({required this.group, required this.onChanged});

  final ReportGroup group;
  final VoidCallback onChanged;

  bool get _event => group.kind == ReportKind.event;

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref, {
    required bool remove,
  }) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final reason = await showConsoleConfirm(
      context,
      title: remove
          ? (_event
                ? l10n.consoleReportsRemoveEvent
                : l10n.consoleReportsSuspend)
          : l10n.consoleReportsDismiss,
      body: remove
          ? (_event
                ? l10n.consoleReportsRemoveEventHint
                : l10n.consoleReportsSuspendHint)
          : l10n.consoleReportsDismissHint,
      confirmLabel: remove
          ? (_event
                ? l10n.consoleReportsRemoveEvent
                : l10n.consoleReportsSuspend)
          : l10n.consoleReportsDismiss,
      needsReason: true,
      destructive: remove,
      confirmKey: const Key('console-report-confirm'),
    );
    if (reason == null) return;
    try {
      final count = await ref
          .read(moderationRepositoryProvider)
          .resolve(group.kind, group.id, remove: remove, reason: reason);
      toast.success(l10n.consoleReportsResolved(count));
      ref.invalidate(adminOverviewProvider);
      onChanged();
    } on Object catch (error) {
      toast.error(
        error == AdminFailure.network || error == AdminFailure.unknown
            ? l10n.consoleActionError
            : consoleFailureMessage(l10n, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final tints = context.tints;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    final open = group.status == ReportStatus.open;
    final reasons = group.reasons.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return TikeoCard(
      key: Key('console-report-${group.kind.name}-${group.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _event ? Icons.event_rounded : Icons.storefront_rounded,
                color: context.palette.accentText,
              ),
              const SizedBox(width: TicketSurSpacing.sm),
              Expanded(child: Text(group.title, style: textTheme.titleMedium)),
              const SizedBox(width: TicketSurSpacing.xs),
              Flexible(
                child: TikeoPill(
                  key: Key('console-report-count-${group.id}'),
                  label: l10n.consoleReportsCount(group.count),
                  tint: open ? tints.red : tints.gray,
                  icon: Icons.flag_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.xxs),
          Text(
            [
              if (_event)
                group.organizationName
              else
                l10n.consoleReportsKindOrg,
              if (group.startsAt case final at?) _when(at),
            ].join(' · '),
            style: muted,
          ),
          Text(
            open
                ? l10n.consoleReportsLast(_when(group.lastAt))
                : l10n.consoleReportsHandledAt(
                    _when(group.handledAt ?? group.lastAt),
                    group.status == ReportStatus.actioned
                        ? (_event
                              ? l10n.consoleReportsRemoved
                              : l10n.consoleReportsSuspended)
                        : l10n.consoleReportsDismissed,
                  ),
            style: muted,
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final MapEntry(key: reason, value: n) in reasons)
                TikeoPill(
                  label: '${reportReasonLabel(l10n, reason)} · $n',
                  tint: tints.amber,
                  icon: reportReasonIcon(reason),
                ),
            ],
          ),
          for (final comment in group.comments) ...[
            const SizedBox(height: TicketSurSpacing.xs),
            Text(
              '« ${comment.comment} »',
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(_when(comment.at), style: muted),
          ],
          const SizedBox(height: TicketSurSpacing.xs),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                key: Key('console-report-open-${group.id}'),
                onPressed: () => unawaited(
                  context.push(
                    _event
                        ? AppRoutes.consoleEvent(group.id)
                        : AppRoutes.consoleOrganization(group.id),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(l10n.consoleReportsOpenFiche),
              ),
              if (open) ...[
                TextButton.icon(
                  key: Key('console-report-dismiss-${group.id}'),
                  onPressed: () =>
                      unawaited(_resolve(context, ref, remove: false)),
                  icon: const Icon(Icons.done_rounded),
                  label: Text(l10n.consoleReportsDismiss),
                ),
                TextButton.icon(
                  key: Key('console-report-remove-${group.id}'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () =>
                      unawaited(_resolve(context, ref, remove: true)),
                  icon: Icon(
                    _event ? Icons.visibility_off_rounded : Icons.block_rounded,
                  ),
                  label: Text(
                    _event
                        ? l10n.consoleReportsRemoveEvent
                        : l10n.consoleReportsSuspend,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
