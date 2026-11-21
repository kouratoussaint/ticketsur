import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/l10n/l10n.dart';

String adminAccountsFailureMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      AdminAccountsFailure.network => l10n.adminAccountsErrorNetwork,
      AdminAccountsFailure.roleForbidden => l10n.adminAccountsErrorRole,
      AdminAccountsFailure.mfaNeeded => l10n.adminAccountsErrorMfaNeeded,
      AdminAccountsFailure.mfaRequired => l10n.consoleMfaRequired,
      AdminAccountsFailure.adminProtected => l10n.adminAccountsErrorProtected,
      AdminAccountsFailure.self => l10n.adminAccountsErrorSelf,
      AdminAccountsFailure.reasonRequired => l10n.adminAccountsErrorReason,
      AdminAccountsFailure.nameInvalid => l10n.adminAccountsErrorName,
      AdminAccountsFailure.phoneInvalid => l10n.adminAccountsErrorPhone,
      AdminAccountsFailure.emailInvalid => l10n.adminAccountsErrorEmail,
      AdminAccountsFailure.emailTaken => l10n.adminAccountsErrorEmailTaken,
      AdminAccountsFailure.confirmationMismatch =>
        l10n.adminAccountsErrorConfirmation,
      AdminAccountsFailure.lastSuperAdmin => l10n.adminAccountsErrorLastSuper,
      AdminAccountsFailure.deletionNotRequested =>
        l10n.adminAccountsErrorNoDeletion,
      AdminAccountsFailure.accountIsAdmin => l10n.adminAccountsErrorIsAdmin,
      AdminAccountsFailure.notFound => l10n.adminAccountsErrorNotFound,
      AdminAccountsFailure.orgNotFound => l10n.adminOrgsErrorNotFound,
      AdminAccountsFailure.orgClosed => l10n.adminOrgsErrorClosed,
      AdminAccountsFailure.orgTrashed => l10n.adminOrgsErrorTrashed,
      AdminAccountsFailure.orgNotTrashed => l10n.adminOrgsErrorNotTrashed,
      AdminAccountsFailure.orgNameInvalid => l10n.adminOrgsErrorName,
      AdminAccountsFailure.cityInvalid => l10n.adminOrgsErrorCity,
      AdminAccountsFailure.memberIsOwner => l10n.adminOrgsErrorOwner,
      AdminAccountsFailure.ownerInactive => l10n.adminOrgsErrorOwnerInactive,
      AdminAccountsFailure.accountInactive =>
        l10n.adminOrgsErrorAccountInactive,
      AdminAccountsFailure.structureLimit => l10n.adminOrgsErrorStructureLimit,
      _ => l10n.adminAccountsErrorUnknown,
    };

String adminRoleLabel(AppLocalizations l10n, AdminRole role) => switch (role) {
  AdminRole.superAdmin => l10n.adminRoleSuper,
  AdminRole.support => l10n.adminRoleSupport,
  AdminRole.moderation => l10n.adminRoleModeration,
  AdminRole.finance => l10n.adminRoleFinance,
};

String adminRoleHint(AppLocalizations l10n, AdminRole role) => switch (role) {
  AdminRole.superAdmin => l10n.adminRoleSuperHint,
  AdminRole.support => l10n.adminRoleSupportHint,
  AdminRole.moderation => l10n.adminRoleModerationHint,
  AdminRole.finance => l10n.adminRoleFinanceHint,
};

/// Champ supplémentaire d'une feuille d'action (nom, téléphone, e-mail…).
@immutable
final class ActionField {
  const new({
    required this.name,
    required this.label,
    this.initial,
    this.keyboard = TextInputType.text,
    this.validator,
    this.required = true,
  });

  final String name;
  final String label;
  final String? initial;
  final TextInputType keyboard;
  final String? Function(String value)? validator;
  final bool required;
}

/// Résultat d'une feuille d'action : motif, prévenir, champs saisis.
typedef ActionSheetResult = ({
  String reason,
  bool notify,
  Map<String, String> fields,
});

/// Feuille commune des actions de la console : champs, motif obligatoire,
/// case « Prévenir la personne » ([notifyDefault] nul : pas de case).
Future<ActionSheetResult?> showAccountActionSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? body,
  bool? notifyDefault,
  List<ActionField> fields = const [],
  bool destructive = false,
}) => showModalBottomSheet<ActionSheetResult>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _ActionSheet(
    title: title,
    body: body,
    confirmLabel: confirmLabel,
    notifyDefault: notifyDefault,
    fields: fields,
    destructive: destructive,
  ),
);

class _ActionSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.confirmLabel,
    required this.fields,
    required this.destructive,
    this.body,
    this.notifyDefault,
  });

  final String title;
  final String? body;
  final String confirmLabel;
  final bool? notifyDefault;
  final List<ActionField> fields;
  final bool destructive;

  @override
  State<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<_ActionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late final Map<String, TextEditingController> _fields = {
    for (final field in widget.fields)
      field.name: TextEditingController(text: field.initial),
  };
  late bool _notify = widget.notifyDefault ?? false;

  @override
  void dispose() {
    _reason.dispose();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      reason: _reason.text.trim(),
      notify: _notify,
      fields: {
        for (final MapEntry(:key, :value) in _fields.entries)
          key: value.text.trim(),
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.body case final body?) ...[
                const SizedBox(height: TicketSurSpacing.xs),
                Text(body),
              ],
              const SizedBox(height: TicketSurSpacing.md),
              for (final field in widget.fields) ...[
                TextFormField(
                  key: Key('account-field-${field.name}'),
                  controller: _fields[field.name],
                  keyboardType: field.keyboard,
                  decoration: InputDecoration(labelText: field.label),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return field.required
                          ? l10n.adminAccountsFieldRequired
                          : null;
                    }
                    return field.validator?.call(text);
                  },
                ),
                const SizedBox(height: TicketSurSpacing.sm),
              ],
              TextFormField(
                key: const Key('account-action-reason'),
                controller: _reason,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.adminAccountsReason,
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value ?? '').trim().length < 3
                    ? l10n.adminAccountsErrorReason
                    : null,
              ),
              if (widget.notifyDefault != null)
                CheckboxListTile(
                  key: const Key('account-action-notify'),
                  contentPadding: EdgeInsets.zero,
                  value: _notify,
                  onChanged: (value) =>
                      setState(() => _notify = value ?? false),
                  title: Text(l10n.adminAccountsNotify),
                  subtitle: Text(l10n.adminAccountsNotifyHint),
                ),
              const SizedBox(height: TicketSurSpacing.sm),
              FilledButton(
                key: const Key('account-action-confirm'),
                style: widget.destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      )
                    : null,
                onPressed: _submit,
                child: Text(widget.confirmLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mot de passe provisoire, affiché une seule fois.
Future<void> showTemporaryPassword(
  BuildContext context, {
  required String password,
  String? email,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      key: const Key('temporary-password'),
      title: Text(l10n.adminAccountsTempPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (email != null) Text(email, style: textTheme.titleSmall),
          const SizedBox(height: TicketSurSpacing.sm),
          SelectableText(
            password,
            key: const Key('temporary-password-value'),
            style: textTheme.headlineSmall?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: TicketSurSpacing.sm),
          Text(l10n.adminAccountsTempPasswordHint),
        ],
      ),
      actions: [
        TextButton.icon(
          key: const Key('temporary-password-copy'),
          onPressed: () async {
            final toast = Toaster.of(context);
            await Clipboard.setData(ClipboardData(text: password));
            toast.info(l10n.mfaCopied);
          },
          icon: const Icon(Icons.copy_rounded),
          label: Text(l10n.mfaCopy),
        ),
        FilledButton(
          key: const Key('temporary-password-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adminAccountsTempPasswordDone),
        ),
      ],
    );
  },
);
