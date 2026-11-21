import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ouvre « Attribuer une structure » pour [account] (#10). Vrai si une
/// structure a été attribuée.
Future<bool> showAssignOrganizationSheet(
  BuildContext context, {
  required AdminAccount account,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AssignOrganizationSheet(account: account),
    ) ??
    false;

String assignFailureMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      AdminFailure.accountInactive => l10n.assignErrorInactive,
      AdminFailure.alreadyOwner => l10n.assignErrorAlreadyOwner,
      AdminFailure.ownerLocked => l10n.assignErrorOwnerLocked,
      AdminFailure.structureLimit => l10n.assignErrorLimit,
      AdminFailure.network || AdminFailure.unknown => l10n.consoleActionError,
      _ => consoleFailureMessage(l10n, error),
    };

/// Structure, rôle (propriétaire = transfert), motif obligatoire ; les
/// structures actuelles du compte en tête.
class AssignOrganizationSheet extends ConsumerStatefulWidget {
  const new({required this.account, super.key});

  final AdminAccount account;

  @override
  ConsumerState<AssignOrganizationSheet> createState() =>
      _AssignOrganizationSheetState();
}

class _AssignOrganizationSheetState
    extends ConsumerState<AssignOrganizationSheet> {
  final _search = TextEditingController();
  final _reason = TextEditingController();
  late final Future<List<AdminAccountStructure>> _current = _loadCurrent();
  Future<List<AdminOrganization>>? _results;
  Timer? _debounce;
  AdminOrganization? _picked;
  MemberRole _role = MemberRole.manager;
  bool _missingReason = false;
  bool _busy = false;

  Future<List<AdminAccountStructure>> _loadCurrent() =>
      ref.read(adminRepositoryProvider).accountStructures(widget.account.id);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _results = text.trim().length < 2
            ? null
            : ref
                  .read(adminRepositoryProvider)
                  .organizations(search: text.trim(), limit: 8);
      });
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final navigator = Navigator.of(context);
    final picked = _picked;
    final reason = _reason.text.trim();
    if (picked == null) return;
    if (reason.isEmpty) {
      setState(() => _missingReason = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .assignOrganization(
            widget.account.id,
            organizationId: picked.id,
            role: _role,
            reason: reason,
          );
      toast.success(
        l10n.assignDone(roleLabel(l10n, _role).toLowerCase(), picked.name),
      );
      navigator.pop(true);
    } on Object catch (error) {
      toast.error(assignFailureMessage(l10n, error));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        key: const Key('assign-sheet'),
        padding: const EdgeInsets.fromLTRB(
          TicketSurSpacing.lg,
          0,
          TicketSurSpacing.lg,
          TicketSurSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.assignTitle, style: theme.textTheme.titleLarge),
            Text(widget.account.displayName, style: muted),
            const SizedBox(height: TicketSurSpacing.md),
            Text(l10n.assignCurrent, style: theme.textTheme.titleSmall),
            const SizedBox(height: TicketSurSpacing.xs),
            FutureBuilder<List<AdminAccountStructure>>(
              future: _current,
              builder: (context, snapshot) => switch (snapshot) {
                AsyncSnapshot(data: final list?) when list.isEmpty => Text(
                  l10n.assignNone,
                  key: const Key('assign-current-none'),
                  style: muted,
                ),
                AsyncSnapshot(data: final list?) => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in list)
                      TikeoPill(
                        key: Key('assign-current-${s.organizationId}'),
                        label: '${s.name} · ${roleLabel(l10n, s.role)}',
                        tint: s.active ? roleTint(s.role, tints) : tints.gray,
                        icon: roleIcon(s.role),
                      ),
                  ],
                ),
                AsyncSnapshot(hasError: true) => Text(
                  l10n.consoleLoadError,
                  style: muted,
                ),
                _ => const LinearProgressIndicator(),
              },
            ),
            const SizedBox(height: TicketSurSpacing.md),
            Text(l10n.assignStructure, style: theme.textTheme.titleSmall),
            const SizedBox(height: TicketSurSpacing.xs),
            if (_picked case final picked?)
              Card(
                key: const Key('assign-picked'),
                child: ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: Text(picked.name),
                  subtitle: Text(l10n.assignOwnerIs(picked.ownerName)),
                  trailing: IconButton(
                    key: const Key('assign-unpick'),
                    tooltip: l10n.assignChange,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _picked = null),
                  ),
                ),
              )
            else ...[
              TextField(
                key: const Key('assign-org-search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.assignSearchHint,
                ),
                onChanged: _onSearch,
              ),
              if (_results case final results?)
                FutureBuilder<List<AdminOrganization>>(
                  future: results,
                  builder: (context, snapshot) => switch (snapshot) {
                    AsyncSnapshot(data: final list?) when list.isEmpty =>
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l10n.assignNoResult, style: muted),
                      ),
                    AsyncSnapshot(data: final list?) => Column(
                      children: [
                        for (final org in list)
                          ListTile(
                            key: Key('assign-org-${org.id}'),
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.storefront_rounded),
                            title: Text(org.name),
                            subtitle: Text(l10n.assignOwnerIs(org.ownerName)),
                            onTap: () => setState(() => _picked = org),
                          ),
                      ],
                    ),
                    AsyncSnapshot(hasError: true) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l10n.consoleLoadError, style: muted),
                    ),
                    _ => const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                  },
                ),
            ],
            const SizedBox(height: TicketSurSpacing.md),
            Text(l10n.assignRole, style: theme.textTheme.titleSmall),
            const SizedBox(height: TicketSurSpacing.xs),
            SegmentedButton<MemberRole>(
              key: const Key('assign-role'),
              showSelectedIcon: false,
              segments: [
                for (final role in MemberRole.values)
                  ButtonSegment(
                    value: role,
                    label: Text(
                      roleLabel(l10n, role),
                      key: Key('assign-role-${role.wireName}'),
                    ),
                  ),
              ],
              selected: {_role},
              onSelectionChanged: (value) =>
                  setState(() => _role = value.single),
            ),
            const SizedBox(height: 6),
            Text(
              _role == MemberRole.owner
                  ? l10n.assignOwnerHint
                  : l10n.assignMemberHint,
              key: const Key('assign-role-hint'),
              style: muted,
            ),
            const SizedBox(height: TicketSurSpacing.md),
            TextField(
              key: const Key('assign-reason'),
              controller: _reason,
              maxLength: 500,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                labelText: l10n.consoleReason,
                errorText: _missingReason ? l10n.consoleReasonRequired : null,
              ),
              onChanged: (_) {
                if (_missingReason) setState(() => _missingReason = false);
              },
            ),
            const SizedBox(height: TicketSurSpacing.md),
            TikeoPrimaryButton(
              key: const Key('assign-submit'),
              label: _role == MemberRole.owner
                  ? l10n.assignTransfer
                  : l10n.assignSubmit,
              icon: Icons.how_to_reg_rounded,
              busy: _busy,
              onPressed: _picked == null || _busy
                  ? null
                  : () => unawaited(_submit()),
            ),
          ],
        ),
      ),
    );
  }
}
