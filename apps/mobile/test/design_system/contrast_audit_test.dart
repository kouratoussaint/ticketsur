import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/favorites/application/favorites_providers.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/support/domain/support.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

import '../helpers/app_harness.dart';
import '../helpers/contrast_audit.dart';
import '../helpers/fake_admin_repository.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_catalog_repository.dart';
import '../helpers/fake_dashboard_repository.dart';
import '../helpers/fake_event_repository.dart';
import '../helpers/fake_event_setup_repository.dart';
import '../helpers/fake_organization_repository.dart';
import '../helpers/fake_support_repository.dart';
import '../helpers/fake_ticket_repository.dart';
import '../helpers/fake_wallet_repository.dart';

/// Parcourt les écrans principaux en thème clair puis sombre et vérifie le
/// contraste de chaque texte affiché.
void main() {
  testWidgets("l'audit repère un texte illisible et ignore les icônes", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ColoredBox(
          color: Color(0xFF061B38),
          child: Column(
            children: [
              Text('Lisible', style: TextStyle(color: Color(0xFFE6ECF4))),
              Text('Illisible', style: TextStyle(color: Color(0xFF52627A))),
              Icon(Icons.star, color: Color(0xFF0B1F3A)),
            ],
          ),
        ),
      ),
    );
    final issues = auditContrast(tester);
    expect(issues, hasLength(1));
    expect(issues.single, startsWith('« Illisible »'));
  });

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

  for (final mode in ['light', 'dark']) {
    final screens = {
      'accueil': AppRoutes.home,
      'événements': AppRoutes.events,
      'fiche événement (brouillon)': AppRoutes.eventDetail('e0'),
      'fiche événement (en cours)': AppRoutes.eventDetail('e2'),
      'tableau de bord': AppRoutes.eventDashboard('e2'),
      'tickets': AppRoutes.tickets,
      'fiche ticket': AppRoutes.ticketDetail('e2', 'tk-0'),
      'équipe': AppRoutes.team,
      'profil': AppRoutes.profile,
      'modifier le profil': AppRoutes.editProfile,
      'nouvel événement': AppRoutes.newEvent,
      'explorer (connecté)': AppRoutes.explore,
      'sans compte : explorer': AppRoutes.discover,
      'sans compte : fiche publique': AppRoutes.publicEvent('p1'),
      'sans compte : organiser': AppRoutes.organize,
      'sans compte : inscription': AppRoutes.signUpWithCode,
      'sans compte : connexion': AppRoutes.signIn,
      'sans compte : favoris': AppRoutes.favorites,
      'favoris (connecté)': AppRoutes.favorites,
      'console': AppRoutes.console,
      'console : organisations': AppRoutes.consoleOrganizations,
      'console : catalogue': AppRoutes.consoleCatalog,
      'console : journal': AppRoutes.consoleJournal,
      'console : comptes': AppRoutes.consoleAccounts,
      'console : support': AppRoutes.consoleSupport,
      'console : fil de support': AppRoutes.consoleSupportThread('r1'),
      'console : annonces': AppRoutes.consoleAnnouncements,
      'console : nouvelle annonce': AppRoutes.consoleAnnouncementNew,
      'aide et support': AppRoutes.support,
      'nouvelle demande': AppRoutes.supportNew,
      'fil de support': AppRoutes.supportThread('r2'),
      'paramètres': AppRoutes.settings,
      'sans compte : conditions': AppRoutes.legal(LegalSlug.terms),
      'console : mentions légales': AppRoutes.consoleLegal,
      'console : modifier les conditions': AppRoutes.consoleLegalEdit(
        LegalSlug.terms,
      ),
      'mes tickets': AppRoutes.wallet,
      'ajouter un ticket': AppRoutes.walletAdd,
      'mon ticket': AppRoutes.walletTicket('w1'),
      'mon ticket utilisé': AppRoutes.walletTicket('w2'),
    };
    for (final MapEntry(key: name, value: path) in screens.entries) {
      testWidgets('thème $mode : $name', (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: await appOverrides(
              auth: FakeAuthRepository(
                user: name.startsWith('sans compte')
                    ? null
                    : const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
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
                  announcement(
                    id: 'a2',
                    title: 'Coupure prévue',
                    important: true,
                  ),
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
            ),
            child: const TicketSurApp(),
          ),
        );
        await tester.pumpAndSettle();
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();

        final issues = <String>{};
        // Écran entier : on fait défiler la liste principale par pas.
        final scrollables = find.byType(Scrollable);
        for (var step = 0; step < 12; step++) {
          issues.addAll(auditContrast(tester));
          if (scrollables.evaluate().isEmpty) break;
          final position = tester
              .state<ScrollableState>(scrollables.first)
              .position;
          if (position.pixels >= position.maxScrollExtent) break;
          position.jumpTo(
            (position.pixels + 600).clamp(0, position.maxScrollExtent),
          );
          await tester.pumpAndSettle();
        }
        expect(issues, isEmpty, reason: issues.join('\n'));
      });
    }
  }
}
