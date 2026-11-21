import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Écran de connexion et de compte (direction artistique, écrans A à L) :
/// en-tête héros sans cloche ni avatar, puis une carte blanche posée dessus
/// qui porte le formulaire. Sans barre de navigation.
class AuthScaffold extends StatelessWidget {
  const new({
    required this.title,
    required this.content,
    this.subtitle,
    this.illustration,
    this.footer = const [],
    this.headerKey,
    this.onBack,
    super.key,
  });

  final String title;
  final String? subtitle;
  final TikeoIllustration? illustration;

  /// Contenu de la carte.
  final List<Widget> content;

  /// Sous la carte (liens, autre parcours).
  final List<Widget> footer;
  final Key? headerKey;

  /// Retour (flèche de l'en-tête et bouton Retour d'Android). Par défaut :
  /// l'écran d'où l'on vient, sinon Explorer (jamais quitter l'app d'ici).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    void back() {
      if (onBack case final custom?) return custom();
      if (canPop) {
        Navigator.of(context).maybePop();
      } else {
        GoRouter.of(context).go(AppRoutes.discover);
      }
    }

    // Défilement simple : tous les champs restent construits (et validés
    // par le formulaire), même hors de l'écran.
    return PopScope(
      canPop: onBack == null && canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête et carte dans une même colonne : la partie de la carte
              // posée sur l'en-tête reste touchable.
              TikeoHeroHeader(
                key: headerKey,
                title: title,
                subtitle: subtitle,
                illustration: illustration,
                onBack: back,
                // Avec le retour à gauche, le logo passe à droite.
                actions: const [
                  TikeoLogo(height: TikeoSizes.headerLogo, onDark: true),
                ],
              ),
              TikeoOverlapCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content,
                ),
              ),
              if (footer.isNotEmpty) ...[
                const SizedBox(height: TikeoSizes.cardGap),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TikeoSizes.screenMargin,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: footer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Solidité d'un mot de passe, de 0 (vide) à 4 (excellent) : longueur,
/// lettres, chiffres, autres caractères. Indicatif : le serveur reste juge
/// (8 caractères au moins).
int passwordStrength(String password) {
  if (password.isEmpty) return 0;
  if (password.length < 8) return 1;
  var score = 1;
  final letters = RegExp('[A-Za-zÀ-ÿ]').hasMatch(password);
  final digits = RegExp(r'\d').hasMatch(password);
  final others = RegExp(r'[^A-Za-zÀ-ÿ\d]').hasMatch(password);
  if (letters && digits) score++;
  if (others || (password.contains(RegExp('[A-Z]')) && letters)) score++;
  if (password.length >= 12 && score >= 3) score++;
  return score.clamp(1, 4);
}

/// Indicateur de solidité sous un champ de mot de passe : quatre barres et
/// un libellé, mis à jour pendant la saisie.
class PasswordStrengthMeter extends StatelessWidget {
  const new({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final score = passwordStrength(controller.text);
        if (score == 0) return const SizedBox.shrink();
        final (tint, label) = switch (score) {
          1 => (tints.red, l10n.passwordStrengthWeak),
          2 => (tints.amber, l10n.passwordStrengthMedium),
          3 => (tints.blue, l10n.passwordStrengthGood),
          _ => (tints.green, l10n.passwordStrengthStrong),
        };
        final track = Theme.of(context).colorScheme.surfaceContainerHighest;
        return Padding(
          key: const Key('password-strength'),
          padding: const EdgeInsets.only(top: 8),
          child: Semantics(
            liveRegion: true,
            label: l10n.passwordStrengthLabel(label),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 1; i <= 4; i++) ...[
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= score ? tint.icon : track,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tint.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bouton « Renvoyer » avec un délai de 60 s entre deux envois.
class ResendButton extends StatefulWidget {
  const new({
    required this.label,
    required this.onResend,
    this.startLocked = true,
    this.seconds = 60,
    super.key,
  });

  final String label;

  /// Renvoie l'e-mail ; une erreur est affichée par l'appelant.
  final Future<void> Function() onResend;

  /// Le premier envoi vient d'avoir lieu : attendre avant le suivant.
  final bool startLocked;
  final int seconds;

  @override
  State<ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends State<ResendButton> {
  Timer? _timer;
  late int _left = widget.startLocked ? widget.seconds : 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_left > 0) _tick();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _left--);
      if (_left <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await widget.onResend();
      if (mounted) {
        setState(() => _left = widget.seconds);
        _tick();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextButton.icon(
      key: const Key('auth-resend'),
      onPressed: _busy || _left > 0 ? null : () => unawaited(_resend()),
      icon: const Icon(Icons.refresh_rounded),
      label: Text(
        _left > 0 ? l10n.authResendIn(widget.label, _left) : widget.label,
      ),
    );
  }
}

/// Ouvre l'application de messagerie du téléphone (boîte de réception).
/// Renvoie faux si aucune n'est installée. Remplaçable en test.
final mailboxOpenerProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    try {
      return await const MethodChannel('ticketsur/send')
              .invokeMethod<bool>('mailbox') ??
          false;
    } on Object {
      return false;
    }
  },
);

/// Étape numérotée (confirmation de l'adresse) : rond menthe et texte.
class AuthStep extends StatelessWidget {
  const new({required this.number, required this.text, super.key});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tint = context.tints.mint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.background,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: tint.text),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
