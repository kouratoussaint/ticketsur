import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/support/application/support_providers.dart';
import 'package:ticketsur/features/updates/application/update_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Coque de l'espace connecté (§12.2, refonte Tikéo). La barre dépend du
/// rôle (sans compte, voir [GuestShell]) :
/// - organisateur : Explorer / Organiser (Accueil, et la liste des
///   événements qu'il ouvre) / Tickets / Équipe / Profil ;
/// - contrôleur : Contrôle / Historique / Explorer / Profil, sans modules
///   d'administration.
///
/// Retour : ferme d'abord une page empilée, sinon revient à l'onglet
/// précédemment consulté (historique sans doublon), sinon à l'Accueil ;
/// depuis l'Accueil sans historique, double appui pour quitter. Chaque
/// onglet garde son état.
class AppShell extends ConsumerStatefulWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Branche de l'Explorer (voir routes.dart).
  static const int exploreTab = 7;

  /// Branches proposées aux organisateurs : Explorer, Organiser (Accueil),
  /// Tickets, Équipe, Profil. La liste des événements (1) s'affiche sous
  /// l'onglet Organiser.
  static const List<int> organizerTabs = [7, 0, 2, 3, 4];

  /// Branches proposées aux contrôleurs : Contrôle, Historique, Explorer,
  /// Profil.
  static const List<int> controllerTabs = [5, 6, 7, 4];

  /// Branches d'un compte classique (sans structure) : Explorer, Favoris,
  /// Profil.
  static const List<int> memberTabs = [7, 8, 4];

  /// Barre d'onglets selon le rôle dans la structure active.
  static List<int> tabsFor(Organization? organization) =>
      switch (organization?.role) {
        null => memberTabs,
        MemberRole.controller => controllerTabs,
        _ => organizerTabs,
      };

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Onglets consultés avant l'onglet courant, du plus ancien au plus récent.
  final List<int> _history = [];
  late int _current = widget.navigationShell.currentIndex;

  /// Onglet visé par un Retour en cours (ne doit pas être réempilé).
  int? _returningTo;

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.navigationShell.currentIndex;
    if (next == _current) return;
    if (_returningTo == next) {
      _returningTo = null;
    } else {
      // Tout changement d'onglet (barre, lien interne) est mémorisé.
      _history
        ..remove(next)
        ..remove(_current)
        ..add(_current);
    }
    _current = next;
  }

  void _select(int index) {
    ref.read(feedbackProvider).tap();
    widget.navigationShell.goBranch(
      index,
      // Retaper l'onglet courant ramène à sa racine.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  List<int> get _tabs => AppShell.tabsFor(ref.read(activeOrganizationProvider));

  /// Onglet de repli et de sortie (Retour) : l'Accueil du promoteur, le
  /// Contrôle, ou l'Explorer d'un compte classique.
  int _home(List<int> tabs) => tabs == AppShell.organizerTabs ? 0 : tabs.first;

  /// Branches affichables pour la barre courante (la liste des événements
  /// appartient à l'onglet Organiser).
  List<int> _allowed(List<int> tabs) =>
      tabs == AppShell.organizerTabs ? [...tabs, 1] : tabs;

  bool _onBack() {
    final current = widget.navigationShell.currentIndex;
    final tabs = _tabs;
    _history.removeWhere(
      (index) => index == current || !_allowed(tabs).contains(index),
    );
    final int target;
    if (_history.isNotEmpty) {
      target = _history.removeLast();
    } else if (current != _home(tabs)) {
      target = _home(tabs);
    } else {
      return false;
    }
    _returningTo = target;
    widget.navigationShell.goBranch(target);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = AppShell.tabsFor(ref.watch(activeOrganizationProvider));
    final current = widget.navigationShell.currentIndex;
    if (!_allowed(tabs).contains(current)) {
      // Onglet hors du rôle (connexion, changement d'organisation) : premier
      // onglet du rôle, après cette image.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_allowed(_tabs).contains(widget.navigationShell.currentIndex)) {
          _returningTo = _home(_tabs);
          widget.navigationShell.goBranch(_home(_tabs));
        }
      });
    }
    // Point sur Profil : réponse du support non lue ou nouvelle version.
    final profileAttention =
        ref.watch(supportUnreadProvider) > 0 ||
        ref.watch(availableUpdateProvider).value != null;
    final destinations = {
      7: NavigationDestination(
        icon: const Icon(Icons.explore_outlined),
        selectedIcon: const Icon(Icons.explore_rounded),
        label: l10n.navExplore,
      ),
      0: NavigationDestination(
        icon: const Icon(Icons.event_outlined),
        selectedIcon: const Icon(Icons.event_rounded),
        label: l10n.navOrganize,
      ),
      1: NavigationDestination(
        icon: const Icon(Icons.event_outlined),
        selectedIcon: const Icon(Icons.event_rounded),
        label: l10n.navEvents,
      ),
      2: NavigationDestination(
        icon: const Icon(Icons.confirmation_number_outlined),
        selectedIcon: const Icon(Icons.confirmation_number_rounded),
        label: l10n.navTickets,
      ),
      3: NavigationDestination(
        icon: const Icon(Icons.groups_outlined),
        selectedIcon: const Icon(Icons.groups_rounded),
        label: l10n.navTeam,
      ),
      4: NavigationDestination(
        icon: Badge(
          key: const Key('nav-profile-badge'),
          isLabelVisible: profileAttention,
          child: const Icon(Icons.account_circle_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: profileAttention,
          child: const Icon(Icons.account_circle_rounded),
        ),
        label: l10n.navProfile,
      ),
      5: NavigationDestination(
        icon: const Icon(Icons.qr_code_scanner_outlined),
        selectedIcon: const Icon(Icons.qr_code_scanner_rounded),
        label: l10n.navControl,
      ),
      6: NavigationDestination(
        icon: const Icon(Icons.history_outlined),
        selectedIcon: const Icon(Icons.history_rounded),
        label: l10n.navHistory,
      ),
      8: NavigationDestination(
        icon: const Icon(Icons.favorite_border_rounded),
        selectedIcon: const Icon(Icons.favorite_rounded),
        label: l10n.navFavorites,
      ),
    };
    final bar = tabs;
    // La liste des événements (1) s'affiche sous « Organiser » (0).
    final selected = bar.indexOf(current == 1 ? 0 : current);
    return DoubleBackToExit(
      onBackIntercept: _onBack,
      child: Scaffold(
        // Onglet hors du rôle (le temps d'y renoncer) : jamais affiché, pas
        // même une image (un contrôleur ne voit pas l'Accueil du promoteur).
        body: Offstage(
          offstage: !_allowed(tabs).contains(current),
          child: widget.navigationShell,
        ),
        bottomNavigationBar: NavigationBar(
          key: const Key('app-navigation-bar'),
          selectedIndex: selected < 0 ? 0 : selected,
          onDestinationSelected: (i) => _select(bar[i]),
          destinations: [for (final index in bar) destinations[index]!],
        ),
      ),
    );
  }
}

/// Conteneur des onglets : tous restent montés (état conservé) ; l'onglet
/// actif apparaît en fondu enchaîné, les autres sont inertes et invisibles
/// pour TalkBack.
class AnimatedBranchContainer extends StatelessWidget {
  const new({required this.currentIndex, required this.children, super.key});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduced = TicketSurMotion.reduced(context);
    final duration = reduced ? Duration.zero : TicketSurMotion.medium;
    // L'onglet actif est peint en dernier (au-dessus) ; les clés conservent
    // l'état de chaque onglet malgré le réordonnancement.
    final order = [
      for (var i = 0; i < children.length; i++)
        if (i != currentIndex) i,
      currentIndex,
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final index in order)
          _Branch(
            key: ValueKey<int>(index),
            active: index == currentIndex,
            duration: duration,
            child: children[index],
          ),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const new({
    required this.active,
    required this.duration,
    required this.child,
    super.key,
  });

  final bool active;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Les animations de fondu restent HORS du TickerMode : un onglet qui
    // sort doit pouvoir finir de s'effacer. (Défaut constaté sur appareil :
    // son fondu figé à 100 % le laissait affiché par-dessus l'onglet choisi.)
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: ExcludeFocus(
          excluding: !active,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: duration,
            curve: active ? TicketSurMotion.enter : TicketSurMotion.exit,
            child: AnimatedScale(
              scale: active ? 1 : 0.97,
              duration: duration,
              curve: TicketSurMotion.enter,
              child: TickerMode(enabled: active, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Coque sans compte : l'Explorer, et deux entrées qui ouvrent la
/// présentation « Organiser » et la connexion. Hors de l'espace connecté :
/// à la déconnexion, la coque connectée (et ses données) est libérée.
class GuestShell extends ConsumerWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DoubleBackToExit(
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          key: const Key('app-navigation-bar'),
          onDestinationSelected: (index) {
            ref.read(feedbackProvider).tap();
            switch (index) {
              case 1:
                unawaited(context.push(AppRoutes.favorites));
              case 2:
                unawaited(context.push(AppRoutes.organize));
              case 3:
                unawaited(context.push(AppRoutes.signIn));
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore_rounded),
              label: l10n.navExplore,
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_border_rounded),
              label: l10n.navFavorites,
            ),
            NavigationDestination(
              icon: const Icon(Icons.event_outlined),
              label: l10n.navOrganize,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_circle_outlined),
              label: l10n.navAccount,
            ),
          ],
        ),
      ),
    );
  }
}
