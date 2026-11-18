import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_shell.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/presentation/forgot_password_page.dart';
import 'package:ticketsur/features/auth/presentation/sign_in_page.dart';
import 'package:ticketsur/features/home/coming_soon_pages.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/profile/profile_page.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_preview_page.dart';
import 'package:ticketsur/features/welcome/welcome_page.dart';

/// Chemins de navigation de l'application.
abstract final class AppRoutes {
  /// Accueil public (S02).
  static const String welcome = '/';

  /// Connexion (S03).
  static const String signIn = '/connexion';

  /// Mot de passe oublié (S04).
  static const String forgotPassword = '/mot-de-passe-oublie';

  /// Onglet Accueil de l'espace connecté.
  static const String home = '/accueil';

  /// Onglet Événements.
  static const String events = '/evenements';

  /// Onglet Billets.
  static const String tickets = '/billets';

  /// Onglet Équipe.
  static const String team = '/equipe';

  /// Onglet Profil.
  static const String profile = '/profil';

  /// Galerie de revue des verdicts (données fictives, sans réseau).
  static const String verdictPreview = '/apercu/verdicts';

  /// Pages réservées aux visiteurs non connectés.
  static const Set<String> guestOnly = {welcome, signIn, forgotPassword};

  /// Pages réservées aux utilisateurs connectés (onglets).
  static const Set<String> signedInOnly = {
    home,
    events,
    tickets,
    team,
    profile,
  };
}

/// Redirection selon la session : un visiteur ne voit jamais une page
/// connectée, un utilisateur connecté ne revoit pas l'accueil public.
/// Retourne `null` quand la page demandée convient.
String? authRedirect({required bool signedIn, required String location}) {
  if (!signedIn && AppRoutes.signedInOnly.contains(location)) {
    return AppRoutes.signIn;
  }
  if (signedIn && AppRoutes.guestOnly.contains(location)) {
    return AppRoutes.home;
  }
  return null;
}

/// Page avec la transition « axe partagé » (on avance dans un parcours).
CustomTransitionPage<void> _forwardPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: TicketSurMotion.page,
      reverseTransitionDuration: TicketSurMotion.page,
      transitionsBuilder: sharedAxisTransition,
    );

/// Page avec la transition « fondu enchaîné » (changement de niveau).
CustomTransitionPage<void> _levelPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: TicketSurMotion.page,
      reverseTransitionDuration: TicketSurMotion.medium,
      transitionsBuilder: fadeThroughTransition,
    );

StatefulShellBranch _tab(String path, Widget page) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      // Le conteneur d'onglets anime déjà le changement.
      pageBuilder: (context, state) => NoTransitionPage(child: page),
    ),
  ],
);

/// Routeur unique, réévalué à chaque changement de session (connexion,
/// déconnexion, expiration ou révocation de la session).
final routerProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final refresh = AuthRefreshNotifier(repository.userChanges);
  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      signedIn: repository.currentUser != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) => _levelPage(state, const WelcomePage()),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        pageBuilder: (context, state) =>
            _forwardPage(state, const SignInPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            _forwardPage(state, const ForgotPasswordPage()),
      ),
      GoRoute(
        path: AppRoutes.verdictPreview,
        pageBuilder: (context, state) =>
            _forwardPage(state, const VerdictPreviewPage()),
      ),
      StatefulShellRoute(
        pageBuilder: (context, state, navigationShell) =>
            _levelPage(state, AppShell(navigationShell: navigationShell)),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AnimatedBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          _tab(AppRoutes.home, const HomePage()),
          _tab(AppRoutes.events, const EventsTabPage()),
          _tab(AppRoutes.tickets, const TicketsTabPage()),
          _tab(AppRoutes.team, const TeamTabPage()),
          _tab(AppRoutes.profile, const ProfilePage()),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
