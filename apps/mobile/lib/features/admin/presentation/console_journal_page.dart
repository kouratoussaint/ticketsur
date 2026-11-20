import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/audit_labels.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Taille d'une page du journal.
const consoleJournalPage = 50;

/// Journal d'audit de toute la plateforme, filtré par famille d'actions.
class ConsoleJournalPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleJournalPage> createState() => _ConsoleJournalPageState();
}

class _ConsoleJournalPageState extends ConsumerState<ConsoleJournalPage> {
  AuditFilter _filter = AuditFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(adminRepositoryProvider);
    String label(AuditFilter filter) => switch (filter) {
      AuditFilter.all => l10n.consoleAuditAll,
      AuditFilter.console => l10n.consoleAuditConsole,
      AuditFilter.events => l10n.consoleAuditEvents,
      AuditFilter.tickets => l10n.consoleAuditTickets,
      AuditFilter.organizations => l10n.consoleAuditOrganizations,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consoleNavJournal)),
      body: ConsolePagedList<AuditEntry>(
        key: ValueKey(('journal', _filter)),
        pageSize: consoleJournalPage,
        load: (offset, _) =>
            repository.auditLogs(filter: _filter, offset: offset),
        header: Padding(
          padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
          child: Wrap(
            spacing: TicketSurSpacing.xs,
            runSpacing: TicketSurSpacing.xs,
            children: [
              for (final filter in AuditFilter.values)
                ChoiceChip(
                  key: Key('console-audit-${filter.name}'),
                  label: Text(label(filter)),
                  selected: filter == _filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
        ),
        itemBuilder: (context, entry, _) => _EntryTile(entry: entry),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const new({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    final who = [
      ?entry.organizationName,
      if (entry.actorName case final name?) l10n.consoleAuditBy(name),
    ].join(' · ');
    final details = auditDetails(l10n, entry.details);
    return Card(
      key: Key('console-audit-entry-${entry.id}'),
      child: ListTile(
        leading: Icon(
          entry.action.startsWith('admin.')
              ? Icons.admin_panel_settings_rounded
              : Icons.history_rounded,
          color: context.palette.accentText,
        ),
        title: Text(auditActionLabel(l10n, entry.action)),
        subtitle: Text(
          [
            formatDateAtTime(entry.createdAt.toLocal()),
            if (who.isNotEmpty) who,
            if (details.isNotEmpty) details,
          ].join('\n'),
          style: muted,
        ),
        isThreeLine: details.isNotEmpty || who.isNotEmpty,
      ),
    );
  }
}
