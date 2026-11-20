import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/auth/presentation/auth_error_banner.dart';
import 'package:ticketsur/features/auth/presentation/auth_widgets.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Met le code en forme pendant la saisie : majuscules, tirets
/// « TSI-XXXX-XXXX-XXXX », caractères ambigus (0, O, 1, I) refusés.
class InvitationCodeFormatter extends TextInputFormatter {
  static final _allowed = RegExp('[2-9A-HJ-NP-Z]');

  /// Forme canonique de [input].
  static String format(String input) {
    var raw = input.toUpperCase().replaceAll(RegExp('[^0-9A-Z]'), '');
    if (raw.startsWith('TSI')) raw = raw.substring(3);
    final body = [
      for (final char in raw.split(''))
        if (_allowed.hasMatch(char)) char,
    ].take(12).join();
    final groups = [
      for (var i = 0; i < body.length; i += 4)
        body.substring(i, i + 4 > body.length ? body.length : i + 4),
    ];
    return body.isEmpty ? '' : ['TSI', ...groups].join('-');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = format(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Rejoindre une organisation avec un code d'invitation (ORG-02).
class JoinOrganizationPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<JoinOrganizationPage> createState() =>
      _JoinOrganizationPageState();
}

class _JoinOrganizationPageState extends ConsumerState<JoinOrganizationPage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Structure rejointe : écran K « Code accepté ».
  Organization? _joined;

  bool get _complete => _code.text.length == 'TSI-XXXX-XXXX-XXXX'.length;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_complete) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await ref
          .read(organizationsProvider.notifier)
          .join(_code.text);
      if (!mounted) return;
      final organization = outcome.organization;
      if (outcome.result == JoinResult.joined && organization != null) {
        setState(() => _joined = organization);
        return;
      }
      setState(() => _error = joinResultMessage(l10n, outcome.result));
    } on OrganizationFailure catch (failure) {
      if (mounted) {
        setState(
          () => _error = failure == OrganizationFailure.network
              ? l10n.eventErrorNetwork
              : l10n.eventErrorUnknown,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// « Commencer » : retour à l'écran d'avant, sinon l'accueil.
  void _start() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (_joined case final organization?) {
      // Écran K : code accepté.
      final tint = roleTint(organization.role, context.tints);
      return AuthScaffold(
        title: l10n.joinAcceptedTitle,
        illustration: TikeoIllustration.team,
        content: [
          Column(
            key: const Key('join-accepted'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.joinWelcome(organization.name),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              Text(
                l10n.joinAcceptedBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: TicketSurSpacing.md),
              Center(
                child: TikeoPill(
                  label: roleLabel(l10n, organization.role),
                  tint: tint,
                  icon: roleIcon(organization.role),
                  large: true,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              TikeoPrimaryButton(
                key: const Key('join-start'),
                onPressed: _start,
                icon: Icons.arrow_forward_rounded,
                label: l10n.joinStart,
              ),
            ],
          ),
        ],
      );
    }
    // Écran J : saisie du code.
    return AuthScaffold(
      title: l10n.joinTitle,
      subtitle: l10n.joinHeroSubtitle,
      illustration: TikeoIllustration.team,
      content: [
        FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.joinIntro, style: theme.textTheme.bodyLarge),
              const SizedBox(height: TicketSurSpacing.lg),
              if (_error case final error?) ...[
                AuthErrorBanner(message: error),
                const SizedBox(height: TicketSurSpacing.md),
              ],
              TikeoFieldLabel(
                label: l10n.joinCodeLabel,
                icon: Icons.key_rounded,
              ),
              TextField(
                key: const Key('join-code'),
                controller: _code,
                autofocus: true,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [InvitationCodeFormatter()],
                style: TikeoTextStyles.ticketNumber.copyWith(
                  fontSize: 18,
                  letterSpacing: 1,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'TSI-XXXX-XXXX-XXXX',
                  error: _error == null ? null : const SizedBox.shrink(),
                ),
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => unawaited(_submit()),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              TikeoPrimaryButton(
                key: const Key('join-submit'),
                busy: _busy,
                onPressed: _busy || !_complete
                    ? null
                    : () => unawaited(_submit()),
                icon: Icons.group_add_rounded,
                label: l10n.joinSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
