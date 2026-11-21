import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_error_banner.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/features/auth/presentation/auth_widgets.dart';
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

  Future<void> _openMailbox() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    if (!await ref.read(mailboxOpenerProvider)()) {
      toast.info(l10n.authOpenMailboxFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final sentTo = _sentTo;
    final failure = _failure;
    void back() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.signIn);
    if (sentTo != null) {
      // Écran H : lien envoyé (même message que le compte existe ou non).
      final tint = context.tints.blue;
      return AuthScaffold(
        onBack: back,
        title: l10n.forgotSentTitle,
        illustration: TikeoIllustration.mail,
        content: [
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.forgotPasswordSent(sentTo),
              key: const Key('forgot-sent'),
              style: textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          Container(
            key: const Key('forgot-nothing'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tint.background,
              borderRadius: BorderRadius.circular(TikeoRadii.field),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_rounded, color: tint.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.forgotNothingTitle,
                        style: textTheme.titleSmall?.copyWith(color: tint.text),
                      ),
                      Text(
                        l10n.forgotNothingBody,
                        style: textTheme.bodySmall?.copyWith(color: tint.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.lg),
          TikeoPrimaryButton(
            key: const Key('forgot-open-mailbox'),
            onPressed: () => unawaited(_openMailbox()),
            icon: Icons.mail_rounded,
            label: l10n.authOpenMailbox,
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          OutlinedButton(
            key: const Key('forgot-back'),
            onPressed: back,
            child: Text(l10n.forgotPasswordBackToSignIn),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          ResendButton(
            label: l10n.forgotResendLink,
            onResend: () async {
              final toast = Toaster.of(context);
              try {
                await ref
                    .read(authRepositoryProvider)
                    .sendPasswordReset(sentTo);
                toast.success(l10n.authResent);
              } on AuthFailure catch (failure) {
                toast.error(authFailureMessage(l10n, failure));
              }
            },
          ),
        ],
      );
    }
    // Écran G : demande du lien.
    return Form(
      key: _formKey,
      child: AuthScaffold(
        onBack: back,
        title: l10n.forgotPasswordTitle,
        subtitle: l10n.forgotHeroSubtitle,
        illustration: TikeoIllustration.lock,
        content: [
          Text(l10n.forgotPasswordIntro, style: textTheme.bodyLarge),
          const SizedBox(height: TicketSurSpacing.lg),
          if (failure != null) ...[
            AuthErrorBanner(
              message: authFailureMessage(l10n, failure),
              failure: failure,
            ),
            const SizedBox(height: TicketSurSpacing.md),
          ],
          TikeoFieldLabel(
            label: l10n.signInEmailLabel,
            icon: Icons.alternate_email_rounded,
          ),
          TextFormField(
            key: const Key('forgot-email'),
            controller: _email,
            enabled: !_submitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(hintText: l10n.signInEmailHint),
            validator: (value) => validateEmail(l10n, value),
          ),
          const SizedBox(height: TicketSurSpacing.lg),
          TikeoPrimaryButton(
            key: const Key('forgot-submit'),
            busy: _submitting,
            onPressed: _submitting ? null : _submit,
            icon: Icons.send_rounded,
            label: l10n.forgotPasswordSubmit,
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          TextButton(
            key: const Key('forgot-back'),
            onPressed: _submitting ? null : back,
            child: Text(l10n.forgotPasswordBackToSignIn),
          ),
        ],
      ),
    );
  }
}
