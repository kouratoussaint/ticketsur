import 'package:flutter/foundation.dart' show immutable;

/// Utilisateur authentifié, réduit à ce dont l'interface a besoin.
@immutable
final class AuthUser {
  /// Crée un utilisateur.
  const new({required this.id, this.email});

  /// Identifiant Supabase Auth.
  final String id;

  /// Adresse e-mail, si connue.
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

/// Causes d'échec présentées à l'utilisateur. Volontairement peu nombreuses :
/// un message trop précis aiderait à deviner quels comptes existent (AUTH-01).
enum AuthFailure implements Exception {
  /// Adresse ou mot de passe incorrects (message générique).
  invalidCredentials,

  /// Compte existant mais adresse jamais confirmée.
  emailNotConfirmed,

  /// Trop de tentatives : attendre avant de réessayer.
  rateLimited,

  /// Serveur injoignable.
  network,

  /// Toute autre erreur.
  unknown,
}

/// Opérations d'authentification utilisées par l'application.
///
/// Toutes les méthodes qui échouent lèvent une [AuthFailure].
abstract interface class AuthRepository {
  /// Utilisateur connecté, ou `null`.
  AuthUser? get currentUser;

  /// Changements de session (connexion, déconnexion, expiration).
  Stream<AuthUser?> get userChanges;

  /// Connexion par adresse e-mail et mot de passe.
  Future<void> signIn({required String email, required String password});

  /// Demande un e-mail de réinitialisation. Réussit en silence même si le
  /// compte n'existe pas, pour ne rien révéler.
  Future<void> sendPasswordReset(String email);

  /// Déconnexion de cet appareil.
  Future<void> signOut();
}
