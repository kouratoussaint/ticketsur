// Partie de `tickets_tab_page.dart` (découpage du lot 4-9) :
// feuille d'annulation groupée.
part of 'tickets_tab_page.dart';

/// Confirmation d'annulation groupée, avec motif facultatif. Renvoie le
/// motif (éventuellement vide), ou `null` si l'on renonce.
Future<String?> showBulkRevokeSheet(
  BuildContext context, {
  required int count,
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _BulkRevokeSheet(count: count),
);

class _BulkRevokeSheet extends StatefulWidget {
  const new({required this.count});

  final int count;

  @override
  State<_BulkRevokeSheet> createState() => _BulkRevokeSheetState();
}

class _BulkRevokeSheetState extends State<_BulkRevokeSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TicketSurSpacing.lg,
          0,
          TicketSurSpacing.lg,
          TicketSurSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.ticketsBulkRevokeTitle(widget.count),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            Text(l10n.ticketsBulkRevokeBody),
            const SizedBox(height: TicketSurSpacing.md),
            TextField(
              key: const Key('tickets-bulk-reason'),
              controller: _reason,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.ticketRevokeReason),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            FilledButton(
              key: const Key('tickets-bulk-revoke-confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
              child: Text(l10n.ticketsBulkRevokeTitle(widget.count)),
            ),
          ],
        ),
      ),
    );
  }
}
