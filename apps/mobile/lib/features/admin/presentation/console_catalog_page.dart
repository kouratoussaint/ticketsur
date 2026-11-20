import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _when(DateTime instant) => formatDateAtTime(instant.toLocal());

/// Modération du catalogue public : retirer ou rétablir un événement.
class ConsoleCatalogPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleCatalogPage> createState() => _ConsoleCatalogPageState();
}

class _ConsoleCatalogPageState extends ConsumerState<ConsoleCatalogPage> {
  String _search = '';
  bool _blockedOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(adminRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consoleNavCatalog)),
      body: ConsolePagedList<AdminPublicEvent>(
        key: ValueKey(('catalog', _search, _blockedOnly)),
        load: (offset, _) => repository.publicEvents(
          search: _search,
          blockedOnly: _blockedOnly,
          offset: offset,
        ),
        header: Padding(
          padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConsoleSearchField(
                key: const Key('console-event-search'),
                hint: l10n.consoleSearchEvents,
                initial: _search,
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              FilterChip(
                key: const Key('console-event-blocked-only'),
                label: Text(l10n.consoleBlockedOnly),
                selected: _blockedOnly,
                onSelected: (value) => setState(() => _blockedOnly = value),
              ),
            ],
          ),
        ),
        itemBuilder: (context, event, reload) =>
            _EventTile(event: event, onChanged: reload),
      ),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const new({required this.event, required this.onChanged});

  final AdminPublicEvent event;
  final VoidCallback onChanged;

  Future<void> _act(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final block = !event.blocked;
    final reason = await showConsoleConfirm(
      context,
      title: block ? l10n.consoleBlock : l10n.consoleUnblock,
      body: block ? l10n.consoleBlockHint : l10n.consoleUnblockHint,
      confirmLabel: block ? l10n.consoleConfirmBlock : l10n.consoleUnblock,
      needsReason: block,
      destructive: block,
      confirmKey: const Key('console-event-confirm'),
    );
    if (reason == null) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .setEventBlocked(
            event.id,
            blocked: block,
            reason: block ? reason : null,
          );
      toast.success(
        block ? l10n.consoleBlockedDone : l10n.consoleUnblockedDone,
      );
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
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    final place = [event.organizationName, ?event.city].join(' · ');
    return Card(
      key: Key('console-event-${event.id}'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  eventKindIcon(event.kind),
                  color: context.palette.accentText,
                ),
                const SizedBox(width: TicketSurSpacing.sm),
                Expanded(
                  child: Text(event.title, style: textTheme.titleMedium),
                ),
                const SizedBox(width: TicketSurSpacing.xs),
                if (event.blocked)
                  ConsoleTag(label: l10n.consoleBlocked, danger: true)
                else
                  ConsoleTag(
                    label: event.listed
                        ? l10n.consoleListed
                        : l10n.consoleNotListed,
                    danger: false,
                  ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(place, style: muted),
            Text(
              '${_when(event.startsAt)} · '
              '${eventStatusLabel(l10n, event.status)}',
              style: muted,
            ),
            if (event.description case final text? when text.isNotEmpty) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
            if (event.blocked) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              Text(
                l10n.consoleBlockedSince(
                  _when(event.blockedAt!),
                  event.blockedReason ?? '—',
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: TicketSurSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: event.blocked
                  ? FilledButton.tonalIcon(
                      key: const Key('console-event-unblock'),
                      onPressed: () => unawaited(_act(context, ref)),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(l10n.consoleUnblock),
                    )
                  : TextButton.icon(
                      key: const Key('console-event-block'),
                      onPressed: () => unawaited(_act(context, ref)),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.visibility_off_rounded),
                      label: Text(l10n.consoleBlock),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
