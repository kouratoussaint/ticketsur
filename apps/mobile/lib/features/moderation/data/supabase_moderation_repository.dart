import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/admin/data/supabase_admin_repository.dart';
import 'package:ticketsur/features/moderation/domain/moderation.dart';

class SupabaseModerationRepository implements ModerationRepository {
  const new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<bool> report(
    ReportKind kind,
    String id,
    ReportReason reason, {
    String? comment,
  }) async {
    try {
      final result = await _client
          .rpc<Map<String, dynamic>>(
            'report_content',
            params: {
              'p_kind': kind.name,
              'p_id': id,
              'p_reason': reason.name,
              'p_comment': comment,
            },
          )
          .timeout(const Duration(seconds: 20));
      return result['already'] == true;
    } on Object catch (error) {
      throw mapReportError(error);
    }
  }

  @override
  Future<ReportsPage> reports({
    bool open = true,
    int offset = 0,
    int limit = 30,
  }) => _admin(() async {
    final json = await _client
        .rpc<Map<String, dynamic>>(
          'admin_content_reports',
          params: {'p_open': open, 'p_limit': limit, 'p_offset': offset},
        )
        .timeout(const Duration(seconds: 20));
    return (
      open: (json['open'] as num? ?? 0).toInt(),
      items: [
        for (final row in (json['items'] as List?) ?? const [])
          ReportGroup.fromJson(Map<String, Object?>.from(row as Map)),
      ],
    );
  });

  @override
  Future<int> resolve(
    ReportKind kind,
    String id, {
    required bool remove,
    required String reason,
  }) => _admin(() async {
    final json = await _client
        .rpc<Map<String, dynamic>>(
          'admin_resolve_reports',
          params: {
            'p_kind': kind.name,
            'p_id': id,
            'p_action': remove ? 'remove' : 'dismiss',
            'p_reason': reason,
          },
        )
        .timeout(const Duration(seconds: 20));
    return (json['resolved'] as num? ?? 0).toInt();
  });

  Future<T> _admin<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapAdminError(error);
    }
  }
}

/// Traduit une erreur du signalement en [ReportFailure].
ReportFailure mapReportError(Object error) {
  if (error is ReportFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return ReportFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return switch (error.message) {
      'report_target_not_found' => ReportFailure.notFound,
      'report_rate_limited' => ReportFailure.rateLimited,
      'report_comment_invalid' => ReportFailure.commentTooLong,
      _ => ReportFailure.unknown,
    };
  }
  return ReportFailure.unknown;
}
