import 'dart:async';

import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/appearance.dart';
import 'package:ticketsur/app/remembered_filters.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/security/application/security_providers.dart';
import 'package:ticketsur/features/security/presentation/app_lock.dart';
import 'package:ticketsur/features/updates/application/update_providers.dart';
import 'package:ticketsur/features/updates/presentation/update_banner.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Racine de l'application Tikéo.
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
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<PushMessage>? _foreground;
  StreamSubscription<String>? _opened;
  StreamSubscription<void>? _recovery;
  bool _updateShown = false;

  /// « Nouvelle version disponible » : une fenêtre par lancement (#9).
  void _onUpdate(AsyncValue<int?>? previous, AsyncValue<int?> next) {
    final build = next.value;
    if (build == null || _updateShown) return;
    _updateShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = ref
          .read(routerProvider)
          .routerDelegate
          .navigatorKey
          .currentContext;
      if (navigator == null || !navigator.mounted) return;
      showDialog<void>(
        context: navigator,
        builder: (context) => UpdateDialog(version: build),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(SystemNavigator.setFrameworkHandlesBack(true));
      unawaited(_listenToPush());
      // Lien « mot de passe oublié » ouvert : choisir le nouveau.
      _recovery = ref
          .read(authRepositoryProvider)
          .passwordRecovery
          .listen((_) => ref.read(routerProvider).go(AppRoutes.newPassword));
    });
  }

  @override
  void dispose() {
    unawaited(_foreground?.cancel());
    unawaited(_opened?.cancel());
    unawaited(_recovery?.cancel());
    super.dispose();
  }

  void _open(String route) {
    if (!mounted || !isSafePushRoute(route) || route == '/') return;
    unawaited(ref.read(routerProvider).push(route));
  }

  /// Notifications : touchées (ouvre la page), reçues application ouverte
  /// (message en bas d'écran, « Voir »).
  Future<void> _listenToPush() async {
    final service = ref.read(pushServiceProvider);
    // Attendre la première synchronisation (Firebase prêt).
    try {
      await ref.read(pushSyncProvider.future);
    } on Object {
      return;
    }
    if (!mounted) return;
    _opened = service.opened.listen(_open);
    _foreground = service.foreground.listen((message) {
      final messengerContext = _messenger.currentContext;
      if (messengerContext == null || !messengerContext.mounted) return;
      final l10n = messengerContext.l10n;
      _messenger.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            message.body.isEmpty
                ? message.title
                : '${message.title}\n${message.body}',
          ),
          action: isSafePushRoute(message.route) && message.route != '/'
              ? SnackBarAction(
                  label: l10n.pushOpen,
                  onPressed: () => _open(message.route!),
                )
              : null,
        ),
      );
    });
    if (await service.initialRoute() case final route?) _open(route);
  }

  @override
  Widget build(BuildContext context) {
    // Garde la synchronisation des notifications active (compte, sujets).
    ref
      ..watch(pushSyncProvider)
      // Vérification de la mise à jour au lancement.
      ..listen(availableUpdateProvider, _onUpdate)
      // Filtres mémorisés d'un compte : oubliés à sa déconnexion.
      ..listen(currentUserProvider, (previous, next) {
        final before = previous?.value?.id;
        if (before == null || next.isLoading || next.value?.id == before) {
          return;
        }
        unawaited(
          RememberedFilters.forgetAccount(
            ref.read(sharedPreferencesProvider),
            before,
          ),
        );
      })
      // Déconnexion décidée depuis un autre appareil : annoncée une fois.
      ..listen(remoteSignOutNoticeProvider, (_, raised) {
        if (!raised) return;
        ref.read(remoteSignOutNoticeProvider.notifier).clear();
        // Après le passage à Explorer (deux pages pendant la transition).
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 700), () {
            final messengerContext = _messenger.currentContext;
            if (messengerContext == null || !messengerContext.mounted) return;
            _messenger.currentState?.showSnackBar(
              SnackBar(
                key: const Key('remote-sign-out'),
                content: Text(messengerContext.l10n.devicesRemoteSignedOut),
              ),
            );
          }),
        );
      });
    return MaterialApp.router(
      scaffoldMessengerKey: _messenger,
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: TicketSurTheme.light(),
      darkTheme: TicketSurTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(appLocaleProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      onNavigationNotification: claimBackHandling,
      // Taille du texte choisie dans Paramètres → Apparence (#11).
      builder: (context, child) => AppTextSize(
        // Verrouillage par empreinte (lot 4-6a).
        child: AppLockGate(child: child ?? const SizedBox.shrink()),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
