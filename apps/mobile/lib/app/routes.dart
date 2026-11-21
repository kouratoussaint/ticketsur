import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_shell.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/features/about/about_page.dart';
import 'package:ticketsur/features/admin/presentation/console_accounts_page.dart';
import 'package:ticketsur/features/admin/presentation/console_announcements_page.dart';
import 'package:ticketsur/features/admin/presentation/console_catalog_page.dart';
import 'package:ticketsur/features/admin/presentation/console_featured_page.dart';
import 'package:ticketsur/features/admin/presentation/console_journal_page.dart';
import 'package:ticketsur/features/admin/presentation/console_legal_page.dart';
import 'package:ticketsur/features/admin/presentation/console_organizations_page.dart';
import 'package:ticketsur/features/admin/presentation/console_page.dart';
import 'package:ticketsur/features/admin/presentation/console_support_page.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/presentation/forgot_password_page.dart';
import 'package:ticketsur/features/auth/presentation/new_password_page.dart';
import 'package:ticketsur/features/auth/presentation/sign_in_page.dart';
import 'package:ticketsur/features/auth/presentation/sign_up_page.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/presentation/addons_page.dart';
import 'package:ticketsur/features/billing/presentation/choose_pack_page.dart';
import 'package:ticketsur/features/billing/presentation/console_collect_pages.dart';
import 'package:ticketsur/features/billing/presentation/console_pack_form_page.dart';
import 'package:ticketsur/features/billing/presentation/console_packs_page.dart';
import 'package:ticketsur/features/billing/presentation/console_payment_settings_page.dart';
import 'package:ticketsur/features/billing/presentation/console_subscriptions_page.dart';
import 'package:ticketsur/features/billing/presentation/event_billing_page.dart';
import 'package:ticketsur/features/billing/presentation/invoices_page.dart';
import 'package:ticketsur/features/billing/presentation/my_pack_page.dart';
import 'package:ticketsur/features/billing/presentation/payment_request_page.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/catalog/presentation/public_event_page.dart';
import 'package:ticketsur/features/dashboard/presentation/event_dashboard_page.dart';
import 'package:ticketsur/features/dashboard/presentation/event_summary_page.dart';
import 'package:ticketsur/features/design_preview/component_gallery_page.dart';
import 'package:ticketsur/features/events/presentation/event_detail_page.dart';
import 'package:ticketsur/features/events/presentation/event_form_page.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/favorites/presentation/favorites_page.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/journal/presentation/journal_page.dart';
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
import 'package:ticketsur/features/search/presentation/search_page.dart';
import 'package:ticketsur/features/security/presentation/devices_page.dart';
import 'package:ticketsur/features/settings/presentation/settings_page.dart';
import 'package:ticketsur/features/support/presentation/support_pages.dart';
import 'package:ticketsur/features/team/presentation/team_tab_page.dart';
import 'package:ticketsur/features/ticket_import/presentation/ticket_import_page.dart';
import 'package:ticketsur/features/ticket_send/presentation/ticket_send_page.dart';
import 'package:ticketsur/features/ticket_templates/presentation/template_pages.dart';
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

  /// Connexion, puis [target] (lien profond qui exige d'être connecté).
  static String signInThen(String target) =>
      '$signIn?suite=${Uri.encodeComponent(target)}';

  /// Destination après la connexion : `suite` si c'est une page de l'app
  /// (chemin local), sinon l'Accueil.
  static String afterSignIn(String? target) =>
      target != null &&
          target.startsWith('/') &&
          !target.startsWith('//') &&
          !target.startsWith(signIn)
      ? target
      : home;

  /// Favoris (pages empilée), pour tous, connecté ou non.
  static const String favorites = '/favoris';

  /// Onglet Favoris des comptes classiques (sans structure).
  static const String favoritesTab = '/mes-favoris';

  /// Mot de passe oublié (S04).
  static const String forgotPassword = '/mot-de-passe-oublie';

  /// Nouveau mot de passe, ouvert par le lien de l'e-mail « mot de passe
  /// oublié » (session de récupération).
  static const String newPassword = '/nouveau-mot-de-passe';

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

  /// Bilan d'après-événement (ADR 0025).
  static String eventSummary(String id) => '/evenements/$id/bilan';

  /// Modèles des tickets d'un événement (ADR 0022).
  static String ticketTemplates(String id) => '/evenements/$id/modeles';

  /// Modèle d'une catégorie.
  static String ticketTemplate(String eventId, String categoryId) =>
      '/evenements/$eventId/modeles/$categoryId';

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

  /// Événements « À la une » d'Explorer (ADR 0028).
  static const String consoleFeatured = '/console/une';

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

  /// Console de facturation (C1 à C6, ADR 0027).
  static const String consolePacks = '/console/packs';

  static const String consolePackNew = '/console/packs/nouveau';

  static String consolePack(String id) => '$consolePacks/$id';

  static const String consoleCollect = '/console/encaisser';

  static String consoleCollectRequest(String id) =>
      '$consoleCollect/demande/$id';

  static String consoleCollectInvoice(String id) =>
      '$consoleCollect/facture/$id';

  static const String consoleSubscriptions = '/console/abonnements';

  static const String consolePaymentSettings = '/console/paiement';

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

  /// Journal de la structure active (propriétaire).
  static const String journal = '/structure/journal';

  /// Appareils connectés au compte (lot 4-6a).
  static const String devices = '/securite/appareils';

  /// Recherche globale du promoteur (lot 4-6b).
  static const String search = '/recherche';

  /// Mon pack et factures du promoteur (P1 à P6, ADR 0027).
  static const String billing = '/facturation';

  static const String billingPacks = '/facturation/packs';

  /// Suppléments de l'abonnement en cours.
  static const String billingAddonsCurrent = '/facturation/supplements';

  /// Suppléments d'un pack choisi, avant la demande d'activation.
  static String billingAddonsFor(String packId, BillingDuration duration) =>
      '$billingAddonsCurrent?pack=$packId&duree=${duration.wireName}';

  static String billingRequest(String id) => '$billing/demande/$id';

  /// Factures et reçus (P7).
  static const String billingInvoices = '/facturation/factures';

  /// Factures à payer seulement.
  static const String billingInvoicesToPay = '$billingInvoices?filtre=a-payer';

  static String billingInvoice(String id) => '$billingInvoices/$id';

  /// Facturation d'un événement (P9).
  static String eventBilling(String id) => '/evenements/$id/facturation';

  /// Paramètres (ouverts à tous).
  static const String settings = '/parametres';

  /// À propos : version, mise à jour, mentions (ouverte à tous).
  static const String about = '/a-propos';

  /// Mentions légales : `/mentions/conditions` ou `/mentions/confidentialite`.
  static String legal(LegalSlug slug) => '/mentions/${legalPathOf(slug)}';

  /// Console : mentions légales.
  static const String consoleLegal = '/console/mentions';

  /// Console : modifier un document légal.
  static String consoleLegalEdit(LegalSlug slug, {String locale = 'fr'}) =>
      '$consoleLegal/${legalPathOf(slug)}'
      '${locale == 'fr' ? '' : '?langue=$locale'}';

  /// Galerie de revue des verdicts (données fictives, sans réseau).
  static const String verdictPreview = '/apercu/verdicts';

  /// Galerie des composants de la direction artistique (revue en image).
  static const String componentGallery = '/apercu/composants';

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
    journal,
    devices,
    search,
    billing,
    walletAdd,
    '/mon-ticket',
  };
}

/// Redirection selon la session : un visiteur ne voit jamais une page
/// connectée, un utilisateur connecté ne revoit pas l'accueil public.
/// Retourne `null` quand la page demandée convient.
String? authRedirect({
  required bool signedIn,
  required String location,
  String? target,
  bool afterSignOut = false,
}) {
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
    // Déconnexion volontaire : Explorer, pas la connexion (#13).
    if (afterSignOut) return AppRoutes.discover;
    final next = target ?? location;
    return next == AppRoutes.home
        ? AppRoutes.signIn
        : AppRoutes.signInThen(next);
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

/// Déconnexion demandée par l'utilisateur : la redirection mène à
/// Explorer au lieu de la connexion. Remis à faux à la connexion suivante.
bool signOutRequested = false;

/// Déconnexion volontaire (« Se déconnecter », « Déconnecter tous les
/// appareils ») : Explorer ensuite, pile vidée (#13).
Future<void> signOutToExplore(
  GoRouter router,
  Future<void> Function() signOut,
) async {
  signOutRequested = true;
  try {
    await signOut();
  } on Object {
    signOutRequested = false;
    rethrow;
  }
  router.go(AppRoutes.discover);
}

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
      final signedIn = repository.currentUser != null;
      if (signedIn) signOutRequested = false;
      final auth = authRedirect(
        signedIn: signedIn,
        location: location,
        target: state.uri.toString(),
        afterSignOut: signOutRequested,
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
        path: AppRoutes.newPassword,
        pageBuilder: (context, state) =>
            _forwardPage(state, const NewPasswordPage()),
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
            path: 'une',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleFeaturedPage()),
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
                    locale: state.uri.queryParameters['langue'] == 'en'
                        ? 'en'
                        : 'fr',
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'packs',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsolePacksPage()),
            routes: [
              GoRoute(
                path: 'nouveau',
                pageBuilder: (context, state) =>
                    _forwardPage(state, const ConsolePackFormPage()),
              ),
              GoRoute(
                path: ':packId',
                pageBuilder: (context, state) => _forwardPage(
                  state,
                  ConsolePackFormPage(packId: state.pathParameters['packId']),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'encaisser',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleCollectPage()),
            routes: [
              GoRoute(
                path: 'demande/:id',
                pageBuilder: (context, state) => _forwardPage(
                  state,
                  ConsolePaymentPage(
                    id: state.pathParameters['id']!,
                    invoice: false,
                  ),
                ),
              ),
              GoRoute(
                path: 'facture/:id',
                pageBuilder: (context, state) => _forwardPage(
                  state,
                  ConsolePaymentPage(
                    id: state.pathParameters['id']!,
                    invoice: true,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'abonnements',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsoleSubscriptionsPage()),
          ),
          GoRoute(
            path: 'paiement',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ConsolePaymentSettingsPage()),
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
        path: AppRoutes.journal,
        pageBuilder: (context, state) =>
            _forwardPage(state, const JournalPage()),
      ),
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) =>
            _forwardPage(state, const SearchPage()),
      ),
      GoRoute(
        path: AppRoutes.devices,
        pageBuilder: (context, state) =>
            _forwardPage(state, const DevicesPage()),
      ),
      GoRoute(
        path: AppRoutes.billing,
        pageBuilder: (context, state) =>
            _forwardPage(state, const MyPackPage()),
        routes: [
          GoRoute(
            path: 'packs',
            pageBuilder: (context, state) =>
                _forwardPage(state, const ChoosePackPage()),
          ),
          GoRoute(
            path: 'supplements',
            pageBuilder: (context, state) => _forwardPage(
              state,
              AddonsPage(
                packId: state.uri.queryParameters['pack'],
                duration: BillingDuration.fromWire(
                  state.uri.queryParameters['duree'],
                ),
              ),
            ),
          ),
          GoRoute(
            path: 'factures',
            pageBuilder: (context, state) => _forwardPage(
              state,
              InvoicesPage(
                initial: state.uri.queryParameters['filtre'] == 'a-payer'
                    ? InvoiceFilter.toPay
                    : InvoiceFilter.all,
              ),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _forwardPage(
                  state,
                  InvoiceDetailPage(invoiceId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'demande/:id',
            pageBuilder: (context, state) => _forwardPage(
              state,
              PaymentRequestPage(requestId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            _forwardPage(state, const SettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.about,
        pageBuilder: (context, state) => _forwardPage(state, const AboutPage()),
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
      GoRoute(
        path: AppRoutes.componentGallery,
        pageBuilder: (context, state) =>
            _forwardPage(state, const ComponentGalleryPage()),
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
        path: '/evenements/:eventId/modeles',
        pageBuilder: (context, state) => _forwardPage(
          state,
          TicketTemplatesPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/evenements/:eventId/modeles/:categoryId',
        pageBuilder: (context, state) => _forwardPage(
          state,
          TemplateEditorPage(
            eventId: state.pathParameters['eventId']!,
            categoryId: state.pathParameters['categoryId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/evenements/:eventId/tableau-de-bord',
        pageBuilder: (context, state) => _forwardPage(
          state,
          EventDashboardPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/evenements/:eventId/facturation',
        pageBuilder: (context, state) => _forwardPage(
          state,
          EventBillingPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/evenements/:eventId/bilan',
        pageBuilder: (context, state) => _forwardPage(
          state,
          EventSummaryPage(eventId: state.pathParameters['eventId']!),
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
