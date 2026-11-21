import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_tools/application/admin_tools_providers.dart';
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/features/reports/presentation/report_files.dart'
    show csvCell;
import 'package:ticketsur/features/tickets/application/ticket_providers.dart'
    show shareFilesProvider;
import 'package:ticketsur/l10n/l10n.dart';

String exportLabel(AppLocalizations l10n, ExportKind kind) => switch (kind) {
  ExportKind.accounts => l10n.consoleNavAccounts,
  ExportKind.organizations => l10n.consoleNavOrganizations,
  ExportKind.events => l10n.consoleNavEvents,
  ExportKind.invoices => l10n.consoleExportInvoices,
  ExportKind.journal => l10n.consoleNavJournal,
};

/// Libellé d'une colonne d'export ; une clé inconnue reste telle quelle.
String exportColumnLabel(AppLocalizations l10n, String column) =>
    switch (column) {
      'id' => l10n.exportColId,
      'name' => l10n.exportColName,
      'email' => l10n.exportColEmail,
      'phone' => l10n.exportColPhone,
      'status' => l10n.exportColStatus,
      'admin_role' => l10n.exportColAdminRole,
      'created_at' => l10n.exportColCreatedAt,
      'last_sign_in_at' => l10n.exportColLastSignIn,
      'deletion_requested_at' => l10n.exportColDeletionRequested,
      'deleted' => l10n.exportColDeleted,
      'organizations' => l10n.consoleNavOrganizations,
      'city' => l10n.exportColCity,
      'closed_at' => l10n.exportColClosedAt,
      'trashed_at' => l10n.exportColTrashedAt,
      'owner_name' => l10n.exportColOwner,
      'owner_email' => l10n.exportColOwnerEmail,
      'members' => l10n.exportColMembers,
      'events' => l10n.consoleNavEvents,
      'tickets' => l10n.consoleNavTickets,
      'title' => l10n.exportColTitle,
      'organization_name' => l10n.exportColOrganization,
      'starts_at' => l10n.exportColStartsAt,
      'ends_at' => l10n.exportColEndsAt,
      'public' => l10n.exportColPublic,
      'admitted' => l10n.exportColAdmitted,
      'issued_at' => l10n.exportColIssuedAt,
      'due_at' => l10n.exportColDueAt,
      'amount' => l10n.exportColAmount,
      'entries' => l10n.exportColEntries,
      'billable_entries' => l10n.exportColBillableEntries,
      'account_name' => l10n.exportColAccount,
      'account_email' => l10n.exportColAccountEmail,
      'event_title' => l10n.exportColEvent,
      'paid_at' => l10n.exportColPaidAt,
      'action' => l10n.exportColAction,
      'actor_name' => l10n.exportColActor,
      'resource_type' => l10n.exportColResourceType,
      'resource_id' => l10n.exportColResourceId,
      'details' => l10n.exportColDetails,
      _ => column,
    };

/// CSV pour Excel en français : `;`, BOM, CRLF, formules neutralisées.
Uint8List buildExportCsv(AppLocalizations l10n, ConsoleExport export) {
  String cell(Object? value) => switch (value) {
    null => '',
    true => l10n.auditDetailYes,
    false => l10n.auditDetailNo,
    _ => '$value',
  };
  final buffer = StringBuffer('\u{FEFF}')
    ..write(
      export.columns.map((c) => csvCell(exportColumnLabel(l10n, c))).join(';'),
    )
    ..write('\r\n');
  for (final row in export.rows) {
    buffer
      ..write(row.map((v) => csvCell(cell(v))).join(';'))
      ..write('\r\n');
  }
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}

/// Nom du fichier : `Tikeo-comptes-2026-11-21.csv`.
String exportFileName(ExportKind kind, DateTime now) {
  final date =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  final slug = switch (kind) {
    ExportKind.accounts => 'comptes',
    ExportKind.organizations => 'structures',
    ExportKind.events => 'evenements',
    ExportKind.invoices => 'factures',
    ExportKind.journal => 'journal',
  };
  return 'Tikeo-$slug-$date.csv';
}

/// Console › Exports : un fichier CSV par liste, à partager ou enregistrer.
class ConsoleExportsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleExportsPage> createState() => _ConsoleExportsPageState();
}

class _ConsoleExportsPageState extends ConsumerState<ConsoleExportsPage> {
  ExportKind? _running;

  Future<void> _export(ExportKind kind) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final share = ref.read(shareFilesProvider);
    setState(() => _running = kind);
    try {
      final export = await ref.read(adminToolsRepositoryProvider).export(kind);
      await share([
        (
          bytes: buildExportCsv(l10n, export),
          name: exportFileName(kind, DateTime.now()),
          mimeType: 'text/csv',
        ),
      ]);
      toast.success(
        export.truncated
            ? l10n.consoleExportTruncated(export.rows.length)
            : l10n.consoleExportDone(export.rows.length),
      );
    } on Object catch (error) {
      toast.error(adminAccountsFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(adminMeProvider).value;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleNavExports)),
      body: ListView(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          Text(l10n.consoleExportsHint),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final kind in ExportKind.values)
                  ListTile(
                    key: Key('console-export-${kind.name}'),
                    enabled: kind.allowedFor(me) && _running == null,
                    leading: const Icon(Icons.table_view_rounded),
                    title: Text(exportLabel(l10n, kind)),
                    subtitle: kind.allowedFor(me)
                        ? null
                        : Text(l10n.consoleExportForbidden),
                    trailing: _running == kind
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share_rounded),
                    onTap: () => unawaited(_export(kind)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
