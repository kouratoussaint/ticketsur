import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/admin/domain/admin.dart';

/// [AdminRepository] adossé aux fonctions `admin_*` (migration 1900).
class SupabaseAdminRepository implements AdminRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  String _cover(String path) =>
      _client.storage.from('event-covers').getPublicUrl(path);

  Future<List<Map<String, Object?>>> _rows(
    String function,
    Map<String, Object?> params,
  ) async {
    final rows = await _client
        .rpc<List<dynamic>>(function, params: params)
        .timeout(_timeout);
    return [for (final row in rows) Map<String, Object?>.from(row as Map)];
  }

  @override
  Future<bool> isPlatformAdmin() => _guard(
    () async =>
        await _client.rpc<bool?>('is_platform_admin').timeout(_timeout) ??
        false,
  );

  @override
  Future<AdminOverview> overview() => _guard(() async {
    final json = await _client
        .rpc<Map<String, dynamic>>('admin_overview')
        .timeout(_timeout);
    return AdminOverview.fromJson(json);
  });

  @override
  Future<List<AdminOrganization>> organizations({
    String search = '',
    bool disabledOnly = false,
    int offset = 0,
    int limit = 30,
  }) => _guard(() async {
    final rows = await _rows('admin_organizations', {
      'p_search': search.trim().isEmpty ? null : search.trim(),
      'p_status': disabledOnly ? 'disabled' : null,
      'p_limit': limit,
      'p_offset': offset,
    });
    return [for (final row in rows) AdminOrganization.fromJson(row)];
  });

  @override
  Future<void> setOrganizationActive(
    String organizationId, {
    required bool active,
    String? reason,
  }) => _guard(() async {
    await _client
        .rpc<Object?>(
          'admin_set_organization_status',
          params: {
            'p_organization_id': organizationId,
            'p_status': active ? 'active' : 'disabled',
            'p_reason': reason,
          },
        )
        .timeout(_timeout);
  });

  @override
  Future<List<AdminPublicEvent>> publicEvents({
    String search = '',
    bool blockedOnly = false,
    int offset = 0,
    int limit = 30,
  }) => _guard(() async {
    final rows = await _rows('admin_public_events', {
      'p_search': search.trim().isEmpty ? null : search.trim(),
      'p_blocked_only': blockedOnly,
      'p_limit': limit,
      'p_offset': offset,
    });
    return [
      for (final row in rows)
        AdminPublicEvent.fromJson(row, coverUrlOf: _cover),
    ];
  });

  @override
  Future<void> setEventBlocked(
    String eventId, {
    required bool blocked,
    String? reason,
  }) => _guard(() async {
    await _client
        .rpc<Object?>(
          'admin_set_event_blocked',
          params: {
            'p_event_id': eventId,
            'p_blocked': blocked,
            'p_reason': reason,
          },
        )
        .timeout(_timeout);
  });

  @override
  Future<List<AuditEntry>> auditLogs({
    AuditFilter filter = AuditFilter.all,
    int offset = 0,
    int limit = 50,
  }) => _guard(() async {
    final rows = await _rows('admin_audit_logs', {
      'p_action_prefix': filter.prefix,
      'p_limit': limit,
      'p_offset': offset,
    });
    return [for (final row in rows) AuditEntry.fromJson(row)];
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapAdminError(error);
    }
  }
}

/// Traduit une erreur réseau ou PostgREST en [AdminFailure].
AdminFailure mapAdminError(Object error) {
  if (error is AdminFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return AdminFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return switch (error.message) {
      'forbidden' => AdminFailure.forbidden,
      'reason_required' => AdminFailure.reasonRequired,
      'organization_not_found' || 'event_not_found' => AdminFailure.notFound,
      _ when error.code == '42501' => AdminFailure.forbidden,
      _ => AdminFailure.unknown,
    };
  }
  return AdminFailure.unknown;
}
