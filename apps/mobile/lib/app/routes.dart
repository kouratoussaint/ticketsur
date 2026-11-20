import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_shell.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/features/admin/presentation/console_accounts_page.dart';
import 'package:ticketsur/features/admin/presentation/console_announcements_page.dart';
import 'package:ticketsur/features/admin/presentation/console_catalog_page.dart';
import 'package:ticketsur/features/admin/presentation/console_journal_page.dart';
import 'package:ticketsur/features/admin/presentation/console_legal_page.dart';
import 'package:ticketsur/features/admin/presentation/console_organizations_page.dart';
import 'package:ticketsur/features/admin/presentation/console_page.dart';
import 'package:ticketsur/features/admin/presentation/console_support_page.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/presentation/forgot_password_page.dart';
import 'package:ticketsur/features/auth/presentation/sign_in_page.dart';
import 'package:ticketsur/features/auth/presentation/sign_up_page.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/catalog/presentation/public_event_page.dart';
import 'package:ticketsur/features/dashboard/presentation/event_dashboard_page.dart';
import 'package:ticketsur/features/events/presentation/event_detail_page.dart';
import 'package:ticketsur/features/events/presentation/event_form_page.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/favorites/presentation/favorites_page.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/legal/presentation/legal_pages.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
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
import 'package:ticketsur/features/settings/presentation/settings_page.dart';
import 'package:ticketsur/features/support/presentation/support_pages.dart';
import 'package:ticketsur/features/team/presentation/team_tab_page.dart';
import 'package:ticketsur/features/ticket_import/presentation/ticket_import_page.dart';
import 'package:ticketsur/features/ticket_send/presentation/ticket_send_page.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_detail_page.dart';
import 'package:ticketsur/features/tickets/presentation/tickets_tab_page.dart';
import 'package:ticketsur/features/wallet/presentation/wallet_pages.dart';
import 'package:ticketsur/features/welcome/welcome_page.dart';

/// Chemins de navigation de l'application.
abstract final class AppRoutes {
  /// Racine : l'Explorer pour le public, l'espace organisateur une fois
  /// connecté.
  static const String welcome = '/';

  /// Explorer dans l'espace connecté (onglet).
  static const String explore = '/explorer';

  /// Explorer sans compte (hors de l'espace connecté).
  static const String discover = '/decouvrir';

  /// Fiche publique d'un événement (connecté ou non).
  static String publicEvent(String id) => '/evenement/$id';

  /// « Organiser » sans compte : présentation et connexion.
  static const String organize = '/organiser';

  /// Connexion (S03).
  static const String signIn = '/connexion';

  /// Création de compte ; `?code=1` : arrivée par un code d'invitation.
  /// Hors de [guestOnly] : la page finit elle-même son parcours (structure,
  /// code) une fois la session ouverte, avant d'aller à l'accueil.
  static const String signUp = '/inscription';

  /// Inscription avec un code d'invitation.
  static const String signUpWithCode = '/inscription?code=1';

  /// Favoris (pages empilée), pour tous, connecté ou non.
  static const String favorites = '/favoris';

  /// Onglet Favoris des comptes classiques (sans structure).
  static const String favoritesTab = '/mes-favoris';

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

  /// Tableau de bord en direct d'un événement (S19).
  static String eventDashboard(String id) => '/evenements/$id/tableau-de-bord';

  /// Onglet Tickets.
  static const String tickets = '/tickets';

  /// Fiche d'un ticket.
  static String ticketDetail(String eventId, String ticketId) =>
      '/tickets/$eventId/$ticketId';

  /// Import d'une liste (Excel, CSV) pour un événement.
  static String ticketImport(String eventId) => '/tickets/importer/$eventId';

  /// Envoi en série des tickets d'un événement.
  static String ticketSend(String eventId) => '/tickets/envoi/$eventId';

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

  /// Console d'administration de la plateforme (administrateurs seulement ;
  /// chaque lecture est vérifiée côté serveur).
  static const String console = '/console';

  /// Console : organisations.
  static const String consoleOrganizations = '/console/organisations';

  /// Console : modération du catalogue public.
  static const String consoleCatalog = '/console/catalogue';

  /// Console : journal d'audit.
  static const String consoleJournal = '/console/journal';

  /// Console : comptes.
  static const String consoleAccounts = '/console/comptes';

  /// Console : demandes de support.
  static const String consoleSupport = '/console/support';

  /// Console : fil d'une demande.
  static String consoleSupportThread(String id) => '$consoleSupport/$id';

  /// Console : annonces.
  static const String consoleAnnouncements = '/console/annonces';

  /// Console : nouvelle annonce.
  static const String consoleAnnouncementNew = '/console/annonces/nouvelle';

  /// Aide et support : mes demandes.
  static const String support = '/support';

  /// Nouvelle demande de support.
  static const String supportNew = '/support/nouvelle';

  /// Fil d'une demande de support.
  static String supportThread(String id) => '$support/$id';

  /// Mes tickets : onglet d'un compte classique.
  static const String walletTab = '/mes-tickets';

  /// Mes tickets, empilé (membre d'une structure, depuis le Profil).
  static const String wallet = '/portefeuille';

  /// Ajouter un ticket à Mes tickets.
  static const String walletAdd = '/ajouter-un-ticket';

  /// Caméra pour ajouter un ticket.
  static const String walletScan = '/ajouter-un-ticket/scanner';

  /// Un ticket de Mes tickets.
  static String walletTicket(String id) => '/mon-ticket/$id';

  /// Paramètres (ouverts à tous).
  static const String settings = '/parametres';

  /// Mentions légales : `/mentions/conditions` ou `/mentions/confidentialite`.
  static String legal(LegalSlug slug) => '/mentions/${legalPathOf(slug)}';

  /// Console : mentions légales.
  static const String consoleLegal = '/console/mentions';

  /// Console : modifier un document légal.
  static String consoleLegalEdit(LegalSlug slug) =>
      '$consoleLegal/${legalPathOf(slug)}';

  /// Galerie de revue des verdicts (données fictives, sans réseau).
  static const String verdictPreview = '/apercu/verdicts';

  /// Pages réservées aux visiteurs non connectés.
  static const Set<String> guestOnly = {
    organize,
    signIn,
    forgotPassword,
    discover,
  };

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
    console,
    favoritesTab,
    support,
    walletTab,
    wallet,
    walletAdd,
    '/mon-ticket',
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
  if (location == AppRoutes.welcome) {
    return signedIn ? AppRoutes.home : AppRoutes.discover;
  }
  if (signedIn && location == AppRoutes.discover) {
    return AppRoutes.explore;
  }
  if (!signedIn && location == AppRoutes.explore) {
    return AppRoutes.discover;
  }
  if (!signedIn && signedInArea) {
    return AppRoutes.signIn;
  }
  if (signedIn && AppRoutes.guestOnly.contains(location)) {
    return AppRoutes.home;
  }
  return null;
}

/// Redirection selon le rôle dans la structure active : un contrôleur ne
/// voit jamais les pages du promoteur ; un compte classique (sans
/// structure, [role] `null`) ni celles du promoteur ni celles du contrôle.
/// Le serveur refuse de toute façon ces lectures et écritures.
String? roleRedirect({required MemberRole? role, required String location}) {
  bool under(String root) => location == root || location.startsWith('$root/');
  final promoterArea =
      [
        AppRoutes.home,
        AppRoutes.events,
        AppRoutes.tickets,
        AppRoutes.team,
      ].any(under) ||
      location == AppRoutes.editOrganization;
  final controlArea = [
    AppRoutes.control,
    AppRoutes.history,
    AppRoutes.posts,
    AppRoutes.scanner,
  ].any(under);
  return switch (role) {
    null when promoterArea || controlArea => AppRoutes.explore,
    MemberRole.controller when promoterArea => AppRoutes.control,
    _ => null,
  };
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
    redirect: (context, state) {
      final location = state.matchedLocation;
      final auth = authRedirect(
        signedIn: repository.currentUser != null,
        location: location,
      );
      if (auth != null || repository.currentUser == null) return auth;
      // Rôle connu seulement si la liste des structures est déjà chargée
      // (sinon la coque choisit les onglets une fois chargée).
      if (!ref.read(organizationsProvider.exists)) return null;
      final organizations = ref.read(organizationsProvider).value;
      if (organizations == null) return null;
      return roleRedirect(role: organizations.active?.role, location: location);
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        // Toujours redirigée (authRedirect) : Explorer ou espace connecté.
        redirect: (context, state) => AppRoutes.discover,
      ),
      GoRoute(
        path: AppRoutes.discover,
        pageBuilder: (context, state) =>
            _levelPage(state, const GuestShell(child: ExplorePage())),
      ),
      GoRoute(
        path: '/evenement/:eventId',
        pageBuilder: (context, state) => _forwardPage(
          state,
          PublicEventPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.organize,
        pageBuilder: (context, state) =>
            _forwardPage(state, const WelcomePage()),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        pageBuilder: (context, state) =>
            _forwardPage(state, const SignInPage()),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        pageBuilder: (context, state) => _forwardPage(
          state,
          SignUpPage(withCode: state.uri.queryParameters['code'] == '1'),
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        pageBuilder: (context, state) =>
            _forwardPage(state, const FavoritesPage()),
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
        path: AppRoutes.console,
        pageBuilder: (context, state) =>
            _forwardPage(state, const ConsolePage()),
        routes: [
          GoRoute(
            path: 'organisations',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleOrganizationsPage()),
          ),
          GoRoute(
            path: 'catalogue',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleCatalogPage()),
          ),
          GoRoute(
            path: 'comptes',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleAccountsPage()),
          ),
          GoRoute(
            path: 'journal',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleJournalPage()),
          ),
          GoRoute(
            path: 'support',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleSupportPage()),
            routes: [
              GoRoute(
                path: ':requestId',
                pageBuilder: (context, state) => _forwardPage(
                  state,
                  SupportThreadPage(
                    requestId: state.pathParameters['requestId']!,
                    admin: true,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'mentions',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleLegalPage()),
            routes: [
              GoRoute(
                path: ':slug',
                redirect: (context, state) =>
                    legalSlugOfPath(state.pathParameters['slug']) == null
                    ? AppRoutes.consoleLegal
                    : null,
                pageBuilder: (context, state) => _forwardPage(
                  state,
                  ConsoleLegalEditPage(
                    slug: legalSlugOfPath(state.pathParameters['slug'])!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'annonces',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleAnnouncementsPage()),
            routes: [
              GoRoute(
                path: 'nouvelle',
                pageBuilder: (context, state) =>
                    _forwardPage(state, const ConsoleAnnouncementFormPage()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.wallet,
        pageBuilder: (context, state) =>
            _forwardPage(state, const WalletPage(showBack: true)),
      ),
      GoRoute(
        path: AppRoutes.walletAdd,
        pageBuilder: (context, state) =>
            _forwardPage(state, const WalletAddPage()),
        routes: [
          GoRoute(
            path: 'scanner',
            pageBuilder: (context, state) =>
                _forwardPage(state, const WalletScanPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/mon-ticket/:ticketId',
        pageBuilder: (context, state) => _forwardPage(
          state,
          WalletTicketPage(ticketId: state.pathParameters['ticketId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            _forwardPage(state, const SettingsPage()),
      ),
      GoRoute(
        path: '/mentions/:slug',
        redirect: (context, state) =>
            legalSlugOfPath(state.pathParameters['slug']) == null
            ? AppRoutes.settings
            : null,
        pageBuilder: (context, state) => _forwardPage(
          state,
          LegalPage(slug: legalSlugOfPath(state.pathParameters['slug'])!),
        ),
      ),
      GoRoute(
        path: AppRoutes.support,
        pageBuilder: (context, state) =>
            _forwardPage(state, const SupportListPage()),
        routes: [
          GoRoute(
            path: 'nouvelle',
            pageBuilder: (context, state) =>
                _forwardPage(state, const NewSupportRequestPage()),
          ),
          GoRoute(
            path: ':requestId',
            pageBuilder: (context, state) => _forwardPage(
              state,
              SupportThreadPage(requestId: state.pathParameters['requestId']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.verdictPreview,
        pageBuilder: (context, state) =>
            _forwardPage(state, const VerdictPreviewPage()),
      ),
      // Pages empilées au-dessus des onglets (navigateur racine) : Retour
      // revient toujours à l'écran d'où l'on vient (Accueil, liste, tableau
      // de bord…), jamais à une page intermédiaire. On y va par push.
      GoRoute(
        path: AppRoutes.newEvent,
        pageBuilder: (context, state) =>
            _forwardPage(state, const EventFormPage()),
      ),
      GoRoute(
        path: '/evenements/:eventId',
        pageBuilder: (context, state) => _forwardPage(
          state,
          EventDetailPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/evenements/:eventId/modifier',
        pageBuilder: (context, state) => _forwardPage(
          state,
          EventFormPage(eventId: state.pathParameters['eventId']),
        ),
      ),
      GoRoute(
        path: '/evenements/:eventId/tableau-de-bord',
        pageBuilder: (context, state) => _forwardPage(
          state,
          EventDashboardPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      // Avant '/tickets/:eventId/:ticketId', qui les masquerait.
      GoRoute(
        path: '/tickets/importer/:eventId',
        pageBuilder: (context, state) => _forwardPage(
          state,
          TicketImportPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/tickets/envoi/:eventId',
        pageBuilder: (context, state) => _forwardPage(
          state,
          TicketSendPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/tickets/:eventId/:ticketId',
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
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) =>
            _forwardPage(state, const EditProfilePage()),
      ),
      GoRoute(
        path: AppRoutes.editOrganization,
        pageBuilder: (context, state) =>
            _forwardPage(state, const OrganizationEditPage()),
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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tickets,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TicketsTabPage()),
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
              ),
            ],
          ),
          // Onglets des contrôleurs (index 5 et 6, voir AppShell).
          _tab(AppRoutes.control, const ControlHomePage()),
          _tab(AppRoutes.history, const RecentScansPage()),
          // Explorer (index 7), ouvert à tous, connecté ou non.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ExplorePage()),
              ),
            ],
          ),
          // Favoris (index 8), onglet des comptes classiques.
          _tab(AppRoutes.favoritesTab, const FavoritesPage(showBack: false)),
          // 9 : Mes tickets (compte classique).
          _tab(AppRoutes.walletTab, const WalletPage()),
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

/// Segment d'adresse d'un document légal.
String legalPathOf(LegalSlug slug) => switch (slug) {
  LegalSlug.terms => 'conditions',
  LegalSlug.privacy => 'confidentialite',
};

LegalSlug? legalSlugOfPath(String? path) => switch (path) {
  'conditions' => LegalSlug.terms,
  'confidentialite' => LegalSlug.privacy,
  _ => null,
};
