import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/notifications/data/supabase_push_repository.dart'
    show flushPushOutbox;

/// [AdminAccountsRepository] : fonctions SQL de la migration 4900 et
/// fonction serveur `admin-accounts` (création, mot de passe, e-mail).
class SupabaseAdminAccountsRepository implements AdminAccountsRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  Future<T> _rpc<T>(String name, [Map<String, dynamic>? params]) =>
      _guard(() => _client.rpc<T>(name, params: params).timeout(_timeout));

  /// Appel de la fonction serveur ; renvoie sa réponse `{ ok: true, … }`.
  Future<Map<String, dynamic>> _function(Map<String, dynamic> body) =>
      _guard(() async {
        final response = await _client.functions
            .invoke('admin-accounts', body: body)
            .timeout(const Duration(seconds: 40));
        final data = response.data;
        if (data is Map<String, dynamic> && data['ok'] == true) return data;
        throw AdminAccountsFailure.fromCode(
          data is Map<String, dynamic> ? data['code'] as String? : null,
        );
      });

  void _flushIf(bool? notify) {
    // Notification éventuelle : la file part tout de suite (sinon à la
    // tâche des 5 minutes).
    if (notify ?? true) unawaited(flushPushOutbox(_client));
  }

  @override
  Future<AdminMe> me() async =>
      AdminMe.fromJson(await _rpc<Map<String, dynamic>>('admin_me'));

  @override
  Future<AdminMe> saveSettings({
    bool? notifyUsers,
    bool? adminIssueTickets,
  }) async {
    await _rpc<Object?>('admin_save_console_settings', {
      'p_notify_users': notifyUsers,
      'p_admin_issue_tickets': adminIssueTickets,
    });
    return await me();
  }

  @override
  Future<AdminMe> saveDoubleScanSeconds(int seconds) async => AdminMe.fromJson(
    await _rpc<Map<String, dynamic>>('admin_save_double_scan_seconds', {
      'p_seconds': seconds,
    }),
  );

  @override
  Future<AccountDetail> detail(String userId) async => AccountDetail.fromJson(
    await _rpc<Map<String, dynamic>>('admin_account_detail', {
      'p_user_id': userId,
    }),
  );

  @override
  Future<List<PlatformAdmin>> platformAdmins() async {
    final rows = await _rpc<List<dynamic>>('admin_platform_admins');
    return [
      for (final row in rows)
        PlatformAdmin.fromJson(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<CreatedAccount> create({
    required String email,
    required String displayName,
    required String reason,
    String? phone,
  }) async {
    final data = await _function({
      'action': 'create',
      'email': email.trim(),
      'display_name': displayName.trim(),
      'phone': phone,
      'reason': reason.trim(),
    });
    return (
      userId: data['user_id']! as String,
      password: data['password']! as String,
    );
  }

  @override
  Future<void> update(
    String userId, {
    required String displayName,
    required String? phone,
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_update_account', {
      'p_user_id': userId,
      'p_display_name': displayName,
      'p_phone': phone,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flushIf(notify);
  }

  @override
  Future<String> resetPassword(
    String userId, {
    required String reason,
    bool? notify,
  }) async {
    final data = await _function({
      'action': 'password',
      'user_id': userId,
      'reason': reason.trim(),
      'notify': notify,
    });
    _flushIf(notify);
    return data['password']! as String;
  }

  @override
  Future<void> changeEmail(
    String userId, {
    required String email,
    required String reason,
    bool? notify,
  }) async {
    await _function({
      'action': 'email',
      'user_id': userId,
      'email': email.trim(),
      'reason': reason.trim(),
      'notify': notify,
    });
    _flushIf(notify);
  }

  @override
  Future<int> signOut(
    String userId, {
    required String reason,
    bool? notify,
  }) async {
    final count = await _rpc<int>('admin_sign_out_account', {
      'p_user_id': userId,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flushIf(notify);
    return count;
  }

  @override
  Future<void> cancelDeletion(
    String userId, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_cancel_account_deletion', {
      'p_user_id': userId,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flushIf(notify);
  }

  @override
  Future<int> deleteNow(
    String userId, {
    required String confirmEmail,
    required String reason,
  }) => _rpc<int>('admin_delete_account_now', {
    'p_user_id': userId,
    'p_confirm_email': confirmEmail,
    'p_reason': reason,
  });

  @override
  Future<AdminRole?> setRole(
    String userId,
    AdminRole? role, {
    required String reason,
  }) async => AdminRole.fromWire(
    await _rpc<String?>('admin_set_admin_role', {
      'p_user_id': userId,
      'p_role': role?.wireName,
      'p_reason': reason,
    }),
  );

  @override
  Future<void> removeMfa(String userId, {required String reason}) =>
      _rpc<Object?>('admin_remove_account_mfa', {
        'p_user_id': userId,
        'p_reason': reason,
      });

  @override
  Future<bool> mustChangePassword() async {
    final json = await _rpc<Map<String, dynamic>?>('my_account_flags');
    return json?['must_change_password'] == true;
  }

  @override
  Future<void> clearMustChangePassword() =>
      _rpc<Object?>('clear_must_change_password');

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapAdminAccountsError(error);
    }
  }
}

AdminAccountsFailure mapAdminAccountsError(Object error) {
  if (error is AdminAccountsFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return AdminAccountsFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return AdminAccountsFailure.fromCode(error.message);
  }
  if (error is supabase.FunctionException) {
    final details = error.details;
    return AdminAccountsFailure.fromCode(
      details is Map ? details['code'] as String? : null,
    );
  }
  return AdminAccountsFailure.unknown;
}
