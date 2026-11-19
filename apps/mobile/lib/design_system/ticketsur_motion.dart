import 'package:material_ui/material_ui.dart';

/// Jetons de mouvement Tikéo (inspirés de Material 3 Motion).
///
/// Règles :
/// * une animation accompagne un changement, elle ne le retarde jamais ;
/// * le chemin de scan reste instantané : les verdicts ne s'animent qu'en
///   surcouche, après affichage de la couleur et du mot ;
/// * le réglage système « supprimer les animations » est toujours respecté.
abstract final class TicketSurMotion {
  /// Micro-retours (icônes, puces) : 150 ms.
  static const Duration short = Duration(milliseconds: 150);

  /// Changements de composant (onglets, apparition d'éléments) : 250 ms.
  static const Duration medium = Duration(milliseconds: 250);

  /// Transitions de pages : 350 ms.
  static const Duration page = Duration(milliseconds: 350);

  /// Entrée de l'écran d'accueil : 700 ms au total, éléments décalés.
  static const Duration entrance = Duration(milliseconds: 700);

  /// Courbe « emphasized decelerate » : ce qui entre.
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1);

  /// Courbe « emphasized accelerate » : ce qui sort.
  static const Curve exit = Cubic(0.3, 0, 0.8, 0.15);

  /// Courbe standard.
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// Vrai si l'utilisateur a demandé de réduire les animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Transition « axe partagé » horizontale : la page suivante glisse de
/// 30 dp en apparaissant, la précédente recule en s'effaçant. Pour les
/// parcours où l'on avance (accueil → connexion → mot de passe oublié).
Widget sharedAxisTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (TicketSurMotion.reduced(context)) return child;
  final incoming = CurvedAnimation(
    parent: animation,
    curve: TicketSurMotion.enter,
    reverseCurve: TicketSurMotion.exit,
  );
  final outgoing = CurvedAnimation(
    parent: secondaryAnimation,
    curve: TicketSurMotion.standard,
  );
  // La page recouverte recule de 8 % et pâlit ; la nouvelle arrive de 8 %.
  return SlideTransition(
    position: Tween(
      begin: Offset.zero,
      end: const Offset(-0.08, 0),
    ).animate(outgoing),
    child: FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(outgoing),
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(incoming),
        child: FadeTransition(opacity: incoming, child: child),
      ),
    ),
  );
}

/// Transition « fondu enchaîné » : l'ancien contenu s'efface, le nouveau
/// apparaît en grossissant légèrement (92 % → 100 %). Pour les changements
/// de niveau (onglets, entrée dans l'espace connecté).
Widget fadeThroughTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (TicketSurMotion.reduced(context)) return child;
  final incoming = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.35, 1, curve: TicketSurMotion.enter),
  );
  return FadeTransition(
    opacity: incoming,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1).animate(incoming),
      child: child,
    ),
  );
}
