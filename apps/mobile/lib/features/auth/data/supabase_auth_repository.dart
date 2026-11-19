import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/auth/domain/auth_repository.dart';

/// Lien ouvert depuis l'e-mail de réinitialisation. À déclarer dans
/// Supabase → Authentication → URL Configuration → Redirect URLs, et dans le
/// manifeste Android (Phase 1, dossier android/).
const String kPasswordResetRedirect = 'com.ticketsur.fasosoft://reset-password';

/// [AuthRepository] adossé à Supabase Auth.
class SupabaseAuthRepository implements AuthRepository {
  /// Crée le dépôt à partir du client Auth de Supabase.
  new(this._auth);

  final supabase.GoTrueClient _auth;

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AuthUser?> get userChanges =>
      _auth.onAuthStateChange.map((state) => _toUser(state.session?.user));

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on Object catch (error) {
      throw mapAuthError(error);
    }
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      return response.session != null;
    } on Object catch (error) {
      throw mapAuthError(error);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kPasswordResetRedirect,
      );
    } on Object catch (error) {
      final failure = mapAuthError(error);
      // Seules les erreurs qui ne disent rien du compte sont remontées.
      if (failure == AuthFailure.rateLimited ||
          failure == AuthFailure.network) {
        throw failure;
      }
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object {
      // La session locale est effacée même si le serveur est injoignable.
    }
  }

  @override
  Future<void> signOutEverywhere() async {
    try {
      await _auth.signOut(scope: supabase.SignOutScope.global);
    } on Object catch (error) {
      throw mapAuthError(error);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _auth.currentUser?.email;
    if (email == null) throw AuthFailure.unknown;
    try {
      // Revérification de l'identité : un téléphone laissé ouvert ne suffit
      // pas pour changer le mot de passe.
      await _auth.signInWithPassword(email: email, password: currentPassword);
      await _auth.updateUser(supabase.UserAttributes(password: newPassword));
    } on Object catch (error) {
      throw mapAuthError(error);
    }
  }

  @override
  Future<void> changeEmail(String newEmail) async {
    try {
      await _auth.updateUser(supabase.UserAttributes(email: newEmail.trim()));
    } on Object catch (error) {
      throw mapAuthError(error);
    }
  }

  static AuthUser? _toUser(supabase.User? user) =>
      user == null ? null : AuthUser(id: user.id, email: user.email);
}

/// Traduit une erreur Supabase Auth ou réseau en [AuthFailure].
AuthFailure mapAuthError(Object error) {
  if (error is AuthFailure) return error;
  if (error is supabase.AuthRetryableFetchException ||
      error is SocketException ||
      error is TimeoutException) {
    return AuthFailure.network;
  }
  if (error is supabase.AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return AuthFailure.invalidCredentials;
      case 'email_not_confirmed':
        return AuthFailure.emailNotConfirmed;
      case 'over_request_rate_limit' || 'over_email_send_rate_limit':
        return AuthFailure.rateLimited;
      case 'weak_password':
        return AuthFailure.weakPassword;
      case 'same_password':
        return AuthFailure.samePassword;
      case 'email_exists' || 'user_already_exists':
        return AuthFailure.emailTaken;
    }
    switch (error.statusCode) {
      case '429':
        return AuthFailure.rateLimited;
      // Anciennes versions de GoTrue : 400 sans code pour un mauvais
      // couple adresse / mot de passe.
      case '400':
        return AuthFailure.invalidCredentials;
    }
  }
  return AuthFailure.unknown;
}
