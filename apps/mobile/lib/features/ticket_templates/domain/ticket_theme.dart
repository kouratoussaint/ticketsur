import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/events/domain/event.dart';

/// Façon d'écrire le titre de l'événement sur un thème intégré.
enum TitleStyle {
  /// Premier mot manuscrit, le reste en gras capitales (Concert).
  firstWordScriptCaps,

  /// Premier mot manuscrit, le reste en gras (Festival culturel).
  firstWordScript,

  /// Gras capitales, première ligne en couleur d'accent (Cinéma).
  capsAccentFirstLine,

  /// Condensé ; « A vs B » avec un losange VS entre les équipes (Match).
  condensedVersus,

  /// Tout en manuscrit (Théâtre).
  script,

  /// Gras capitales (Conférence).
  caps,

  /// Gras (Exposition, Challenge sportif).
  bold,

  /// Gras, petits mots (« du », « de »…) en manuscrit (Gastronomie).
  boldScriptSmallWords,

  /// Gras, dernier mot en couleur d'accent (Atelier jeunes).
  boldAccentLastWord,

  /// Tout en manuscrit, couleur d'accent (Soirée club).
  scriptAccent,

  /// Gras, couleur d'accent (Workshop).
  boldAccent,
}

/// Un des 12 modèles intégrés (spécification « Modèles de tickets », §4).
@immutable
final class TicketTheme {
  const new({
    required this.id,
    required this.accent,
    required this.dark,
    required this.ink,
    required this.frame,
    required this.chip,
    required this.chipText,
    required this.titleStyle,
  });

  /// 1 à 12 (valeur enregistrée côté serveur).
  final int id;

  /// Couleur d'accent : type d'événement, icônes, trait vertical.
  final Color accent;

  /// Couleur sombre du dégradé (et du fond sans photo).
  final Color dark;

  /// « Scannez ici » et chevrons.
  final Color ink;

  /// Bordure du cadre du QR.
  final Color frame;

  /// Pastille de la catégorie et son texte.
  final Color chip;
  final Color chipText;

  final TitleStyle titleStyle;
}

const _white = Color(0xFFFFFFFF);

/// Les 12 thèmes, dans l'ordre de la spécification.
const List<TicketTheme> ticketThemes = [
  TicketTheme(
    id: 1,
    accent: Color(0xFFF5B800),
    dark: Color.fromARGB(255, 22, 10, 2),
    ink: Color(0xFF8A6400),
    frame: Color(0xFFF5B800),
    chip: Color(0xFFF5B800),
    chipText: Color(0xFF1A1200),
    titleStyle: TitleStyle.firstWordScriptCaps,
  ),
  TicketTheme(
    id: 2,
    accent: Color(0xFF4ADE80),
    dark: Color.fromARGB(255, 4, 26, 10),
    ink: Color(0xFF15803D),
    frame: Color(0xFF16A34A),
    chip: Color(0xFF15803D),
    chipText: _white,
    titleStyle: TitleStyle.firstWordScript,
  ),
  TicketTheme(
    id: 3,
    accent: Color(0xFF60A5FA),
    dark: Color.fromARGB(255, 3, 8, 36),
    ink: Color(0xFF1D4ED8),
    frame: Color(0xFF2563EB),
    chip: Color(0xFF1D4ED8),
    chipText: _white,
    titleStyle: TitleStyle.capsAccentFirstLine,
  ),
  TicketTheme(
    id: 4,
    accent: Color(0xFF22C55E),
    dark: Color.fromARGB(255, 3, 20, 10),
    ink: Color(0xFF15803D),
    frame: Color(0xFF16A34A),
    chip: Color(0xFF15803D),
    chipText: _white,
    titleStyle: TitleStyle.condensedVersus,
  ),
  TicketTheme(
    id: 5,
    accent: Color(0xFFF87171),
    dark: Color.fromARGB(255, 34, 3, 6),
    ink: Color(0xFFB91C1C),
    frame: Color(0xFFDC2626),
    chip: Color(0xFFDC2626),
    chipText: _white,
    titleStyle: TitleStyle.script,
  ),
  TicketTheme(
    id: 6,
    accent: Color(0xFFC4B5FD),
    dark: Color.fromARGB(255, 8, 8, 44),
    ink: Color(0xFF6D28D9),
    frame: Color(0xFF7C3AED),
    chip: Color(0xFF6D28D9),
    chipText: _white,
    titleStyle: TitleStyle.caps,
  ),
  TicketTheme(
    id: 7,
    accent: Color(0xFFFDBA74),
    dark: Color.fromARGB(255, 44, 12, 3),
    ink: Color(0xFFC2410C),
    frame: Color(0xFFEA580C),
    chip: Color(0xFFC2410C),
    chipText: _white,
    titleStyle: TitleStyle.bold,
  ),
  TicketTheme(
    id: 8,
    accent: Color(0xFFFBBF24),
    dark: Color.fromARGB(255, 36, 15, 4),
    ink: Color(0xFFB45309),
    frame: Color(0xFFD97706),
    chip: Color(0xFFB45309),
    chipText: _white,
    titleStyle: TitleStyle.boldScriptSmallWords,
  ),
  TicketTheme(
    id: 9,
    accent: Color(0xFFFACC15),
    dark: Color.fromARGB(255, 6, 16, 44),
    ink: Color(0xFFA16207),
    frame: Color(0xFFEAB308),
    chip: Color(0xFFFACC15),
    chipText: Color(0xFF1A1400),
    titleStyle: TitleStyle.boldAccentLastWord,
  ),
  TicketTheme(
    id: 10,
    accent: Color(0xFF38BDF8),
    dark: Color.fromARGB(255, 4, 20, 50),
    ink: Color(0xFF0369A1),
    frame: Color(0xFF0284C7),
    // #0284C7 de la spécification : 4,1:1 avec le texte blanc ; foncé
    // pour atteindre 4,5:1 (audit des contrastes).
    chip: Color(0xFF0369A1),
    chipText: _white,
    titleStyle: TitleStyle.bold,
  ),
  TicketTheme(
    id: 11,
    accent: Color(0xFFF472B6),
    dark: Color.fromARGB(255, 22, 3, 32),
    ink: Color(0xFFBE185D),
    frame: Color(0xFFDB2777),
    chip: Color(0xFFDB2777),
    chipText: _white,
    titleStyle: TitleStyle.scriptAccent,
  ),
  TicketTheme(
    id: 12,
    accent: Color(0xFFFBBF24),
    dark: Color.fromARGB(255, 14, 14, 16),
    ink: Color(0xFF92400E),
    frame: Color(0xFF6B7280),
    chip: Color(0xFF1F2937),
    chipText: _white,
    titleStyle: TitleStyle.boldAccent,
  ),
];

/// Thème n° [id] (1 à 12) ; le premier si l'identifiant est inconnu.
TicketTheme themeById(int id) => ticketThemes.firstWhere(
  (theme) => theme.id == id,
  orElse: () => ticketThemes.first,
);

/// Thème proposé selon le type d'événement (spécification, §4).
int defaultThemeFor(EventKind kind) => switch (kind) {
  EventKind.concert => 1,
  EventKind.conference => 6,
  EventKind.training => 9,
  EventKind.sport => 4,
  EventKind.worship => 2,
  EventKind.wedding || EventKind.gala => 12,
  EventKind.other => 1,
};
