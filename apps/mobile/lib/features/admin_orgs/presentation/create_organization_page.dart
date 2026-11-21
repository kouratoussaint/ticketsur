import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_orgs/application/admin_orgs_providers.dart';
import 'package:ticketsur/features/admin_orgs/presentation/account_picker.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Console : créer une structure pour un compte (au pack de ce compte).
/// Renvoie l'identifiant de la structure créée.
class CreateOrganizationPage extends ConsumerStatefulWidget {
  const new({this.owner, super.key});

  /// Propriétaire choisi d'avance (depuis la fiche d'un compte).
  final AdminAccount? owner;

  @override
  ConsumerState<CreateOrganizationPage> createState() =>
      _CreateOrganizationPageState();
}

class _CreateOrganizationPageState
    extends ConsumerState<CreateOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _reason = TextEditingController();
  late AdminAccount? _owner = widget.owner;
  late bool _notify = ref.read(adminMeProvider).value?.notifyUsers ?? false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _city, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    final owner = _owner;
    if (owner == null) {
      setState(() => _error = l10n.adminOrgsOwnerRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(adminOrgsRepositoryProvider)
          .create(
            ownerId: owner.id,
            name: _name.text,
            city: _city.text.trim().isEmpty ? null : _city.text.trim(),
            reason: _reason.text,
            notify: _notify,
          );
      ref.invalidate(adminOverviewProvider);
      if (mounted) Navigator.of(context).pop(id);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = adminAccountsFailureMessage(l10n, error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.adminOrgsCreate)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TicketSurSpacing.md),
            child: TikeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.adminOrgsCreateHint),
                  if (_error case final message?) ...[
                    const SizedBox(height: TicketSurSpacing.sm),
                    Text(
                      message,
                      key: const Key('create-org-error'),
                      style: TextStyle(color: error),
                    ),
                  ],
                  const SizedBox(height: TicketSurSpacing.md),
                  Text(
                    l10n.adminOrgsOwner,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  AccountPicker(
                    keyPrefix: 'create-org-owner',
                    picked: _owner,
                    onPicked: (account) => setState(() => _owner = account),
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  TextFormField(
                    key: const Key('create-org-name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.adminOrgsName),
                    validator: (value) {
                      final length = (value ?? '').trim().length;
                      return length < 2 || length > 120
                          ? l10n.adminOrgsErrorName
                          : null;
                    },
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  TextFormField(
                    key: const Key('create-org-city'),
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.adminOrgsCityOptional,
                    ),
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  TextFormField(
                    key: const Key('create-org-reason'),
                    controller: _reason,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: l10n.adminAccountsReason,
                    ),
                    validator: (value) => (value ?? '').trim().length < 3
                        ? l10n.adminAccountsErrorReason
                        : null,
                  ),
                  CheckboxListTile(
                    key: const Key('create-org-notify'),
                    contentPadding: EdgeInsets.zero,
                    value: _notify,
                    onChanged: (value) =>
                        setState(() => _notify = value ?? false),
                    title: Text(l10n.adminAccountsNotify),
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  FilledButton.icon(
                    key: const Key('create-org-submit'),
                    onPressed: _busy ? null : () => unawaited(_submit()),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_business_rounded),
                    label: Text(l10n.adminOrgsCreate),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
