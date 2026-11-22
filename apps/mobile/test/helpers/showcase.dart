import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/favorites/application/favorites_providers.dart';
import 'package:ticketsur/features/support/domain/support.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

import 'app_harness.dart';
import 'fake_admin_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_billing_admin_repository.dart';
import 'fake_billing_repository.dart';
import 'fake_catalog_repository.dart';
import 'fake_closed_org_repository.dart';
import 'fake_dashboard_repository.dart';
import 'fake_event_repository.dart';
import 'fake_event_setup_repository.dart';
import 'fake_organization_repository.dart';
import 'fake_support_repository.dart';
import 'fake_ticket_repository.dart';
import 'fake_wallet_repository.dart';

/// Données de démonstration communes à l'audit des contrastes et aux
/// captures de référence (lot 4-9) : une structure, un événement par état,
/// un ticket par état, la console remplie. [mode] : `light` ou `dark`.
Future<List<Override>> showcaseOverrides({
  required bool signedIn,
  required String mode,
  String language = 'fr',
  String textSize = 'normal',
  bool closedOrgs = false,
}) async {
  final tickets = [
    for (final (i, status) in TicketStatus.values.indexed)
      TicketSummary(
        id: 'tk-$i',
        reference: 'TS-AAAA-000$i',
        categoryName: i.isEven ? 'VIP' : 'Invités',
        isInvitation: i.isOdd,
        status: status,
        issuedAt: DateTime.utc(2030, 1, 1, 12),
        revokedAt: status == TicketStatus.revoked
            ? DateTime.utc(2030, 1, 2)
            : null,
        holder: i == 0 ? const TicketHolder(name: 'Awa') : TicketHolder.none,
      ),
  ];
  final events = [
    for (final (i, status) in EventStatus.values.indexed)
      testEvent(
        id: 'e$i',
        title: 'Événement ${status.name}',
        status: status,
        city: 'Ouagadougou',
      ),
  ];
  return await appOverrides(
    // Structure fermée (audit seulement : les captures n'en ont pas).
    closedOrgs: closedOrgs
        ? FakeClosedOrgRepository(
            organizations: [closedOrganization()],
            events: {
              'org-closed': [closedEvent()],
            },
          )
        : null,
    auth: FakeAuthRepository(
      user: signedIn
          ? const AuthUser(id: 'u1', email: 'chef@exemple.bf')
          : null,
    ),
    catalog: FakeCatalogRepository(
      [
        publicEvent(id: 'p1', minPrice: 2000),
        publicEvent(
          id: 'p2',
          title: 'Finale inter-quartiers',
          kind: EventKind.sport,
          minPrice: 0,
        ),
        for (final (i, kind) in EventKind.values.indexed)
          publicEvent(id: 'k$i', title: 'Événement $i', kind: kind),
      ],
      {
        'p1': PublicEventDetail(
          summary: publicEvent(id: 'p1', minPrice: 2000),
          description: 'Trois formations en plein air.',
          publicPhone: '+22670112233',
          categories: const [
            (name: 'Standard', price: 2000),
            (name: 'VIP', price: null),
          ],
        ),
      },
    ),
    organizations: FakeOrganizationRepository([testOrganization]),
    events: FakeEventRepository(events),
    setup: FakeEventSetupRepository(
      categories: const [
        TicketCategory(
          id: 'c1',
          eventId: 'e2',
          name: 'VIP',
          capacity: 50,
          issued: 10,
          redeemed: 4,
        ),
        TicketCategory(
          id: 'c2',
          eventId: 'e2',
          name: 'Invités',
          isInvitation: true,
        ),
      ],
    ),
    tickets: FakeTicketRepository(tickets),
    dashboard: FakeDashboardRepository(),
    billingAdmin: FakeBillingAdminRepository(billing: sampleAdminBilling()),
    billing: FakeBillingRepository(billing: sampleMyBilling()),
    admin: FakeAdminRepository(
      admin: true,
      accounts: [
        adminAccount(admin: true),
        adminAccount(id: 'u3', active: false, reason: 'Abus'),
        adminAccount(id: 'u4', due: true),
        adminAccount(id: 'u5', deleted: true),
      ],
      organizations: [
        adminOrganization(),
        adminOrganization(
          id: 'o2',
          name: 'Faso Gala',
          active: false,
          reason: 'Fraude signalée',
        ),
      ],
      events: [
        adminEvent(),
        adminEvent(
          id: 'p2',
          title: 'Soirée retirée',
          blocked: true,
          reason: 'Contenu trompeur',
        ),
      ],
      audit: [
        AuditEntry(
          id: 'a1',
          createdAt: DateTime.utc(2030, 6, 1, 10),
          action: 'admin.event_moderated',
          resourceType: 'event',
          organizationName: 'Kwabo Événements',
          actorName: 'Toussaint',
          details: const {'blocked': true},
        ),
      ],
    ),
    support: FakeSupportRepository(
      requests: [
        supportRequest(unread: true, requesterName: 'Awa Ouédraogo'),
        supportRequest(
          id: 'r2',
          subject: 'Question sur un paiement',
          status: SupportStatus.answered,
        ),
        supportRequest(
          id: 'r3',
          subject: 'Ancienne demande',
          status: SupportStatus.closed,
        ),
      ],
    )..adminMode = true,
    announcements: FakeAnnouncementRepository(
      mine: [
        announcement(),
        announcement(id: 'a2', title: 'Coupure prévue', important: true),
      ],
      all: [
        announcement(important: true),
        announcement(id: 'a2', active: false),
      ],
    ),
    wallet: FakeWalletRepository(
      mine: [
        walletRow(),
        walletRow(id: 'w2', status: TicketStatus.redeemed),
      ],
    ),
    preferences: {
      'appearance.theme_mode': mode,
      'appearance.language': language,
      'appearance.text_size': textSize,
      favoritesPreferenceKey:
          '[{"id":"p1","title":"Soirée Afro-Jazz","kind":"concert", '
          '"starts_at":"2030-06-20T20:00:00Z",'
          '"ends_at":"2030-06-21T00:00:00Z",'
          '"timezone":"Africa/Ouagadougou","venue":"Jardin",'
          '"city":"Ouagadougou","cover_url":null,'
          '"organization_name":"Kwabo","min_price":2000},'
          '{"id":"p0","title":"Gala passé","kind":"gala", '
          '"starts_at":"2020-06-20T20:00:00Z",'
          '"ends_at":"2020-06-21T00:00:00Z",'
          '"timezone":"Africa/Ouagadougou","venue":null,'
          '"city":"Bobo-Dioulasso","cover_url":null,'
          '"organization_name":"Kwabo","min_price":null}]',
    },
  );
}
