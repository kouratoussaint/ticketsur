import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ce que l'utilisateur veut faire d'un lot.
enum BatchAction {
  /// N'afficher que les tickets du lot.
  view,

  /// Sélectionner tous les tickets du lot (PDF, planche, annulation).
  select,

  /// Imprimer directement la planche A4 des tickets valables du lot.
  print,
}

/// Feuille « Lots » : un lot par génération (lot rapide, nominatif, import),
/// du plus récent au plus ancien. Renvoie le lot et l'action choisis.
Future<(TicketBatch, BatchAction)?> showBatchesSheet(
  BuildContext context,
  String eventId,
) => showModalBottomSheet<(TicketBatch, BatchAction)>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _BatchesSheet(eventId: eventId),
);

class _BatchesSheet extends ConsumerWidget {
  const new({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final batches = ref.watch(ticketBatchesProvider(eventId));
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        key: const Key('batches-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.lg,
              0,
              TicketSurSpacing.lg,
              TicketSurSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.batchesTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  l10n.batchesIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: switch (batches) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.lg),
                child: Text(
                  l10n.batchesEmpty,
                  key: const Key('batches-empty'),
                  textAlign: TextAlign.center,
                ),
              ),
              AsyncData(:final value) => ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  0,
                  TicketSurSpacing.md,
                  TicketSurSpacing.lg,
                ),
                itemCount: value.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: TicketSurSpacing.sm),
                itemBuilder: (context, index) =>
                    _BatchCard(batch: value[index]),
              ),
              AsyncError() => Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      l10n.batchesError,
                      key: const Key('batches-error'),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(ticketBatchesProvider(eventId)),
                      child: Text(l10n.orgRetry),
                    ),
                  ],
                ),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(TicketSurSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const new({required this.batch});

  final TicketBatch batch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final tint = context.tints.mint;
    void pick(BatchAction action) => Navigator.of(context).pop((batch, action));
    return Card(
      key: Key('batch-${batch.number}'),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => pick(BatchAction.view),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TicketSurSpacing.md,
            TicketSurSpacing.sm,
            TicketSurSpacing.sm,
            TicketSurSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: tint.background,
                    child: Text(
                      '${batch.number}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tint.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: TicketSurSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.batchTitle(batch.number, batch.total),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          [
                            formatLocalDateTime(batch.createdAt),
                            ?batch.createdBy,
                          ].join(' · '),
                          style: muted,
                        ),
                        if (batch.categories.isNotEmpty)
                          Text(batch.categories.join(', '), style: muted),
                        Text(
                          l10n.batchCounts(
                            batch.issued,
                            batch.redeemed,
                            batch.revoked,
                          ),
                          key: Key('batch-counts-${batch.number}'),
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    key: Key('batch-select-${batch.number}'),
                    onPressed: () => pick(BatchAction.select),
                    icon: const Icon(Icons.checklist_rounded),
                    label: Text(l10n.batchSelect),
                  ),
                  TextButton.icon(
                    key: Key('batch-print-${batch.number}'),
                    onPressed: batch.issued == 0
                        ? null
                        : () => pick(BatchAction.print),
                    icon: const Icon(Icons.print_rounded),
                    label: Text(l10n.batchPrint),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
