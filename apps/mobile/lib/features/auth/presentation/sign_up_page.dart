import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_error_banner.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/join_organization_page.dart';
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
  String? _info;

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
    setState(() {
      _failure = null;
      _info = null;
    });
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
          );
      if (!signedIn) {
        // Confirmation par e-mail exigée : la structure et le code se feront
        // après la première connexion, depuis le profil.
        if (mounted) setState(() => _info = l10n.signUpConfirmEmail);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final failure = _failure;
    Widget gap([double size = TicketSurSpacing.md]) => SizedBox(height: size);
    final codeField = TextFormField(
      key: const Key('sign-up-code'),
      controller: _code,
      enabled: !_submitting,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [InvitationCodeFormatter()],
      decoration: InputDecoration(
        labelText: l10n.signUpCodeLabel,
        helperText: l10n.signUpCodeHelp,
        hintText: 'TSI-XXXX-XXXX-XXXX',
        prefixIcon: const Icon(Icons.key_rounded),
      ),
      validator: (value) {
        final text = value ?? '';
        return text.isEmpty || text.length == 'TSI-XXXX-XXXX-XXXX'.length
            ? null
            : l10n.joinInvalid;
      },
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUpTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(TicketSurSpacing.lg),
              children: [
                const Center(child: TikeoLogo(height: 56)),
                gap(TicketSurSpacing.lg),
                if (failure != null) ...[
                  AuthErrorBanner(message: authFailureMessage(l10n, failure)),
                  gap(),
                ],
                if (_info case final info?) ...[
                  Card(
                    key: const Key('sign-up-confirm'),
                    child: ListTile(
                      leading: const Icon(Icons.mark_email_read_rounded),
                      title: Text(info),
                    ),
                  ),
                  gap(),
                ],
                if (widget.withCode) ...[codeField, gap()],
                TextFormField(
                  key: const Key('sign-up-name'),
                  controller: _name,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(labelText: l10n.signUpNameLabel),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.signUpNameRequired
                      : null,
                ),
                gap(),
                TextFormField(
                  key: const Key('sign-up-email'),
                  controller: _email,
                  enabled: !_submitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: l10n.signInEmailLabel),
                  validator: (value) => validateEmail(l10n, value),
                ),
                gap(),
                TextFormField(
                  key: const Key('sign-up-password'),
                  controller: _password,
                  enabled: !_submitting,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: l10n.signInPasswordLabel,
                    helperText: l10n.signUpPasswordHelp,
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
                  validator: (value) => (value ?? '').length < 8
                      ? l10n.signUpPasswordTooShort
                      : null,
                ),
                gap(),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      CheckboxListTile(
                        key: const Key('sign-up-promoter'),
                        value: _promoter,
                        onChanged: _submitting
                            ? null
                            : (value) =>
                                  setState(() => _promoter = value ?? false),
                        title: Text(l10n.signUpPromoter),
                        subtitle: Text(l10n.signUpPromoterHint),
                        secondary: const Icon(Icons.campaign_rounded),
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
                                  children: [
                                    TextFormField(
                                      key: const Key('sign-up-structure'),
                                      controller: _structure,
                                      enabled: !_submitting,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: InputDecoration(
                                        labelText: l10n.orgNameLabel,
                                      ),
                                      validator: (value) =>
                                          _promoter &&
                                              (value ?? '').trim().length < 2
                                          ? l10n.signUpStructureRequired
                                          : null,
                                    ),
                                    gap(),
                                    TextFormField(
                                      key: const Key('sign-up-public-phone'),
                                      controller: _publicPhone,
                                      enabled: !_submitting,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: l10n.orgPublicPhoneLabel,
                                        helperText: l10n.orgPublicPhoneHelp,
                                        helperMaxLines: 3,
                                        prefixIcon: const Icon(
                                          Icons.chat_rounded,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                if (!widget.withCode) ...[gap(), codeField],
                gap(),
                const _LegalNotice(),
                gap(),
                FilledButton(
                  key: const Key('sign-up-submit'),
                  onPressed: _submitting ? null : () => unawaited(_submit()),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(l10n.signUpSubmit),
                ),
                gap(TicketSurSpacing.xs),
                TextButton(
                  key: const Key('sign-up-to-sign-in'),
                  onPressed: _submitting
                      ? null
                      : () => context.pushReplacement(AppRoutes.signIn),
                  child: Text(
                    l10n.signUpHaveAccount,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
