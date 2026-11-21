import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show AsyncNotifierProviderFamily;
import 'package:share_plus/share_plus.dart';
import 'package:ticketsur/core/bulk.dart';
import 'package:ticketsur/features/billing/domain/billing_block.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/team/domain/team.dart';

/// Dépôt de l'équipe (Supabase au démarrage, faux en test).
final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => throw UnimplementedError(
    'teamRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Partage d'un texte par le menu Android (WhatsApp, SMS…), remplacé en test.
final shareTextProvider = Provider<Future<void> Function(String text)>(
  (ref) => (text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  },
);

/// Membres et invitations de l'organisation active.
@immutable
final class TeamState {
  const new({required this.members, required this.invitations});

  final List<TeamMember> members;
  final List<Invitation> invitations;
}

/// Équipe de l'organisation active (organisateurs uniquement).
class TeamController extends AsyncNotifier<TeamState> {
  TeamRepository get _repository => ref.read(teamRepositoryProvider);

  String? get _organizationId => ref.read(activeOrganizationProvider)?.id;

  @override
  Future<TeamState> build() async {
    final organization = ref.watch(activeOrganizationProvider);
    if (organization == null || organization.role == MemberRole.controller) {
      return const TeamState(members: [], invitations: []);
    }
    return await _load(organization.id);
  }

  Future<TeamState> _load(String organizationId) async {
    final results = await Future.wait([
      _repository.members(organizationId),
      _repository.invitations(organizationId),
    ]);
    return TeamState(
      members: results[0] as List<TeamMember>,
      invitations: results[1] as List<Invitation>,
    );
  }

  Future<void> _refresh() async {
    final id = _organizationId;
    if (id != null) state = AsyncData(await _load(id));
  }

  /// Crée une invitation ; le code n'est renvoyé qu'ici.
  /// Lève une [TeamFailure] en cas d'échec.
  Future<CreatedInvitation> invite(
    MemberRole role, {
    required int validDays,
    required int maxUses,
  }) async {
    final id = _organizationId;
    if (id == null) throw TeamFailure.forbidden;
    final created = await _repository.createInvitation(
      id,
      role,
      validDays: validDays,
      maxUses: maxUses,
    );
    await _refresh();
    return created;
  }

  Future<void> revoke(String invitationId) async {
    await _repository.revokeInvitation(invitationId);
    await _refresh();
  }

  Future<void> updateMember(
    String userId, {
    required MemberRole role,
    required bool active,
  }) async {
    final id = _organizationId;
    if (id == null) throw TeamFailure.forbidden;
    await _repository.updateMember(id, userId, role: role, active: active);
    await _refresh();
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Équipe de l'organisation active.
final AsyncNotifierProvider<TeamController, TeamState> teamProvider =
    AsyncNotifierProvider.autoDispose<TeamController, TeamState>(
      TeamController.new,
      retry: (retryCount, error) => null,
    );

/// Affectations d'un événement.
class EventTeamController extends AsyncNotifier<List<Assignment>> {
  new(this.eventId);

  final String eventId;

  TeamRepository get _repository => ref.read(teamRepositoryProvider);

  @override
  Future<List<Assignment>> build() => _repository.eventTeam(eventId);

  /// Lève une [TeamFailure] en cas d'échec.
  Future<void> assign(String userId, String? checkpointId) async {
    await _repository.assign(eventId, userId, checkpointId);
    state = AsyncData(await _repository.eventTeam(eventId));
  }

  /// Affecte plusieurs membres à la même porte (ou à toutes), un par un ;
  /// la liste est relue une seule fois. Arrêt si le réseau est coupé ou si
  /// une limite du pack est atteinte.
  Future<BulkOutcome> assignMany(
    Iterable<String> userIds,
    String? checkpointId,
  ) async {
    final outcome = await runBulk(
      userIds,
      (userId) => _repository.assign(eventId, userId, checkpointId),
      stopOn: (error) =>
          error == TeamFailure.network || billingBlockJustReported,
    );
    if (outcome.done > 0) {
      state = AsyncData(await _repository.eventTeam(eventId));
    }
    return outcome;
  }

  Future<void> unassign(String assignmentId) async {
    await _repository.unassign(assignmentId);
    state = AsyncData(await _repository.eventTeam(eventId));
  }
}

/// Affectations d'un événement (organisateurs).
final AsyncNotifierProviderFamily<EventTeamController, List<Assignment>, String>
eventTeamProvider = AsyncNotifierProvider.autoDispose
    .family<EventTeamController, List<Assignment>, String>(
      EventTeamController.new,
      retry: (retryCount, error) => null,
    );
