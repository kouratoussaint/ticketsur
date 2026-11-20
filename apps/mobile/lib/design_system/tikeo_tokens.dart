import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';

/// Jetons de la direction artistique « Nuit et Menthe » (ADR 0026) :
/// couleurs de surface, en-tête héros, arrondis, ombres et tailles.
///
/// Les couleurs de marque restent celles de [TicketSurColors] (ADR 0011).
/// Les teintes par sens (statuts, rôles, types) sont dans `TikeoTints`.
abstract final class TikeoColors {
  /// Menthe vive : début du dégradé des boutons et de l'onglet actif.
  static const Color mintBright = Color(0xFF19E3BC);

  /// Dégradé du bouton principal (toujours avec du texte Nuit).
  static const LinearGradient mintGradient = LinearGradient(
    colors: [mintBright, TicketSurColors.mint],
  );

  /// Point de notification (cloche, onglet).
  static const Color notificationDot = Color(0xFFFF4D4F);

  /// Étincelles jaunes des illustrations.
  static const Color sparkle = Color(0xFFFFC93C);

  // Thème clair -------------------------------------------------------------

  /// Fond de l'écran.
  static const Color backgroundLight = Color(0xFFF4F7FB);

  /// Carte.
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Tuile secondaire, champ.
  static const Color tileLight = Color(0xFFEEF2F7);

  /// Bordure des cartes et séparateurs.
  static const Color borderLight = Color(0xFFE3E9F0);

  /// Bordure des champs.
  static const Color fieldBorderLight = Color(0xFFDCE3EA);

  /// Texte secondaire.
  static const Color mutedLight = Color(0xFF52627A);

  // Thème sombre ------------------------------------------------------------

  static const Color backgroundDark = Color(0xFF061428);
  static const Color cardDark = Color(0xFF0C1F3A);
  static const Color tileDark = Color(0xFF13294A);
  static const Color borderDark = Color(0xFF1E3557);
  static const Color textDark = Color(0xFFE8EEF6);
  static const Color mutedDark = Color(0xFFB4C3D2);

  // En-tête héros (identique dans les deux thèmes) --------------------------

  /// Dégradé du fond, du haut à gauche vers le bas à droite.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF021A36), Color(0xFF0A3366)],
  );

  /// Halo menthe en haut à droite.
  static const RadialGradient heroHalo = RadialGradient(
    center: Alignment.topRight,
    radius: 0.9,
    colors: [Color(0x5900C9A7), Color(0x0000C9A7)],
  );

  /// Vague organique en bas à droite (`#0E3D73` à 60 %).
  static const Color heroWave = Color(0x990E3D73);

  /// Fond de l'avatar de l'en-tête.
  static const Color avatarMintPale = Color(0xFFD9F7EF);
}

/// Arrondis (dp).
abstract final class TikeoRadii {
  /// Pastilles.
  static const double pill = 999;

  /// Vignette dans un menu déroulant, petit QR.
  static const double xs = 8;

  /// Vignette du sélecteur d'événement.
  static const double thumb = 12;

  /// Champ, bouton secondaire, option sélectionnable, bouton carré.
  static const double field = 14;

  /// Bouton principal, ligne de liste, vignette de fiche.
  static const double button = 16;

  /// Tuile de chiffre, pastille active de la barre de navigation.
  static const double tile = 18;

  /// Carte, action rapide, carte « À la une ».
  static const double card = 20;

  /// Carte événement héros.
  static const double hero = 24;

  /// Coins du haut de la barre de navigation et des feuilles.
  static const double navBar = 28;
}

/// Ombres douces, teintées de Nuit.
abstract final class TikeoShadows {
  /// Carte : `0 4 16 rgba(2,36,69,0.06)`.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F022445), offset: Offset(0, 4), blurRadius: 16),
  ];

  /// Carte qui chevauche l'en-tête : `0 10 30 rgba(2,36,69,0.12)`.
  static const List<BoxShadow> overlap = [
    BoxShadow(color: Color(0x1F022445), offset: Offset(0, 10), blurRadius: 30),
  ];

  /// Halo du bouton menthe : `0 8 20 rgba(0,201,167,0.30)`.
  static const List<BoxShadow> mintGlow = [
    BoxShadow(color: Color(0x4D00C9A7), offset: Offset(0, 8), blurRadius: 20),
  ];

  /// Ombres de carte selon le thème (aucune en sombre : invisibles).
  static List<BoxShadow> cardFor(Brightness brightness) =>
      brightness == Brightness.dark ? const [] : card;
}

/// Tailles relevées sur les maquettes (largeur de référence 412 dp). Toute
/// zone touchable fait au moins 48 dp.
abstract final class TikeoSizes {
  /// Marges d'écran.
  static const double screenMargin = 16;

  /// Écart entre deux cartes et entre deux sections.
  static const double cardGap = 12;
  static const double sectionGap = 28;

  /// En-tête héros (sans la carte) : court, long, avec illustration.
  static const double heroHeader = 190;
  static const double heroHeaderLong = 210;
  static const double heroHeaderIllustrated = 230;

  /// Chevauchement de la carte sur l'en-tête, en-tête replié.
  static const double heroOverlap = 48;
  static const double heroCollapsed = 64;

  /// Logo Tikéo de l'en-tête, cloche, point de notification.
  static const double headerLogo = 34;
  static const double headerBell = 26;
  static const double notificationDot = 10;

  /// Avatars : en-tête, liste, profil (badge crayon).
  static const double avatarHeader = 44;
  static const double avatarList = 52;
  static const double avatarProfile = 88;
  static const double avatarBadge = 28;

  /// Barre de navigation (hors zone système) et sa pastille active.
  static const double navBar = 72;
  static const Size navIndicator = Size(64, 52);
  static const double navIcon = 26;

  /// Boutons : principal, secondaire ou danger, carré (recherche, filtre).
  static const double primaryButton = 56;
  static const double secondaryButton = 52;
  static const double squareButton = 48;
  static const double buttonIcon = 22;

  /// Champs : hauteur, zone de texte minimale ; option sélectionnable.
  static const double field = 52;
  static const double textArea = 96;
  static const double option = 56;

  /// Tuiles : action rapide, chiffre, filtre de type ; ligne de réglage.
  static const double quickAction = 96;
  static const double statTile = 88;
  static const Size kindFilter = Size(72, 64);
  static const double settingsRow = 72;
  static const double settingsIconCircle = 44;

  /// Pastilles : courante, grande (fiche ticket), icône.
  static const double chip = 28;
  static const double chipLarge = 40;
  static const double chipIcon = 16;

  /// Trait de statut à gauche d'une ligne de ticket.
  static const double statusStripe = 4;

  /// Images affichées.
  static const double heroCardHeight = 220;
  static const double featuredCardHeight = 170;
  static const Size listThumb = Size(128, 80);
  static const Size pickerThumb = Size(64, 52);
  static const double ticketEventThumb = 88;
  static const Size menuThumb = Size(44, 32);
  static const double organizationLogo = 48;
  static const Size organizationCard = Size(104, 120);
  static const double listQr = 36;
  static const double ticketQr = 128;
}

/// Styles de texte propres à la direction artistique, en plus du
/// `TextTheme` (Nunito pour les titres et les chiffres, Inter pour le reste).
abstract final class TikeoTextStyles {
  static TextStyle _style(
    String family,
    double size,
    FontWeight weight, {
    double height = 1.25,
    double? letterSpacing,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );

  /// Titre d'en-tête : Nunito 28 / 800.
  static final TextStyle heroTitle = _style('Nunito', 28, FontWeight.w800);

  /// Sous-titre d'en-tête : Inter 15 / 400 (blanc à 85 % sur l'en-tête).
  static final TextStyle heroSubtitle = _style(
    'Inter',
    15,
    FontWeight.w400,
    height: 1.4,
  );

  /// Titre de carte héros : Nunito 24 / 900.
  static final TextStyle heroCardTitle = _style('Nunito', 24, FontWeight.w900);

  /// Grand chiffre : Nunito 28 / 900, chiffres tabulaires.
  static final TextStyle bigNumber = _style(
    'Nunito',
    28,
    FontWeight.w900,
    height: 1.1,
    tabular: true,
  );

  /// Chiffre de tuile : Nunito 24 / 900, chiffres tabulaires.
  static final TextStyle tileNumber = _style(
    'Nunito',
    24,
    FontWeight.w900,
    height: 1.1,
    tabular: true,
  );

  /// Numéro de ticket sur la fiche (« N° 000510 ») : Nunito 32 / 900.
  static final TextStyle ticketNumber = _style(
    'Nunito',
    32,
    FontWeight.w900,
    height: 1.1,
    tabular: true,
  );

  /// Sur-titre (« CONCERT ») : Inter 12 / 800, capitales, espacement 1.
  static final TextStyle overline = _style(
    'Inter',
    12,
    FontWeight.w800,
    letterSpacing: 1,
  );

  /// Texte d'une pastille : Inter 14 / 700.
  static final TextStyle chip = _style('Inter', 14, FontWeight.w700);

  /// Texte d'une grande pastille : 18 / 800.
  static final TextStyle chipLarge = _style('Inter', 18, FontWeight.w800);
}
