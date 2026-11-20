import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/features/auth/presentation/auth_widgets.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Feuille « Changer le mot de passe ».
Future<void> showChangePasswordSheet(BuildContext context) =>
    _showSheet(context, const _ChangePasswordForm());

/// Feuille « Changer d'adresse e-mail ».
Future<void> showChangeEmailSheet(BuildContext context) =>
    _showSheet(context, const _ChangeEmailForm());

Future<void> _showSheet(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        // Le clavier ne recouvre pas les champs.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TicketSurSpacing.md,
            0,
            TicketSurSpacing.md,
            TicketSurSpacing.lg,
          ),
          child: child,
        ),
      ),
    );

class _ChangePasswordForm extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_ChangePasswordForm> createState() =>
      _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
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
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      final toast = Toaster.of(context);
      Navigator.of(context).pop();
      toast.success(l10n.profilePasswordChanged);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(
        () => _error = failure == AuthFailure.invalidCredentials
            ? l10n.profileWrongPassword
            : authFailureMessage(l10n, failure),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final toggle = IconButton(
      onPressed: () => setState(() => _obscure = !_obscure),
      icon: Icon(
        _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      ),
    );
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileChangePassword,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TicketSurSpacing.md),
          if (_error case final error?) ...[
            Text(
              error,
              key: const Key('password-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
          ],
          TextFormField(
            key: const Key('password-current'),
            controller: _current,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: l10n.profileCurrentPassword,
              suffixIcon: toggle,
            ),
            validator: (value) =>
                (value ?? '').isEmpty ? l10n.profilePasswordRequired : null,
          ),
          const SizedBox(height: TicketSurSpacing.sm),
          TextFormField(
            key: const Key('password-new'),
            controller: _next,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(labelText: l10n.profileNewPassword),
            validator: (value) =>
                (value ?? '').length < 8 ? l10n.profilePasswordTooShort : null,
          ),
          // Écran L : solidité du nouveau mot de passe pendant la saisie.
          PasswordStrengthMeter(controller: _next),
          const SizedBox(height: TicketSurSpacing.sm),
          TextFormField(
            key: const Key('password-confirm'),
            controller: _confirm,
            obscureText: _obscure,
            decoration: InputDecoration(labelText: l10n.profileConfirmPassword),
            validator: (value) =>
                value != _next.text ? l10n.profilePasswordMismatch : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: TicketSurSpacing.lg),
          FilledButton(
            key: const Key('password-submit'),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(l10n.profileSave),
          ),
        ],
      ),
    );
  }
}

class _ChangeEmailForm extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_ChangeEmailForm> createState() => _ChangeEmailFormState();
}

class _ChangeEmailFormState extends ConsumerState<_ChangeEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final email = _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).changeEmail(email);
      if (!mounted) return;
      final toast = Toaster.of(context);
      Navigator.of(context).pop();
      toast.info(l10n.profileEmailSent(email));
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = authFailureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = ref.watch(currentUserProvider).value?.email ?? '';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileChangeEmail,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          Text(l10n.profileEmailHelp),
          const SizedBox(height: TicketSurSpacing.md),
          if (_error case final error?) ...[
            Text(
              error,
              key: const Key('email-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
          ],
          TextFormField(
            key: const Key('email-new'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.profileNewEmail),
            validator: (value) {
              final invalid = validateEmail(l10n, value);
              if (invalid != null) return invalid;
              return value!.trim().toLowerCase() == current.toLowerCase()
                  ? l10n.profileEmailSame
                  : null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: TicketSurSpacing.lg),
          FilledButton(
            key: const Key('email-submit'),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(l10n.profileSend),
          ),
        ],
      ),
    );
  }
}
