/// Échelle d'espacement TicketSûr (en dp) : 4 / 8 / 12 / 16 / 24 / 32.
abstract final class TicketSurSpacing {
  /// 4 dp.
  static const double xxs = 4;

  /// 8 dp.
  static const double xs = 8;

  /// 12 dp.
  static const double sm = 12;

  /// 16 dp.
  static const double md = 16;

  /// 24 dp.
  static const double lg = 24;

  /// 32 dp.
  static const double xl = 32;
}

/// Rayons d'angle TicketSûr (12 à 20 dp).
abstract final class TicketSurRadii {
  /// Champs, puces.
  static const double sm = 12;

  /// Cartes, boutons.
  static const double md = 16;

  /// Feuilles et grands conteneurs.
  static const double lg = 20;
}

/// Hauteur minimale des actions principales du scanner (usage à une main,
/// gants, plein soleil) — au-delà du minimum Material de 48 dp.
const double kScannerActionHeight = 64;
