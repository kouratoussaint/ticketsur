import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart' show AdminAccount;
import 'package:ticketsur/features/admin/presentation/audit_labels.dart';
import 'package:ticketsur/features/admin/presentation/console_assign_sheet.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

String _when(DateTime instant) => formatDateAtTime(instant.toLocal());

/// Console : fiche complète d'un compte et actions (lot 4-11a, ADR 0038).
class AccountDetailPage extends ConsumerWidget {
  const new({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(accountDetailProvider(userId));
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(detail.value?.displayName ?? l10n.adminAccountsTitle),
      ),
      body: switch (detail) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(accountDetailProvider(userId).future),
          child: _Detail(account: value),
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adminAccountsFailureMessage(l10n, error),
                  key: const Key('account-error'),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(accountDetailProvider(userId)),
                  child: Text(l10n.consoleRetry),
                ),
              ],
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const new({required this.account});

  final AccountDetail account;

  /// Lance une action, puis relit la fiche et la liste.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<String?> Function() action,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    try {
      final message = await action();
      if (message != null) toast.success(message);
      ref
        ..invalidate(accountDetailProvider(account.id))
        ..invalidate(adminOverviewProvider);
    } on Object catch (error) {
      toast.error(adminAccountsFailureMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(adminMeProvider).value;
    final self = ref.watch(currentUserProvider).value?.id == account.id;
    final repository = ref.read(adminAccountsRepositoryProvider);
    final notify = me?.notifyUsers ?? false;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    // Compte d'un administrateur : réservé au super administrateur.
    final manageable =
        me != null &&
        !account.deleted &&
        !self &&
        me.can(AdminPermission.accounts) &&
        (account.adminRole == null || me.can(AdminPermission.admins));

    Future<void> edit() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminAccountsEdit,
        confirmLabel: l10n.profileSave,
        notifyDefault: notify,
        fields: [
          ActionField(
            name: 'name',
            label: l10n.adminAccountsName,
            initial: account.displayName,
            validator: (value) => value.length < 2 || value.length > 60
                ? l10n.adminAccountsErrorName
                : null,
          ),
          ActionField(
            name: 'phone',
            label: l10n.adminAccountsPhone,
            initial: account.phone,
            keyboard: TextInputType.phone,
            required: false,
          ),
        ],
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await repository.update(
          account.id,
          displayName: result.fields['name']!,
          phone: result.fields['phone']!.isEmpty
              ? null
              : result.fields['phone'],
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminAccountsUpdated;
      });
    }

    Future<void> changeEmail() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminAccountsEmailChange,
        body: l10n.adminAccountsEmailChangeHint,
        confirmLabel: l10n.profileSave,
        notifyDefault: notify,
        fields: [
          ActionField(
            name: 'email',
            label: l10n.adminAccountsEmail,
            initial: account.email,
            keyboard: TextInputType.emailAddress,
            validator: (value) =>
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)
                ? null
                : l10n.adminAccountsErrorEmail,
          ),
        ],
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await repository.changeEmail(
          account.id,
          email: result.fields['email']!,
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminAccountsEmailChanged;
      });
    }

    Future<void> resetPassword() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminAccountsPassword,
        body: l10n.adminAccountsPasswordHint,
        confirmLabel: l10n.adminAccountsPasswordConfirm,
        notifyDefault: notify,
      );
      if (result == null || !context.mounted) return;
      String? password;
      await _run(context, ref, () async {
        password = await repository.resetPassword(
          account.id,
          reason: result.reason,
          notify: result.notify,
        );
        return null;
      });
      if (password case final value? when context.mounted) {
        await showTemporaryPassword(
          context,
          password: value,
          email: account.email,
        );
      }
    }

    Future<void> signOut() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminAccountsSignOut,
        body: l10n.adminAccountsSignOutHint,
        confirmLabel: l10n.adminAccountsSignOut,
        notifyDefault: notify,
        destructive: true,
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        final count = await repository.signOut(
          account.id,
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminAccountsSignedOut(count);
      });
    }

    Future<void> cancelDeletion() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminAccountsCancelDeletion,
        confirmLabel: l10n.adminAccountsCancelDeletion,
        notifyDefault: notify,
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await repository.cancelDeletion(
          account.id,
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminAccountsDeletionCancelled;
      });
    }

    Future<void> deleteNow() async {
      final email = account.email ?? '';
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminAccountsDeleteNow,
        body: l10n.adminAccountsDeleteNowHint(email),
        confirmLabel: l10n.adminAccountsDeleteNow,
        destructive: true,
        fields: [
          ActionField(
            name: 'confirm',
            label: l10n.adminAccountsDeleteConfirmLabel,
            keyboard: TextInputType.emailAddress,
            validator: (value) => value.toLowerCase() == email.toLowerCase()
                ? null
                : l10n.adminAccountsErrorConfirmation,
          ),
        ],
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        final structures = await repository.deleteNow(
          account.id,
          confirmEmail: result.fields['confirm']!,
          reason: result.reason,
        );
        return l10n.consolePurgeDone(structures);
      });
    }

    Future<void> setRole() async {
      final picked = await showModalBottomSheet<(AdminRole?, String)>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _RoleSheet(current: account.adminRole),
      );
      if (picked == null || !context.mounted) return;
      final (role, reason) = picked;
      await _run(context, ref, () async {
        await repository.setRole(account.id, role, reason: reason);
        ref.invalidate(platformAdminsProvider);
        return role == null
            ? l10n.adminRoleRemoved
            : l10n.adminRoleGiven(adminRoleLabel(l10n, role));
      });
    }

    Future<void> removeMfa() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminAccountsRemoveMfa,
        body: l10n.adminAccountsRemoveMfaHint,
        confirmLabel: l10n.adminAccountsRemoveMfa,
        destructive: true,
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await repository.removeMfa(account.id, reason: result.reason);
        return l10n.adminAccountsMfaRemoved;
      });
    }

    Future<void> assign() async {
      final changed = await showAssignOrganizationSheet(
        context,
        account: AdminAccount(
          id: account.id,
          displayName: account.displayName,
          email: account.email,
          active: account.active,
          createdAt: account.createdAt,
        ),
      );
      if (changed) ref.invalidate(accountDetailProvider(account.id));
    }

    final actions = <Widget>[
      if (manageable) ...[
        OutlinedButton.icon(
          key: const Key('account-edit'),
          onPressed: () => unawaited(edit()),
          icon: const Icon(Icons.edit_rounded),
          label: Text(l10n.adminAccountsEdit),
        ),
        OutlinedButton.icon(
          key: const Key('account-email'),
          onPressed: () => unawaited(changeEmail()),
          icon: const Icon(Icons.alternate_email_rounded),
          label: Text(l10n.adminAccountsEmailChange),
        ),
        OutlinedButton.icon(
          key: const Key('account-password'),
          onPressed: () => unawaited(resetPassword()),
          icon: const Icon(Icons.password_rounded),
          label: Text(l10n.adminAccountsPassword),
        ),
        OutlinedButton.icon(
          key: const Key('account-sign-out'),
          onPressed: () => unawaited(signOut()),
          icon: const Icon(Icons.logout_rounded),
          label: Text(l10n.adminAccountsSignOut),
        ),
        if (account.deletionRequestedAt != null)
          OutlinedButton.icon(
            key: const Key('account-cancel-deletion'),
            onPressed: () => unawaited(cancelDeletion()),
            icon: const Icon(Icons.restore_rounded),
            label: Text(l10n.adminAccountsCancelDeletion),
          ),
      ],
      if (me != null &&
          me.can(AdminPermission.organizations) &&
          account.active &&
          !account.deleted)
        OutlinedButton.icon(
          key: const Key('account-assign'),
          onPressed: () => unawaited(assign()),
          icon: const Icon(Icons.add_business_rounded),
          label: Text(l10n.assignTitle),
        ),
      if (me != null && me.can(AdminPermission.admins) && !account.deleted) ...[
        OutlinedButton.icon(
          key: const Key('account-role'),
          onPressed: () => unawaited(setRole()),
          icon: const Icon(Icons.admin_panel_settings_rounded),
          label: Text(l10n.adminRoleTitle),
        ),
        if (account.mfaEnrolled && !self)
          OutlinedButton.icon(
            key: const Key('account-remove-mfa'),
            onPressed: () => unawaited(removeMfa()),
            icon: const Icon(Icons.no_encryption_rounded),
            label: Text(l10n.adminAccountsRemoveMfa),
          ),
      ],
      if (me != null &&
          me.can(AdminPermission.accountsDelete) &&
          !account.deleted &&
          !self &&
          account.adminRole == null)
        FilledButton.icon(
          key: const Key('account-delete-now'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => unawaited(deleteNow()),
          icon: const Icon(Icons.delete_forever_rounded),
          label: Text(l10n.adminAccountsDeleteNow),
        ),
    ];

    return ListView(
      key: const Key('account-detail'),
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      children: [
        TikeoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(account.displayName, style: textTheme.titleLarge),
              if (account.email case final email? when !account.deleted)
                Text(email, key: const Key('account-email-value')),
              if (account.phone case final phone?) Text(phone),
              const SizedBox(height: TicketSurSpacing.xs),
              Wrap(
                spacing: TicketSurSpacing.xxs,
                runSpacing: TicketSurSpacing.xxs,
                children: [
                  if (account.adminRole case final role?)
                    ConsoleTag(
                      key: const Key('account-role-tag'),
                      label: adminRoleLabel(l10n, role),
                      danger: false,
                    ),
                  if (account.deleted)
                    ConsoleTag(label: l10n.consoleAccountDeleted, danger: true)
                  else if (!account.active)
                    ConsoleTag(
                      label: l10n.consoleAccountDisabled,
                      danger: true,
                    ),
                  if (account.deletionRequestedAt != null && !account.deleted)
                    ConsoleTag(
                      label: l10n.adminAccountsDeletionRequested,
                      danger: true,
                    ),
                  if (account.mustChangePassword)
                    ConsoleTag(
                      key: const Key('account-must-change'),
                      label: l10n.adminAccountsMustChange,
                      danger: false,
                    ),
                  if (account.mfaEnrolled)
                    ConsoleTag(label: l10n.mfaTitle, danger: false),
                ],
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Text(
                l10n.consoleAccountCreated(_day(account.createdAt)),
                style: muted,
              ),
              Text(
                account.lastSignInAt == null
                    ? l10n.consoleAccountNeverSignedIn
                    : l10n.consoleAccountLastSignIn(
                        _when(account.lastSignInAt!),
                      ),
                style: muted,
              ),
              if (!account.active && account.disabledReason != null)
                Text(
                  l10n.adminAccountsDisabledReason(account.disabledReason!),
                  style: muted,
                ),
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            key: const Key('account-actions'),
            child: Wrap(
              spacing: TicketSurSpacing.xs,
              runSpacing: TicketSurSpacing.xs,
              children: actions,
            ),
          ),
        ],
        const SizedBox(height: TicketSurSpacing.md),
        _Section(
          title: l10n.adminAccountsStructures,
          empty: l10n.adminAccountsNoStructure,
          children: [
            for (final org in account.organizations)
              ListTile(
                key: Key('account-org-${org.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apartment_rounded),
                title: Text(org.name),
                subtitle: Text(
                  [
                    roleLabel(l10n, org.role),
                    if (!org.memberActive) l10n.adminAccountsMemberInactive,
                    if (!org.organizationActive) l10n.consoleAccountDisabled,
                  ].join(' · '),
                ),
              ),
          ],
        ),
        const SizedBox(height: TicketSurSpacing.md),
        TikeoCard(
          key: const Key('account-activity'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.adminAccountsActivity, style: textTheme.titleMedium),
              const SizedBox(height: TicketSurSpacing.xs),
              Text(l10n.adminAccountsWalletTickets(account.walletTickets)),
              Text(
                l10n.adminAccountsSupport(
                  account.supportRequests,
                  account.supportOpen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TicketSurSpacing.md),
        _Section(
          title: l10n.devicesTitle,
          empty: l10n.adminAccountsNoDevice,
          children: [
            for (final device in account.devices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.smartphone_rounded),
                title: Text(device.label),
                subtitle: Text(
                  l10n.adminAccountsDeviceSeen(_when(device.lastSeenAt)),
                ),
              ),
          ],
        ),
        const SizedBox(height: TicketSurSpacing.md),
        _Section(
          title: l10n.adminAccountsHistory,
          empty: l10n.adminAccountsNoHistory,
          children: [
            for (final action in account.actions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded),
                title: Text(auditActionLabel(l10n, action.action)),
                subtitle: Text(
                  '${_when(action.at)} · ${action.by}\n'
                  '${l10n.adminAccountsReasonValue(action.reason)}',
                ),
                isThreeLine: true,
              ),
          ],
        ),
        const SizedBox(height: TicketSurSpacing.xl),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.title, required this.empty, required this.children});

  final String title;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => TikeoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TicketSurSpacing.xs),
        if (children.isEmpty)
          Text(empty, style: TextStyle(color: context.palette.mutedText))
        else
          ...children,
      ],
    ),
  );
}

/// Choix du rôle d'administration (ou aucun) et motif.
class _RoleSheet extends StatefulWidget {
  const new({required this.current});

  final AdminRole? current;

  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  late AdminRole? _role = widget.current;
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.md,
      ),
      child: SingleChildScrollView(
        child: RadioGroup<AdminRole?>(
          groupValue: _role,
          onChanged: (role) => setState(() => _role = role),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.adminRoleTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(l10n.adminRoleMfaHint),
              RadioListTile<AdminRole?>(
                key: const Key('admin-role-none'),
                value: null,
                title: Text(l10n.adminRoleNone),
              ),
              for (final role in AdminRole.values)
                RadioListTile<AdminRole?>(
                  key: Key('admin-role-${role.wireName}'),
                  value: role,
                  title: Text(adminRoleLabel(l10n, role)),
                  subtitle: Text(adminRoleHint(l10n, role)),
                ),
              TextField(
                key: const Key('account-action-reason'),
                controller: _reason,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.adminAccountsReason,
                  errorText: _error,
                ),
              ),
              FilledButton(
                key: const Key('account-action-confirm'),
                onPressed: () {
                  if (_reason.text.trim().length < 3) {
                    setState(() => _error = l10n.adminAccountsErrorReason);
                    return;
                  }
                  Navigator.of(context).pop((_role, _reason.text.trim()));
                },
                child: Text(l10n.profileSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
