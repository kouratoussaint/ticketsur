import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

/// Langue de l'application, choisie dans les Paramètres.
enum AppLanguage {
  /// Celle du téléphone (français si elle n'est ni française ni anglaise).
  system,
  fr,
  en,
}

/// Langue des dates et des nombres formatés hors des widgets (tickets, PDF,
/// rapports, messages). Tenue à jour par l'application ; français par
/// défaut (tests, démarrage).
String appLocaleTag = 'fr';

/// Langue retenue pour [language] et les langues du téléphone [device].
Locale resolveAppLocale(AppLanguage language, List<Locale> device) =>
    switch (language) {
      AppLanguage.fr => const Locale('fr'),
      AppLanguage.en => const Locale('en'),
      AppLanguage.system => Locale(
        device
            .map((l) => l.languageCode)
            .firstWhere(
              (code) => code == 'fr' || code == 'en',
              orElse: () => 'fr',
            ),
      ),
    };

/// Choix de la langue sur cet appareil.
class AppLanguageController extends Notifier<AppLanguage> {
  static const key = 'appearance.language';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppLanguage build() => switch (_prefs.getString(key)) {
    'fr' => AppLanguage.fr,
    'en' => AppLanguage.en,
    _ => AppLanguage.system,
  };

  Future<void> select(AppLanguage language) async {
    state = language;
    await _prefs.setString(key, language.name);
  }
}

final NotifierProvider<AppLanguageController, AppLanguage> appLanguageProvider =
    NotifierProvider<AppLanguageController, AppLanguage>(
      AppLanguageController.new,
    );

/// Langues du téléphone (remplacées en test).
final deviceLocalesProvider = Provider<List<Locale>>(
  (ref) => PlatformDispatcher.instance.locales,
);

/// Langue effective de l'application.
final Provider<Locale> appLocaleProvider = Provider<Locale>((ref) {
  final locale = resolveAppLocale(
    ref.watch(appLanguageProvider),
    ref.watch(deviceLocalesProvider),
  );
  appLocaleTag = locale.languageCode;
  return locale;
});

/// « 20 nov. 2026 à 21:00 » / « Nov 20, 2026 at 21:00 ».
String formatDateAtTime(DateTime instant, {bool year = true}) {
  final at = appLocaleTag == 'en' ? 'at' : 'à';
  final date = year
      ? DateFormat.yMMMd(appLocaleTag)
      : DateFormat.MMMd(appLocaleTag);
  final time = DateFormat.Hm(appLocaleTag).format(instant);
  return '${date.format(instant)} $at $time';
}
