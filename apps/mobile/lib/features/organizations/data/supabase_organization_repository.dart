import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:math' show Random;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;
import 'package:ticketsur/features/organizations/domain/organization.dart';

/// [OrganizationRepository] adossé aux fonctions `my_organizations`,
/// `create_organization` (migration 0500), `update_organization`,
/// `set_organization_logo`, `leave_organization` (migration 1200) et au
/// bucket `org-logos`.
class SupabaseOrganizationRepository implements OrganizationRepository {
  /// Crée le dépôt à partir du client Supabase.
  new(this._client, {Random? random}) : _random = random ?? Random.secure();

  final supabase.SupabaseClient _client;
  final Random _random;

  /// Bucket des logos.
  static const logoBucket = 'org-logos';

  String _logoUrl(String path) =>
      _client.storage.from(logoBucket).getPublicUrl(path);

  Organization _read(Map<String, Object?> json) =>
      Organization.fromJson(json, logoUrlOf: _logoUrl);

  @override
  Future<List<Organization>> myOrganizations() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('my_organizations');
      return [
        for (final row in rows) _read(Map<String, Object?>.from(row as Map)),
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
            ? _read(Map<String, Object?>.from(organization))
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
      return _read(json);
    } on Object catch (error) {
      throw mapOrganizationError(error);
    }
  }

  @override
  Future<Organization> update(
    String organizationId,
    OrganizationDraft draft,
  ) async {
    try {
      await _client.rpc<Map<String, dynamic>>(
        'update_organization',
        params: {'p_organization_id': organizationId, ...draft.toParams()},
      );
      final json = await _client.rpc<Map<String, dynamic>>(
        'set_organization_public_phone',
        params: {
          'p_organization_id': organizationId,
          'p_phone': draft.publicPhoneParam,
        },
      );
      return _read(json);
    } on Object catch (error) {
      throw mapOrganizationError(error);
    }
  }

  @override
  Future<Organization> setLogo(
    Organization organization,
    CoverImage image,
  ) async {
    try {
      final name = List.generate(
        16,
        (_) => _random.nextInt(16).toRadixString(16),
      ).join();
      final path = '${organization.id}/$name.${image.extension}';
      final bucket = _client.storage.from(logoBucket);
      await bucket.uploadBinary(
        path,
        image.bytes,
        fileOptions: supabase.FileOptions(
          contentType: image.mimeType,
          cacheControl: '31536000',
        ),
      );
      final Map<String, dynamic> json;
      try {
        json = await _client.rpc<Map<String, dynamic>>(
          'set_organization_logo',
          params: {'p_organization_id': organization.id, 'p_path': path},
        );
      } on Object {
        await _removeQuietly(path);
        rethrow;
      }
      if (organization.logoPath case final old? when old != path) {
        await _removeQuietly(old);
      }
      return _read(json);
    } on Object catch (error) {
      throw mapOrganizationError(error);
    }
  }

  @override
  Future<void> leave(String organizationId) async {
    try {
      await _client.rpc<void>(
        'leave_organization',
        params: {'p_organization_id': organizationId},
      );
    } on Object catch (error) {
      throw mapOrganizationError(error);
    }
  }

  Future<void> _removeQuietly(String path) async {
    try {
      await _client.storage.from(logoBucket).remove([path]);
    } on Object {
      // Un fichier orphelin ne gêne personne.
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
  if (error is supabase.StorageException) {
    return OrganizationFailure.logoInvalid;
  }
  if (error is supabase.PostgrestException) {
    switch (error.message) {
      case 'org_not_found':
        return OrganizationFailure.notFound;
      case 'org_name_invalid':
        return OrganizationFailure.invalidName;
      case 'org_phone_invalid':
        return OrganizationFailure.phoneInvalid;
      case 'org_email_invalid':
        return OrganizationFailure.emailInvalid;
      case 'org_city_invalid':
        return OrganizationFailure.cityInvalid;
      case 'org_logo_invalid':
        return OrganizationFailure.logoInvalid;
      case 'org_last_owner':
        return OrganizationFailure.lastOwner;
    }
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
