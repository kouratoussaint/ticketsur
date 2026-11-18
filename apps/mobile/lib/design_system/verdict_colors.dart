import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';

/// Nature d'un verdict, telle que l'agent doit la comprendre au premier coup
/// d'œil.
enum VerdictKind {
  /// Confirmation serveur effective : une entrée autorisée.
  admitted,

  /// Refus certain (déjà utilisé, révoqué, inconnu, non autorisé…).
  refused,

  /// Aucune certitude (réseau, timeout, réponse inattendue) : pas d'entrée.
  indeterminate,

  /// Requête en vol, avant toute réponse.
  verifying,
}

/// Couleurs plein écran des verdicts. Identiques en mode clair et sombre :
/// l'agent doit reconnaître un verdict sans dépendre du thème du téléphone.
@immutable
class VerdictColors extends ThemeExtension<VerdictColors> {
  /// Crée un jeu de couleurs de verdict.
  const new({
    required this.admittedBackground,
    required this.admittedForeground,
    required this.refusedBackground,
    required this.refusedForeground,
    required this.indeterminateBackground,
    required this.indeterminateForeground,
    required this.verifyingBackground,
    required this.verifyingForeground,
  });

  /// Valeurs TicketSûr (contrastes ≥ 4,5:1, vérifiés par les tests).
  static const VerdictColors standard = VerdictColors(
    admittedBackground: TicketSurColors.success,
    admittedForeground: TicketSurColors.navy,
    refusedBackground: TicketSurColors.error,
    refusedForeground: TicketSurColors.white,
    indeterminateBackground: TicketSurColors.warning,
    indeterminateForeground: TicketSurColors.navy,
    verifyingBackground: TicketSurColors.verifying,
    verifyingForeground: TicketSurColors.navy,
  );

  /// Fond « entrée autorisée ».
  final Color admittedBackground;

  /// Texte et icône « entrée autorisée ».
  final Color admittedForeground;

  /// Fond « entrée refusée ».
  final Color refusedBackground;

  /// Texte et icône « entrée refusée ».
  final Color refusedForeground;

  /// Fond « état à confirmer ».
  final Color indeterminateBackground;

  /// Texte et icône « état à confirmer ».
  final Color indeterminateForeground;

  /// Fond « vérification en cours ».
  final Color verifyingBackground;

  /// Texte « vérification en cours ».
  final Color verifyingForeground;

  /// Couleur de fond pour [kind].
  Color background(VerdictKind kind) => switch (kind) {
    VerdictKind.admitted => admittedBackground,
    VerdictKind.refused => refusedBackground,
    VerdictKind.indeterminate => indeterminateBackground,
    VerdictKind.verifying => verifyingBackground,
  };

  /// Couleur de premier plan pour [kind].
  Color foreground(VerdictKind kind) => switch (kind) {
    VerdictKind.admitted => admittedForeground,
    VerdictKind.refused => refusedForeground,
    VerdictKind.indeterminate => indeterminateForeground,
    VerdictKind.verifying => verifyingForeground,
  };

  @override
  VerdictColors copyWith({
    Color? admittedBackground,
    Color? admittedForeground,
    Color? refusedBackground,
    Color? refusedForeground,
    Color? indeterminateBackground,
    Color? indeterminateForeground,
    Color? verifyingBackground,
    Color? verifyingForeground,
  }) {
    return VerdictColors(
      admittedBackground: admittedBackground ?? this.admittedBackground,
      admittedForeground: admittedForeground ?? this.admittedForeground,
      refusedBackground: refusedBackground ?? this.refusedBackground,
      refusedForeground: refusedForeground ?? this.refusedForeground,
      indeterminateBackground:
          indeterminateBackground ?? this.indeterminateBackground,
      indeterminateForeground:
          indeterminateForeground ?? this.indeterminateForeground,
      verifyingBackground: verifyingBackground ?? this.verifyingBackground,
      verifyingForeground: verifyingForeground ?? this.verifyingForeground,
    );
  }

  @override
  VerdictColors lerp(VerdictColors? other, double t) {
    if (other == null) return this;
    return VerdictColors(
      admittedBackground: Color.lerp(
        admittedBackground,
        other.admittedBackground,
        t,
      )!,
      admittedForeground: Color.lerp(
        admittedForeground,
        other.admittedForeground,
        t,
      )!,
      refusedBackground: Color.lerp(
        refusedBackground,
        other.refusedBackground,
        t,
      )!,
      refusedForeground: Color.lerp(
        refusedForeground,
        other.refusedForeground,
        t,
      )!,
      indeterminateBackground: Color.lerp(
        indeterminateBackground,
        other.indeterminateBackground,
        t,
      )!,
      indeterminateForeground: Color.lerp(
        indeterminateForeground,
        other.indeterminateForeground,
        t,
      )!,
      verifyingBackground: Color.lerp(
        verifyingBackground,
        other.verifyingBackground,
        t,
      )!,
      verifyingForeground: Color.lerp(
        verifyingForeground,
        other.verifyingForeground,
        t,
      )!,
    );
  }
}
