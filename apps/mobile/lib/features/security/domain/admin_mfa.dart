import 'package:flutter/foundation.dart' show immutable;

/// État de la double authentification d'un administrateur (migration 4800).
@immutable
final class AdminMfaStatus {
  const new({
    this.enrolled = false,
    this.aal2 = false,
    this.recoveryCodesLeft = 0,
  });

  factory fromJson(Map<String, dynamic> json) => AdminMfaStatus(
    enrolled: json['enrolled'] as bool? ?? false,
    aal2: json['aal'] == 'aal2',
    recoveryCodesLeft: (json['recovery_codes_left'] as num?)?.toInt() ?? 0,
  );

  /// Facteur TOTP vérifié.
  final bool enrolled;

  /// Session déjà validée par le code.
  final bool aal2;
  final int recoveryCodesLeft;
}

/// Facteur en cours d'activation : à scanner dans l'application
/// d'authentification, ou à saisir à la main (`secret`).
typedef MfaEnrollment = ({String factorId, String uri, String secret});

/// Échecs de la double authentification.
enum MfaFailure implements Exception {
  /// Code à 6 chiffres refusé.
  invalidCode,

  /// Trop d'essais de codes de secours dans l'heure.
  rateLimited,

  /// Aucun facteur activé.
  notEnrolled,
  network,
  unknown,
}

/// Double authentification des administrateurs (Supabase Auth + migration
/// 4800).
abstract interface class AdminMfaRepository {
  Future<AdminMfaStatus> status();

  /// Crée un facteur TOTP non vérifié (les anciens non vérifiés sont retirés).
  Future<MfaEnrollment> enroll();

  /// Vérifie un code : active le facteur [factorId] ou, sans [factorId],
  /// valide la session avec le facteur déjà activé (niveau aal2).
  Future<void> verify(String code, {String? factorId});

  /// Nouveaux codes de secours (remplacent les anciens), affichés une fois.
  Future<List<String>> generateRecoveryCodes();

  /// Code de secours : retire la double authentification. Faux si refusé.
  Future<bool> useRecoveryCode(String code);

  /// Retire la double authentification (session aal2 exigée).
  Future<void> disable();
}

/// Code à 6 chiffres valide ?
bool isTotpCode(String value) => RegExp(r'^\d{6}$').hasMatch(value.trim());
