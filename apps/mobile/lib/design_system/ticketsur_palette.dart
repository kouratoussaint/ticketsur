import 'package:material_ui/material_ui.dart';

/// Couleurs de texte et d'icône « sémantiques » qui changent avec le thème.
///
/// Toutes sont lisibles (≥ 4,5:1) sur la surface et sur tous les conteneurs
/// de surface de leur thème ; vérifié par `test/design_system/theme_test.dart`.
/// À utiliser à la place des couleurs de marque fixes (bleu, ambre, rouge,
/// ardoise) dès qu'un texte ou une icône est posé sur une surface du thème.
@immutable
final class TicketSurPalette extends ThemeExtension<TicketSurPalette> {
  const new({
    required this.accentText,
    required this.successText,
    required this.warningText,
    required this.dangerText,
    required this.mutedText,
    required this.warningContainer,
    required this.warningBorder,
  });

  /// Thème clair.
  static const light = TicketSurPalette(
    accentText: Color(0xFF0B6FB0),
    successText: Color(0xFF0E7A25),
    warningText: Color(0xFF8A5A00),
    dangerText: Color(0xFFB02A37),
    mutedText: Color(0xFF52627A),
    warningContainer: Color(0xFFFEF3DA),
    warningBorder: Color(0xFFF8C96A),
  );

  /// Thème sombre.
  static const dark = TicketSurPalette(
    accentText: Color(0xFF7CC8FB),
    successText: Color(0xFF7FE08F),
    warningText: Color(0xFFFFC861),
    dangerText: Color(0xFFFFB4AB),
    mutedText: Color(0xFFB8C4D6),
    warningContainer: Color(0xFF3A2C0A),
    warningBorder: Color(0xFF8A6A1E),
  );

  /// Accent (liens, sur-titres, statut « valable »).
  final Color accentText;

  /// Réussite (ticket utilisé, contrôle ouvert).
  final Color successText;

  /// Avertissement (à compléter, alertes d'import).
  final Color warningText;

  /// Danger (annulé, refus).
  final Color dangerText;

  /// Secondaire (expiré, clôturé).
  final Color mutedText;

  /// Fond des encadrés d'avertissement.
  final Color warningContainer;

  /// Bordure des encadrés d'avertissement.
  final Color warningBorder;

  /// Les sept couleurs, nommées (tests de contraste).
  Map<String, Color> get textColors => {
    'accentText': accentText,
    'successText': successText,
    'warningText': warningText,
    'dangerText': dangerText,
    'mutedText': mutedText,
  };

  @override
  TicketSurPalette copyWith({
    Color? accentText,
    Color? successText,
    Color? warningText,
    Color? dangerText,
    Color? mutedText,
    Color? warningContainer,
    Color? warningBorder,
  }) => TicketSurPalette(
    accentText: accentText ?? this.accentText,
    successText: successText ?? this.successText,
    warningText: warningText ?? this.warningText,
    dangerText: dangerText ?? this.dangerText,
    mutedText: mutedText ?? this.mutedText,
    warningContainer: warningContainer ?? this.warningContainer,
    warningBorder: warningBorder ?? this.warningBorder,
  );

  @override
  TicketSurPalette lerp(TicketSurPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return TicketSurPalette(
      accentText: mix(accentText, other.accentText),
      successText: mix(successText, other.successText),
      warningText: mix(warningText, other.warningText),
      dangerText: mix(dangerText, other.dangerText),
      mutedText: mix(mutedText, other.mutedText),
      warningContainer: mix(warningContainer, other.warningContainer),
      warningBorder: mix(warningBorder, other.warningBorder),
    );
  }
}

/// Accès à la palette du thème courant.
extension TicketSurPaletteX on BuildContext {
  TicketSurPalette get palette =>
      Theme.of(this).extension<TicketSurPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? TicketSurPalette.dark
          : TicketSurPalette.light);
}
