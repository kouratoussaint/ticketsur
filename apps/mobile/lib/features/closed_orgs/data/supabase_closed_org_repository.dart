import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/closed_orgs/domain/closed_org.dart';
import 'package:ticketsur/features/events/domain/event.dart';

/// [ClosedOrgRepository] adossé à `my_closed_organizations` et
/// `closed_organization_events` (migration 5400).
class SupabaseClosedOrgRepository implements ClosedOrgRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  String _logo(String path) =>
      _client.storage.from('org-logos').getPublicUrl(path);

  String _cover(String path) =>
      _client.storage.from('event-covers').getPublicUrl(path);

  @override
  Future<List<ClosedOrganization>> list() => _guard(() async {
    final rows = await _client
        .rpc<List<dynamic>>('my_closed_organizations')
        .timeout(const Duration(seconds: 20));
    return [
      for (final row in rows)
        ClosedOrganization.fromJson(
          Map<String, Object?>.from(row as Map),
          logoUrlOf: _logo,
        ),
    ];
  });

  @override
  Future<ClosedOrganizationDetail> detail(String organizationId) =>
      _guard(() async {
        final json = await _client
            .rpc<Map<String, dynamic>>(
              'closed_organization_events',
              params: {'p_organization_id': organizationId},
            )
            .timeout(const Duration(seconds: 20));
        return closedDetailFromJson(json, logoUrlOf: _logo, coverUrlOf: _cover);
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapClosedOrgError(error);
    }
  }
}

/// Lit la réponse de `closed_organization_events`.
ClosedOrganizationDetail closedDetailFromJson(
  Map<String, Object?> json, {
  String Function(String path)? logoUrlOf,
  String Function(String path)? coverUrlOf,
}) => (
  organization: ClosedOrganization.fromJson(
    Map<String, Object?>.from(json['organization']! as Map),
    logoUrlOf: logoUrlOf,
  ),
  events: [
    for (final row in json['events']! as List<Object?>)
      if (Map<String, Object?>.from(row! as Map) case final map)
        (
          event: TicketEvent.fromJson(map, coverUrlOf: coverUrlOf),
          issued: (map['issued'] as num?)?.toInt() ?? 0,
          admitted: (map['admitted'] as num?)?.toInt() ?? 0,
          revoked: (map['revoked'] as num?)?.toInt() ?? 0,
        ),
  ],
);

/// Traduit une erreur PostgREST ou réseau en [ClosedOrgFailure].
ClosedOrgFailure mapClosedOrgError(Object error) {
  if (error is ClosedOrgFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return ClosedOrgFailure.network;
  }
  if (error is supabase.PostgrestException &&
      (error.message == 'organization_not_found' || error.code == 'P0002')) {
    return ClosedOrgFailure.notFound;
  }
  return ClosedOrgFailure.unknown;
}
