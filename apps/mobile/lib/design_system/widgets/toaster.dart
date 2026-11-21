import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';

/// Nature d'un message.
enum ToastTone {
  /// Action réussie : vert, son de réussite.
  success,

  /// Action refusée ou échouée : rouge, son d'erreur.
  error,

  /// Information neutre : sans son.
  info,
}

/// Messages éphémères stylés, avec retour sonore et haptique.
///
/// À obtenir AVANT toute attente asynchrone (`Toaster.of(context)`), comme
/// un `ScaffoldMessenger`.
final class Toaster {
  const new _(this._messenger, this._feedback);

  /// Messagerie et retours du contexte donné.
  factory of(BuildContext context) => Toaster._(
    ScaffoldMessenger.of(context),
    ProviderScope.containerOf(context, listen: false).read(feedbackProvider),
  );

  final ScaffoldMessengerState _messenger;
  final AppFeedback _feedback;

  /// Hauteur d'une barre posée en bas de l'écran (barre d'actions du mode
  /// sélection) : les messages s'affichent au-dessus, sans la couvrir.
  static final bottomClearance = ValueNotifier<double>(0);

  /// Vrai quand un message d'erreur doit être tu (une feuille l'explique
  /// déjà, comme « Limite atteinte »). Réglé par l'application.
  static bool Function()? muteErrors;

  void success(String message, {Key? key}) =>
      show(message, tone: ToastTone.success, key: key);

  void error(String message, {Key? key}) {
    if (muteErrors?.call() ?? false) return;
    show(message, tone: ToastTone.error, key: key);
  }

  void info(
    String message, {
    Key? key,
    Duration? duration,
    SnackBarAction? action,
  }) => show(
    message,
    tone: ToastTone.info,
    key: key,
    duration: duration,
    action: action,
  );

  void show(
    String message, {
    required ToastTone tone,
    Key? key,
    Duration? duration,
    SnackBarAction? action,
  }) {
    switch (tone) {
      case ToastTone.success:
        _feedback.success();
      case ToastTone.error:
        _feedback.error();
      case ToastTone.info:
        break;
    }
    _messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: key,
          duration: duration ?? const Duration(seconds: 4),
          backgroundColor: switch (tone) {
            // Fonds sombres : texte blanc ≥ 6:1.
            ToastTone.success => const Color(0xFF1B6E35),
            ToastTone.error => const Color(0xFFA4262C),
            ToastTone.info => null,
          },
          content: _ToastContent(message: message, tone: tone),
          action: action,
          margin: switch (bottomClearance.value) {
            0 => null,
            final clearance => EdgeInsets.fromLTRB(15, 5, 15, 10 + clearance),
          },
          // Avec « Annuler » : disparaît quand même après le délai.
          persist: false,
        ),
      );
  }
}

class _ToastContent extends StatelessWidget {
  const new({required this.message, required this.tone});

  final String message;
  final ToastTone tone;

  @override
  Widget build(BuildContext context) {
    final icon = switch (tone) {
      ToastTone.success => Icons.check_circle_rounded,
      ToastTone.error => Icons.error_rounded,
      ToastTone.info => Icons.info_rounded,
    };
    final reduced = TicketSurMotion.reduced(context);
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: reduced ? 1 : 0.4, end: 1),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 420),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Icon(icon, color: TicketSurColors.white),
        ),
        const SizedBox(width: TicketSurSpacing.sm),
        Expanded(child: Text(message)),
      ],
    );
  }
}
