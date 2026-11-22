import 'package:ticketsur/features/closed_orgs/domain/closed_org.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

/// Faux dépôt des structures fermées (vide par défaut).
class FakeClosedOrgRepository implements ClosedOrgRepository {
  new({
    List<ClosedOrganization>? organizations,
    Map<String, List<ClosedEvent>>? events,
  }) : organizations = [...?organizations],
       events = {...?events};

  final List<ClosedOrganization> organizations;
  final Map<String, List<ClosedEvent>> events;
  final List<String> calls = [];
  ClosedOrgFailure? failure;

  @override
  Future<List<ClosedOrganization>> list() async {
    calls.add('list');
    if (failure case final failure?) throw failure;
    return organizations;
  }

  @override
  Future<ClosedOrganizationDetail> detail(String organizationId) async {
    calls.add('detail $organizationId');
    if (failure case final failure?) throw failure;
    final organization = organizations.firstWhere(
      (o) => o.id == organizationId,
      orElse: () => throw ClosedOrgFailure.notFound,
    );
    return (
      organization: organization,
      events: events[organizationId] ?? const [],
    );
  }
}

/// Structure fermée de test.
ClosedOrganization closedOrganization({
  String id = 'org-closed',
  String name = 'Kwabo Archives',
  MemberRole role = MemberRole.owner,
  int eventCount = 1,
}) => ClosedOrganization(
  id: id,
  name: name,
  role: role,
  closedAt: DateTime.utc(2030, 5, 2, 10),
  city: 'Ouagadougou',
  eventCount: eventCount,
);

/// Événement passé d'une structure fermée, avec ses chiffres.
ClosedEvent closedEvent({
  String id = 'ev-closed',
  String organizationId = 'org-closed',
  String title = 'Festival archivé',
}) => (
  event: TicketEvent(
    id: id,
    organizationId: organizationId,
    title: title,
    timezone: 'Africa/Ouagadougou',
    startsAt: DateTime.utc(2030, 4, 12, 20),
    endsAt: DateTime.utc(2030, 4, 13, 2),
    status: EventStatus.archived,
    venue: 'Jardin de la musique',
  ),
  issued: 120,
  admitted: 97,
  revoked: 3,
);
