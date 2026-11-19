import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;
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
  final List<String> joinCalls = [];
  final List<(String, OrganizationDraft)> updateCalls = [];
  final List<CoverImage> logoCalls = [];
  final List<String> leaveCalls = [];

  /// Erreur levée par la prochaine écriture (fiche, logo, départ).
  OrganizationFailure? nextWriteFailure;

  void _failWrite() {
    if (nextWriteFailure case final failure?) {
      nextWriteFailure = null;
      throw failure;
    }
  }

  /// Réponse du prochain [join] (par défaut : code inconnu).
  JoinOutcome nextJoin = const JoinOutcome(JoinResult.invalid);
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

  @override
  Future<JoinOutcome> join(String code) async {
    joinCalls.add(code);
    final outcome = nextJoin;
    if (outcome.organization case final organization?
        when outcome.result == JoinResult.joined) {
      organizations.add(organization);
    }
    return outcome;
  }

  @override
  Future<Organization> update(
    String organizationId,
    OrganizationDraft draft,
  ) async {
    updateCalls.add((organizationId, draft));
    _failWrite();
    final index = organizations.indexWhere((o) => o.id == organizationId);
    final current = organizations[index];
    final params = draft.toParams();
    final updated = Organization(
      id: current.id,
      name: (params['p_name']! as String).replaceAll(RegExp(r'\s+'), ' '),
      slug: current.slug,
      role: current.role,
      logoPath: current.logoPath,
      logoUrl: current.logoUrl,
      phone: params['p_phone'] as String?,
      contactEmail: (params['p_contact_email'] as String?)?.toLowerCase(),
      city: params['p_city'] as String?,
    );
    organizations[index] = updated;
    return updated;
  }

  @override
  Future<Organization> setLogo(
    Organization organization,
    CoverImage image,
  ) async {
    logoCalls.add(image);
    _failWrite();
    final index = organizations.indexWhere((o) => o.id == organization.id);
    final path = '${organization.id}/logo-${logoCalls.length}.png';
    final current = organizations[index];
    final updated = Organization(
      id: current.id,
      name: current.name,
      slug: current.slug,
      role: current.role,
      logoPath: path,
      logoUrl: 'https://logos.test/$path',
      phone: current.phone,
      contactEmail: current.contactEmail,
      city: current.city,
    );
    organizations[index] = updated;
    return updated;
  }

  @override
  Future<void> leave(String organizationId) async {
    leaveCalls.add(organizationId);
    _failWrite();
    organizations.removeWhere((o) => o.id == organizationId);
  }
}
