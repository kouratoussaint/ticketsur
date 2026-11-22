import 'package:flutter/widgets.dart';
import 'package:ticketsur/l10n/gen/app_localizations.dart';

export 'package:ticketsur/l10n/gen/app_localizations.dart';

/// Accès court aux textes localisés : `context.l10n.appName`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// « il y a 5 min », « il y a 2 h », « il y a 3 jours » depuis [instant].
String timeAgo(AppLocalizations l10n, DateTime instant, DateTime now) {
  final elapsed = now.difference(instant);
  if (elapsed.inMinutes < 1) return l10n.timeAgoNow;
  if (elapsed.inHours < 1) return l10n.timeAgoMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.timeAgoHours(elapsed.inHours);
  return l10n.timeAgoDays(elapsed.inDays);
}
