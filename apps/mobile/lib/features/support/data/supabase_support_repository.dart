import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/notifications/data/supabase_push_repository.dart';
import 'package:ticketsur/features/support/domain/support.dart';

/// [SupportRepository] adossé aux fonctions de la migration 2300.
class SupabaseSupportRepository implements SupportRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  Future<List<Map<String, Object?>>> _rows(
    String function, [
    Map<String, Object?>? params,
  ]) async {
    final rows = await _client
        .rpc<List<dynamic>>(function, params: params)
        .timeout(_timeout);
    return [for (final row in rows) Map<String, Object?>.from(row as Map)];
  }

  @override
  Future<List<SupportRequest>> myRequests() => _guard(() async {
    final rows = await _rows('my_support_requests');
    return [for (final row in rows) SupportRequest.fromJson(row)];
  });

  @override
  Future<String> create({
    required String subject,
    required SupportCategory category,
    required String body,
    String? organizationId,
  }) => _guard(
    () => _client
        .rpc<String>(
          'create_support_request',
          params: {
            'p_subject': subject.trim(),
            'p_category': category.wireName,
            'p_body': body.trim(),
            'p_organization_id': organizationId,
          },
        )
        .timeout(_timeout),
  );

  @override
  Future<List<SupportMessage>> thread(String requestId) => _guard(() async {
    final rows = await _rows('support_thread', {'p_request_id': requestId});
    return [for (final row in rows) SupportMessage.fromJson(row)];
  });

  @override
  Future<SupportStatus> reply(String requestId, String body) =>
      _guard(() async {
        final status = await _client
            .rpc<String>(
              'reply_support_request',
              params: {'p_request_id': requestId, 'p_body': body.trim()},
            )
            .timeout(_timeout);
        // Réponse de l'équipe : la notification part tout de suite.
        unawaited(flushPushOutbox(_client));
        return SupportStatus.fromWire(status);
      });

  @override
  Future<void> close(String requestId) => _guard(() async {
    await _client
        .rpc<Object?>(
          'close_support_request',
          params: {'p_request_id': requestId},
        )
        .timeout(_timeout);
  });

  @override
  Future<List<SupportRequest>> adminRequests({
    SupportStatus? status,
    String search = '',
    int offset = 0,
    int limit = 30,
  }) => _guard(() async {
    final rows = await _rows('admin_support_requests', {
      'p_status': status?.wireName,
      'p_search': search.trim().isEmpty ? null : search.trim(),
      'p_limit': limit,
      'p_offset': offset,
    });
    return [for (final row in rows) SupportRequest.fromJson(row)];
  });

  @override
  Future<SupportCounts> adminCounts() => _guard(() async {
    final json = await _client
        .rpc<Map<String, dynamic>>('admin_support_counts')
        .timeout(_timeout);
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return (open: n('open'), unread: n('unread'), answered: n('answered'));
  });

  @override
  Future<List<SupportTemplate>> templates() => _guard(() async {
    final rows = await _client
        .rpc<List<dynamic>>('admin_support_templates')
        .timeout(_timeout);
    return [
      for (final row in rows)
        SupportTemplate.fromJson(row as Map<String, dynamic>),
    ];
  });

  @override
  Future<String> saveTemplate({
    required String title,
    required String body,
    String? id,
  }) => _guard(
    () => _client
        .rpc<String>(
          'admin_save_support_template',
          params: {
            'p_template_id': id,
            'p_title': title.trim(),
            'p_body': body.trim(),
          },
        )
        .timeout(_timeout),
  );

  @override
  Future<void> deleteTemplate(String id) => _guard(() async {
    await _client
        .rpc<Object?>(
          'admin_delete_support_template',
          params: {'p_template_id': id},
        )
        .timeout(_timeout);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapSupportError(error);
    }
  }
}

/// Traduit une erreur réseau ou PostgREST en [SupportFailure].
SupportFailure mapSupportError(Object error) {
  if (error is SupportFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return SupportFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return switch (error.message) {
      'support_subject_invalid' ||
      'support_body_invalid' ||
      'support_category_invalid' ||
      'support_template_title_invalid' ||
      'support_template_body_invalid' => SupportFailure.invalid,
      'support_limit' ||
      'support_rate_limited' ||
      'support_templates_limit' => SupportFailure.limit,
      'support_not_found' ||
      'support_template_not_found' ||
      'forbidden' => SupportFailure.notFound,
      _ => SupportFailure.unknown,
    };
  }
  return SupportFailure.unknown;
}
