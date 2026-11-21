import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

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
  Future<List<DailyStat>> dailyStats({int days = 30}) => _guard(() async {
    final rows = await _client
        .rpc<List<dynamic>>('admin_daily_stats', params: {'p_days': days})
        .timeout(_timeout);
    return [
      for (final row in rows) DailyStat.fromJson(row as Map<String, dynamic>),
    ];
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
  Future<List<AdminAccount>> accounts({
    String search = '',
    AccountFilter filter = AccountFilter.all,
    int offset = 0,
    int limit = 30,
  }) => _guard(() async {
    final rows = await _rows('admin_accounts', {
      'p_search': search.trim().isEmpty ? null : search.trim(),
      'p_filter': filter.wireName,
      'p_limit': limit,
      'p_offset': offset,
    });
    return [for (final row in rows) AdminAccount.fromJson(row)];
  });

  @override
  Future<void> setAccountActive(
    String userId, {
    required bool active,
    String? reason,
  }) => _guard(() async {
    await _client
        .rpc<Object?>(
          'admin_set_account_status',
          params: {
            'p_user_id': userId,
            'p_status': active ? 'active' : 'disabled',
            'p_reason': reason,
          },
        )
        .timeout(_timeout);
  });

  @override
  Future<int> purgeAccount(String userId) => _guard(() async {
    final count = await _client
        .rpc<int>('admin_purge_account', params: {'p_user_id': userId})
        .timeout(_timeout);
    return count;
  });

  @override
  Future<({int accounts, int structures})> purgeDueAccounts() =>
      _guard(() async {
        final json = await _client
            .rpc<Map<String, dynamic>>('admin_purge_due_accounts')
            .timeout(const Duration(seconds: 60));
        return (
          accounts: (json['accounts'] as num).toInt(),
          structures: (json['structures_suspended'] as num).toInt(),
        );
      });

  @override
  Future<List<AdminAccountStructure>> accountStructures(String userId) =>
      _guard(() async {
        final rows = await _rows('admin_account_structures', {
          'p_user_id': userId,
        });
        return [for (final row in rows) AdminAccountStructure.fromJson(row)];
      });

  @override
  Future<void> assignOrganization(
    String userId, {
    required String organizationId,
    required MemberRole role,
    required String reason,
  }) => _guard(() async {
    await _client
        .rpc<Object?>(
          'admin_assign_organization',
          params: {
            'p_user_id': userId,
            'p_organization_id': organizationId,
            'p_role': role.wireName,
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

  @override
  Future<List<FeaturedEntry>> featuredEvents() => _guard(() async {
    final rows = await _client
        .rpc<List<dynamic>>('admin_featured_events')
        .timeout(_timeout);
    return [
      for (final row in rows)
        FeaturedEntry.fromJson(
          Map<String, Object?>.from(row as Map),
          coverUrlOf: _cover,
        ),
    ];
  });

  Future<void> _call(String function, Map<String, Object?> params) =>
      _guard(() async {
        await _client.rpc<Object?>(function, params: params).timeout(_timeout);
      });

  @override
  Future<void> addFeatured(
    String eventId, {
    DateTime? startsAt,
    DateTime? endsAt,
  }) => _call('admin_add_featured_event', {
    'p_event_id': eventId,
    'p_starts_at': startsAt?.toUtc().toIso8601String(),
    'p_ends_at': endsAt?.toUtc().toIso8601String(),
  });

  @override
  Future<void> setFeaturedPeriod(
    String id,
    DateTime startsAt,
    DateTime endsAt,
  ) => _call('admin_set_featured_period', {
    'p_id': id,
    'p_starts_at': startsAt.toUtc().toIso8601String(),
    'p_ends_at': endsAt.toUtc().toIso8601String(),
  });

  @override
  Future<void> moveFeatured(String id, int direction) => _call(
    'admin_move_featured_event',
    {'p_id': id, 'p_direction': direction},
  );

  @override
  Future<void> removeFeatured(String id) =>
      _call('admin_remove_featured_event', {'p_id': id});

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
      'mfa_required' => AdminFailure.mfaRequired,
      'reason_required' => AdminFailure.reasonRequired,
      'organization_not_found' ||
      'event_not_found' ||
      'account_not_found' => AdminFailure.notFound,
      'self_forbidden' ||
      'account_deleted' ||
      'deletion_not_due' ||
      'account_is_admin' => AdminFailure.notAllowed,
      'featured_event_invalid' ||
      'featured_period_invalid' => AdminFailure.featuredInvalid,
      'featured_exists' => AdminFailure.featuredExists,
      'account_inactive' => AdminFailure.accountInactive,
      'already_owner' => AdminFailure.alreadyOwner,
      'owner_role_locked' => AdminFailure.ownerLocked,
      'billing_limit_structures' => AdminFailure.structureLimit,
      'featured_not_found' => AdminFailure.notFound,
      _ when error.code == '42501' => AdminFailure.forbidden,
      _ => AdminFailure.unknown,
    };
  }
  return AdminFailure.unknown;
}
