import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_orgs/domain/admin_orgs.dart';
import 'package:ticketsur/features/events/domain/event.dart' show EventStatus;
import 'package:ticketsur/features/organizations/domain/organization.dart'
    show MemberRole;

/// Fiche de test : Kwabo, propriétaire Awa, un gestionnaire, un événement.
OrganizationDetail orgDetail({
  String id = 'o1',
  String name = 'Kwabo Événements',
  bool active = true,
  DateTime? closedAt,
  DateTime? trashedAt,
  List<OrgMember>? members,
  List<OrgInvitationSummary>? invitations,
  int eventsTotal = 1,
}) => OrganizationDetail(
  id: id,
  name: name,
  active: active,
  createdAt: DateTime.utc(2026, 9),
  ownerId: 'u-awa',
  ownerName: 'Awa Ouédraogo',
  ownerEmail: 'awa@exemple.bf',
  city: 'Ouagadougou',
  closedAt: closedAt,
  trashedAt: trashedAt,
  purgeDueAt: trashedAt?.add(const Duration(days: 30)),
  packName: 'Découverte',
  members:
      members ??
      const [
        OrgMember(
          userId: 'u-awa',
          displayName: 'Awa Ouédraogo',
          role: MemberRole.owner,
          active: true,
        ),
        OrgMember(
          userId: 'u-issa',
          displayName: 'Issa Kaboré',
          email: 'issa@exemple.bf',
          role: MemberRole.manager,
          active: true,
        ),
      ],
  invitations:
      invitations ??
      [
        OrgInvitationSummary(
          id: 'inv1',
          role: MemberRole.controller,
          codeHint: 'K7QP',
          expiresAt: DateTime.utc(2026, 12),
        ),
      ],
  events: eventsTotal == 0
      ? const []
      : [
          OrgEventSummary(
            id: 'e1',
            title: 'Concert de Noël',
            status: EventStatus.published,
            startsAt: DateTime.utc(2026, 12, 24, 20),
            tickets: 120,
          ),
        ],
  eventsTotal: eventsTotal,
  eventsUpcoming: eventsTotal,
  ticketsIssued: eventsTotal == 0 ? 0 : 120,
);

/// Structures de la console en mémoire.
class FakeAdminOrgsRepository implements AdminOrgsRepository {
  new({Map<String, OrganizationDetail>? organizations, List<TrashItem>? trash})
    : organizations = organizations ?? {'o1': orgDetail()},
      trashItems = trash ?? [];

  final Map<String, OrganizationDetail> organizations;
  final List<TrashItem> trashItems;
  final List<String> calls = [];

  /// Échec de la prochaine action.
  AdminAccountsFailure? failure;

  OrgDeletePreview preview = const OrgDeletePreview(
    trash: false,
    eventsToCancel: 1,
    ticketsToCancel: 120,
    holdersToNotify: 37,
  );

  void _fail() {
    if (failure case final f?) {
      failure = null;
      throw f;
    }
  }

  @override
  String logoUrl(String path) => 'https://exemple.test/$path';

  @override
  Future<OrganizationDetail> detail(String organizationId) async {
    final org = organizations[organizationId];
    if (org == null) throw AdminAccountsFailure.orgNotFound;
    return org;
  }

  @override
  Future<String> create({
    required String ownerId,
    required String name,
    required String reason,
    String? city,
    bool? notify,
  }) async {
    calls.add('create $ownerId $name ${city ?? '-'} $reason $notify');
    _fail();
    final id = 'o-new-${organizations.length}';
    organizations[id] = orgDetail(id: id, name: name, eventsTotal: 0);
    return id;
  }

  @override
  Future<void> update(
    String organizationId, {
    required String name,
    required String reason,
    String? city,
    String? phone,
    String? contactEmail,
    String? publicPhone,
    bool? notify,
  }) async {
    calls.add(
      'update $organizationId $name ${city ?? '-'} ${phone ?? '-'} '
      '${publicPhone ?? '-'} $reason $notify',
    );
    _fail();
    organizations[organizationId] = orgDetail(id: organizationId, name: name);
  }

  @override
  Future<void> removeLogo(
    String organizationId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('remove-logo $organizationId $reason');
    _fail();
  }

  @override
  Future<void> setMemberRole(
    String organizationId,
    String userId,
    MemberRole role, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('role $organizationId $userId ${role.wireName} $reason $notify');
    _fail();
  }

  @override
  Future<void> removeMember(
    String organizationId,
    String userId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('remove $organizationId $userId $reason $notify');
    _fail();
  }

  @override
  Future<void> revokeInvitation(
    String invitationId, {
    required String reason,
  }) async {
    calls.add('revoke-invitation $invitationId $reason');
    _fail();
  }

  @override
  Future<OrgDeletePreview> deletePreview(String organizationId) async {
    calls.add('preview $organizationId');
    _fail();
    return preview;
  }

  @override
  Future<OrgDeleteOutcome> delete(
    String organizationId, {
    required String confirmName,
    required String reason,
    bool? notify,
  }) async {
    calls.add('delete $organizationId $confirmName $reason');
    _fail();
    final org = organizations[organizationId]!;
    final now = DateTime.now().toUtc();
    organizations[organizationId] = orgDetail(
      id: organizationId,
      name: org.name,
      active: false,
      closedAt: preview.trash ? null : now,
      trashedAt: preview.trash ? now : null,
    );
    return OrgDeleteOutcome(
      trash: preview.trash,
      eventsCancelled: preview.eventsToCancel,
      ticketsCancelled: preview.ticketsToCancel,
      holdersNotified: preview.holdersToNotify,
    );
  }

  @override
  Future<List<TrashItem>> trash() async => trashItems;

  @override
  Future<void> restore(
    String organizationId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('restore $organizationId $reason');
    _fail();
    trashItems.removeWhere((item) => item.id == organizationId);
  }

  @override
  Future<void> purgeNow(
    String organizationId, {
    required String confirmName,
    required String reason,
  }) async {
    calls.add('purge $organizationId $confirmName $reason');
    _fail();
  }
}
