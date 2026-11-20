import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/brand_pdf.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/dashboard/application/dashboard_providers.dart';
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/dashboard/domain/event_summary.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/reports/application/report_providers.dart';
import 'package:ticketsur/features/reports/domain/report.dart';
import 'package:ticketsur/features/reports/presentation/report_files.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ouvre le choix du rapport : bilan PDF ou liste des tickets (CSV).
Future<void> showReportSheet(BuildContext context, TicketEvent event) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(event: event),
    );

enum _Kind { pdf, csv }

class _ReportSheet extends ConsumerStatefulWidget {
  const new({required this.event});

  final TicketEvent event;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  _Kind? _busy;
  String? _error;

  Future<void> _make(_Kind kind) async {
    final l10n = context.l10n;
    final share = ref.read(shareFilesProvider);
    final event = widget.event;
    final organization = ref.read(activeOrganizationProvider)?.name ?? '';
    setState(() {
      _busy = kind;
      _error = null;
    });
    try {
      final slug = fileSlug(event.title);
      switch (kind) {
        case _Kind.pdf:
          // Chiffres les plus récents : relus à la demande du rapport.
          final dashboard = await ref
              .read(dashboardRepositoryProvider)
              .load(event.id);
          // Bilan (affluence, comparaison) : facultatif, le rapport part
          // sans lui si le serveur ne le fournit pas.
          EventSummary? summary;
          try {
            summary = await ref
                .read(summaryRepositoryProvider)
                .summary(event.id);
          } on Object {
            summary = null;
          }
          final bytes = await buildReportPdf(
            l10n,
            event: event,
            dashboard: dashboard,
            organizationName: organization,
            logo: await loadPdfLogo(),
            summary: summary,
          );
          await share([
            (
              bytes: bytes,
              name: 'Rapport-$slug.pdf',
              mimeType: 'application/pdf',
            ),
          ]);
        case _Kind.csv:
          final rows = await ref.read(reportRepositoryProvider).rows(event.id);
          final bytes = buildReportCsv(l10n, event: event, rows: rows);
          await share([
            (bytes: bytes, name: 'Tickets-$slug.csv', mimeType: 'text/csv'),
          ]);
      }
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      final notFound =
          error == ReportFailure.notFound || error == DashboardFailure.notFound;
      setState(
        () =>
            _error = notFound ? l10n.reportErrorNotFound : l10n.reportErrorLoad,
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget option(_Kind kind, IconData icon, String title, String hint) =>
        ListTile(
          key: Key('report-${kind.name}'),
          enabled: _busy == null,
          leading: _busy == kind
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: theme.colorScheme.primary),
          title: Text(title),
          subtitle: Text(hint),
          onTap: () => unawaited(_make(kind)),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        TicketSurSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.reportSheetTitle, style: theme.textTheme.titleLarge),
          Text(widget.event.title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: TicketSurSpacing.sm),
          option(
            _Kind.pdf,
            Icons.picture_as_pdf_rounded,
            l10n.reportPdf,
            l10n.reportPdfHint,
          ),
          option(
            _Kind.csv,
            Icons.table_view_rounded,
            l10n.reportCsv,
            l10n.reportCsvHint,
          ),
          if (_error case final text?)
            Padding(
              padding: const EdgeInsets.only(top: TicketSurSpacing.sm),
              child: Text(
                text,
                key: const Key('report-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
