import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
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
      tertiary: TicketSurColors.successStrong,
      onTertiary: TicketSurColors.white,
      error: Color(0xFFB3261E),
      onError: TicketSurColors.white,
      surface: TicketSurColors.surfaceLight,
      onSurface: TicketSurColors.navy,
      onSurfaceVariant: Color(0xFF3D4F6B),
      outline: Color(0xFF73829A),
      surfaceContainerHighest: Color(0xFFE6ECF4),
    ),
  );

  /// Thème sombre (proposition de départ, à auditer sur appareil).
  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9CC9FF),
      onPrimary: TicketSurColors.navy,
      primaryContainer: Color(0xFF123F7D),
      onPrimaryContainer: Color(0xFFD6E4F7),
      secondary: Color(0xFF7CC8FB),
      onSecondary: TicketSurColors.navy,
      tertiary: Color(0xFF7FE08F),
      onTertiary: Color(0xFF00390F),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: TicketSurColors.surfaceDark,
      onSurface: Color(0xFFE6ECF4),
      onSurfaceVariant: Color(0xFFB8C4D6),
      outline: Color(0xFF8A97AB),
      surfaceContainerHighest: Color(0xFF16305A),
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final textTheme = _textTheme(scheme.onSurface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: kUiFontFamily,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: const [VerdictColors.standard],
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
