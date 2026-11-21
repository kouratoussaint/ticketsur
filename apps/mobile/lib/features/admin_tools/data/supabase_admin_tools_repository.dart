import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/admin_accounts/data/supabase_admin_accounts_repository.dart'
    show mapAdminAccountsError;
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/features/notifications/data/supabase_push_repository.dart'
    show flushPushOutbox;

/// [AdminToolsRepository] : fonctions SQL de la migration 5200.
class SupabaseAdminToolsRepository implements AdminToolsRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 30);

  Future<T> _rpc<T>(String name, Map<String, dynamic> params) async {
    try {
      return await _client.rpc<T>(name, params: params).timeout(_timeout);
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
}
