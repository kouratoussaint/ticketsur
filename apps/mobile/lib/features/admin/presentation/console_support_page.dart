import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/remembered_filters.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/swipe.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/support/application/support_providers.dart';
import 'package:ticketsur/features/support/domain/support.dart';
import 'package:ticketsur/features/support/presentation/support_pages.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Console : demandes de support, non lues d'abord.
class ConsoleSupportPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleSupportPage> createState() => _ConsoleSupportPageState();
}

class _ConsoleSupportPageState extends ConsumerState<ConsoleSupportPage> {
  String _search = '';

  /// `null` : toutes.
  /// Mémorisé (« all » pour toutes) ; ouvertes par défaut.
  late SupportStatus? _status = switch (ref
      .read(rememberedFiltersProvider)
      .read('console.support')) {
    'all' => null,
    final name => enumByName(SupportStatus.values, name) ?? SupportStatus.open,
  };
  int _generation = 0;

  Future<void> _open(SupportRequest request) async {
    await context.push(AppRoutes.consoleSupportThread(request.id));
    // Au retour : non lu, état et nombre de messages ont pu changer.
    ref.invalidate(supportCountsProvider);
    if (mounted) setState(() => _generation++);
  }

  /// Balayage : ferme la demande ; vrai si c'est fait (la ligne part).
  Future<bool> _closeOne(SupportRequest request) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    try {
      await ref.read(supportRepositoryProvider).close(request.id);
    } on Object {
      toast.error(l10n.consoleSupportCloseFailed);
      return false;
    }
    ref.invalidate(supportCountsProvider);
    toast.success(l10n.consoleBulkSupportClosed(1));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(supportRepositoryProvider);
    final filters = <SupportStatus?, String>{
      SupportStatus.open: l10n.supportStatusOpen,
      SupportStatus.answered: l10n.supportStatusAnswered,
      SupportStatus.closed: l10n.supportStatusClosed,
      null: l10n.consoleSupportAll,
    };
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleNavSupport)),
      body: ConsolePagedList<SupportRequest>(
        key: ValueKey(('support', _search, _status, _generation)),
        load: (offset, _) => repository.adminRequests(
          status: _status,
          search: _search,
          offset: offset,
        ),
        header: Padding(
          padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConsoleSearchField(
                key: const Key('console-support-search'),
                hint: l10n.consoleSupportSearch,
                initial: _search,
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: [
                  for (final MapEntry(key: status, value: label)
                      in filters.entries)
                    ChoiceChip(
                      key: Key('console-support-${status?.wireName ?? 'all'}'),
                      label: Text(label),
                      selected: status == _status,
                      onSelected: (_) {
                        ref
                            .read(rememberedFiltersProvider)
                            .write('console.support', status?.name ?? 'all');
                        setState(() => _status = status);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        itemBuilder: (context, request, reload) => SwipeToAct(
          swipeKey: ValueKey('support-swipe-${request.id}'),
          icon: Icons.task_alt_rounded,
          label: l10n.consoleBulkSupportClose,
          danger: false,
          // Une demande fermée ne se ferme pas deux fois.
          enabled: request.status != SupportStatus.closed,
          confirm: () => _closeOne(request),
          onSwiped: reload,
          child: SupportRequestTile(
            request: request,
            onTap: () => unawaited(_open(request)),
          ),
        ),
        idOf: (request) => request.id,
        bulkActions: [
          ConsoleBulkAction(
            key: const Key('console-support-bulk-close'),
            icon: Icons.task_alt_rounded,
            label: l10n.consoleBulkSupportClose,
            run: (context, items, started) async {
              final done = await runConsoleBulk(
                context,
                items: items,
                onStarted: started,
                applies: (r) => r.status != SupportStatus.closed,
                noneMessage: l10n.consoleBulkSupportCloseNone,
                title: l10n.consoleBulkSupportCloseTitle,
                body: l10n.consoleBulkSupportCloseBody,
                confirmLabel: l10n.consoleBulkSupportClose,
                confirmKey: const Key('console-bulk-confirm'),
                act: (r, _) => repository.close(r.id),
                doneMessage: l10n.consoleBulkSupportClosed,
              );
              if (done) ref.invalidate(supportCountsProvider);
              return done;
            },
          ),
        ],
      ),
    );
  }
}
