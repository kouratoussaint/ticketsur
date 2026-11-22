import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/catalog/domain/catalog.dart';

/// [CatalogRepository] adossé à `public_events` et `public_event`
/// (migration 1800), ouvertes sans compte.
class SupabaseCatalogRepository implements CatalogRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  String _cover(String path) =>
      _client.storage.from('event-covers').getPublicUrl(path);

  String _logo(String path) =>
      _client.storage.from('org-logos').getPublicUrl(path);

  @override
  Future<List<PublicEventSummary>> search(
    CatalogQuery query, {
    required DateTime now,
    int offset = 0,
    int limit = 30,
  }) => _guard(() async {
    final range = query.period.range(now);
    final rows = await _client
        .rpc<List<dynamic>>(
          'public_events',
          params: {
            'p_search': query.search.trim().isEmpty
                ? null
                : query.search.trim(),
            'p_kinds': query.kinds.isEmpty
                ? null
                : [for (final kind in query.kinds) kind.wireName],
            'p_city': query.city,
            'p_from': range.from?.toIso8601String(),
            'p_to': range.to?.toIso8601String(),
            'p_free_only': query.freeOnly,
            'p_limit': limit,
            'p_offset': offset,
          },
        )
        .timeout(const Duration(seconds: 20));
    return [
      for (final row in rows)
        PublicEventSummary.fromJson(
          Map<String, Object?>.from(row as Map),
          coverUrlOf: _cover,
        ),
    ];
  });

  @override
  Future<PublicEventDetail> event(String id) => _guard(() async {
    final json = await _client
        .rpc<Map<String, dynamic>>('public_event', params: {'p_event_id': id})
        .timeout(const Duration(seconds: 20));
    return PublicEventDetail.fromJson(
      json,
      coverUrlOf: _cover,
      logoUrlOf: _logo,
    );
  });

  @override
  Future<List<PublicEventSummary>> featured() => _guard(() async {
    final rows = await _client
        .rpc<List<dynamic>>('public_featured_events')
        .timeout(const Duration(seconds: 20));
    return [
      for (final row in rows)
        PublicEventSummary.fromJson(
          Map<String, Object?>.from(row as Map),
          coverUrlOf: _cover,
        ),
    ];
  });

  @override
  Future<PublicOrganization> organization(String id) => _guard(() async {
    final json = await _client
        .rpc<Map<String, dynamic>>(
          'public_organization',
          params: {'p_organization_id': id},
        )
        .timeout(const Duration(seconds: 20));
    return PublicOrganization.fromJson(
      json,
      coverUrlOf: _cover,
      logoUrlOf: _logo,
    );
  });

  @override
  Future<({bool following, int followers})> follow(
    String organizationId, {
    required bool follow,
  }) => _guard(() async {
    final json = await _client
        .rpc<Map<String, dynamic>>(
          'follow_organization',
          params: {'p_organization_id': organizationId, 'p_follow': follow},
        )
        .timeout(const Duration(seconds: 20));
    return (
      following: json['following'] == true,
      followers: (json['followers'] as num?)?.toInt() ?? 0,
    );
  });

  @override
  Future<List<FollowedOrganization>> followed() => _guard(() async {
    final rows = await _client
        .rpc<List<dynamic>>('my_followed_organizations')
        .timeout(const Duration(seconds: 20));
    return [
      for (final row in rows)
        followedFromJson(
          Map<String, Object?>.from(row as Map),
          logoUrlOf: _logo,
        ),
    ];
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapCatalogError(error);
    }
  }
}

/// Traduit une erreur réseau ou PostgREST en [CatalogFailure].
CatalogFailure mapCatalogError(Object error) {
  if (error is CatalogFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return CatalogFailure.network;
  }
  if (error is supabase.PostgrestException &&
      (error.message == 'event_not_found' ||
          error.message == 'organization_not_found' ||
          error.code == '42501' ||
          error.code == 'P0002')) {
    return CatalogFailure.notFound;
  }
  if (error is supabase.PostgrestException && error.message == 'follow_limit') {
    return CatalogFailure.followLimit;
  }
  return CatalogFailure.unknown;
}
