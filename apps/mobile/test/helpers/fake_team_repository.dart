import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/team/domain/team.dart';

/// Faux dépôt d'équipe, piloté par les tests.
class FakeTeamRepository implements TeamRepository {
  new({
    List<TeamMember>? members,
    List<Invitation>? invitations,
    List<Assignment>? assignments,
  }) : memberRows = [...?members],
       invitationRows = [...?invitations],
       assignmentRows = [...?assignments];

  final List<TeamMember> memberRows;
  final List<Invitation> invitationRows;
  final List<Assignment> assignmentRows;
  final List<String> calls = [];
  TeamFailure? nextWriteFailure;
  int _ids = 0;

  void _write(String call) {
    calls.add(call);
    if (nextWriteFailure case final failure?) {
      nextWriteFailure = null;
      throw failure;
    }
  }

  @override
  Future<List<TeamMember>> members(String organizationId) async =>
      List.of(memberRows);

  @override
  Future<List<Invitation>> invitations(String organizationId) async =>
      List.of(invitationRows);

  @override
  Future<CreatedInvitation> createInvitation(
    String organizationId,
    MemberRole role, {
    required int validDays,
    required int maxUses,
  }) async {
    _write('invite ${role.wireName} $validDays $maxUses');
    final invitation = Invitation(
      id: 'inv-${++_ids}',
      role: role,
      codeHint: 'WXYZ',
      expiresAt: DateTime.utc(2030, 1, 1 + validDays, 12),
      maxUses: maxUses,
      uses: 0,
    );
    invitationRows.add(invitation);
    return CreatedInvitation(
      invitation: invitation,
      code: 'TSI-ABCD-EFGH-WXYZ',
    );
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    _write('revoke $invitationId');
    invitationRows.removeWhere((i) => i.id == invitationId);
  }

  /// Codes réaffichables (id → code) ; absent : invitation ancienne.
  final Map<String, String> codes = {};

  @override
  Future<InvitationDetails> invitationDetails(String invitationId) async {
    calls.add('details $invitationId');
    final invitation = invitationRows.firstWhere(
      (i) => i.id == invitationId,
      orElse: () => throw TeamFailure.forbidden,
    );
    return InvitationDetails(
      id: invitation.id,
      organizationName: 'Organisation de test',
      role: invitation.role,
      state: InvitationState.active,
      codeHint: invitation.codeHint,
      codeAvailable: codes.containsKey(invitationId),
      createdByName: 'Awa Ouédraogo',
      createdAt: DateTime.utc(2030),
      expiresAt: invitation.expiresAt,
      uses: invitation.uses,
      maxUses: invitation.maxUses,
      usedBy: [
        if (invitation.uses > 0)
          (name: 'Issa Sawadogo', at: DateTime.utc(2030, 1, 2)),
      ],
    );
  }

  @override
  Future<String> revealInvitationCode(String invitationId) async {
    _write('reveal $invitationId');
    return codes[invitationId] ?? (throw TeamFailure.codeUnavailable);
  }

  @override
  Future<void> updateMember(
    String organizationId,
    String userId, {
    required MemberRole role,
    required bool active,
  }) async {
    _write('update $userId ${role.wireName} $active');
    final index = memberRows.indexWhere((m) => m.userId == userId);
    final old = memberRows[index];
    memberRows[index] = TeamMember(
      userId: old.userId,
      displayName: old.displayName,
      email: old.email,
      role: role,
      active: active,
    );
  }

  @override
  Future<List<Assignment>> eventTeam(String eventId) async =>
      List.of(assignmentRows);

  @override
  Future<void> assign(
    String eventId,
    String userId,
    String? checkpointId,
  ) async {
    _write('assign $userId ${checkpointId ?? 'toutes'}');
    final member = memberRows.firstWhere((m) => m.userId == userId);
    assignmentRows.add(
      Assignment(
        id: 'asg-${++_ids}',
        userId: userId,
        displayName: member.displayName,
        memberActive: member.active,
        role: member.role,
        checkpointId: checkpointId,
        checkpointName: checkpointId == null ? null : 'Porte $checkpointId',
      ),
    );
  }

  @override
  Future<void> unassign(String assignmentId) async {
    _write('unassign $assignmentId');
    assignmentRows.removeWhere((a) => a.id == assignmentId);
  }

  /// Activité par membre (vide sinon) et appels.
  final Map<String, MemberActivity> activities = {};
  final List<String> activityCalls = [];

  @override
  Future<MemberActivity> memberActivity(
    String organizationId,
    String userId,
  ) async {
    activityCalls.add(userId);
    return activities[userId] ?? const MemberActivity();
  }
}
