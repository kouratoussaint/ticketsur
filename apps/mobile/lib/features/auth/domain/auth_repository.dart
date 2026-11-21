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

  /// Nouveau mot de passe trop faible.
  weakPassword,

  /// Nouveau mot de passe identique à l'ancien.
  samePassword,

  /// Adresse déjà utilisée par un autre compte.
  emailTaken,

  /// Inscriptions fermées : un code d'invitation valable est nécessaire
  /// (lot 4-11d).
  signupsClosed,

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

  /// Création d'un compte ; le nom sert au profil (`display_name`). Renvoie
  /// vrai si la session est ouverte, faux si l'adresse doit d'abord être
  /// confirmée.
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    String? invitationCode,
  });

  /// Demande un e-mail de réinitialisation. Réussit en silence même si le
  /// compte n'existe pas, pour ne rien révéler.
  Future<void> sendPasswordReset(String email);

  /// Renvoie l'e-mail de confirmation d'un compte créé. Réussit en silence,
  /// sauf trop de demandes ou absence de réseau.
  Future<void> resendSignUpConfirmation(String email);

  /// Ouverture de l'app par le lien « mot de passe oublié » : une session de
  /// récupération est ouverte, l'utilisateur doit choisir un nouveau mot de
  /// passe.
  Stream<void> get passwordRecovery;

  /// Nouveau mot de passe, sans l'actuel (session de récupération).
  Future<void> setNewPassword(String password);

  /// Déconnexion de cet appareil.
  Future<void> signOut();

  /// Déconnexion de tous les appareils (sessions révoquées côté serveur).
  Future<void> signOutEverywhere();

  /// Change le mot de passe après avoir revérifié l'actuel.
  /// [AuthFailure.invalidCredentials] si l'actuel est faux.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Demande le changement d'adresse : un lien de confirmation est envoyé ;
  /// l'adresse ne change qu'après confirmation.
  Future<void> changeEmail(String newEmail);
}
