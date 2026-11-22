import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin_accounts/data/supabase_admin_accounts_repository.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_accounts_repository.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'toussaint@tikeo.bf');

  group('domaine', () {
    test('profil d’administration lu, permissions par rôle', () {
      final me = AdminMe.fromJson(const {
        'role': 'support',
        'permissions': ['accounts', 'organizations', 'support'],
        'mfa_enrolled': true,
        'notify_users': true,
      });
      expect(me.role, AdminRole.support);
      expect(me.can(AdminPermission.accounts), isTrue);
      expect(me.can(AdminPermission.admins), isFalse);
      expect(me.notifyUsers, isTrue);
      expect(me.adminIssueTickets, isFalse);
      expect(AdminRole.fromWire('inconnu'), isNull);
      expect(AdminRole.fromWire('super'), AdminRole.superAdmin);
    });

    test('fiche d’un compte lue', () {
      final detail = AccountDetail.fromJson(const {
        'id': 'u2',
        'display_name': 'Awa',
        'email': 'awa@exemple.bf',
        'phone': '+22670112233',
        'status': 'active',
        'created_at': '2026-11-01T10:00:00Z',
        'must_change_password': true,
        'admin_role': 'finance',
        'mfa_enrolled': false,
        'organizations': [
          {'id': 'o1', 'name': 'Kwabo', 'role': 'owner', 'status': 'active'},
        ],
        'wallet_tickets': 3,
        'support_requests': 2,
        'support_open': 1,
        'devices': [
          {
            'label': 'Tecno Spark',
            'platform': 'android',
            'app_build': 160,
            'last_seen_at': '2026-11-20T08:00:00Z',
          },
        ],
        'actions': [
          {
            'action': 'admin.account_updated',
            'at': '2026-11-20T09:00:00Z',
            'reason': 'Demande au support',
            'by': 'Toussaint',
          },
        ],
      });
      expect(detail.adminRole, AdminRole.finance);
      expect(detail.mustChangePassword, isTrue);
      expect(detail.organizations.single.organizationActive, isTrue);
      expect(detail.walletTickets, 3);
      expect(detail.supportOpen, 1);
      expect(detail.devices.single.appBuild, 160);
      expect(detail.actions.single.reason, 'Demande au support');
      expect(detail.deleted, isFalse);
    });

    test('erreurs du serveur et de la fonction traduites', () {
      expect(
        mapAdminAccountsError(
          const supabase.PostgrestException(message: 'admin_role_forbidden'),
        ),
        AdminAccountsFailure.roleForbidden,
      );
      expect(
        mapAdminAccountsError(
          const supabase.PostgrestException(message: 'last_super_admin'),
        ),
        AdminAccountsFailure.lastSuperAdmin,
      );
      expect(
        mapAdminAccountsError(
          const supabase.FunctionException(
            status: 409,
            details: {'ok': false, 'code': 'account_email_taken'},
          ),
        ),
        AdminAccountsFailure.emailTaken,
      );
      expect(
        mapAdminAccountsError(const supabase.FunctionException(status: 500)),
        AdminAccountsFailure.unknown,
      );
      expect(
        AdminAccountsFailure.fromCode('admin_mfa_needed'),
        AdminAccountsFailure.mfaNeeded,
      );
    });
  });

  group('écrans', () {
    late FakeAdminRepository admin;
    late FakeAdminAccountsRepository accounts;
    late FakeAuthRepository auth;

    setUp(() {
      admin = FakeAdminRepository(
        admin: true,
        accounts: [adminAccount(name: 'Awa')],
      );
      accounts = FakeAdminAccountsRepository(
        accounts: {
          'u2': accountDetail(id: 'u2', name: 'Awa', email: 'u2@faso.bf'),
        },
      );
      auth = FakeAuthRepository(user: user);
    });

    Future<void> openApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: auth,
            admin: admin,
            adminAccounts: accounts,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    void go(WidgetTester tester, String path) =>
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);

    Future<void> openAccount(WidgetTester tester, String id) async {
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('console-account-open-$id')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-detail')), findsOneWidget);
    }

    Future<void> confirmWithReason(WidgetTester tester, String reason) async {
      await tester.enterText(
        find.byKey(const Key('account-action-reason')),
        reason,
      );
      await tester.tap(find.byKey(const Key('account-action-confirm')));
      await tester.pumpAndSettle();
    }

    testWidgets('console : rôle affiché, entrée « Réglages »', (tester) async {
      await openApp(tester);
      go(tester, AppRoutes.console);
      await tester.pumpAndSettle();
      expect(find.text('Votre rôle : Super administrateur'), findsOneWidget);
      expect(find.byKey(const Key('console-nav-settings')), findsOneWidget);
    });

    testWidgets('fiche : modifier le nom avec motif obligatoire', (
      tester,
    ) async {
      await openApp(tester);
      await openAccount(tester, 'u2');
      expect(find.text('u2@faso.bf'), findsOneWidget);
      await tester.tap(find.byKey(const Key('account-edit')));
      await tester.pumpAndSettle();
      // Sans motif : refusé.
      await tester.tap(find.byKey(const Key('account-action-confirm')));
      await tester.pumpAndSettle();
      expect(accounts.calls, isEmpty);
      await tester.enterText(
        find.byKey(const Key('account-field-name')),
        'Awa Sawadogo',
      );
      // Réglage « Prévenir » désactivé : case décochée d'avance.
      final notify = tester.widget<CheckboxListTile>(
        find.byKey(const Key('account-action-notify')),
      );
      expect(notify.value, isFalse);
      await confirmWithReason(tester, 'Demande au support');
      expect(accounts.calls, [
        'update u2 Awa Sawadogo +22670112233 Demande au support false',
      ]);
      expect(find.text('Awa Sawadogo'), findsWidgets);
    });

    testWidgets('fiche : mot de passe provisoire affiché une fois', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await openApp(tester);
      await openAccount(tester, 'u2');
      await tester.ensureVisible(find.byKey(const Key('account-password')));
      await tester.tap(find.byKey(const Key('account-password')));
      await tester.pumpAndSettle();
      await confirmWithReason(tester, 'Téléphone perdu');
      expect(accounts.calls.single, startsWith('password u2 Téléphone perdu'));
      expect(find.byKey(const Key('temporary-password')), findsOneWidget);
      expect(find.text('AAAA-BBBB-CCCC'), findsOneWidget);
      await tester.tap(find.byKey(const Key('temporary-password-copy')));
      await tester.pump();
      expect(copied, 'AAAA-BBBB-CCCC');
      await tester.tap(find.byKey(const Key('temporary-password-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('temporary-password')), findsNothing);
    });

    testWidgets('fiche : supprimer maintenant exige l’adresse exacte', (
      tester,
    ) async {
      await openApp(tester);
      await openAccount(tester, 'u2');
      await tester.ensureVisible(find.byKey(const Key('account-delete-now')));
      await tester.tap(find.byKey(const Key('account-delete-now')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('account-field-confirm')),
        'autre@faso.bf',
      );
      await confirmWithReason(tester, 'Demande écrite');
      expect(accounts.calls, isEmpty);
      expect(
        find.text("Saisissez exactement l'adresse e-mail du compte."),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('account-field-confirm')),
        'U2@faso.bf',
      );
      await tester.tap(find.byKey(const Key('account-action-confirm')));
      await tester.pumpAndSettle();
      expect(accounts.calls, ['delete u2 U2@faso.bf Demande écrite']);
    });

    testWidgets('fiche : donner un rôle d’administration', (tester) async {
      await openApp(tester);
      await openAccount(tester, 'u2');
      await tester.ensureVisible(find.byKey(const Key('account-role')));
      await tester.tap(find.byKey(const Key('account-role')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-role-moderation')));
      await tester.pumpAndSettle();
      await confirmWithReason(tester, 'Renfort modération');
      expect(accounts.calls, ['role u2 moderation Renfort modération']);
    });

    testWidgets('rôle support : ni suppression immédiate ni rôles', (
      tester,
    ) async {
      accounts.meValue = AdminMe(
        role: AdminRole.support,
        permissions: permissionsOf(AdminRole.support),
        mfaEnrolled: true,
      );
      await openApp(tester);
      await openAccount(tester, 'u2');
      expect(find.byKey(const Key('account-edit')), findsOneWidget);
      expect(find.byKey(const Key('account-delete-now')), findsNothing);
      expect(find.byKey(const Key('account-role')), findsNothing);
    });

    testWidgets('compte d’un administrateur : protégé pour le support', (
      tester,
    ) async {
      accounts
        ..meValue = AdminMe(
          role: AdminRole.support,
          permissions: permissionsOf(AdminRole.support),
          mfaEnrolled: true,
        )
        ..accounts['u2'] = accountDetail(
          id: 'u2',
          name: 'Awa',
          adminRole: AdminRole.finance,
        );
      await openApp(tester);
      await openAccount(tester, 'u2');
      expect(find.byKey(const Key('account-role-tag')), findsOneWidget);
      expect(find.byKey(const Key('account-edit')), findsNothing);
      expect(find.byKey(const Key('account-password')), findsNothing);
    });

    testWidgets('créer un compte : mot de passe provisoire puis fiche', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-account-create')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-account-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Adresse e-mail invalide.'), findsOneWidget);
      expect(accounts.calls, isEmpty);

      await tester.enterText(
        find.byKey(const Key('create-account-email')),
        'Promoteur@Faso.bf',
      );
      await tester.enterText(
        find.byKey(const Key('create-account-name')),
        'Issa Kaboré',
      );
      await tester.enterText(
        find.byKey(const Key('create-account-reason')),
        'Contrat signé',
      );
      await tester.tap(find.byKey(const Key('create-account-submit')));
      await tester.pumpAndSettle();
      expect(accounts.calls, [
        'create Promoteur@Faso.bf Issa Kaboré - Contrat signé',
      ]);
      expect(find.byKey(const Key('temporary-password')), findsOneWidget);
      expect(find.text('promoteur@faso.bf'), findsOneWidget);
      await tester.tap(find.byKey(const Key('temporary-password-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-detail')), findsOneWidget);
      expect(find.text('Issa Kaboré'), findsWidgets);
    });

    testWidgets('créer un compte : e-mail déjà utilisé', (tester) async {
      accounts.failure = AdminAccountsFailure.emailTaken;
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-account-create')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('create-account-email')),
        'awa@faso.bf',
      );
      await tester.enterText(
        find.byKey(const Key('create-account-name')),
        'Awa',
      );
      await tester.enterText(
        find.byKey(const Key('create-account-reason')),
        'Contrat signé',
      );
      await tester.tap(find.byKey(const Key('create-account-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('create-account-error')), findsOneWidget);
      expect(
        find.text('Un compte utilise déjà cette adresse e-mail.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('temporary-password')), findsNothing);
    });

    testWidgets('rôle finance : pas de bouton « Créer un compte »', (
      tester,
    ) async {
      accounts.meValue = AdminMe(
        role: AdminRole.finance,
        permissions: permissionsOf(AdminRole.finance),
        mfaEnrolled: true,
      );
      await openApp(tester);
      go(tester, AppRoutes.consoleAccounts);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-account-create')), findsNothing);
    });

    testWidgets('réglages : interrupteurs et administrateurs', (tester) async {
      accounts.admins = [
        const PlatformAdmin(
          id: 'u2',
          displayName: 'Awa',
          email: 'u2@faso.bf',
          role: AdminRole.support,
          mfaEnrolled: true,
        ),
      ];
      await openApp(tester);
      go(tester, AppRoutes.consoleSettings);
      await tester.pumpAndSettle();
      expect(find.text('Votre rôle : Super administrateur'), findsOneWidget);
      await tester.tap(find.byKey(const Key('console-setting-notify')));
      await tester.pumpAndSettle();
      expect(accounts.calls, ['settings true null']);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('console-setting-notify')),
            )
            .value,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('console-setting-issue')));
      await tester.pumpAndSettle();
      expect(accounts.calls.last, 'settings null true');
      // La carte « Plateforme » (lot 4-11d) précède la liste.
      await tester.scrollUntilVisible(
        find.byKey(const Key('console-admin-u2')),
        300,
      );
      await tester.pumpAndSettle();
      expect(find.text('Support · u2@faso.bf'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('console-admin-u2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('console-admin-u2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-detail')), findsOneWidget);
    });

    testWidgets('réglages : lecture seule hors super administrateur', (
      tester,
    ) async {
      accounts.meValue = AdminMe(
        role: AdminRole.moderation,
        permissions: permissionsOf(AdminRole.moderation),
        mfaEnrolled: true,
      );
      await openApp(tester);
      go(tester, AppRoutes.consoleSettings);
      await tester.pumpAndSettle();
      expect(
        find.text('Seul un super administrateur modifie ces réglages.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('console-setting-notify')));
      await tester.pumpAndSettle();
      expect(accounts.calls, isEmpty);
    });

    testWidgets('réglage « Prévenir » actif : case cochée d’avance', (
      tester,
    ) async {
      accounts.meValue = AdminMe(
        role: AdminRole.superAdmin,
        permissions: permissionsOf(AdminRole.superAdmin),
        mfaEnrolled: true,
        notifyUsers: true,
      );
      await openApp(tester);
      await openAccount(tester, 'u2');
      await tester.ensureVisible(find.byKey(const Key('account-sign-out')));
      await tester.tap(find.byKey(const Key('account-sign-out')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('account-action-notify')),
            )
            .value,
        isTrue,
      );
      await confirmWithReason(tester, 'Appareil volé');
      expect(accounts.calls, ['signout u2 Appareil volé true']);
    });

    testWidgets('mot de passe provisoire : choisi avant tout le reste', (
      tester,
    ) async {
      admin.admin = false;
      accounts.mustChange = true;
      await openApp(tester);
      expect(find.byKey(const Key('password-change-gate')), findsOneWidget);
      expect(find.text('Choisissez votre mot de passe'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('new-password')),
        'Kwabo-2026-sur',
      );
      await tester.enterText(
        find.byKey(const Key('new-password-confirm')),
        'Kwabo-2026-sur',
      );
      await tester.tap(find.byKey(const Key('new-password-submit')));
      await tester.pumpAndSettle();
      expect(auth.newPasswords, ['Kwabo-2026-sur']);
      expect(accounts.calls, ['clear-must-change']);
      expect(find.byKey(const Key('password-change-gate')), findsNothing);
    });

    testWidgets('mot de passe provisoire : « Retour » déconnecte', (
      tester,
    ) async {
      accounts.mustChange = true;
      await openApp(tester);
      await tester.tap(find.byTooltip('Retour').first);
      await tester.pumpAndSettle();
      expect(auth.signOutCalls, 1);
      expect(find.byKey(const Key('password-change-gate')), findsNothing);
    });
  });
}
