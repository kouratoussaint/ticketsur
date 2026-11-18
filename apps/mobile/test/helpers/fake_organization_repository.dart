import 'package:ticketsur/features/organizations/domain/organization.dart';

/// Organisation de test par défaut.
const testOrganization = Organization(
  id: 'org-test',
  name: 'Organisation de test',
  slug: 'organisation-de-test',
  role: MemberRole.owner,
);

/// Faux dépôt d'organisations, piloté par les tests.
class FakeOrganizationRepository implements OrganizationRepository {
  new([List<Organization>? organizations])
    : organizations = [...?organizations];

  final List<Organization> organizations;

  /// Erreur levée par le prochain [myOrganizations], puis effacée.
  OrganizationFailure? nextLoadFailure;

  /// Erreur levée par le prochain [create], puis effacée.
  OrganizationFailure? nextCreateFailure;

  final List<String> createCalls = [];
  int loadCalls = 0;

  @override
  Future<List<Organization>> myOrganizations() async {
    loadCalls++;
    if (nextLoadFailure case final failure?) {
      nextLoadFailure = null;
      throw failure;
    }
    return List.unmodifiable(organizations);
  }

  @override
  Future<Organization> create(String name) async {
    createCalls.add(name);
    if (nextCreateFailure case final failure?) {
      nextCreateFailure = null;
      throw failure;
    }
    final trimmed = name.trim();
    final organization = Organization(
      id: 'org-${organizations.length + 1}',
      name: trimmed,
      slug: trimmed.toLowerCase().replaceAll(' ', '-'),
      role: MemberRole.owner,
    );
    organizations.add(organization);
    return organization;
  }
}
