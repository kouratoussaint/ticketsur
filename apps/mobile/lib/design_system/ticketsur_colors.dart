import 'package:flutter/painting.dart';

/// Palette Tikéo, tirée du logo (ADR 0011).
///
/// Règles de contraste vérifiées par `test/design_system/contrast_test.dart`
/// et `theme_test.dart` (WCAG AA : 4,5:1 pour le texte) :
/// * [mint] et [success] ne portent JAMAIS de texte blanc ; on y écrit en
///   [navy] (7,4:1 sur la menthe) ;
/// * le texte menthe sur fond clair utilise [mintDeep] ;
/// * [spark] est un accent rare (« À la une », invitations), texte [navy].
abstract final class TicketSurColors {
  /// Bleu « Nuit » : titres, navigation, texte courant.
  static const Color navy = Color(0xFF022445);

  /// Bleu nuit éclairci, second ton des bandeaux et des couvertures.
  static const Color navyLight = Color(0xFF0A3A66);

  /// Vert « Menthe » : boutons principaux, sélection, accents. Jamais sous du
  /// texte blanc.
  static const Color mint = Color(0xFF00C9A7);

  /// Menthe profonde : texte, liens et boutons à texte blanc sur fond clair.
  static const Color mintDeep = Color(0xFF006B5B);

  /// Orange « Étincelle » : accent rare.
  static const Color spark = Color(0xFFFF6B3D);

  /// Vert de validation, réservé à une confirmation serveur effective.
  static const Color success = Color(0xFF17BE35);

  /// Vert sombre pour du texte de succès sur fond clair.
  static const Color successStrong = Color(0xFF0E7A25);

  /// Rouge de refus et d'erreur critique.
  static const Color error = Color(0xFFDC3545);

  /// Orange des états indéterminés et avertissements.
  static const Color warning = Color(0xFFF59E0B);

  /// Gris neutre de l'état « Vérification… » (aucune couleur de verdict).
  static const Color verifying = Color(0xFFE3E8EF);

  /// Surface claire par défaut (« Brume »).
  static const Color surfaceLight = Color(0xFFF5F8FA);

  /// Surface sombre (bleu nuit profond).
  static const Color surfaceDark = Color(0xFF011A33);

  /// Blanc.
  static const Color white = Color(0xFFFFFFFF);
}

/// Rapport de contraste WCAG 2.x entre deux couleurs opaques (1 à 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
