import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/remembered_filters.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_assign_sheet.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_accounts/presentation/create_account_page.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

String _when(DateTime instant) => formatDateAtTime(instant.toLocal());

/// Comptes de la plateforme : recherche, désactivation, suppression
/// définitive à échéance (30 jours après la demande).
class ConsoleAccountsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleAccountsPage> createState() =>
      _ConsoleAccountsPageState();
}

class _ConsoleAccountsPageState extends ConsumerState<ConsoleAccountsPage> {
  String _search = '';

  /// Filtre affiché (mémorisé).
  late AccountFilter _filter =
      enumByName(
        AccountFilter.values,
        ref.read(rememberedFiltersProvider).read('console.accounts'),
      ) ??
      AccountFilter.all;

  /// Change à chaque action pour relire la liste.
  int _generation = 0;
  bool _selecting = false;

  /// Liste relue depuis le début : nouvelle liste, sans sélection.
  void _restart() {
    _generation++;
    _selecting = false;
  }

  Future<void> _purgeAll(int count) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final confirmed = await showConsoleConfirm(
      context,
      title: l10n.consolePurgeAll(count),
      body: l10n.consolePurgeAllHint,
      confirmLabel: l10n.consolePurgeAccount,
      needsReason: false,
      confirmKey: const Key('console-accounts-purge-confirm'),
    );
    if (confirmed == null) return;
    try {
      final result = await ref.read(adminRepositoryProvider).purgeDueAccounts();
      toast.success(
        l10n.consolePurgeAllDone(result.accounts, result.structures),
      );
      ref.invalidate(adminOverviewProvider);
      if (mounted) setState(_restart);
    } on Object catch (error) {
      toast.error(_actionMessage(l10n, error));
    }
  }

  /// Créer un compte, puis ouvrir sa fiche (lot 4-11a).
  Future<void> _create() async {
    final router = GoRouter.of(context);
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CreateAccountPage()),
    );
    if (id == null || !mounted) return;
    setState(_restart);
    unawaited(router.push(AppRoutes.consoleAccount(id)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(adminRepositoryProvider);
    final me = ref.watch(currentUserProvider).value?.id;
    final due =
        ref.watch(adminOverviewProvider).value?.accountsDeletionDue ?? 0;
    final labels = {
      AccountFilter.all: l10n.consoleAccountsAll,
      AccountFilter.disabled: l10n.consoleAccountsDisabled,
      AccountFilter.deletion: l10n.consoleAccountsDeletion,
      AccountFilter.due: l10n.consoleAccountsDue,
      AccountFilter.deleted: l10n.consoleAccountsDeleted,
    };
    final canCreate =
        ref.watch(adminMeProvider).value?.can(AdminPermission.accounts) ??
        false;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleNavAccounts)),
      // Caché en mode sélection : la barre d'actions est en bas.
      floatingActionButton: canCreate && !_selecting
          ? FloatingActionButton.extended(
              key: const Key('console-account-create'),
              heroTag: 'console-account-create',
              onPressed: () => unawaited(_create()),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(l10n.adminAccountsCreate),
            )
          : null,
      body: ConsolePagedList<AdminAccount>(
        key: ValueKey(('accounts', _search, _filter, _generation)),
        onSelectingChanged: (selecting) =>
            setState(() => _selecting = selecting),
        load: (offset, _) => repository.accounts(
          search: _search,
          filter: _filter,
          offset: offset,
        ),
        header: Padding(
          padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (due > 0) ...[
                FilledButton.icon(
                  key: const Key('console-accounts-purge-all'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => unawaited(_purgeAll(due)),
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: Text(l10n.consolePurgeAll(due)),
                ),
                const SizedBox(height: TicketSurSpacing.sm),
              ],
              ConsoleSearchField(
                key: const Key('console-account-search'),
                hint: l10n.consoleSearchAccounts,
                initial: _search,
                onChanged: (value) => setState(() {
                  _search = value;
                  _selecting = false;
                }),
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: [
                  for (final MapEntry(key: filter, value: label)
                      in labels.entries)
                    ChoiceChip(
                      key: Key('console-accounts-${filter.name}'),
                      label: Text(label),
                      selected: filter == _filter,
                      onSelected: (_) {
                        ref
                            .read(rememberedFiltersProvider)
                            .write('console.accounts', filter.name);
                        setState(() {
                          _filter = filter;
                          _selecting = false;
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        itemBuilder: (context, account, reload) =>
            _AccountTile(account: account, onChanged: reload),
        idOf: (account) => account.id,
        bulkActions: [
          ConsoleBulkAction(
            key: const Key('console-accounts-bulk-disable'),
            icon: Icons.block_rounded,
            label: l10n.consoleBulkDisable,
            danger: true,
            run: (context, items, started) => refreshOverviewAfter(
              ref,
              runConsoleBulk(
                context,
                items: items,
                onStarted: started,
                // Jamais son propre compte ; jamais un compte supprimé.
                applies: (a) => a.active && !a.deleted && a.id != me,
                noneMessage: l10n.consoleBulkAccountsDisableNone,
                title: l10n.consoleBulkAccountsDisableTitle,
                body: l10n.consoleDisableAccountHint,
                confirmLabel: l10n.consoleConfirmDisable,
                confirmKey: const Key('console-bulk-confirm'),
                needsReason: true,
                destructive: true,
                act: (a, reason) => repository.setAccountActive(
                  a.id,
                  active: false,
                  reason: reason,
                ),
                doneMessage: l10n.consoleBulkAccountsDisabled,
              ),
            ),
          ),
          ConsoleBulkAction(
            key: const Key('console-accounts-bulk-reactivate'),
            icon: Icons.restart_alt_rounded,
            label: l10n.consoleReactivate,
            run: (context, items, started) => refreshOverviewAfter(
              ref,
              runConsoleBulk(
                context,
                items: items,
                onStarted: started,
                applies: (a) => !a.active && !a.deleted,
                noneMessage: l10n.consoleBulkAccountsReactivateNone,
                title: l10n.consoleBulkAccountsReactivateTitle,
                body: l10n.consoleBulkReactivateBody,
                confirmLabel: l10n.consoleReactivate,
                confirmKey: const Key('console-bulk-confirm'),
                act: (a, _) => repository.setAccountActive(a.id, active: true),
                doneMessage: l10n.consoleBulkAccountsReactivated,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _actionMessage(AppLocalizations l10n, Object error) =>
    error == AdminFailure.network || error == AdminFailure.unknown
    ? l10n.consoleActionError
    : consoleFailureMessage(l10n, error);

class _AccountTile extends ConsumerWidget {
  const new({required this.account, required this.onChanged});

  final AdminAccount account;
  final VoidCallback onChanged;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final disable = account.active;
    final reason = await showConsoleConfirm(
      context,
      title: disable
          ? l10n.consoleDisableAccount
          : l10n.consoleReactivateAccount,
      body: disable ? l10n.consoleDisableAccountHint : account.displayName,
      confirmLabel: disable
          ? l10n.consoleConfirmDisable
          : l10n.consoleReactivateAccount,
      needsReason: disable,
      destructive: disable,
      confirmKey: const Key('console-account-confirm'),
    );
    if (reason == null) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .setAccountActive(
            account.id,
            active: !disable,
            reason: disable ? reason : null,
          );
      toast.success(
        disable
            ? l10n.consoleAccountDisabledDone
            : l10n.consoleAccountReactivatedDone,
      );
      ref.invalidate(adminOverviewProvider);
      onChanged();
    } on Object catch (error) {
      toast.error(_actionMessage(l10n, error));
    }
  }

  Future<void> _purge(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final confirmed = await showConsoleConfirm(
      context,
      title: l10n.consolePurgeAccount,
      body: '${account.displayName}\n\n${l10n.consolePurgeAccountHint}',
      confirmLabel: l10n.consolePurgeAccount,
      needsReason: false,
      confirmKey: const Key('console-account-purge-confirm'),
    );
    if (confirmed == null) return;
    try {
      final structures = await ref
          .read(adminRepositoryProvider)
          .purgeAccount(account.id);
      toast.success(l10n.consolePurgeDone(structures));
      ref.invalidate(adminOverviewProvider);
      onChanged();
    } on Object catch (error) {
      toast.error(_actionMessage(l10n, error));
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
    final me = ref.watch(currentUserProvider).value?.id == account.id;
    final due = account.dueAt(DateTime.now().toUtc());
    return Card(
      key: Key('console-account-${account.id}'),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    account.displayName,
                    style: textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: TicketSurSpacing.xs),
                Flexible(
                  child: Wrap(
                    spacing: TicketSurSpacing.xxs,
                    runSpacing: TicketSurSpacing.xxs,
                    children: [
                      if (account.platformAdmin)
                        ConsoleTag(
                          label: l10n.consoleAccountAdmin,
                          danger: false,
                        ),
                      if (account.deleted)
                        ConsoleTag(
                          label: l10n.consoleAccountDeleted,
                          danger: true,
                        )
                      else if (due)
                        ConsoleTag(label: l10n.consoleAccountDue, danger: true)
                      else if (!account.active)
                        ConsoleTag(
                          label: l10n.consoleAccountDisabled,
                          danger: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (account.email case final email? when !account.deleted)
              Text(email, style: textTheme.bodyMedium),
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(
              l10n.consoleAccountCreated(_day(account.createdAt)),
              style: muted,
            ),
            Text(
              account.lastSignInAt == null
                  ? l10n.consoleAccountNeverSignedIn
                  : l10n.consoleAccountLastSignIn(_when(account.lastSignInAt!)),
              style: muted,
            ),
            Text(
              l10n.consoleAccountCounts(
                account.memberships,
                account.ownedStructures,
              ),
              style: muted,
            ),
            if (account.deletedAt case final at?)
              Text(l10n.consoleAccountDeletedOn(_day(at)), style: muted)
            else if (account.deletionRequestedAt case final at?)
              Text(
                l10n.consoleAccountDeletionAt(
                  _day(at),
                  _day(account.deletionDueAt ?? at),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            if (!account.active &&
                !account.deleted &&
                account.disabledAt != null)
              Text(
                l10n.consoleAccountDisabledSince(
                  _day(account.disabledAt!),
                  account.disabledReason ?? '—',
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            // Fiche complète du compte (lot 4-11a), aussi pour un compte
            // supprimé ou le sien.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: Key('console-account-open-${account.id}'),
                onPressed: () async {
                  await context.push(AppRoutes.consoleAccount(account.id));
                  onChanged();
                },
                icon: const Icon(Icons.manage_accounts_rounded),
                label: Text(l10n.adminAccountsOpen),
              ),
            ),
            if (!account.deleted && !me) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: [
                  if (account.active)
                    // Attribuer une structure (#10).
                    OutlinedButton.icon(
                      key: const Key('console-account-assign'),
                      onPressed: () async {
                        if (await showAssignOrganizationSheet(
                          context,
                          account: account,
                        )) {
                          onChanged();
                        }
                      },
                      icon: const Icon(Icons.add_business_rounded),
                      label: Text(l10n.assignTitle),
                    ),
                  if (account.active)
                    TextButton.icon(
                      key: const Key('console-account-disable'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () => unawaited(_toggle(context, ref)),
                      icon: const Icon(Icons.person_off_rounded),
                      label: Text(l10n.consoleDisableAccount),
                    )
                  else
                    FilledButton.tonalIcon(
                      key: const Key('console-account-reactivate'),
                      onPressed: () => unawaited(_toggle(context, ref)),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(l10n.consoleReactivateAccount),
                    ),
                  if (due && !account.platformAdmin)
                    FilledButton.icon(
                      key: const Key('console-account-purge'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: () => unawaited(_purge(context, ref)),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: Text(l10n.consolePurgeAccount),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
