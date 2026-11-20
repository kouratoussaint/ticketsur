import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/journal/domain/journal.dart';

class SupabaseJournalRepository implements JournalRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<List<JournalEntry>> entries(
    String organizationId, {
    JournalFilter filter = JournalFilter.all,
    int offset = 0,
    int limit = 50,
  }) async {
    final rows = await _client
        .rpc<List<dynamic>>(
          'organization_audit_logs',
          params: {
            'p_organization_id': organizationId,
            'p_prefixes': filter.prefixes.isEmpty ? null : filter.prefixes,
            'p_limit': limit,
            'p_offset': offset,
          },
        )
        .timeout(const Duration(seconds: 20));
    return [
      for (final row in rows)
        JournalEntry.fromJson(Map<String, Object?>.from(row as Map)),
    ];
  }
}
