import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';

/// Famille des titres et de la marque (Nunito, SIL OFL, embarquée) :
/// terminaisons arrondies, proches du logo Tikéo.
const String kBrandFontFamily = 'Nunito';

/// Famille de l'interface (Inter, SIL OFL, embarquée).
const String kUiFontFamily = 'Inter';

/// Thèmes Material 3 de Tikéo : source unique des couleurs, typographies
/// et styles de composants.
abstract final class TicketSurTheme {
  /// Thème clair (par défaut) : fond gris-bleu très clair, cartes blanches
  /// (direction artistique « Nuit et Menthe », ADR 0026).
  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: TicketSurColors.navy,
      onPrimary: TicketSurColors.white,
      primaryContainer: Color(0xFFCFF6EE),
      onPrimaryContainer: TicketSurColors.navy,
      secondary: TicketSurColors.mintDeep,
      onSecondary: TicketSurColors.white,
      secondaryContainer: Color(0xFFE3F9F3),
      onSecondaryContainer: TicketSurColors.navy,
      tertiary: TicketSurColors.successStrong,
      onTertiary: TicketSurColors.white,
      tertiaryContainer: Color(0xFFDCF5E1),
      onTertiaryContainer: Color(0xFF00390F),
      error: Color(0xFFB3261E),
      onError: TicketSurColors.white,
      errorContainer: Color(0xFFFDECEC),
      onErrorContainer: Color(0xFF7A1A22),
      surface: TikeoColors.backgroundLight,
      onSurface: TicketSurColors.navy,
      onSurfaceVariant: TikeoColors.mutedLight,
      outline: Color(0xFF6E7F92),
      outlineVariant: TikeoColors.borderLight,
      surfaceContainerLowest: TikeoColors.cardLight,
      surfaceContainerLow: Color(0xFFF8FAFD),
      surfaceContainer: Color(0xFFF2F5F9),
      surfaceContainerHigh: Color(0xFFF0F3F8),
      surfaceContainerHighest: TikeoColors.tileLight,
      inverseSurface: Color(0xFF12304F),
      onInverseSurface: Color(0xFFEEF3F7),
      inversePrimary: Color(0xFF5EE6C9),
      surfaceTint: Color(0x00000000),
      shadow: Color(0xFF022445),
      scrim: Color(0xFF000000),
    ),
    TicketSurPalette.light,
    TikeoTints.light,
    card: TikeoColors.cardLight,
    fieldBorder: TikeoColors.fieldBorderLight,
  );

  /// Thème sombre : nuit profonde, cartes et champs de plus en plus clairs,
  /// textes et accents éclaircis (contrastes vérifiés par les tests).
  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: TicketSurColors.mint,
      onPrimary: TicketSurColors.navy,
      primaryContainer: Color(0xFF0B5E52),
      onPrimaryContainer: Color(0xFFCFF6EE),
      secondary: Color(0xFF5EE6C9),
      onSecondary: TicketSurColors.navy,
      secondaryContainer: Color(0xFF0B4A47),
      onSecondaryContainer: Color(0xFFCFF6EE),
      tertiary: Color(0xFF7FE08F),
      onTertiary: Color(0xFF00390F),
      tertiaryContainer: Color(0xFF1E5A2A),
      onTertiaryContainer: Color(0xFFC9F5D2),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: TikeoColors.backgroundDark,
      onSurface: TikeoColors.textDark,
      onSurfaceVariant: TikeoColors.mutedDark,
      outline: Color(0xFF8395A8),
      outlineVariant: TikeoColors.borderDark,
      surfaceContainerLowest: Color(0xFF030E1F),
      surfaceContainerLow: TikeoColors.cardDark,
      surfaceContainer: Color(0xFF0F2340),
      surfaceContainerHigh: Color(0xFF112645),
      surfaceContainerHighest: TikeoColors.tileDark,
      inverseSurface: TikeoColors.textDark,
      onInverseSurface: TicketSurColors.navy,
      inversePrimary: TicketSurColors.mintDeep,
      surfaceTint: Color(0x00000000),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    ),
    TicketSurPalette.dark,
    TikeoTints.dark,
    card: TikeoColors.cardDark,
    fieldBorder: TikeoColors.borderDark,
  );

  static ThemeData _build(
    ColorScheme scheme,
    TicketSurPalette palette,
    TikeoTints tints, {
    required Color card,
    required Color fieldBorder,
  }) {
    final textTheme = _textTheme(scheme.onSurface);
    final dark = scheme.brightness == Brightness.dark;
    // Liens et boutons texte : Menthe profonde sur fond clair.
    final link = dark ? palette.accentText : TicketSurColors.mintDeep;
    RoundedRectangleBorder rounded(double radius) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    OutlineInputBorder field(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(TikeoRadii.field),
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      fontFamily: kUiFontFamily,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [VerdictColors.standard, palette, tints],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: const Color(0x00000000),
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      // Bouton principal Tikéo : menthe, texte Nuit (7,4:1), dans les deux
      // thèmes ; 56 de haut, arrondi 16, icône 22.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TicketSurColors.mint,
          foregroundColor: TicketSurColors.navy,
          minimumSize: const Size.fromHeight(TikeoSizes.primaryButton),
          iconSize: TikeoSizes.buttonIcon,
          textStyle: textTheme.labelLarge,
          shape: rounded(TikeoRadii.button),
        ),
      ),
      // Bouton secondaire : contour, 52 de haut, arrondi 14.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? scheme.onSurface : TicketSurColors.navy,
          minimumSize: const Size.fromHeight(TikeoSizes.secondaryButton),
          iconSize: TikeoSizes.buttonIcon,
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outline),
          shape: rounded(TikeoRadii.field),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: link,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelMedium,
          shape: rounded(TikeoRadii.field),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size.square(48)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: TicketSurColors.mint,
        foregroundColor: TicketSurColors.navy,
        extendedTextStyle: textTheme.labelLarge,
        shape: rounded(TikeoRadii.button),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(48, 48),
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
          textStyle: textTheme.labelMedium,
          shape: rounded(TikeoRadii.field),
        ),
      ),
      // Barre de navigation Nuit (les deux thèmes) ; onglet actif en
      // pastille menthe, icône Nuit, libellé menthe (7,4:1 sur le Nuit).
      navigationBarTheme: NavigationBarThemeData(
        height: TikeoSizes.navBar,
        elevation: 0,
        backgroundColor: TicketSurColors.navy,
        surfaceTintColor: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
        indicatorColor: TicketSurColors.mint,
        indicatorShape: rounded(TikeoRadii.tile),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: TikeoSizes.navIcon,
            color: states.contains(WidgetState.selected)
                ? TicketSurColors.navy
                : TikeoColors.mutedDark,
          ),
        ),
        // 13 / 700 sélectionné : les libellés actuels tiennent sur une
        // ligne avec cinq onglets sur un écran de 360 dp.
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            fontSize: 13,
            color: states.contains(WidgetState.selected)
                ? TicketSurColors.mint
                : TikeoColors.mutedDark,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
      ),
      // Cartes blanches très arrondies (20) ; ombre douce teintée de Nuit
      // en clair, aucune en sombre.
      cardTheme: CardThemeData(
        elevation: dark ? 0 : 2,
        color: card,
        surfaceTintColor: const Color(0x00000000),
        shadowColor: dark ? const Color(0x00000000) : const Color(0x29022445),
        shape: rounded(TikeoRadii.card),
      ),
      listTileTheme: ListTileThemeData(
        shape: rounded(TikeoRadii.button),
        iconColor: scheme.onSurfaceVariant,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: tints.mint.background,
        disabledColor: scheme.surfaceContainerHighest,
        checkmarkColor: tints.mint.text,
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: tints.mint.text,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? TicketSurColors.white
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (dark ? TicketSurColors.mint : TicketSurColors.mintDeep)
              : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0x00000000)
              : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (dark ? TicketSurColors.mint : TicketSurColors.mintDeep)
              : null,
        ),
        checkColor: WidgetStatePropertyAll(
          dark ? TicketSurColors.navy : TicketSurColors.white,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (dark ? TicketSurColors.mint : TicketSurColors.mintDeep)
              : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? TicketSurColors.mint : TicketSurColors.mintDeep,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        dragHandleColor: scheme.outline,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TikeoRadii.navBar),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? scheme.surfaceContainerHigh : card,
        surfaceTintColor: const Color(0x00000000),
        shape: rounded(TikeoRadii.hero),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded(TikeoRadii.field),
      ),
      // Champ : fond tuile, bordure fine, focus Menthe profonde ; 52 de haut.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: field(fieldBorder),
        enabledBorder: field(fieldBorder),
        disabledBorder: field(scheme.outlineVariant),
        focusedBorder: field(link, 2),
        errorBorder: field(scheme.error),
        focusedErrorBorder: field(scheme.error, 2),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => (textTheme.bodyLarge ?? const TextStyle()).copyWith(
            color: states.contains(WidgetState.error)
                ? scheme.error
                : states.contains(WidgetState.focused)
                ? link
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Fixe le poids à la fois par `fontWeight` et par l'axe `wght`, car les
  /// polices embarquées sont variables.
  static TextStyle _style(
    String family,
    double size,
    FontWeight weight,
    double height,
    Color color,
  ) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    height: height,
    color: color,
  );

  /// Échelle de la direction artistique (section 4) : Nunito pour les
  /// titres et les chiffres, Inter pour le texte.
  static TextTheme _textTheme(Color color) => TextTheme(
    // Grand chiffre.
    displaySmall: _style(kBrandFontFamily, 36, FontWeight.w900, 1.1, color),
    headlineLarge: _style(kBrandFontFamily, 32, FontWeight.w900, 1.15, color),
    // Titre d'en-tête.
    headlineMedium: _style(kBrandFontFamily, 28, FontWeight.w800, 1.2, color),
    // Titre de carte héros.
    headlineSmall: _style(kBrandFontFamily, 24, FontWeight.w900, 1.25, color),
    // Titre de section, barre d'application.
    titleLarge: _style(kBrandFontFamily, 20, FontWeight.w800, 1.25, color),
    // Titre de carte.
    titleMedium: _style(kBrandFontFamily, 17, FontWeight.w800, 1.3, color),
    titleSmall: _style(kUiFontFamily, 14, FontWeight.w700, 1.4, color),
    // Texte.
    bodyLarge: _style(kUiFontFamily, 15, FontWeight.w400, 1.5, color),
    bodyMedium: _style(kUiFontFamily, 14, FontWeight.w400, 1.45, color),
    // Petit texte (dates, « Mis à jour le… »).
    bodySmall: _style(kUiFontFamily, 13, FontWeight.w500, 1.4, color),
    // Boutons.
    labelLarge: _style(kUiFontFamily, 16, FontWeight.w700, 1.25, color),
    // Libellé : boutons secondaires, champs.
    labelMedium: _style(kUiFontFamily, 14, FontWeight.w600, 1.25, color),
    labelSmall: _style(kUiFontFamily, 12, FontWeight.w600, 1.25, color),
  );
}

/// Accès aux couleurs de verdict depuis un [BuildContext].
extension VerdictColorsX on BuildContext {
  /// Couleurs de verdict du thème courant.
  VerdictColors get verdictColors =>
      Theme.of(this).extension<VerdictColors>() ?? VerdictColors.standard;
}
