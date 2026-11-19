import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/announcements/domain/announcement.dart';

/// [AnnouncementRepository] adossé aux fonctions de la migration 2300.
class SupabaseAnnouncementRepository implements AnnouncementRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  @override
  Future<List<Announcement>> mine() => _guard(() async {
    final rows = await _client
        .rpc<List<dynamic>>('my_announcements')
        .timeout(_timeout);
    return [
      for (final row in rows)
        Announcement.fromJson(Map<String, Object?>.from(row as Map)),
    ];
  });

  @override
  Future<List<Announcement>> all({int offset = 0, int limit = 50}) =>
      _guard(() async {
        final rows = await _client
            .rpc<List<dynamic>>(
              'admin_announcements',
              params: {'p_limit': limit, 'p_offset': offset},
            )
            .timeout(_timeout);
        return [
          for (final row in rows)
            Announcement.fromJson(Map<String, Object?>.from(row as Map)),
        ];
      });

  @override
  Future<String> publish({
    required String title,
    required String body,
    required Set<AnnouncementAudience> audiences,
    required bool important,
    DateTime? endsAt,
  }) => _guard(
    () => _client
        .rpc<String>(
          'admin_publish_announcement',
          params: {
            'p_title': title.trim(),
            'p_body': body.trim(),
            'p_audiences': [for (final a in audiences) a.wireName],
            'p_level': important ? 'important' : 'info',
            'p_ends_at': endsAt?.toUtc().toIso8601String(),
          },
        )
        .timeout(_timeout),
  );

  @override
  Future<void> archive(String id) => _guard(() async {
    await _client
        .rpc<Object?>(
          'admin_archive_announcement',
          params: {'p_announcement_id': id},
        )
        .timeout(_timeout);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      if (error is SocketException ||
          error is TimeoutException ||
          error is supabase.AuthRetryableFetchException) {
        throw AnnouncementFailure.network;
      }
      if (error is supabase.PostgrestException && error.code == '22023') {
        throw AnnouncementFailure.invalid;
      }
      throw AnnouncementFailure.unknown;
    }
  }
}
