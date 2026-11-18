import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_preview_page.dart';
import 'package:ticketsur/features/welcome/welcome_page.dart';

/// Chemins de navigation de l'application.
abstract final class AppRoutes {
  /// Accueil (S02).
  static const String welcome = '/';

  /// Galerie de revue des verdicts.
  static const String verdictPreview = '/apercu/verdicts';
}

/// Routeur unique de l'application. Les redirections d'authentification
/// (session expirée, rôle contrôleur/organisateur) s'ajoutent en Phase 1.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.verdictPreview,
        builder: (context, state) => const VerdictPreviewPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
