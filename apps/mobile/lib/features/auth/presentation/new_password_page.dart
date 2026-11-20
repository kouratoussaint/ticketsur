import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_error_banner.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/features/auth/presentation/auth_widgets.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Écran I : nouveau mot de passe, ouvert par le lien « mot de passe
/// oublié » reçu par e-mail (session de récupération, sans l'actuel).
class NewPasswordPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends ConsumerState<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  AuthFailure? _failure;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).setNewPassword(_password.text);
      if (!mounted) return;
      context.go(AppRoutes.home);
      toast.success(l10n.profilePasswordChanged);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;
    Widget visibility() => IconButton(
      tooltip: _obscure ? l10n.signInShowPassword : l10n.signInHidePassword,
      icon: Icon(
        _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
    return Form(
      key: _formKey,
      child: AuthScaffold(
        title: l10n.newPasswordTitle,
        subtitle: l10n.newPasswordSubtitle,
        illustration: TikeoIllustration.lock,
        content: [
          if (failure != null) ...[
            AuthErrorBanner(
              message: authFailureMessage(l10n, failure),
              failure: failure,
            ),
            const SizedBox(height: TicketSurSpacing.md),
          ],
          TikeoFieldLabel(
            label: l10n.profileNewPassword,
            icon: Icons.lock_rounded,
            required: true,
          ),
          TextFormField(
            key: const Key('new-password'),
            controller: _password,
            enabled: !_busy,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(suffixIcon: visibility()),
            validator: (value) =>
                (value ?? '').length < 8 ? l10n.profilePasswordTooShort : null,
          ),
          PasswordStrengthMeter(controller: _password),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoFieldLabel(
            label: l10n.profileConfirmPassword,
            icon: Icons.lock_reset_rounded,
            required: true,
          ),
          TextFormField(
            key: const Key('new-password-confirm'),
            controller: _confirm,
            enabled: !_busy,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            onFieldSubmitted: (_) => unawaited(_submit()),
            validator: (value) =>
                value != _password.text ? l10n.profilePasswordMismatch : null,
          ),
          const SizedBox(height: TicketSurSpacing.md),
          _Rules(controller: _password),
          const SizedBox(height: TicketSurSpacing.lg),
          TikeoPrimaryButton(
            key: const Key('new-password-submit'),
            busy: _busy,
            onPressed: _busy ? null : () => unawaited(_submit()),
            icon: Icons.check_rounded,
            label: l10n.newPasswordSubmit,
          ),
        ],
      ),
    );
  }
}

/// Règles cochées pendant la saisie.
class _Rules extends StatelessWidget {
  const new({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final text = controller.text;
        Widget rule(bool ok, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                ok
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: ok
                    ? tints.green.icon
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(label)),
            ],
          ),
        );
        return Column(
          key: const Key('new-password-rules'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            rule(text.length >= 8, l10n.newPasswordRuleLength),
            rule(
              RegExp('[A-Za-zÀ-ÿ]').hasMatch(text),
              l10n.newPasswordRuleLetters,
            ),
            rule(RegExp(r'\d').hasMatch(text), l10n.newPasswordRuleDigits),
          ],
        );
      },
    );
  }
}
