import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/team/domain/team.dart';

/// [TeamRepository] adossé aux fonctions de la migration 0800.
class SupabaseTeamRepository implements TeamRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  Future<List<Map<String, Object?>>> _rows(
    String function,
    Map<String, Object?> params,
  ) async {
    final rows = await _client.rpc<List<dynamic>>(function, params: params);
    return [for (final row in rows) Map<String, Object?>.from(row as Map)];
  }

  @override
  Future<List<TeamMember>> members(String organizationId) => _guard(
    () async => [
      for (final row in await _rows('organization_team', {
        'p_organization_id': organizationId,
      }))
        TeamMember.fromJson(row),
    ],
  );

  @override
  Future<List<Invitation>> invitations(String organizationId) => _guard(
    () async => [
      for (final row in await _rows('organization_invitations_list', {
        'p_organization_id': organizationId,
      }))
        Invitation.fromJson(row),
    ],
  );

  @override
  Future<CreatedInvitation> createInvitation(
    String organizationId,
    MemberRole role, {
    required int validDays,
    required int maxUses,
  }) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'create_invitation',
      params: {
        'p_organization_id': organizationId,
        'p_role': role.wireName,
        'p_valid_days': validDays,
        'p_max_uses': maxUses,
      },
    );
    return CreatedInvitation(
      invitation: Invitation.fromJson(json),
      code: json['code']! as String,
    );
  });

  @override
  Future<void> revokeInvitation(String invitationId) => _guard(
    () => _client.rpc<void>(
      'revoke_invitation',
      params: {'p_invitation_id': invitationId},
    ),
  );

  @override
  Future<void> updateMember(
    String organizationId,
    String userId, {
    required MemberRole role,
    required bool active,
  }) => _guard(
    () => _client.rpc<void>(
      'update_member',
      params: {
        'p_organization_id': organizationId,
        'p_user_id': userId,
        'p_role': role.wireName,
        'p_active': active,
      },
    ),
  );

  @override
  Future<List<Assignment>> eventTeam(String eventId) => _guard(
    () async => [
      for (final row in await _rows('event_team', {'p_event_id': eventId}))
        Assignment.fromJson(row),
    ],
  );

  @override
  Future<void> assign(String eventId, String userId, String? checkpointId) =>
      _guard(
        () => _client.rpc<void>(
          'assign_member',
          params: {
            'p_event_id': eventId,
            'p_user_id': userId,
            'p_checkpoint_id': checkpointId,
          },
        ),
      );

  @override
  Future<void> unassign(String assignmentId) => _guard(
    () => _client.rpc<void>(
      'unassign_member',
      params: {'p_assignment_id': assignmentId},
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapTeamError(error);
    }
  }
}

/// Traduit une erreur PostgREST ou réseau en [TeamFailure].
TeamFailure mapTeamError(Object error) {
  if (error is TeamFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return TeamFailure.network;
  }
  if (error is supabase.PostgrestException) {
    final failure = TeamFailure.fromServerCode(error.message);
    if (failure != TeamFailure.unknown) return failure;
    if (error.code == '42501') return TeamFailure.forbidden;
  }
  return TeamFailure.unknown;
}
