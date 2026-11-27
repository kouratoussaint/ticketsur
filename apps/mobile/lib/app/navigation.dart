import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Retour fiable depuis une page empilée.
extension BackNavigation on BuildContext {
  /// Revient à l'écran précédent ; arrivé directement ici (lien, reprise de
  /// l'app), va à [fallback] plutôt que de ne rien faire.
  void popOr(String fallback) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}

/// Retour système fiable : arrivé sur la page sans écran en dessous (après un
/// `go`), le bouton retour d'Android va à [fallback] au lieu de quitter l'app.
class BackToFallback extends StatelessWidget {
  const new({required this.fallback, required this.child, super.key});

  final String fallback;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: GoRouter.of(context).canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.go(fallback);
    },
    child: child,
  );
}
