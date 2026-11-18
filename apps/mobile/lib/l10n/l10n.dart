import 'package:flutter/widgets.dart';
import 'package:ticketsur/l10n/gen/app_localizations.dart';

export 'package:ticketsur/l10n/gen/app_localizations.dart';

/// Accès court aux textes localisés : `context.l10n.appName`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
