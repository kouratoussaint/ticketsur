import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin_accounts/data/supabase_admin_accounts_repository.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_orgs/domain/admin_orgs.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_accounts_repository.dart';
import '../../helpers/fake_admin_orgs_repository.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'toussaint@tikeo.bf');

  group('domaine', () {
    test('fiche d’une structure lue', () {
      final org = OrganizationDetail.fromJson(const {
        'id': 'o1',
        'name': 'Kwabo',
        'slug': 'kwabo',
        'status': 'disabled',
        'created_at': '2026-09-01T10:00:00Z',
        'closed_at': '2026-11-21T10:00:00Z',
        'owner': {'id': 'u2', 'display_name': 'Awa', 'email': 'awa@exemple.bf'},
        'members': [
          {
            'user_id': 'u2',
            'display_name': 'Awa',
            'role': 'owner',
            'active': true,
          },
        ],
        'invitations': [
          {
            'id': 'i1',
            'role': 'controller',
            'code_hint': 'K7QP',
            'expires_at': '2026-12-01T00:00:00Z',
          },
        ],
        'events': [
          {
            'id': 'e1',
            'title': 'Gala',
            'status': 'cancelled',
            'starts_at': '2026-12-24T20:00:00Z',
            'tickets': 10,
            'admitted': 2,
          },
        ],
        'events_total': 3,
        'tickets_issued': 10,
        'invoices_due': 1,
        'pack_name': 'Découverte',
        'actions': <Object>[],
      });
      expect(org.closed, isTrue);
      expect(org.editable, isFalse);
      expect(org.ownerName, 'Awa');
      expect(org.members.single.role, MemberRole.owner);
      expect(org.invitations.single.codeHint, 'K7QP');
      expect(org.events.single.admitted, 2);
      expect(org.invoicesDue, 1);
    });

    test('aperçu, corbeille et erreurs', () {
      final preview = OrgDeletePreview.fromJson(const {
        'mode': 'close',
        'events_to_cancel': 2,
        'tickets_to_cancel': 40,
        'holders_to_notify': 12,
      });
      expect(preview.trash, isFalse);
      expect(preview.ticketsToCancel, 40);
      final item = TrashItem(
        id: 'o2',
        name: 'Vide',
        trashedAt: DateTime.utc(2026, 11),
        purgeDueAt: DateTime.utc(2026, 12),
      );
      expect(item.daysLeft(DateTime.utc(2026, 11, 21)), 10);
      expect(item.daysLeft(DateTime.utc(2027)), 0);
      expect(
        mapAdminAccountsError(
          const supabase.PostgrestException(message: 'organization_closed'),
        ),
        AdminAccountsFailure.orgClosed,
      );
      expect(
        AdminAccountsFailure.fromCode('billing_limit_structures'),
        AdminAccountsFailure.structureLimit,
      );
      expect(
        AdminAccountsFailure.fromCode('member_not_found'),
        AdminAccountsFailure.orgNotFound,
      );
    });
  });

  group('écrans', () {
    late FakeAdminRepository admin;
    late FakeAdminAccountsRepository accounts;
    late FakeAdminOrgsRepository orgs;

    setUp(() {
      admin = FakeAdminRepository(admin: true, accounts: [adminAccount()]);
      accounts = FakeAdminAccountsRepository(
        accounts: {'u2': accountDetail(id: 'u2')},
      );
      orgs = FakeAdminOrgsRepository();
    });

    Future<void> openApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            admin: admin,
            adminAccounts: accounts,
            adminOrgs: orgs,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    void go(WidgetTester tester, String path) =>
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);

    Future<void> openOrg(WidgetTester tester, [String id = 'o1']) async {
      go(tester, AppRoutes.consoleOrganizations);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('console-org-open-$id')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('org-detail')), findsOneWidget);
    }

    Future<void> confirmWithReason(WidgetTester tester, String reason) async {
      await tester.enterText(
        find.byKey(const Key('account-action-reason')),
        reason,
      );
      await tester.tap(find.byKey(const Key('account-action-confirm')));
      await tester.pumpAndSettle();
    }

    Future<void> tapAction(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    testWidgets('fiche : propriétaire, membres, invitations, événements', (
      tester,
    ) async {
      await openApp(tester);
      await openOrg(tester);
      expect(find.text('Propriétaire : Awa Ouédraogo'), findsOneWidget);
      expect(find.byKey(const Key('org-member-u-issa')), findsOneWidget);
      expect(find.byKey(const Key('org-invitation-inv1')), findsOneWidget);
      expect(find.byKey(const Key('org-event-e1')), findsOneWidget);
      expect(find.text('Événements : 1 (à venir : 1)'), findsOneWidget);
    });

    testWidgets('modifier les informations avec un motif', (tester) async {
      await openApp(tester);
      await openOrg(tester);
      await tapAction(tester, 'org-edit');
      await tester.enterText(
        find.byKey(const Key('account-field-public_phone')),
        '70 44 55 66',
      );
      await confirmWithReason(tester, 'Demande au support');
      const expected =
          'update o1 Kwabo Événements Ouagadougou - 70 44 55 66 Demande au '
          'support false';
      expect(orgs.calls, [expected]);
    });

    testWidgets('membre : changer le rôle, puis retirer', (tester) async {
      await openApp(tester);
      await openOrg(tester);
      await tapAction(tester, 'org-member-u-issa');
      await tester.tap(find.byKey(const Key('member-action-role')));
      await tester.pumpAndSettle();
      expect(find.text('Passer contrôleur'), findsOneWidget);
      await confirmWithReason(tester, 'Changement d’équipe');
      expect(
        orgs.calls.last,
        'role o1 u-issa controller Changement d’équipe false',
      );

      await tapAction(tester, 'org-member-u-issa');
      await tester.tap(find.byKey(const Key('member-action-remove')));
      await tester.pumpAndSettle();
      await confirmWithReason(tester, 'Départ');
      expect(orgs.calls.last, 'remove o1 u-issa Départ false');
    });

    testWidgets('membre : transférer la propriété', (tester) async {
      await openApp(tester);
      await openOrg(tester);
      await tapAction(tester, 'org-member-u-issa');
      await tester.tap(find.byKey(const Key('member-action-transfer')));
      await tester.pumpAndSettle();
      await confirmWithReason(tester, 'Vente de la structure');
      expect(admin.assignCalls, [
        ('u-issa', 'o1', MemberRole.owner, 'Vente de la structure'),
      ]);
    });

    testWidgets('propriétaire : aucune action de membre', (tester) async {
      await openApp(tester);
      await openOrg(tester);
      await tapAction(tester, 'org-member-u-awa');
      expect(find.byKey(const Key('member-action-open')), findsOneWidget);
      expect(find.byKey(const Key('member-action-role')), findsNothing);
      expect(find.byKey(const Key('member-action-remove')), findsNothing);
    });

    testWidgets('ajouter un membre : recherche, rôle, motif', (tester) async {
      await openApp(tester);
      await openOrg(tester);
      await tapAction(tester, 'org-add-member');
      await tester.tap(find.byKey(const Key('add-member-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez un compte.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('add-member-search')), 'Awa');
      await tester.tap(find.byKey(const Key('add-member-find')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-member-result-u2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add-member-picked')), findsOneWidget);
      await tester.tap(find.byKey(const Key('add-member-role-manager')));
      await tester.enterText(
        find.byKey(const Key('add-member-reason')),
        'Renfort pour le festival',
      );
      await tester.tap(find.byKey(const Key('add-member-submit')));
      await tester.pumpAndSettle();
      expect(admin.assignCalls, [
        ('u2', 'o1', MemberRole.manager, 'Renfort pour le festival'),
      ]);
      expect(find.byKey(const Key('add-member-sheet')), findsNothing);
    });

    testWidgets('annuler une invitation', (tester) async {
      await openApp(tester);
      await openOrg(tester);
      await tapAction(tester, 'org-invitation-revoke-inv1');
      await confirmWithReason(tester, 'Code diffusé par erreur');
      expect(orgs.calls, ['revoke-invitation inv1 Code diffusé par erreur']);
    });

    testWidgets('fermer : conséquences affichées, nom à recopier', (
      tester,
    ) async {
      await openApp(tester);
      await openOrg(tester);
      await tapAction(tester, 'org-delete');
      expect(find.text('Fermer définitivement'), findsOneWidget);
      expect(
        find.textContaining('120 tickets non entrés annulés'),
        findsOneWidget,
      );
      expect(find.textContaining('37 détenteurs prévenus'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('account-field-confirm')),
        'Kwabo',
      );
      await confirmWithReason(tester, 'Fraude avérée');
      expect(orgs.calls, ['preview o1']);
      expect(
        find.text('Saisissez exactement le nom de la structure.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('account-field-confirm')),
        'kwabo événements',
      );
      await tester.tap(find.byKey(const Key('account-action-confirm')));
      await tester.pumpAndSettle();
      expect(orgs.calls.last, 'delete o1 kwabo événements Fraude avérée');
      expect(find.byKey(const Key('org-tag-closed')), findsOneWidget);
      expect(find.byKey(const Key('org-edit')), findsNothing);
      expect(find.byKey(const Key('org-delete')), findsNothing);
    });

    testWidgets('structure vide : corbeille, puis restaurer', (tester) async {
      orgs.preview = const OrgDeletePreview(trash: true);
      await openApp(tester);
      await openOrg(tester);
      await tapAction(tester, 'org-delete');
      expect(find.text('Mettre à la corbeille'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('account-field-confirm')),
        'Kwabo Événements',
      );
      await confirmWithReason(tester, 'Doublon');
      expect(find.byKey(const Key('org-tag-trashed')), findsOneWidget);
      expect(find.byKey(const Key('org-purge-due')), findsOneWidget);
      expect(find.byKey(const Key('org-restore')), findsOneWidget);
      expect(find.byKey(const Key('org-purge')), findsOneWidget);
      await tapAction(tester, 'org-restore');
      await confirmWithReason(tester, 'Supprimée par erreur');
      expect(orgs.calls.last, 'restore o1 Supprimée par erreur');
    });

    testWidgets('rôle support : modifier oui, supprimer non', (tester) async {
      accounts.meValue = AdminMe(
        role: AdminRole.support,
        permissions: permissionsOf(AdminRole.support),
        mfaEnrolled: true,
      );
      await openApp(tester);
      await openOrg(tester);
      expect(find.byKey(const Key('org-edit')), findsOneWidget);
      expect(find.byKey(const Key('org-delete')), findsNothing);
    });

    testWidgets('rôle modération : suspendre seulement', (tester) async {
      accounts.meValue = AdminMe(
        role: AdminRole.moderation,
        permissions: permissionsOf(AdminRole.moderation),
        mfaEnrolled: true,
      );
      await openApp(tester);
      await openOrg(tester);
      expect(find.byKey(const Key('org-suspend')), findsOneWidget);
      expect(find.byKey(const Key('org-edit')), findsNothing);
      expect(find.byKey(const Key('org-add-member')), findsNothing);
    });

    testWidgets('créer une structure depuis la liste', (tester) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleOrganizations);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-org-create')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('create-org-name')),
        'Faso Live',
      );
      await tester.enterText(
        find.byKey(const Key('create-org-reason')),
        'Contrat signé',
      );
      await tester.tap(find.byKey(const Key('create-org-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez le compte propriétaire.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('create-org-owner-search')),
        'Awa',
      );
      await tester.tap(find.byKey(const Key('create-org-owner-find')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-org-owner-result-u2')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('create-org-city')),
        'Koudougou',
      );
      await tester.tap(find.byKey(const Key('create-org-submit')));
      await tester.pumpAndSettle();
      expect(orgs.calls, ['create u2 Faso Live Koudougou Contrat signé false']);
      expect(find.byKey(const Key('org-detail')), findsOneWidget);
      expect(find.text('Faso Live'), findsWidgets);
    });

    testWidgets('créer une structure : quota du pack atteint', (tester) async {
      orgs.failure = AdminAccountsFailure.structureLimit;
      await openApp(tester);
      go(tester, AppRoutes.consoleOrganizations);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-org-create')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('create-org-owner-search')),
        'Awa',
      );
      await tester.tap(find.byKey(const Key('create-org-owner-find')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-org-owner-result-u2')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('create-org-name')),
        'Faso Live',
      );
      await tester.enterText(
        find.byKey(const Key('create-org-reason')),
        'Contrat signé',
      );
      await tester.tap(find.byKey(const Key('create-org-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('create-org-error')), findsOneWidget);
      expect(
        find.text(
          'Le pack du propriétaire ne permet pas une structure de plus.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('fiche d’un compte : créer une structure pour lui', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-account-open-u2')));
      await tester.pumpAndSettle();
      await tapAction(tester, 'account-create-org');
      expect(find.byKey(const Key('create-org-owner-picked')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('create-org-name')),
        'Awa Prod',
      );
      await tester.enterText(
        find.byKey(const Key('create-org-reason')),
        'Demande au guichet',
      );
      await tester.tap(find.byKey(const Key('create-org-submit')));
      await tester.pumpAndSettle();
      expect(orgs.calls.single, startsWith('create u2 Awa Prod'));
      expect(find.byKey(const Key('org-detail')), findsOneWidget);
    });

    testWidgets('corbeille : jours restants, restaurer', (tester) async {
      final now = DateTime.now().toUtc();
      orgs.trashItems.add(
        TrashItem(
          id: 'o9',
          name: 'Studio Vide',
          ownerName: 'Awa Ouédraogo',
          trashedAt: now.subtract(const Duration(days: 20)),
          purgeDueAt: now.add(const Duration(days: 10)),
        ),
      );
      await openApp(tester);
      go(tester, AppRoutes.console);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-nav-trash')), findsOneWidget);
      go(tester, AppRoutes.consoleTrash);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trash-o9')), findsOneWidget);
      expect(find.textContaining('Effacement dans 10 jours'), findsOneWidget);
      await tester.tap(find.byKey(const Key('trash-restore-o9')));
      await tester.pumpAndSettle();
      await confirmWithReason(tester, 'Supprimée par erreur');
      expect(orgs.calls, ['restore o9 Supprimée par erreur']);
      expect(find.byKey(const Key('trash-empty')), findsOneWidget);
    });

    testWidgets('liste : structure fermée, ni réactiver ni suspendre', (
      tester,
    ) async {
      admin.orgs
        ..clear()
        ..add(
          AdminOrganization(
            id: 'o3',
            name: 'Ancienne',
            slug: 'ancienne',
            active: false,
            createdAt: DateTime.utc(2026, 9),
            ownerName: 'Awa',
            members: 1,
            events: 2,
            tickets: 10,
            closedAt: DateTime.utc(2026, 11, 21),
          ),
        );
      await openApp(tester);
      go(tester, AppRoutes.consoleOrganizations);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-org-closed-o3')), findsOneWidget);
      expect(find.byKey(const Key('console-org-reactivate')), findsNothing);
      expect(find.byKey(const Key('console-org-suspend')), findsNothing);
    });
  });
}
