import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

/// Thème choisi sur cet appareil : celui du système (par défaut), clair ou
/// sombre. Persisté dans les préférences de l'appareil.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'appearance.theme_mode';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ThemeMode build() => switch (_prefs.getString(_key)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

final NotifierProvider<ThemeModeController, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Taille du texte choisie dans l'app (#11), multipliée par celle du
/// téléphone.
enum TextSize {
  small(0.9),
  normal(1),
  large(1.15),
  extraLarge(1.3);

  new(this.factor);

  final double factor;
}

/// Taille du texte : Normale par défaut, persistée sur l'appareil.
class TextSizeController extends Notifier<TextSize> {
  static const _key = 'appearance.text_size';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  TextSize build() => TextSize.values.firstWhere(
    (size) => size.name == _prefs.getString(_key),
    orElse: () => TextSize.normal,
  );

  Future<void> select(TextSize size) async {
    state = size;
    await _prefs.setString(_key, size.name);
  }
}

final NotifierProvider<TextSizeController, TextSize> textSizeProvider =
    NotifierProvider<TextSizeController, TextSize>(TextSizeController.new);

/// Échelle du téléphone ([base], éventuellement non linéaire) multipliée par
/// la taille choisie dans l'app.
@immutable
final class AppTextScaler extends TextScaler {
  const new(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // Exigé par l'interface (déprécié) ; on suit l'échelle du système.
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is AppTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

/// Applique la taille du texte choisie sous [child].
class AppTextSize extends ConsumerWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factor = ref.watch(textSizeProvider).factor;
    if (factor == 1) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: AppTextScaler(media.textScaler, factor)),
      child: child,
    );
  }
}
