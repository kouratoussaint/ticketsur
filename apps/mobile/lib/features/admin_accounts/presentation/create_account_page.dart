import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Console : créer un compte (mot de passe provisoire affiché une fois,
/// à changer à la première connexion). Renvoie l'identifiant créé.
class CreateAccountPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_email, _name, _phone, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(adminAccountsRepositoryProvider)
          .create(
            email: _email.text,
            displayName: _name.text,
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            reason: _reason.text,
          );
      ref.invalidate(adminOverviewProvider);
      if (!mounted) return;
      // Compte créé : plus d'attente pendant la lecture du mot de passe.
      setState(() => _busy = false);
      await showTemporaryPassword(
        context,
        password: created.password,
        email: _email.text.trim().toLowerCase(),
      );
      if (mounted) Navigator.of(context).pop(created.userId);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = adminAccountsFailureMessage(l10n, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(adminMeProvider).value;
    final mfaMissing = me != null && !me.mfaEnrolled;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.adminAccountsCreate)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TicketSurSpacing.md),
            child: TikeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.adminAccountsCreateHint),
                  if (mfaMissing) ...[
                    const SizedBox(height: TicketSurSpacing.sm),
                    Text(
                      l10n.adminAccountsErrorMfaNeeded,
                      key: const Key('create-account-mfa'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_error case final error?) ...[
                    const SizedBox(height: TicketSurSpacing.sm),
                    Text(
                      error,
                      key: const Key('create-account-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: TicketSurSpacing.md),
                  TextFormField(
                    key: const Key('create-account-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.adminAccountsEmail,
                    ),
                    validator: (value) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch((value ?? '').trim())
                        ? null
                        : l10n.adminAccountsErrorEmail,
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  TextFormField(
                    key: const Key('create-account-name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.adminAccountsName,
                    ),
                    validator: (value) {
                      final length = (value ?? '').trim().length;
                      return length < 2 || length > 60
                          ? l10n.adminAccountsErrorName
                          : null;
                    },
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  TextFormField(
                    key: const Key('create-account-phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.adminAccountsPhoneOptional,
                    ),
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  TextFormField(
                    key: const Key('create-account-reason'),
                    controller: _reason,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: l10n.adminAccountsReason,
                    ),
                    validator: (value) => (value ?? '').trim().length < 3
                        ? l10n.adminAccountsErrorReason
                        : null,
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  FilledButton.icon(
                    key: const Key('create-account-submit'),
                    onPressed: _busy ? null : () => unawaited(_submit()),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(l10n.adminAccountsCreate),
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
