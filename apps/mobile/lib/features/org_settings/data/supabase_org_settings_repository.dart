import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/org_settings/domain/org_settings.dart';

/// [OrgSettingsRepository] adossé à la migration 4600.
class SupabaseOrgSettingsRepository implements OrgSettingsRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  @override
  Future<OrgSettings> read(String organizationId) async {
    try {
      final json = await _client
          .rpc<Map<String, dynamic>>(
            'organization_settings',
            params: {'p_organization_id': organizationId},
          )
          .timeout(_timeout);
      return OrgSettings.fromJson(json);
    } on Object catch (error) {
      throw mapOrgSettingsError(error);
    }
  }

  @override
  Future<OrgSettings> save(String organizationId, OrgSettings settings) async {
    try {
      final json = await _client
          .rpc<Map<String, dynamic>>(
            'update_organization_settings',
            params: {
              'p_organization_id': organizationId,
              'p_ticket_message': settings.ticketMessage,
              'p_invitation_message': settings.invitationMessage,
              'p_default_timezone': settings.defaultTimezone,
              'p_default_city': settings.defaultCity,
              'p_default_kind': settings.defaultKind?.wireName,
              'p_default_categories': [
                for (final category in settings.defaultCategories)
                  category.toJson(),
              ],
              'p_default_checkpoints': settings.defaultCheckpoints,
            },
          )
          .timeout(_timeout);
      return OrgSettings.fromJson(json);
    } on Object catch (error) {
      throw mapOrgSettingsError(error);
    }
  }

  @override
  Future<AppliedDefaults> applyToEvent(String eventId) async {
    try {
      final json = await _client
          .rpc<Map<String, dynamic>>(
            'apply_event_defaults',
            params: {'p_event_id': eventId},
          )
          .timeout(_timeout);
      return (
        categories: (json['categories'] as num).toInt(),
        checkpoints: (json['checkpoints'] as num).toInt(),
      );
    } on Object catch (error) {
      throw mapOrgSettingsError(error);
    }
  }
}

OrgSettingsFailure mapOrgSettingsError(Object error) {
  if (error is OrgSettingsFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return OrgSettingsFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return switch (error.message) {
      'organization_not_found' ||
      'event_not_found' ||
      'event_locked' => OrgSettingsFailure.forbidden,
      'settings_message_invalid' => OrgSettingsFailure.message,
      'settings_timezone_invalid' => OrgSettingsFailure.timezone,
      'settings_city_invalid' => OrgSettingsFailure.city,
      'settings_kind_invalid' ||
      'settings_categories_invalid' => OrgSettingsFailure.categories,
      'settings_checkpoints_invalid' => OrgSettingsFailure.checkpoints,
      _ => OrgSettingsFailure.unknown,
    };
  }
  return OrgSettingsFailure.unknown;
}
