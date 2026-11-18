import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_error_banner.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Demande de réinitialisation du mot de passe (S04, AUTH-02).
///
/// La confirmation est identique que le compte existe ou non : l'écran ne
/// doit pas permettre de vérifier quelles adresses sont inscrites.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  AuthFailure? _failure;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) setState(() => _sentTo = email);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final sentTo = _sentTo;
    final failure = _failure;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            children: [
              if (sentTo != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.forgotPasswordSent(sentTo),
                    key: const Key('forgot-sent'),
                    style: textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.signIn),
                  child: Text(l10n.forgotPasswordBackToSignIn),
                ),
              ] else ...[
                Text(l10n.forgotPasswordIntro, style: textTheme.bodyLarge),
                const SizedBox(height: TicketSurSpacing.lg),
                if (failure != null) ...[
                  AuthErrorBanner(message: authFailureMessage(l10n, failure)),
                  const SizedBox(height: TicketSurSpacing.md),
                ],
                TextFormField(
                  key: const Key('forgot-email'),
                  controller: _email,
                  enabled: !_submitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(labelText: l10n.signInEmailLabel),
                  validator: (value) => validateEmail(l10n, value),
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                FilledButton(
                  key: const Key('forgot-submit'),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(l10n.forgotPasswordSubmit),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
