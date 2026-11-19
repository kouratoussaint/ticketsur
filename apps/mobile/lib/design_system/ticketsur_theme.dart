import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';

/// Famille des titres et de la marque (Manrope, SIL OFL, embarquée).
const String kBrandFontFamily = 'Manrope';

/// Famille de l'interface (Inter, SIL OFL, embarquée).
const String kUiFontFamily = 'Inter';

/// Thèmes Material 3 de TicketSûr : source unique des couleurs, typographies
/// et styles de composants.
abstract final class TicketSurTheme {
  /// Thème clair (par défaut).
  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: TicketSurColors.navy,
      onPrimary: TicketSurColors.white,
      primaryContainer: Color(0xFFD6E4F7),
      onPrimaryContainer: TicketSurColors.navy,
      secondary: TicketSurColors.blueText,
      onSecondary: TicketSurColors.white,
      secondaryContainer: Color(0xFFDDF0FD),
      onSecondaryContainer: TicketSurColors.navy,
      tertiary: TicketSurColors.successStrong,
      onTertiary: TicketSurColors.white,
      tertiaryContainer: Color(0xFFDCF5E1),
      onTertiaryContainer: Color(0xFF00390F),
      error: Color(0xFFB3261E),
      onError: TicketSurColors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: TicketSurColors.surfaceLight,
      onSurface: TicketSurColors.navy,
      onSurfaceVariant: Color(0xFF3D4F6B),
      outline: Color(0xFF73829A),
      outlineVariant: Color(0xFFC5CFDC),
      surfaceContainerLowest: TicketSurColors.white,
      surfaceContainerLow: Color(0xFFF1F5FA),
      surfaceContainer: Color(0xFFEDF1F7),
      surfaceContainerHigh: Color(0xFFE9EEF5),
      surfaceContainerHighest: Color(0xFFE6ECF4),
      inverseSurface: Color(0xFF1B2B44),
      onInverseSurface: Color(0xFFEEF2F8),
      inversePrimary: Color(0xFF9CC9FF),
      surfaceTint: TicketSurColors.navy,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    ),
    TicketSurPalette.light,
  );

  /// Thème sombre : bleu nuit profond, conteneurs de plus en plus clairs,
  /// textes et accents éclaircis (contrastes vérifiés par les tests).
  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9CC9FF),
      onPrimary: TicketSurColors.navy,
      primaryContainer: Color(0xFF123F7D),
      onPrimaryContainer: Color(0xFFD6E4F7),
      secondary: Color(0xFF7CC8FB),
      onSecondary: TicketSurColors.navy,
      secondaryContainer: Color(0xFF0B4A7A),
      onSecondaryContainer: Color(0xFFDDF0FD),
      tertiary: Color(0xFF7FE08F),
      onTertiary: Color(0xFF00390F),
      tertiaryContainer: Color(0xFF1E5A2A),
      onTertiaryContainer: Color(0xFFC9F5D2),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: TicketSurColors.surfaceDark,
      onSurface: Color(0xFFE6ECF4),
      onSurfaceVariant: Color(0xFFB8C4D6),
      outline: Color(0xFF8A97AB),
      outlineVariant: Color(0xFF2C4468),
      surfaceContainerLowest: Color(0xFF03132A),
      surfaceContainerLow: Color(0xFF0A2349),
      surfaceContainer: Color(0xFF0E2951),
      surfaceContainerHigh: Color(0xFF122F59),
      surfaceContainerHighest: Color(0xFF16355F),
      inverseSurface: Color(0xFFE6ECF4),
      onInverseSurface: TicketSurColors.navy,
      inversePrimary: TicketSurColors.blueText,
      surfaceTint: Color(0xFF9CC9FF),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    ),
    TicketSurPalette.dark,
  );

  static ThemeData _build(ColorScheme scheme, TicketSurPalette palette) {
    final textTheme = _textTheme(scheme.onSurface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: kUiFontFamily,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [VerdictColors.standard, palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TicketSurRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TicketSurRadii.md),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 3,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.primary,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        // 12 px (Material 3) : « Événements » tient sur une ligne avec
        // cinq onglets sur un écran de 360 dp.
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TicketSurRadii.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        dragHandleColor: scheme.outline,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TicketSurRadii.sm),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TicketSurRadii.sm),
          borderSide: BorderSide.none,
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

  static TextTheme _textTheme(Color color) => TextTheme(
    displaySmall: _style(kBrandFontFamily, 36, FontWeight.w800, 1.1, color),
    headlineLarge: _style(kBrandFontFamily, 32, FontWeight.w800, 1.15, color),
    headlineMedium: _style(kBrandFontFamily, 28, FontWeight.w700, 1.2, color),
    headlineSmall: _style(kBrandFontFamily, 24, FontWeight.w700, 1.25, color),
    titleLarge: _style(kBrandFontFamily, 22, FontWeight.w700, 1.25, color),
    titleMedium: _style(kUiFontFamily, 16, FontWeight.w600, 1.4, color),
    titleSmall: _style(kUiFontFamily, 14, FontWeight.w600, 1.4, color),
    bodyLarge: _style(kUiFontFamily, 16, FontWeight.w400, 1.5, color),
    bodyMedium: _style(kUiFontFamily, 14, FontWeight.w400, 1.45, color),
    bodySmall: _style(kUiFontFamily, 12, FontWeight.w400, 1.4, color),
    labelLarge: _style(kUiFontFamily, 16, FontWeight.w600, 1.25, color),
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
