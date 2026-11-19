import 'package:flutter/painting.dart';

/// Palette TicketSûr (identité « Option B »).
///
/// Règles de contraste vérifiées par `test/design_system/contrast_test.dart`
/// (WCAG AA : 4,5:1 pour le texte) :
/// * [blue] et [success] ne portent JAMAIS de texte blanc (2,9:1 et 2,5:1) ;
/// * le verdict « accepté » écrit en [navy] sur [success] (5,4:1) ;
/// * les boutons colorés à texte blanc utilisent [blueText] (5,4:1).
abstract final class TicketSurColors {
  /// Bleu nuit de marque : titres, navigation, texte courant.
  static const Color navy = Color(0xFF082D60);

  /// Bleu électrique : accents, focus, indicateurs. Jamais sous du texte blanc.
  static const Color blue = Color(0xFF079EF4);

  /// Bleu assombri pour les boutons colorés portant du texte blanc.
  static const Color blueText = Color(0xFF0B6FB0);

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

  /// Surface claire par défaut.
  static const Color surfaceLight = Color(0xFFF7F9FC);

  /// Surface sombre de départ (mode sombre, à auditer sur appareil).
  static const Color surfaceDark = Color(0xFF061B38);

  /// Blanc.
  static const Color white = Color(0xFFFFFFFF);

  /// Or des invitations : texte et filets sur [navy] (7,6:1), jamais sur blanc.
  static const Color gold = Color(0xFFF5B301);
}

/// Rapport de contraste WCAG 2.x entre deux couleurs opaques (1 à 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
