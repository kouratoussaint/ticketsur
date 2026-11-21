import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_tools/application/admin_tools_providers.dart';
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Peut envoyer un message ciblé : permission `support` ou `announcements`.
bool canSendMessages(AdminMe? me) =>
    me != null &&
    (me.can(AdminPermission.support) || me.can(AdminPermission.announcements));

/// Boutons communs aux fiches de la console : « Envoyer un message »
/// (si [canMessage]) et « Journal » filtré sur la fiche.
List<Widget> consoleFicheShortcuts(
  BuildContext context,
  WidgetRef ref, {
  required MessageTarget target,
  required AuditScope journal,
  required bool canMessage,
  required String keyPrefix,
}) {
  final l10n = context.l10n;
  return [
    if (canMessage && canSendMessages(ref.watch(adminMeProvider).value))
      OutlinedButton.icon(
        key: Key('$keyPrefix-message'),
        onPressed: () => unawaited(sendConsoleMessage(context, ref, target)),
        icon: const Icon(Icons.campaign_rounded),
        label: Text(l10n.adminMessageSend),
      ),
    OutlinedButton.icon(
      key: Key('$keyPrefix-journal'),
      onPressed: () => unawaited(
        GoRouter.of(context).push(
          Uri(
            path: AppRoutes.consoleJournal,
            queryParameters: journal.toQuery(),
          ).toString(),
        ),
      ),
      icon: const Icon(Icons.history_rounded),
      label: Text(l10n.consoleNavJournal),
    ),
  ];
}

/// Ouvre la feuille d'envoi, envoie et affiche le résultat.
Future<void> sendConsoleMessage(
  BuildContext context,
  WidgetRef ref,
  MessageTarget target,
) async {
  final toast = Toaster.of(context);
  final l10n = context.l10n;
  final count = await showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MessageSheet(
      target: target,
      repository: ref.read(adminToolsRepositoryProvider),
    ),
  );
  if (count != null) toast.success(l10n.adminMessageSent(count));
}

class _MessageSheet extends StatefulWidget {
  const new({required this.target, required this.repository});

  final MessageTarget target;
  final AdminToolsRepository repository;

  @override
  State<_MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<_MessageSheet> {
  static const _durations = [1, 3, 7, 30];

  final _title = TextEditingController();
  final _body = TextEditingController();
  int _days = 7;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.length < 3 || body.isEmpty) {
      setState(() => _error = l10n.adminMessageErrorInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final count = await widget.repository.sendMessage(
        widget.target,
        title: title,
        body: body,
        days: _days,
      );
      if (mounted) Navigator.of(context).pop(count);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = adminAccountsFailureMessage(l10n, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final target = widget.target;
    final hint = switch (target.kind) {
      MessageTargetKind.account => l10n.adminMessageHintAccount(target.name),
      MessageTargetKind.organization => l10n.adminMessageHintOrganization(
        target.name,
      ),
      MessageTargetKind.event => l10n.adminMessageHintEvent(target.name),
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          key: const Key('message-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.adminMessageSend,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(hint, key: const Key('message-hint')),
            const SizedBox(height: TicketSurSpacing.sm),
            TextField(
              key: const Key('message-title'),
              controller: _title,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.adminMessageTitle),
            ),
            TextField(
              key: const Key('message-body'),
              controller: _body,
              maxLength: 1000,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.adminMessageBody),
            ),
            if (target.kind != MessageTargetKind.account) ...[
              Text(l10n.adminMessageDuration),
              const SizedBox(height: TicketSurSpacing.xxs),
              Wrap(
                spacing: TicketSurSpacing.xs,
                children: [
                  for (final days in _durations)
                    ChoiceChip(
                      key: Key('message-days-$days'),
                      label: Text(l10n.adminMessageDays(days)),
                      selected: _days == days,
                      onSelected: (_) => setState(() => _days = days),
                    ),
                ],
              ),
              const SizedBox(height: TicketSurSpacing.sm),
            ],
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: TicketSurSpacing.xs),
                child: Text(
                  error,
                  key: const Key('message-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton.icon(
              key: const Key('message-submit'),
              onPressed: _busy ? null : () => unawaited(_send()),
              icon: const Icon(Icons.send_rounded),
              label: Text(l10n.adminMessageSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
