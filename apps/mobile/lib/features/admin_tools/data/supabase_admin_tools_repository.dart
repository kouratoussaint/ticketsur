import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/admin_accounts/data/supabase_admin_accounts_repository.dart'
    show mapAdminAccountsError;
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/features/notifications/data/supabase_push_repository.dart'
    show flushPushOutbox;
import 'package:ticketsur/features/platform/domain/platform_status.dart';

/// [AdminToolsRepository] : fonctions SQL de la migration 5200.
class SupabaseAdminToolsRepository implements AdminToolsRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 30);

  Future<T> _rpc<T>(
    String name,
    Map<String, dynamic> params, {
    Duration timeout = _timeout,
  }) async {
    try {
      return await _client.rpc<T>(name, params: params).timeout(timeout);
    } on Object catch (error) {
      throw mapAdminAccountsError(error);
    }
  }

  @override
  Future<GlobalSearchResult> search(String query) async =>
      GlobalSearchResult.fromJson(
        await _rpc<Map<String, dynamic>>('admin_global_search', {
          'p_query': query.trim(),
          'p_limit': 5,
        }),
      );

  @override
  Future<int> sendMessage(
    MessageTarget target, {
    required String title,
    required String body,
    int days = 7,
  }) async {
    final result = await _rpc<Map<String, dynamic>>('admin_send_message', {
      'p_target_kind': target.kind.wireName,
      'p_target_id': target.id,
      'p_title': title.trim(),
      'p_body': body.trim(),
      'p_days': days,
    });
    // Les notifications partent tout de suite.
    unawaited(flushPushOutbox(_client));
    return (result['recipients'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<PlatformStatus> savePlatformStatus({
    required bool maintenance,
    required String message,
    required bool blockWrites,
    required bool signupsOpen,
  }) async => PlatformStatus.fromJson(
    await _rpc<Map<String, dynamic>>('admin_save_platform_status', {
      'p_maintenance': maintenance,
      'p_message': message.trim(),
      'p_block_writes': blockWrites,
      'p_signups_open': signupsOpen,
    }),
  );

  @override
  Future<ConsoleExport> export(ExportKind kind) async => ConsoleExport.fromJson(
    kind,
    await _rpc<Map<String, dynamic>>(
      'admin_export',
      {'p_kind': kind.wireName},
      // Jusqu'à 50 000 lignes.
      timeout: const Duration(seconds: 120),
    ),
  );
}
