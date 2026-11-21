import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/security/domain/admin_mfa.dart';

/// [AdminMfaRepository] : facteurs TOTP de Supabase Auth, codes de secours
/// côté serveur (migration 4800).
class SupabaseAdminMfaRepository implements AdminMfaRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  supabase.GoTrueMFAApi get _mfa => _client.auth.mfa;

  @override
  Future<AdminMfaStatus> status() => _guard(() async {
    final json = await _client
        .rpc<Map<String, dynamic>>('admin_mfa_status')
        .timeout(_timeout);
    return AdminMfaStatus.fromJson(json);
  });

  @override
  Future<MfaEnrollment> enroll() => _guard(() async {
    final factors = await _mfa.listFactors().timeout(_timeout);
    for (final factor in factors.all) {
      if (factor.status == supabase.FactorStatus.unverified) {
        await _mfa.unenroll(factor.id).timeout(_timeout);
      }
    }
    final now = DateTime.now();
    final response = await _mfa
        .enroll(
          issuer: 'Tikéo',
          friendlyName: 'Tikéo ${now.millisecondsSinceEpoch}',
        )
        .timeout(_timeout);
    final totp = response.totp;
    if (totp == null) throw MfaFailure.unknown;
    return (factorId: response.id, uri: totp.uri, secret: totp.secret);
  });

  @override
  Future<void> verify(String code, {String? factorId}) => _guard(() async {
    var id = factorId;
    if (id == null) {
      final factors = await _mfa.listFactors().timeout(_timeout);
      if (factors.totp.isEmpty) throw MfaFailure.notEnrolled;
      id = factors.totp.first.id;
    }
    await _mfa
        .challengeAndVerify(factorId: id, code: code.trim())
        .timeout(_timeout);
  });

  @override
  Future<List<String>> generateRecoveryCodes() => _guard(() async {
    final codes = await _client
        .rpc<List<dynamic>>('admin_generate_recovery_codes')
        .timeout(_timeout);
    return [for (final code in codes) code as String];
  });

  @override
  Future<bool> useRecoveryCode(String code) => _guard(() async {
    final ok = await _client
        .rpc<bool>('admin_use_recovery_code', params: {'p_code': code})
        .timeout(_timeout);
    // Facteurs retirés côté serveur : session relue.
    if (ok) await _client.auth.refreshSession().timeout(_timeout);
    return ok;
  });

  @override
  Future<void> disable() => _guard(() async {
    final factors = await _mfa.listFactors().timeout(_timeout);
    for (final factor in factors.all) {
      await _mfa.unenroll(factor.id).timeout(_timeout);
    }
    await _client.auth.refreshSession().timeout(_timeout);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapMfaError(error);
    }
  }
}

MfaFailure mapMfaError(Object error) {
  if (error is MfaFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return MfaFailure.network;
  }
  if (error is supabase.AuthException) {
    return switch (error.code) {
      'mfa_verification_failed' ||
      'mfa_verification_rejected' ||
      'mfa_challenge_expired' => MfaFailure.invalidCode,
      _ => MfaFailure.unknown,
    };
  }
  if (error is supabase.PostgrestException) {
    return switch (error.message) {
      'recovery_rate_limited' => MfaFailure.rateLimited,
      'mfa_not_enrolled' => MfaFailure.notEnrolled,
      _ => MfaFailure.unknown,
    };
  }
  return MfaFailure.unknown;
}
