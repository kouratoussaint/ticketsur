import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
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
        final toast = Toaster.of(context);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
        // Message affiché une fois la transition lancée : affiché avant, il
        // apparaîtrait à la fois dans l'écran qui part et dans celui qui
        // arrive (animations en double).
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => toast.success(l10n.joinWelcome(organization.name)),
        );
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TicketSurSpacing.lg),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: TikeoLogo(height: 52)),
                const SizedBox(height: TicketSurSpacing.md),
                Text(l10n.joinIntro, style: theme.textTheme.bodyLarge),
                const SizedBox(height: TicketSurSpacing.lg),
                TextField(
                  key: const Key('join-code'),
                  controller: _code,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [InvitationCodeFormatter()],
                  style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 2),
                  decoration: InputDecoration(
                    labelText: l10n.joinCodeLabel,
                    hintText: 'TSI-XXXX-XXXX-XXXX',
                    errorText: _error,
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => unawaited(_submit()),
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                FilledButton(
                  key: const Key('join-submit'),
                  onPressed: _busy || !_complete
                      ? null
                      : () => unawaited(_submit()),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(l10n.joinSubmit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
