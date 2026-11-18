import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/organizations/domain/organization.dart';

/// [OrganizationRepository] adossé aux fonctions `my_organizations` et
/// `create_organization` (migration 0500).
class SupabaseOrganizationRepository implements OrganizationRepository {
  /// Crée le dépôt à partir du client Supabase.
  new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<List<Organization>> myOrganizations() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('my_organizations');
      return [
        for (final row in rows)
          Organization.fromJson(Map<String, Object?>.from(row as Map)),
      ];
    } on Object catch (error) {
      throw mapOrganizationError(error);
    }
  }

  @override
  Future<JoinOutcome> join(String code) async {
    try {
      final json = await _client.rpc<Map<String, dynamic>>(
        'accept_invitation',
        params: {'p_code': code.trim()},
      );
      final result = JoinResult.fromWire(json['result']);
      final organization = json['organization'];
      return JoinOutcome(
        result,
        organization is Map
            ? Organization.fromJson(Map<String, Object?>.from(organization))
            : null,
      );
    } on Object catch (error) {
      throw mapOrganizationError(error);
    }
  }

  @override
  Future<Organization> create(String name) async {
    try {
      final json = await _client.rpc<Map<String, dynamic>>(
        'create_organization',
        params: {'p_name': name.trim()},
      );
      return Organization.fromJson(json);
    } on Object catch (error) {
      throw mapOrganizationError(error);
    }
  }
}

/// Traduit une erreur PostgREST ou réseau en [OrganizationFailure].
OrganizationFailure mapOrganizationError(Object error) {
  if (error is OrganizationFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return OrganizationFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return switch (error.code) {
      // invalid_parameter_value
      '22023' => OrganizationFailure.invalidName,
      // configuration_limit_exceeded
      '53400' => OrganizationFailure.limitReached,
      _ => OrganizationFailure.unknown,
    };
  }
  return OrganizationFailure.unknown;
}
