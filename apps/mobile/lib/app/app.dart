import 'dart:async';

import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Racine de l'application TicketSûr.
class TicketSurApp extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<TicketSurApp> createState() => _TicketSurAppState();
}

/// Déclare au système que l'application gère elle-même la touche Retour.
///
/// Sur Android 13+ (et par défaut sur Android 16, que l'application cible),
/// le système n'envoie Retour à l'application que si elle s'est déclarée.
/// Flutter le fait au fil des changements de page, mais ce signal peut se
/// perdre au démarrage : Android fermait alors l'application au lieu
/// d'afficher « Appuyez encore… » (défaut constaté sur appareil le 18/11).
/// Toutes nos pages racines gèrent Retour (double appui, retour à l'Accueil),
/// on se déclare donc toujours.
bool claimBackHandling(NavigationNotification notification) {
  unawaited(SystemNavigator.setFrameworkHandlesBack(true));
  return true;
}

class _TicketSurAppState extends ConsumerState<TicketSurApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(SystemNavigator.setFrameworkHandlesBack(true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: TicketSurTheme.light(),
      darkTheme: TicketSurTheme.dark(),
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      onNavigationNotification: claimBackHandling,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
