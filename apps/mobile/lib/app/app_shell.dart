import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Coque de l'espace connecté (§12.2). La barre dépend du rôle :
/// - organisateur : Accueil / Événements / Tickets / Équipe / Profil ;
/// - contrôleur : Contrôle / Historique / Profil, sans modules
///   d'administration.
///
/// Retour : ferme d'abord une page empilée, sinon revient à l'onglet
/// précédemment consulté (historique sans doublon), sinon à l'Accueil ;
/// depuis l'Accueil sans historique, double appui pour quitter. Chaque
/// onglet garde son état.
class AppShell extends ConsumerStatefulWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Branches (voir routes.dart) proposées aux organisateurs.
  static const List<int> organizerTabs = [0, 1, 2, 3, 4];

  /// Branches proposées aux contrôleurs : Contrôle, Historique, Profil.
  static const List<int> controllerTabs = [5, 6, 4];

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

  List<int> get _tabs =>
      ref.read(activeOrganizationProvider)?.role == MemberRole.controller
      ? AppShell.controllerTabs
      : AppShell.organizerTabs;

  bool _onBack() {
    final current = widget.navigationShell.currentIndex;
    final tabs = _tabs;
    _history.removeWhere((index) => index == current || !tabs.contains(index));
    final int target;
    if (_history.isNotEmpty) {
      target = _history.removeLast();
    } else if (current != tabs.first) {
      target = tabs.first;
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
    final isController =
        ref.watch(activeOrganizationProvider.select((o) => o?.role)) ==
        MemberRole.controller;
    final tabs = isController
        ? AppShell.controllerTabs
        : AppShell.organizerTabs;
    final current = widget.navigationShell.currentIndex;
    if (!tabs.contains(current)) {
      // Onglet hors du rôle (connexion, changement d'organisation) : premier
      // onglet du rôle, après cette image.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_tabs.contains(widget.navigationShell.currentIndex)) {
          _returningTo = _tabs.first;
          widget.navigationShell.goBranch(_tabs.first);
        }
      });
    }
    final destinations = {
      0: NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: l10n.navHome,
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
        icon: const Icon(Icons.account_circle_outlined),
        selectedIcon: const Icon(Icons.account_circle_rounded),
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
    };
    final selected = tabs.indexOf(current);
    return DoubleBackToExit(
      onBackIntercept: _onBack,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          key: const Key('app-navigation-bar'),
          selectedIndex: selected < 0 ? 0 : selected,
          onDestinationSelected: (i) => _select(tabs[i]),
          destinations: [for (final index in tabs) destinations[index]!],
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
