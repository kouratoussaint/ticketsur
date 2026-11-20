import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/admin/presentation/audit_labels.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/journal/domain/journal.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Journal ; surchargé dans `main.dart` et dans les tests.
final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => throw UnimplementedError(
    'journalRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Journal de la structure active (propriétaire) : qui a fait quoi.
class JournalPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  JournalFilter _filter = JournalFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final organization = ref.watch(activeOrganizationProvider);
    final repository = ref.watch(journalRepositoryProvider);
    String label(JournalFilter f) => switch (f) {
      JournalFilter.all => l10n.journalAll,
      JournalFilter.events => l10n.journalEvents,
      JournalFilter.tickets => l10n.journalTickets,
      JournalFilter.control => l10n.journalControl,
      JournalFilter.team => l10n.journalTeam,
      JournalFilter.structure => l10n.journalStructure,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.journalTitle)),
      body: organization == null
          ? const SizedBox.shrink()
          : ConsolePagedList<JournalEntry>(
              key: ValueKey(('journal', organization.id, _filter)),
              pageSize: 50,
              load: (offset, _) => repository.entries(
                organization.id,
                filter: _filter,
                offset: offset,
              ),
              header: Padding(
                padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
                child: Wrap(
                  spacing: TicketSurSpacing.xs,
                  runSpacing: TicketSurSpacing.xs,
                  children: [
                    for (final f in JournalFilter.values)
                      ChoiceChip(
                        key: Key('journal-filter-${f.name}'),
                        label: Text(label(f)),
                        selected: f == _filter,
                        onSelected: (_) => setState(() => _filter = f),
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

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    final who = entry.byPlatform
        ? l10n.journalByTikeo
        : entry.actorName == null
        ? null
        : l10n.consoleAuditBy(entry.actorName!);
    final details = auditDetails(l10n, entry.details);
    return Card(
      key: Key('journal-entry-${entry.id}'),
      child: ListTile(
        leading: Icon(
          entry.byPlatform
              ? Icons.verified_user_rounded
              : Icons.history_rounded,
          color: context.palette.accentText,
        ),
        title: Text(auditActionLabel(l10n, entry.action)),
        subtitle: Text(
          [
            DateFormat(
              "d MMM y 'à' HH:mm",
              'fr',
            ).format(entry.createdAt.toLocal()),
            ?entry.subject,
            ?who,
            if (details.isNotEmpty) details,
          ].join('\n'),
          style: muted,
        ),
        isThreeLine: true,
      ),
    );
  }
}
