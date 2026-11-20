import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';

/// Une teinte « par sens » : fond pâle, icône et texte de la même couleur,
/// plus foncée (direction artistique, section 3).
@immutable
final class TikeoTint {
  const new({required this.background, required this.icon, required this.text});

  /// Version sombre d'une teinte claire : fond = couleur d'icône à 16 % sur
  /// la carte sombre ; icône et texte = version claire [light].
  factory darkOf(TikeoTint tint, Color light) => TikeoTint(
    background: Color.alphaBlend(
      tint.icon.withValues(alpha: 0.16),
      TikeoColors.cardDark,
    ),
    icon: light,
    text: light,
  );

  final Color background;
  final Color icon;
  final Color text;

  @override
  bool operator ==(Object other) =>
      other is TikeoTint &&
      other.background == background &&
      other.icon == icon &&
      other.text == text;

  @override
  int get hashCode => Object.hash(background, icon, text);
}

/// Teintes par sens, en clair et en sombre. Une couleur garde le même sens
/// dans toute l'application (événements menthe, tickets bleu, personnes
/// ambre, contrôle violet, danger rouge, annonce saumon).
@immutable
final class TikeoTints extends ThemeExtension<TikeoTints> {
  const new({
    required this.mint,
    required this.blue,
    required this.amber,
    required this.violet,
    required this.red,
    required this.salmon,
    required this.green,
    required this.live,
    required this.gray,
    required this.vip,
    required this.conference,
    required this.sky,
    required this.pink,
    required this.orange,
  });

  /// Thème clair : valeurs des maquettes.
  static const light = TikeoTints(
    mint: TikeoTint(
      background: Color(0xFFE3F9F3),
      icon: Color(0xFF00A383),
      text: Color(0xFF006B5B),
    ),
    blue: TikeoTint(
      background: Color(0xFFE5EFFF),
      icon: Color(0xFF2F6FED),
      text: Color(0xFF1F4FB8),
    ),
    amber: TikeoTint(
      background: Color(0xFFFFF3DC),
      icon: Color(0xFFF2A516),
      text: Color(0xFF8A5A00),
    ),
    violet: TikeoTint(
      background: Color(0xFFF0E9FE),
      icon: Color(0xFF7C3AED),
      text: Color(0xFF5B21B6),
    ),
    red: TikeoTint(
      background: Color(0xFFFDECEC),
      icon: Color(0xFFE5484D),
      text: Color(0xFFB02A37),
    ),
    salmon: TikeoTint(
      background: Color(0xFFFFE8DF),
      icon: Color(0xFFE0512B),
      text: Color(0xFF7A2A12),
    ),
    // Texte des maquettes (#15803D) à 4,4:1 sur son fond : foncé en #166534.
    green: TikeoTint(
      background: Color(0xFFDDF7E6),
      icon: Color(0xFF16A34A),
      text: Color(0xFF166534),
    ),
    live: TikeoTint(
      background: Color(0xFFE2F9D5),
      icon: Color(0xFF22C55E),
      text: Color(0xFF166534),
    ),
    gray: TikeoTint(
      background: Color(0xFFEEF2F7),
      icon: Color(0xFF6B7A90),
      text: Color(0xFF52627A),
    ),
    vip: TikeoTint(
      background: Color(0xFFFFF1D6),
      icon: Color(0xFFD69E2E),
      text: Color(0xFF8A5A00),
    ),
    conference: TikeoTint(
      background: Color(0xFFEDE7FE),
      icon: Color(0xFF6D28D9),
      text: Color(0xFF4C1D95),
    ),
    sky: TikeoTint(
      background: Color(0xFFE0F4FD),
      icon: Color(0xFF0EA5E9),
      text: Color(0xFF0369A1),
    ),
    pink: TikeoTint(
      background: Color(0xFFFCE7F3),
      icon: Color(0xFFDB2777),
      text: Color(0xFF9D174D),
    ),
    orange: TikeoTint(
      background: Color(0xFFFFEDE3),
      icon: Color(0xFFC2410C),
      text: Color(0xFF9A3412),
    ),
  );

  /// Thème sombre : fond = icône à 16 %, texte éclairci.
  static final dark = TikeoTints(
    mint: TikeoTint.darkOf(light.mint, const Color(0xFF5EE6C9)),
    blue: TikeoTint.darkOf(light.blue, const Color(0xFFA8C5FF)),
    amber: TikeoTint.darkOf(light.amber, const Color(0xFFFFC861)),
    violet: TikeoTint.darkOf(light.violet, const Color(0xFFC9B8FD)),
    red: TikeoTint.darkOf(light.red, const Color(0xFFFFB4AB)),
    salmon: TikeoTint.darkOf(light.salmon, const Color(0xFFFFB59C)),
    green: TikeoTint.darkOf(light.green, const Color(0xFF7FE08F)),
    live: TikeoTint.darkOf(light.live, const Color(0xFF86EFAC)),
    gray: TikeoTint.darkOf(light.gray, const Color(0xFFB4C3D2)),
    vip: TikeoTint.darkOf(light.vip, const Color(0xFFFFD27A)),
    conference: TikeoTint.darkOf(light.conference, const Color(0xFFD8CCFE)),
    sky: TikeoTint.darkOf(light.sky, const Color(0xFF7DD3FC)),
    pink: TikeoTint.darkOf(light.pink, const Color(0xFFF9A8D4)),
    orange: TikeoTint.darkOf(light.orange, const Color(0xFFFDBA8C)),
  );

  /// Événements, propriétaire, prix et « Gratuit ».
  final TikeoTint mint;

  /// Tickets, ticket valable, événement à venir, gestionnaire, formation.
  final TikeoTint blue;

  /// Personnes, brouillon, gala.
  final TikeoTint amber;

  /// Statistiques, contrôle, contrôleur, concert.
  final TikeoTint violet;

  /// Danger : ticket ou événement annulé, déconnexion.
  final TikeoTint red;

  /// Annonce.
  final TikeoTint salmon;

  /// Ticket utilisé, sport.
  final TikeoTint green;

  /// Événement en cours (point « en direct »).
  final TikeoTint live;

  /// Expiré, terminé, catégorie ordinaire.
  final TikeoTint gray;

  /// Catégorie VIP (couronne).
  final TikeoTint vip;

  /// Types d'événement : conférence, culte, mariage, autre.
  final TikeoTint conference;
  final TikeoTint sky;
  final TikeoTint pink;
  final TikeoTint orange;

  /// Toutes les teintes, nommées (tests de contraste).
  Map<String, TikeoTint> get all => {
    'mint': mint,
    'blue': blue,
    'amber': amber,
    'violet': violet,
    'red': red,
    'salmon': salmon,
    'green': green,
    'live': live,
    'gray': gray,
    'vip': vip,
    'conference': conference,
    'sky': sky,
    'pink': pink,
    'orange': orange,
  };

  @override
  TikeoTints copyWith() => this;

  @override
  TikeoTints lerp(TikeoTints? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// Couleurs pleines des types d'événement, pour une pastille posée sur une
/// photo (texte blanc). Les couleurs des maquettes qui n'atteignaient pas
/// 4,5:1 avec le blanc ont été foncées (sport, culte, mariage, gala).
abstract final class TikeoKindColors {
  static const Color concert = Color(0xFF7C3AED);
  static const Color conference = Color(0xFF6D28D9);
  static const Color training = Color(0xFF2563EB);
  static const Color sport = Color(0xFF15803D);
  static const Color worship = Color(0xFF0369A1);
  static const Color wedding = Color(0xFFBE185D);
  static const Color gala = Color(0xFF8A5A00);
  static const Color other = Color(0xFFC2410C);

  /// Fond sur une photo : plein (85 % dans les maquettes, mais le texte
  /// blanc doit rester à 4,5:1 sur une photo ou une vignette claire).
  static Color onPhoto(Color solid) => solid;
}

/// Accès aux teintes du thème courant.
extension TikeoTintsX on BuildContext {
  TikeoTints get tints =>
      Theme.of(this).extension<TikeoTints>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? TikeoTints.dark
          : TikeoTints.light);
}
