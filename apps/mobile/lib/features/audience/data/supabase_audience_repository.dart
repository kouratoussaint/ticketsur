import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/audience/domain/audience.dart';

class SupabaseAudienceRepository implements AudienceRepository {
  const new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<void> recordEventView(String eventId, {String? device}) => _guard(
    () => _client
        .rpc<void>(
          'record_event_view',
          params: {'p_event_id': eventId, 'p_device': device},
        )
        .timeout(const Duration(seconds: 20)),
  );

  @override
  Future<AudienceSeries> eventViews(String eventId) => _guard(() async {
    final json = await _client
        .rpc<Map<String, dynamic>>(
          'event_page_views',
          params: {'p_event_id': eventId},
        )
        .timeout(const Duration(seconds: 20));
    return AudienceSeries.fromJson(
      json,
      totalKey: 'total',
      recentKey: 'last_7',
    );
  });

  @override
  Future<AudienceSeries> followerStats(String organizationId) =>
      _guard(() async {
        final json = await _client
            .rpc<Map<String, dynamic>>(
              'organization_followers_stats',
              params: {'p_organization_id': organizationId},
            )
            .timeout(const Duration(seconds: 20));
        return AudienceSeries.fromJson(
          json,
          totalKey: 'followers',
          recentKey: 'new_30d',
        );
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapAudienceError(error);
    }
  }
}

AudienceFailure mapAudienceError(Object error) {
  if (error is AudienceFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return AudienceFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return switch (error.message) {
      'event_not_found' || 'organization_not_found' => AudienceFailure.notFound,
      _ => AudienceFailure.unknown,
    };
  }
  return AudienceFailure.unknown;
}
