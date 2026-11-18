import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/organizations/domain/organization.dart';

/// Membre d'une organisation (S16).
@immutable
final class TeamMember {
  const new({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.active,
    this.email,
  });

  /// Lit une ligne de `organization_team`.
  factory fromJson(Map<String, Object?> json) => TeamMember(
    userId: json['user_id']! as String,
    displayName: json['display_name']! as String,
    email: json['email'] as String?,
    role: MemberRole.fromWire(json['role']),
    active: json['active']! as bool,
  );

  final String userId;
  final String displayName;
  final String? email;
  final MemberRole role;

  /// Un membre inactif ne peut plus rien faire, scans compris (ORG-03).
  final bool active;

  @override
  bool operator ==(Object other) =>
      other is TeamMember &&
      other.userId == userId &&
      other.displayName == displayName &&
      other.email == email &&
      other.role == role &&
      other.active == active;

  @override
  int get hashCode => Object.hash(userId, displayName, email, role, active);
}

/// Invitation encore utilisable (le code n'est plus connu du serveur).
@immutable
final class Invitation {
  const new({
    required this.id,
    required this.role,
    required this.codeHint,
    required this.expiresAt,
    required this.maxUses,
    required this.uses,
  });

  /// Lit une ligne de `organization_invitations_list` ou la réponse de
  /// `create_invitation`.
  factory fromJson(Map<String, Object?> json) => Invitation(
    id: json['id']! as String,
    role: MemberRole.fromWire(json['role']),
    codeHint: json['code_hint']! as String,
    expiresAt: DateTime.parse(json['expires_at']! as String).toUtc(),
    maxUses: (json['max_uses']! as num).toInt(),
    uses: (json['uses'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final MemberRole role;

  /// Quatre derniers caractères du code.
  final String codeHint;
  final DateTime expiresAt;
  final int maxUses;
  final int uses;
}

/// Invitation tout juste créée : seul moment où le code est connu.
@immutable
final class CreatedInvitation {
  const new({required this.invitation, required this.code});

  final Invitation invitation;

  /// Code complet « TSI-XXXX-XXXX-XXXX », à partager tout de suite.
  final String code;
}

/// Affectation d'un membre à un événement (S17).
@immutable
final class Assignment {
  const new({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.memberActive,
    this.email,
    this.role,
    this.checkpointId,
    this.checkpointName,
  });

  /// Lit une ligne de `event_team`.
  factory fromJson(Map<String, Object?> json) => Assignment(
    id: json['id']! as String,
    userId: json['user_id']! as String,
    displayName: json['display_name']! as String,
    email: json['email'] as String?,
    role: json['role'] == null ? null : MemberRole.fromWire(json['role']),
    memberActive: json['member_active'] as bool? ?? false,
    checkpointId: json['checkpoint_id'] as String?,
    checkpointName: json['checkpoint_name'] as String?,
  );

  final String id;
  final String userId;
  final String displayName;
  final String? email;
  final MemberRole? role;
  final bool memberActive;

  /// `null` : toutes les portes de l'événement.
  final String? checkpointId;
  final String? checkpointName;
}

/// Échecs de gestion d'équipe (codes de la migration 0800).
enum TeamFailure implements Exception {
  /// Droits insuffisants ou élément inconnu.
  forbidden,

  /// Rôle ou paramètres d'invitation invalides.
  invalid,

  /// Membre inconnu ou inactif.
  memberNotFound,

  /// Le propriétaire ne peut pas être modifié.
  isOwner,

  /// On ne modifie pas son propre accès.
  isSelf,

  /// Porte inconnue pour cet événement.
  checkpointNotFound,

  /// Événement clôturé, annulé ou archivé.
  locked,

  /// Serveur injoignable.
  network,

  /// Toute autre erreur.
  unknown;

  /// Échec correspondant au code serveur [code].
  static TeamFailure fromServerCode(String? code) => switch (code) {
    'org_forbidden' ||
    'event_not_found' ||
    'invitation_not_found' ||
    'assignment_not_found' => forbidden,
    'invitation_role_invalid' || 'invitation_params_invalid' => invalid,
    'member_not_found' => memberNotFound,
    'member_is_owner' => isOwner,
    'member_is_self' => isSelf,
    'checkpoint_not_found' => checkpointNotFound,
    'event_locked' => locked,
    _ => unknown,
  };
}

/// Gestion de l'équipe d'une organisation et des affectations.
abstract interface class TeamRepository {
  Future<List<TeamMember>> members(String organizationId);

  Future<List<Invitation>> invitations(String organizationId);

  Future<CreatedInvitation> createInvitation(
    String organizationId,
    MemberRole role, {
    required int validDays,
    required int maxUses,
  });

  Future<void> revokeInvitation(String invitationId);

  /// Change le rôle et/ou l'état d'un membre.
  Future<void> updateMember(
    String organizationId,
    String userId, {
    required MemberRole role,
    required bool active,
  });

  Future<List<Assignment>> eventTeam(String eventId);

  /// [checkpointId] `null` : toutes les portes.
  Future<void> assign(String eventId, String userId, String? checkpointId);

  Future<void> unassign(String assignmentId);
}
