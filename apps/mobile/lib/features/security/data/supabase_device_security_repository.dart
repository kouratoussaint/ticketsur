import 'dart:async';
import 'dart:io' show SocketException;

import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/security/domain/security.dart';

/// [DeviceSecurityRepository] adossé aux fonctions de la migration 4300.
class SupabaseDeviceSecurityRepository implements DeviceSecurityRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  @override
  Future<void> register(DeviceIdentity device) => _guard(() async {
    await _client
        .rpc<Object?>(
          'register_device',
          params: {
            'p_label': device.label,
            'p_platform': device.platform,
            'p_app_build': device.appBuild,
          },
        )
        .timeout(_timeout);
  });

  @override
  Future<List<ConnectedDevice>> devices() => _guard(() async {
    final rows = await _client
        .rpc<List<dynamic>>('my_devices')
        .timeout(_timeout);
    return [
      for (final row in rows)
        ConnectedDevice.fromJson(Map<String, Object?>.from(row as Map)),
    ];
  });

  @override
  Future<void> revoke(String sessionId) => _guard(() async {
    await _client
        .rpc<Object?>('revoke_device', params: {'p_session_id': sessionId})
        .timeout(_timeout);
  });

  @override
  Future<int> revokeOthers() => _guard(() async {
    final count = await _client
        .rpc<int>('revoke_other_devices')
        .timeout(_timeout);
    return count;
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapDeviceError(error);
    }
  }
}

/// Traduit une erreur réseau ou PostgREST en [DeviceFailure].
DeviceFailure mapDeviceError(Object error) {
  if (error is DeviceFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return DeviceFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return switch (error.message) {
      'session_revoked' => DeviceFailure.sessionRevoked,
      'device_current' => DeviceFailure.current,
      'device_not_found' => DeviceFailure.notFound,
      _ => DeviceFailure.unknown,
    };
  }
  return DeviceFailure.unknown;
}

/// Empreinte, visage ou code du téléphone, par `local_auth`.
class LocalAuthBiometricService implements BiometricService {
  const new();

  static final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
