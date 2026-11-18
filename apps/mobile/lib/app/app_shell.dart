import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Coque de l'espace connecté (§12.2) : barre de navigation à cinq onglets.
///
/// Retour : ferme d'abord une page empilée, sinon revient à l'onglet
/// précédemment consulté (historique sans doublon), sinon à l'Accueil ;
/// depuis l'Accueil sans historique, double appui pour quitter. Chaque
/// onglet garde son état.
class AppShell extends StatefulWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
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

  void _select(int index) => widget.navigationShell.goBranch(
    index,
    // Retaper l'onglet courant ramène à sa racine.
    initialLocation: index == widget.navigationShell.currentIndex,
  );

  bool _onBack() {
    final current = widget.navigationShell.currentIndex;
    _history.remove(current);
    final int target;
    if (_history.isNotEmpty) {
      target = _history.removeLast();
    } else if (current != 0) {
      target = 0;
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
    return DoubleBackToExit(
      onBackIntercept: _onBack,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          key: const Key('app-navigation-bar'),
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.event_outlined),
              selectedIcon: const Icon(Icons.event_rounded),
              label: l10n.navEvents,
            ),
            NavigationDestination(
              icon: const Icon(Icons.confirmation_number_outlined),
              selectedIcon: const Icon(Icons.confirmation_number_rounded),
              label: l10n.navTickets,
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: const Icon(Icons.groups_rounded),
              label: l10n.navTeam,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_circle_outlined),
              selectedIcon: const Icon(Icons.account_circle_rounded),
              label: l10n.navProfile,
            ),
          ],
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
