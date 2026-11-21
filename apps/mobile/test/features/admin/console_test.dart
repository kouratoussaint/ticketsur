import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/features/admin/data/supabase_admin_repository.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_page.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/navigation.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'toussaint@tikeo.bf');

  group('domaine', () {
    test('vue d’ensemble lue', () {
      final overview = sampleOverview();
      expect(overview.organizations, 12);
      expect(overview.organizationsDisabled, 1);
      expect(overview.accountsDeletionRequested, 3);
      expect(overview.eventsListed, 7);
      expect(overview.ticketsIssued, 4200);
      expect(overview.scansRefused24h, 12);
    });

    test('version inconnue : refusée', () {
      expect(
        () => AdminOverview.fromJson(const {'version': 2}),
        throwsA(AdminFailure.unknown),
      );
    });

    test('erreurs serveur traduites', () {
      supabase.PostgrestException error(String message, [String? code]) =>
          supabase.PostgrestException(message: message, code: code);
      expect(
        mapAdminError(error('forbidden', '42501')),
        AdminFailure.forbidden,
      );
      expect(
        mapAdminError(error('reason_required', '22023')),
        AdminFailure.reasonRequired,
      );
      expect(
        mapAdminError(error('event_not_found', 'P0002')),
        AdminFailure.notFound,
      );
      expect(
        mapAdminError(error('owner_role_locked', '55000')),
        AdminFailure.ownerLocked,
      );
      expect(
        mapAdminError(error('billing_limit_structures', '54000')),
        AdminFailure.structureLimit,
      );
      expect(mapAdminError(error('autre', '42501')), AdminFailure.forbidden);
      expect(mapAdminError(error('autre')), AdminFailure.unknown);
    });

    test('filtres du journal : préfixes du serveur', () {
      expect(AuditFilter.all.prefix, isNull);
      expect(AuditFilter.console.prefix, 'admin.');
      expect(AuditFilter.tickets.prefix, 'ticket');
    });
  });

  group('écrans', () {
    late FakeAdminRepository admin;
    late FakeEventRepository events;

    setUp(() {
      admin = FakeAdminRepository(admin: true);
      events = FakeEventRepository([
        testEvent(id: 'e1', status: EventStatus.published),
      ]);
    });

    Future<void> openApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: events,
            admin: admin,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    void go(WidgetTester tester, String path) =>
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);

    Future<void> openProfile(WidgetTester tester) async {
      go(tester, AppRoutes.profile);
      await tester.pumpAndSettle();
    }

    testWidgets('compte ordinaire : aucune entrée Console', (tester) async {
      admin.admin = false;
      await openApp(tester);
      await openProfile(tester);
      expect(find.byKey(const Key('profile-console')), findsNothing);
    });

    testWidgets('compte ordinaire sur /console : refus du serveur affiché', (
      tester,
    ) async {
      admin.admin = false;
      await openApp(tester);
      go(tester, AppRoutes.console);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-forbidden')), findsOneWidget);
      expect(find.byKey(const Key('console-nav-organizations')), findsNothing);
    });

    testWidgets(
      'administrateur : Profil → Console, chiffres de la plateforme',
      (tester) async {
        await openApp(tester);
        await openProfile(tester);
        final entry = find.byKey(const Key('profile-console'));
        expect(entry, findsOneWidget);
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(find.byType(ConsolePage), findsOneWidget);
        expect(find.byKey(const Key('console-overview')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('console-stat-tickets')),
            matching: find.text('4 200'),
          ),
          findsOneWidget,
        );
        expect(find.text('Retirés : 1'), findsOneWidget);
        expect(find.text('À supprimer : 1'), findsOneWidget);
      },
    );

    testWidgets('suspendre une organisation : motif obligatoire', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleOrganizations);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-org-o1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-org-suspend')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-org-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Indiquez un motif.'), findsOneWidget);
      expect(admin.statusCalls, isEmpty);

      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Fraude signalée',
      );
      await tester.tap(find.byKey(const Key('console-org-confirm')));
      await tester.pumpAndSettle();
      expect(admin.statusCalls, [('o1', false, 'Fraude signalée')]);
      expect(find.text('Suspendue'), findsOneWidget);
      expect(find.textContaining('Motif : Fraude signalée'), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-org-reactivate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-org-confirm')));
      await tester.pumpAndSettle();
      expect(admin.statusCalls.last, ('o1', true, null));
      expect(find.text('Suspendue'), findsNothing);
    });

    testWidgets(
      'sélection multiple : suspendre puis réactiver des structures',
      (tester) async {
        admin.orgs
          ..add(adminOrganization(id: 'o2', name: 'Faso Live'))
          ..add(
            adminOrganization(
              id: 'o3',
              name: 'Ancienne',
              active: false,
              reason: 'Doublon',
            ),
          );
        await openApp(tester);
        go(tester, AppRoutes.consoleOrganizations);
        await tester.pumpAndSettle();
        await tester.longPress(find.byKey(const Key('console-org-o1')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('console-selection-bar')), findsOneWidget);
        // En sélection, les boutons de la carte sont inactifs : un appui coche.
        await tester.tap(find.byKey(const Key('console-item-o2')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('console-item-o3')));
        await tester.pumpAndSettle();
        expect(find.text('3 sélectionnés'), findsOneWidget);

        await tester.tap(find.byKey(const Key('console-orgs-bulk-suspend')));
        await tester.pumpAndSettle();
        expect(find.text('Suspendre 2 structures ?'), findsOneWidget);
        expect(
          find.textContaining("1 élément choisi n'est pas concerné"),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('console-bulk-confirm')));
        await tester.pumpAndSettle();
        expect(find.text('Indiquez un motif.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('console-reason')),
          'Contrôle qualité',
        );
        await tester.tap(find.byKey(const Key('console-bulk-confirm')));
        await tester.pumpAndSettle();
        expect(admin.statusCalls, [
          ('o1', false, 'Contrôle qualité'),
          ('o2', false, 'Contrôle qualité'),
        ]);
        expect(find.text('2 structures suspendues'), findsOneWidget);
        expect(find.byKey(const Key('console-selection-bar')), findsNothing);
        // Le message disparaît (il couvrirait la barre d'actions).
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();

        await tester.longPress(find.byKey(const Key('console-org-o1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('selection-all')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('console-orgs-bulk-reactivate')));
        await tester.pumpAndSettle();
        expect(find.text('Réactiver 3 structures ?'), findsOneWidget);
        await tester.tap(find.byKey(const Key('console-bulk-confirm')));
        await tester.pumpAndSettle();
        expect(admin.statusCalls.skip(2), [
          ('o1', true, null),
          ('o2', true, null),
          ('o3', true, null),
        ]);
        expect(find.text('3 structures réactivées'), findsOneWidget);
      },
    );

    testWidgets('sélection multiple : jamais son propre compte', (
      tester,
    ) async {
      admin.accountList
        ..add(adminAccount(id: 'u3', name: 'Issa'))
        ..add(adminAccount(id: 'u1', name: 'Moi', admin: true));
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('console-account-u2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selection-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-accounts-bulk-disable')));
      await tester.pumpAndSettle();
      expect(find.text('Désactiver 2 comptes ?'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Inactivité',
      );
      await tester.tap(find.byKey(const Key('console-bulk-confirm')));
      await tester.pumpAndSettle();
      expect(admin.accountStatusCalls, [
        ('u2', false, 'Inactivité'),
        ('u3', false, 'Inactivité'),
      ]);
      expect(find.text('2 comptes désactivés'), findsOneWidget);

      // Retour quitte la sélection sans quitter la page.
      await tester.longPress(find.byKey(const Key('console-account-u2')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-selection-bar')), findsNothing);
      expect(find.byKey(const Key('console-account-u2')), findsOneWidget);
    });

    testWidgets('recherche et filtre des organisations', (tester) async {
      admin.orgs.add(
        adminOrganization(id: 'o2', name: 'Faso Gala', active: false),
      );
      await openApp(tester);
      go(tester, AppRoutes.consoleOrganizations);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-org-o2')), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('console-org-search')),
          matching: find.byType(TextField),
        ),
        'kwabo',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(admin.orgQueries.last, ('kwabo', false));
      expect(find.byKey(const Key('console-org-o2')), findsNothing);

      await tester.tap(find.byKey(const Key('console-org-disabled-only')));
      await tester.pumpAndSettle();
      expect(admin.orgQueries.last, ('kwabo', true));
      expect(find.byKey(const Key('console-list-empty')), findsOneWidget);
    });

    testWidgets('retirer un événement du catalogue, puis le rétablir', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleCatalog);
      await tester.pumpAndSettle();
      expect(find.text('Au catalogue'), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-event-block')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Contenu trompeur',
      );
      await tester.tap(find.byKey(const Key('console-event-confirm')));
      await tester.pumpAndSettle();
      expect(admin.blockCalls, [('p1', true, 'Contenu trompeur')]);
      expect(find.text('Retiré'), findsOneWidget);
      expect(find.textContaining('Motif : Contenu trompeur'), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-event-unblock')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-event-confirm')));
      await tester.pumpAndSettle();
      expect(admin.blockCalls.last, ('p1', false, null));
    });

    testWidgets('comptes : désactiver avec motif, puis réactiver', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-account-u2')), findsOneWidget);
      expect(find.text('u2@faso.bf'), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-account-disable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-account-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Indiquez un motif.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Comportement abusif',
      );
      await tester.tap(find.byKey(const Key('console-account-confirm')));
      await tester.pumpAndSettle();
      expect(admin.accountStatusCalls, [('u2', false, 'Comportement abusif')]);
      expect(
        find.textContaining('Motif : Comportement abusif'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('console-account-reactivate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-account-confirm')));
      await tester.pumpAndSettle();
      expect(admin.accountStatusCalls.last, ('u2', true, null));
    });

    testWidgets('comptes : attribuer une structure (#10)', (tester) async {
      admin.orgs.add(adminOrganization(id: 'o2', name: 'Faso Spectacles'));
      admin.structures['u2'] = [
        const AdminAccountStructure(
          organizationId: 'o1',
          name: 'Kwabo Événements',
          role: MemberRole.controller,
          active: true,
        ),
      ];
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-account-assign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('assign-current-o1')), findsOneWidget);
      expect(find.text('Kwabo Événements · Contrôleur'), findsOneWidget);
      // Rien à attribuer tant qu'aucune structure n'est choisie.
      expect(
        tester
            .widget<TikeoPrimaryButton>(find.byKey(const Key('assign-submit')))
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('assign-org-search')),
        'faso',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assign-org-o2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('assign-picked')), findsOneWidget);

      // Propriétaire = transfert, expliqué.
      await tester.tap(find.byKey(const Key('assign-role-owner')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Transfert :'), findsOneWidget);
      expect(find.text('Transférer la structure'), findsOneWidget);

      // Motif obligatoire.
      await tester.ensureVisible(find.byKey(const Key('assign-submit')));
      await tester.tap(find.byKey(const Key('assign-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Indiquez un motif.'), findsOneWidget);
      expect(admin.assignCalls, isEmpty);

      // Refus du serveur : message lisible, la feuille reste ouverte.
      admin.nextAssignFailure = AdminFailure.structureLimit;
      await tester.enterText(
        find.byKey(const Key('assign-reason')),
        'Cession demandée',
      );
      await tester.ensureVisible(find.byKey(const Key('assign-submit')));
      await tester.tap(find.byKey(const Key('assign-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Le pack de ce compte ne permet pas une structure de plus.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('assign-sheet')), findsOneWidget);

      await tester.tap(find.byKey(const Key('assign-submit')));
      await tester.pumpAndSettle();
      expect(admin.assignCalls.last, (
        'u2',
        'o2',
        MemberRole.owner,
        'Cession demandée',
      ));
      expect(find.byKey(const Key('assign-sheet')), findsNothing);
      expect(
        find.text('Compte désormais propriétaire de « Faso Spectacles ».'),
        findsOneWidget,
      );
    });

    testWidgets('comptes : pas d’action sur son propre compte', (tester) async {
      admin.accountList
        ..clear()
        ..add(adminAccount(id: user.id, name: 'Toussaint', admin: true));
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      expect(find.text('Administrateur'), findsOneWidget);
      expect(find.byKey(const Key('console-account-disable')), findsNothing);
    });

    testWidgets('comptes : suppression définitive à échéance', (tester) async {
      admin.accountList
        ..clear()
        ..addAll([
          adminAccount(id: 'u3', name: 'Moussa Parti', due: true),
          adminAccount(id: 'u4', name: 'Fati Restée'),
        ]);
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      // Bouton global (1 compte à échéance d'après la vue d'ensemble).
      expect(
        find.byKey(const Key('console-accounts-purge-all')),
        findsOneWidget,
      );
      // Seul le compte à échéance a « Supprimer définitivement ».
      expect(find.byKey(const Key('console-account-purge')), findsOneWidget);
      await tester.tap(find.byKey(const Key('console-account-purge')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-account-purge-confirm')));
      await tester.pumpAndSettle();
      expect(admin.purgeCalls, ['u3']);
      expect(find.text('Compte supprimé'), findsOneWidget);
      expect(find.byKey(const Key('console-account-purge')), findsNothing);

      await tester.tap(find.byKey(const Key('console-accounts-due')));
      await tester.pumpAndSettle();
      expect(admin.accountQueries.last.$2, AccountFilter.due);
      expect(find.byKey(const Key('console-list-empty')), findsOneWidget);
    });

    testWidgets('comptes : tout supprimer à échéance', (tester) async {
      admin.accountList
        ..clear()
        ..add(adminAccount(id: 'u3', name: 'Moussa Parti', due: true));
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-accounts-purge-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-accounts-purge-confirm')));
      await tester.pumpAndSettle();
      expect(admin.purgeAllCalls, 1);
      expect(find.text('Compte supprimé'), findsOneWidget);
    });

    testWidgets('journal : libellés lisibles et filtres', (tester) async {
      admin.audit.addAll([
        AuditEntry(
          id: 'a1',
          createdAt: DateTime.utc(2030, 6, 1, 10),
          action: 'admin.event_moderated',
          resourceType: 'event',
          organizationName: 'Kwabo Événements',
          actorName: 'Toussaint',
          details: const {'blocked': true},
        ),
        AuditEntry(
          id: 'a2',
          createdAt: DateTime.utc(2030, 6, 1, 9),
          action: 'tickets.issued',
          resourceType: 'event',
          details: const {'quantity': 3},
        ),
        AuditEntry(
          id: 'a3',
          createdAt: DateTime.utc(2030, 6, 1, 8),
          action: 'action.inconnue',
          resourceType: 'event',
        ),
      ]);
      await openApp(tester);
      go(tester, AppRoutes.consoleJournal);
      await tester.pumpAndSettle();
      expect(find.text('Modération du catalogue'), findsOneWidget);
      expect(find.text('Tickets émis'), findsOneWidget);
      expect(find.text('action.inconnue'), findsOneWidget);
      expect(find.textContaining('par Toussaint'), findsOneWidget);
      expect(find.textContaining('retiré : oui'), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-audit-console')));
      await tester.pumpAndSettle();
      expect(admin.auditQueries.last, (AuditFilter.console, 0));
      expect(find.text('Tickets émis'), findsNothing);
    });

    testWidgets('échec réseau : message et nouvel essai', (tester) async {
      admin.failure = AdminFailure.network;
      await openApp(tester);
      go(tester, AppRoutes.consoleOrganizations);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-list-error')), findsOneWidget);
      admin.failure = null;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-org-o1')), findsOneWidget);
    });
  });

  group('organisateur', () {
    testWidgets('événement retiré par Tikéo : motif affiché, pas de '
        'republication', (tester) async {
      final events = FakeEventRepository([
        testEvent(
          id: 'e1',
          status: EventStatus.published,
          blockedReason: 'Contenu trompeur',
        ),
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([testOrganization]),
            events: events,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await openEventsList(tester);
      await tester.tap(find.byKey(const Key('event-card-e1')));
      await tester.pumpAndSettle();
      final blocked = find.byKey(const Key('event-public-blocked'));
      await tester.ensureVisible(blocked);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(blocked).data,
        'Retiré du catalogue par Tikéo. Motif : Contenu trompeur',
      );
      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('event-public')),
      );
      expect(toggle.onChanged, isNull);
    });
  });
}
