import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_error_banner.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/features/auth/presentation/auth_widgets.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/join_organization_page.dart';
import 'package:ticketsur/features/platform/application/platform_providers.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Création de compte. Par défaut, un compte classique (Explorer, favoris,
/// profil) ; « Je suis promoteur d'événement » ajoute la structure à créer.
/// Un code d'invitation, facultatif, fait rejoindre l'équipe d'un promoteur.
class SignUpPage extends ConsumerStatefulWidget {
  const new({this.withCode = false, super.key});

  /// Arrivée par « J'ai un code d'invitation » : le champ du code d'abord.
  final bool withCode;

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _structure = TextEditingController();
  final _publicPhone = TextEditingController();
  final _code = TextEditingController();
  bool _promoter = false;
  bool _obscure = true;
  bool _submitting = false;
  AuthFailure? _failure;

  /// Adresse à confirmer (écran F), une fois le compte créé.
  String? _confirmEmail;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _password,
      _structure,
      _publicPhone,
      _code,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = context.l10n;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final toast = Toaster.of(context);
    try {
      final signedIn = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _email.text,
            password: _password.text,
            displayName: _name.text,
            invitationCode: _code.text,
          );
      if (!signedIn) {
        // Confirmation par e-mail exigée : la structure et le code se feront
        // après la première connexion, depuis le profil.
        if (mounted) setState(() => _confirmEmail = _email.text.trim());
        return;
      }
      final followUp = await _followUp(l10n);
      if (!mounted) return;
      context.go(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (followUp case final problem?) {
          toast.error(l10n.signUpStepFailed(problem));
        } else {
          toast.success(l10n.signUpWelcome(_name.text.trim()));
        }
      });
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Structure du promoteur et code d'invitation, une fois connecté.
  /// Renvoie le message d'un échec, `null` si tout a réussi.
  Future<String?> _followUp(AppLocalizations l10n) async {
    final repository = ref.read(organizationRepositoryProvider);
    try {
      if (_promoter) {
        final created = await repository.create(_structure.text.trim());
        final phone = _publicPhone.text.trim();
        if (phone.isNotEmpty) {
          await repository.update(
            created.id,
            OrganizationDraft(name: created.name, publicPhone: phone),
          );
        }
      }
      final code = _code.text;
      if (code.isNotEmpty) {
        final outcome = await repository.join(code);
        if (outcome.result != JoinResult.joined) {
          return joinResultMessage(l10n, outcome.result);
        }
      }
      return null;
    } on OrganizationFailure catch (failure) {
      return failure == OrganizationFailure.network
          ? l10n.eventErrorNetwork
          : l10n.eventErrorUnknown;
    }
  }

  Future<void> _openMailbox() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    if (!await ref.read(mailboxOpenerProvider)()) {
      toast.info(l10n.authOpenMailboxFailed);
    }
  }

  /// Écran F : confirmer l'adresse avant la première connexion.
  Widget _confirm(BuildContext context, String email) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return AuthScaffold(
      title: l10n.confirmEmailTitle,
      // Confirmer l'adresse : Retour mène à la connexion.
      onBack: () => context.pushReplacement(AppRoutes.signIn),
      illustration: TikeoIllustration.mail,
      content: [
        Column(
          key: const Key('sign-up-confirm'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.confirmEmailBody, style: textTheme.bodyLarge),
            Text(
              email,
              key: const Key('sign-up-confirm-email'),
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: TicketSurSpacing.md),
            AuthStep(number: 1, text: l10n.confirmEmailStep1),
            AuthStep(number: 2, text: l10n.confirmEmailStep2),
            AuthStep(number: 3, text: l10n.confirmEmailStep3),
            const SizedBox(height: TicketSurSpacing.md),
            TikeoPrimaryButton(
              key: const Key('sign-up-open-mailbox'),
              onPressed: () => unawaited(_openMailbox()),
              icon: Icons.mail_rounded,
              label: l10n.authOpenMailbox,
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            OutlinedButton(
              key: const Key('sign-up-confirm-sign-in'),
              onPressed: () => context.pushReplacement(AppRoutes.signIn),
              child: Text(l10n.welcomeSignIn),
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            ResendButton(
              label: l10n.authResend,
              onResend: () async {
                final toast = Toaster.of(context);
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .resendSignUpConfirmation(email);
                  toast.success(l10n.authResent);
                } on AuthFailure catch (failure) {
                  toast.error(authFailureMessage(l10n, failure));
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final failure = _failure;
    if (_confirmEmail case final email?) return _confirm(context, email);
    // Inscriptions fermées : le code d'invitation devient obligatoire et
    // passe en premier.
    final closed =
        !(ref.watch(platformStatusProvider).value?.signupsOpen ?? true);
    final withCode = widget.withCode || closed;
    Widget gap([double size = TicketSurSpacing.md]) => SizedBox(height: size);
    final codeField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TikeoFieldLabel(label: l10n.signUpCodeLabel, icon: Icons.key_rounded),
        TextFormField(
          key: const Key('sign-up-code'),
          controller: _code,
          enabled: !_submitting,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [InvitationCodeFormatter()],
          decoration: InputDecoration(
            helperText: l10n.signUpCodeHelp,
            hintText: 'TSI-XXXX-XXXX-XXXX',
          ),
          validator: (value) {
            final text = value ?? '';
            if (text.isEmpty && closed) return l10n.signUpCodeRequired;
            return text.isEmpty || text.length == 'TSI-XXXX-XXXX-XXXX'.length
                ? null
                : l10n.joinInvalid;
          },
        ),
      ],
    );
    final mint = context.tints.mint;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: AuthScaffold(
          title: l10n.signUpTitle,
          subtitle: l10n.signUpHeroSubtitle,
          illustration: TikeoIllustration.team,
          content: [
            if (failure != null) ...[
              AuthErrorBanner(
                message: authFailureMessage(l10n, failure),
                failure: failure,
              ),
              gap(),
            ],
            if (closed) ...[
              TintedBanner(
                key: const Key('sign-up-closed'),
                tint: context.tints.amber,
                icon: Icons.lock_rounded,
                title: l10n.signUpClosedTitle,
                body: l10n.signUpClosedBody,
              ),
              gap(),
            ],
            if (withCode) ...[codeField, gap()],
            TikeoFieldLabel(
              label: l10n.signUpNameLabel,
              icon: Icons.person_rounded,
              required: true,
            ),
            TextFormField(
              key: const Key('sign-up-name'),
              controller: _name,
              enabled: !_submitting,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.signUpNameRequired : null,
            ),
            gap(),
            TikeoFieldLabel(
              label: l10n.signInEmailLabel,
              icon: Icons.alternate_email_rounded,
              required: true,
            ),
            TextFormField(
              key: const Key('sign-up-email'),
              controller: _email,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(hintText: l10n.signInEmailHint),
              validator: (value) => validateEmail(l10n, value),
            ),
            gap(),
            TikeoFieldLabel(
              label: l10n.signInPasswordLabel,
              icon: Icons.lock_rounded,
              required: true,
            ),
            TextFormField(
              key: const Key('sign-up-password'),
              controller: _password,
              enabled: !_submitting,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                helperText: l10n.signUpPasswordRules,
                helperMaxLines: 2,
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
              validator: (value) =>
                  (value ?? '').length < 8 ? l10n.signUpPasswordTooShort : null,
            ),
            PasswordStrengthMeter(controller: _password),
            gap(),
            // Écran E : « Je suis promoteur » ouvre le bloc de la structure.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _promoter ? mint.background : null,
                borderRadius: BorderRadius.circular(TikeoRadii.tile),
                border: Border.all(
                  color: _promoter
                      ? TicketSurColorsMint.border(theme)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              // Material transparent : le fond teinté reste sous la ligne.
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const Key('sign-up-promoter'),
                      value: _promoter,
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() => _promoter = value),
                      title: Text(
                        l10n.signUpPromoter,
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(l10n.signUpPromoterHint),
                      secondary: Icon(Icons.campaign_rounded, color: mint.icon),
                    ),
                    MotionSize(
                      child: !_promoter
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(
                                TicketSurSpacing.md,
                                0,
                                TicketSurSpacing.md,
                                TicketSurSpacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TikeoFieldLabel(
                                    label: l10n.orgNameLabel,
                                    icon: Icons.storefront_rounded,
                                    required: true,
                                  ),
                                  TextFormField(
                                    key: const Key('sign-up-structure'),
                                    controller: _structure,
                                    enabled: !_submitting,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: (value) =>
                                        _promoter &&
                                            (value ?? '').trim().length < 2
                                        ? l10n.signUpStructureRequired
                                        : null,
                                  ),
                                  gap(),
                                  TikeoFieldLabel(
                                    label: l10n.orgPublicPhoneLabel,
                                    icon: Icons.chat_rounded,
                                  ),
                                  TextFormField(
                                    key: const Key('sign-up-public-phone'),
                                    controller: _publicPhone,
                                    enabled: !_submitting,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      helperText: l10n.orgPublicPhoneHelp,
                                      helperMaxLines: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (!withCode) ...[gap(), codeField],
            gap(),
            const _LegalNotice(),
            gap(),
            TikeoPrimaryButton(
              key: const Key('sign-up-submit'),
              busy: _submitting,
              onPressed: _submitting ? null : () => unawaited(_submit()),
              icon: Icons.person_add_alt_1_rounded,
              label: l10n.signUpSubmit,
            ),
          ],
          footer: [
            TextButton(
              key: const Key('sign-up-to-sign-in'),
              onPressed: _submitting
                  ? null
                  : () => context.pushReplacement(AppRoutes.signIn),
              child: Text(l10n.signUpHaveAccount),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordure du bloc promoteur : menthe, plus claire en sombre.
abstract final class TicketSurColorsMint {
  static Color border(ThemeData theme) => theme.brightness == Brightness.dark
      ? const Color(0xFF00C9A7)
      : const Color(0xFF8BE3D2);
}

/// « En créant un compte, vous acceptez les Conditions d'utilisation et la
/// Politique de confidentialité », avec deux liens.
class _LegalNotice extends StatefulWidget {
  const new();

  @override
  State<_LegalNotice> createState() => _LegalNoticeState();
}

class _LegalNoticeState extends State<_LegalNotice> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => unawaited(context.push(AppRoutes.legal(LegalSlug.terms)));
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => unawaited(context.push(AppRoutes.legal(LegalSlug.privacy)));

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final link = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      key: const Key('sign-up-legal'),
      TextSpan(
        style: theme.textTheme.bodySmall,
        children: [
          TextSpan(text: l10n.signUpLegalPrefix),
          TextSpan(text: l10n.legalTerms, style: link, recognizer: _terms),
          TextSpan(text: l10n.signUpLegalAnd),
          TextSpan(text: l10n.legalPrivacy, style: link, recognizer: _privacy),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
