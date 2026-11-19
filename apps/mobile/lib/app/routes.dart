import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_shell.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/presentation/forgot_password_page.dart';
import 'package:ticketsur/features/auth/presentation/sign_in_page.dart';
import 'package:ticketsur/features/events/presentation/event_detail_page.dart';
import 'package:ticketsur/features/events/presentation/event_form_page.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/organizations/presentation/create_organization_page.dart';
import 'package:ticketsur/features/organizations/presentation/join_organization_page.dart';
import 'package:ticketsur/features/organizations/presentation/organization_edit_page.dart';
import 'package:ticketsur/features/organizations/presentation/organization_gate.dart';
import 'package:ticketsur/features/profile/presentation/edit_profile_page.dart';
import 'package:ticketsur/features/profile/profile_page.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/features/scanner/presentation/control_home_page.dart';
import 'package:ticketsur/features/scanner/presentation/recent_scans_page.dart';
import 'package:ticketsur/features/scanner/presentation/scanner_page.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_preview_page.dart';
import 'package:ticketsur/features/team/presentation/team_tab_page.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_detail_page.dart';
import 'package:ticketsur/features/tickets/presentation/tickets_tab_page.dart';
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

  /// Création d'un événement.
  static const String newEvent = '/evenements/nouveau';

  /// Fiche d'un événement.
  static String eventDetail(String id) => '/evenements/$id';

  /// Modification d'un événement.
  static String editEvent(String id) => '/evenements/$id/modifier';

  /// Onglet Tickets.
  static const String tickets = '/tickets';

  /// Fiche d'un ticket.
  static String ticketDetail(String eventId, String ticketId) =>
      '/tickets/$eventId/$ticketId';

  /// Onglet Contrôle (contrôleurs).
  static const String control = '/controle';

  /// Onglet Historique des scans (contrôleurs).
  static const String history = '/historique';

  /// Postes de contrôle, page empilée (organisateurs affectés).
  static const String posts = '/postes';

  /// Poste de scan plein écran (le poste est passé en `extra`).
  static const String scanner = '/scan';

  /// Onglet Équipe.
  static const String team = '/equipe';

  /// Onglet Profil.
  static const String profile = '/profil';

  /// Modification du profil.
  static const String editProfile = '/profil/modifier';

  /// Fiche de l'organisation active.
  static const String editOrganization = '/profil/organisation';

  /// Création d'une organisation supplémentaire.
  static const String newOrganization = '/organisation/nouvelle';

  /// Rejoindre une organisation avec un code.
  static const String joinOrganization = '/organisation/rejoindre';

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
    control,
    history,
    posts,
    scanner,
  };
}

/// Redirection selon la session : un visiteur ne voit jamais une page
/// connectée, un utilisateur connecté ne revoit pas l'accueil public.
/// Retourne `null` quand la page demandée convient.
String? authRedirect({required bool signedIn, required String location}) {
  final signedInArea =
      location == AppRoutes.newOrganization ||
      location == AppRoutes.joinOrganization ||
      AppRoutes.signedInOnly.any(
        (root) => location == root || location.startsWith('$root/'),
      );
  if (!signedIn && signedInArea) {
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
        path: AppRoutes.newOrganization,
        pageBuilder: (context, state) =>
            _forwardPage(state, const CreateOrganizationPage()),
      ),
      GoRoute(
        path: AppRoutes.posts,
        pageBuilder: (context, state) => _forwardPage(
          state,
          ControlHomePage(eventId: state.uri.queryParameters['evenement']),
        ),
      ),
      GoRoute(
        path: AppRoutes.scanner,
        // Sans poste (redémarrage, lien direct) : retour au choix du poste.
        redirect: (context, state) =>
            state.extra is ScanPost ? null : AppRoutes.posts,
        pageBuilder: (context, state) =>
            _forwardPage(state, ScannerPage(post: state.extra! as ScanPost)),
      ),
      GoRoute(
        path: AppRoutes.joinOrganization,
        pageBuilder: (context, state) =>
            _forwardPage(state, const JoinOrganizationPage()),
      ),
      GoRoute(
        path: AppRoutes.verdictPreview,
        pageBuilder: (context, state) =>
            _forwardPage(state, const VerdictPreviewPage()),
      ),
      StatefulShellRoute(
        pageBuilder: (context, state, navigationShell) => _levelPage(
          state,
          OrganizationGate(child: AppShell(navigationShell: navigationShell)),
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AnimatedBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          _tab(AppRoutes.home, const HomePage()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.events,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: EventsTabPage()),
                routes: [
                  GoRoute(
                    path: 'nouveau',
                    pageBuilder: (context, state) =>
                        _forwardPage(state, const EventFormPage()),
                  ),
                  GoRoute(
                    path: ':eventId',
                    pageBuilder: (context, state) => _forwardPage(
                      state,
                      EventDetailPage(
                        eventId: state.pathParameters['eventId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'modifier',
                        pageBuilder: (context, state) => _forwardPage(
                          state,
                          EventFormPage(
                            eventId: state.pathParameters['eventId'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tickets,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TicketsTabPage()),
                routes: [
                  GoRoute(
                    path: ':eventId/:ticketId',
                    pageBuilder: (context, state) => _forwardPage(
                      state,
                      TicketDetailPage(
                        eventId: state.pathParameters['eventId']!,
                        ticketId: state.pathParameters['ticketId']!,
                        initial: state.extra is TicketSummary
                            ? state.extra! as TicketSummary
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _tab(AppRoutes.team, const TeamTabPage()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfilePage()),
                routes: [
                  GoRoute(
                    path: 'modifier',
                    pageBuilder: (context, state) =>
                        _forwardPage(state, const EditProfilePage()),
                  ),
                  GoRoute(
                    path: 'organisation',
                    pageBuilder: (context, state) =>
                        _forwardPage(state, const OrganizationEditPage()),
                  ),
                ],
              ),
            ],
          ),
          // Onglets des contrôleurs (index 5 et 6, voir AppShell).
          _tab(AppRoutes.control, const ControlHomePage()),
          _tab(AppRoutes.history, const RecentScansPage()),
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
