import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';

/// Dépôt d'authentification. Fourni au démarrage (Supabase) ou par les tests.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError(
    'authRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Utilisateur courant, mis à jour à chaque changement de session.
final currentUserProvider = StreamProvider<AuthUser?>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  yield repository.currentUser;
  yield* repository.userChanges;
});

/// Notifie GoRouter à chaque changement de session pour réévaluer les
/// redirections (connexion, déconnexion, session expirée).
class AuthRefreshNotifier extends ChangeNotifier {
  /// Écoute [changes] jusqu'à [dispose].
  new(Stream<AuthUser?> changes) {
    _subscription = changes.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthUser?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
