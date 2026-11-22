import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Recherche d'un compte actif dans la console (nom ou e-mail), puis choix.
class AccountPicker extends ConsumerStatefulWidget {
  const new({
    required this.onPicked,
    this.picked,
    this.keyPrefix = 'account-picker',
    super.key,
  });

  final AdminAccount? picked;
  final ValueChanged<AdminAccount?> onPicked;

  /// Préfixe des clés : `<prefix>-search`, `<prefix>-find`,
  /// `<prefix>-result-<id>`, `<prefix>-picked`, `<prefix>-none`.
  final String keyPrefix;

  @override
  ConsumerState<AccountPicker> createState() => _AccountPickerState();
}

class _AccountPickerState extends ConsumerState<AccountPicker> {
  final _search = TextEditingController();
  List<AdminAccount>? _results;
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final text = _search.text.trim();
    if (text.length < 2 || _busy) return;
    setState(() => _busy = true);
    try {
      final rows = await ref
          .read(adminRepositoryProvider)
          .accounts(search: text, limit: 8);
      if (mounted) {
        setState(
          () => _results = [
            for (final account in rows)
              if (account.active && account.deletedAt == null) account,
          ],
        );
      }
    } on Object {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefix = widget.keyPrefix;
    if (widget.picked case final account?) {
      return ListTile(
        key: Key('$prefix-picked'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person_rounded),
        title: Text(account.displayName),
        subtitle: Text(account.email ?? '—'),
        trailing: IconButton(
          tooltip: l10n.adminOrgsChangeAccount,
          onPressed: () => widget.onPicked(null),
          icon: const Icon(Icons.close_rounded),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TikeoSearchBar(
          fieldKey: Key('$prefix-search'),
          controller: _search,
          hint: l10n.adminOrgsFindAccount,
          onSubmitted: (_) => unawaited(_find()),
          suffix: IconButton(
            key: Key('$prefix-find'),
            tooltip: l10n.adminOrgsFindAccount,
            onPressed: () => unawaited(_find()),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
          ),
        ),
        if (_results case final results?)
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: TicketSurSpacing.xs),
              child: Text(l10n.adminOrgsNoAccount, key: Key('$prefix-none')),
            )
          else
            for (final account in results)
              ListTile(
                key: Key('$prefix-result-${account.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(account.displayName),
                subtitle: Text(account.email ?? '—'),
                onTap: () => widget.onPicked(account),
              ),
      ],
    );
  }
}
