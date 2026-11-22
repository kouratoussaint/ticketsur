import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_tools/application/admin_tools_providers.dart';
import 'package:ticketsur/features/platform/application/platform_providers.dart';
import 'package:ticketsur/features/platform/domain/platform_status.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Réglages de la plateforme (lot 4-11d) : maintenance, message,
/// modifications bloquées, inscriptions. [editable] : permission `settings`.
class ConsolePlatformCard extends ConsumerWidget {
  const new({required this.editable, super.key});

  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(platformStatusProvider)) {
        AsyncData(:final value) => _PlatformForm(
          key: ValueKey(value),
          status: value,
          editable: editable,
        ),
        AsyncError() => TikeoCard(
          child: Text(context.l10n.adminAccountsErrorUnknown),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      };
}

class _PlatformForm extends ConsumerStatefulWidget {
  const new({required this.status, required this.editable, super.key});

  final PlatformStatus status;
  final bool editable;

  @override
  ConsumerState<_PlatformForm> createState() => _PlatformFormState();
}

class _PlatformFormState extends ConsumerState<_PlatformForm> {
  late bool _maintenance = widget.status.maintenance;
  late bool _blockWrites = widget.status.writesBlocked;
  late bool _signupsOpen = widget.status.signupsOpen;
  late final _message = TextEditingController(
    text: widget.status.message ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(adminToolsRepositoryProvider)
          .savePlatformStatus(
            maintenance: _maintenance,
            message: _maintenance ? _message.text : '',
            blockWrites: _maintenance && _blockWrites,
            signupsOpen: _signupsOpen,
          );
      toast.success(l10n.consoleSettingsSaved);
      ref.invalidate(platformStatusProvider);
    } on Object catch (error) {
      toast.error(adminAccountsFailureMessage(l10n, error));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final editable = widget.editable && !_busy;
    return TikeoCard(
      key: const Key('console-platform'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.consolePlatformTitle, style: textTheme.titleMedium),
          SwitchListTile(
            key: const Key('console-maintenance'),
            contentPadding: EdgeInsets.zero,
            value: _maintenance,
            onChanged: editable
                ? (value) => setState(() => _maintenance = value)
                : null,
            title: Text(l10n.consoleMaintenance),
            subtitle: Text(l10n.consoleMaintenanceHint),
          ),
          if (_maintenance) ...[
            TextField(
              key: const Key('console-maintenance-message'),
              controller: _message,
              enabled: editable,
              maxLength: 300,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.consoleMaintenanceMessage,
              ),
            ),
            SwitchListTile(
              key: const Key('console-maintenance-writes'),
              contentPadding: EdgeInsets.zero,
              value: _blockWrites,
              onChanged: editable
                  ? (value) => setState(() => _blockWrites = value)
                  : null,
              title: Text(l10n.consoleMaintenanceWrites),
              subtitle: Text(l10n.consoleMaintenanceWritesHint),
            ),
          ],
          SwitchListTile(
            key: const Key('console-signups-open'),
            contentPadding: EdgeInsets.zero,
            value: _signupsOpen,
            onChanged: editable
                ? (value) => setState(() => _signupsOpen = value)
                : null,
            title: Text(l10n.consoleSignupsOpen),
            subtitle: Text(l10n.consoleSignupsOpenHint),
          ),
          if (widget.editable) ...[
            const SizedBox(height: TicketSurSpacing.xs),
            FilledButton(
              key: const Key('console-platform-save'),
              onPressed: editable ? () => unawaited(_save()) : null,
              child: Text(l10n.consolePlatformSave),
            ),
          ],
        ],
      ),
    );
  }
}
