import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_error_banner.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Connexion par adresse e-mail et mot de passe (S03, AUTH-01).
class SignInPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  AuthFailure? _failure;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      if (mounted) context.go(AppRoutes.home);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;
    // Arrivée directe ici (session expirée) : Retour ne quitte pas d'un coup.
    return DoubleBackToExit(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.signInTitle)),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: ListView(
                padding: const EdgeInsets.all(TicketSurSpacing.lg),
                children: [
                  if (failure != null) ...[
                    AuthErrorBanner(message: authFailureMessage(l10n, failure)),
                    const SizedBox(height: TicketSurSpacing.md),
                  ],
                  TextFormField(
                    key: const Key('sign-in-email'),
                    controller: _email,
                    enabled: !_submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l10n.signInEmailLabel,
                    ),
                    validator: (value) => validateEmail(l10n, value),
                  ),
                  const SizedBox(height: TicketSurSpacing.md),
                  TextFormField(
                    key: const Key('sign-in-password'),
                    controller: _password,
                    enabled: !_submitting,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.signInPasswordLabel,
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? l10n.signInShowPassword
                            : l10n.signInHidePassword,
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (value) => (value ?? '').isEmpty
                        ? l10n.validationPasswordRequired
                        : null,
                  ),
                  const SizedBox(height: TicketSurSpacing.lg),
                  FilledButton(
                    key: const Key('sign-in-submit'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : Text(l10n.signInSubmit),
                  ),
                  const SizedBox(height: TicketSurSpacing.xs),
                  TextButton(
                    key: const Key('sign-in-forgot'),
                    onPressed: _submitting
                        ? null
                        : () => context.push(AppRoutes.forgotPassword),
                    child: Text(l10n.signInForgotPassword),
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
