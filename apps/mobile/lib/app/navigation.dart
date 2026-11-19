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
