import 'dart:async';

import 'package:ticketsur/features/auth/domain/auth_repository.dart';

/// Faux dépôt d'authentification, piloté par les tests.
class FakeAuthRepository implements AuthRepository {
  new({this._user});

  final StreamController<AuthUser?> _changes =
      StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  /// Erreur levée par le prochain [signIn], puis effacée.
  AuthFailure? nextSignInFailure;

  /// Erreur levée par le prochain [sendPasswordReset], puis effacée.
  AuthFailure? nextResetFailure;

  /// Si défini, [signIn] attend sa complétion (test de l'état « en cours »).
  Completer<void>? signInGate;

  final List<({String email, String password})> signInCalls = [];
  final List<String> resetCalls = [];
  int signOutCalls = 0;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls.add((email: email, password: password));
    if (signInGate case final gate?) await gate.future;
    if (nextSignInFailure case final failure?) {
      nextSignInFailure = null;
      throw failure;
    }
    _user = AuthUser(id: 'utilisateur-test', email: email.trim());
    _changes.add(_user);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    resetCalls.add(email);
    if (nextResetFailure case final failure?) {
      nextResetFailure = null;
      throw failure;
    }
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _changes.add(null);
  }

  int signOutEverywhereCalls = 0;
  final List<({String current, String next})> passwordCalls = [];
  final List<String> emailCalls = [];

  /// Erreur levée par le prochain changement de mot de passe ou d'e-mail.
  AuthFailure? nextAccountFailure;

  @override
  Future<void> signOutEverywhere() async {
    signOutEverywhereCalls++;
    _user = null;
    _changes.add(null);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordCalls.add((current: currentPassword, next: newPassword));
    if (nextAccountFailure case final failure?) {
      nextAccountFailure = null;
      throw failure;
    }
  }

  @override
  Future<void> changeEmail(String newEmail) async {
    emailCalls.add(newEmail);
    if (nextAccountFailure case final failure?) {
      nextAccountFailure = null;
      throw failure;
    }
  }

  /// Simule une session expirée ou révoquée côté serveur.
  void expireSession() {
    _user = null;
    _changes.add(null);
  }
}
