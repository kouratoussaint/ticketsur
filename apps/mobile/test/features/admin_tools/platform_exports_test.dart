import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/features/admin_tools/presentation/console_exports_page.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/platform/domain/platform_status.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart'
    show SharedFile;
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_accounts_repository.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_admin_tools_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_platform_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'toussaint@tikeo.bf');

  group('domaine', () {
    test('état de la plateforme lu', () {
      final status = PlatformStatus.fromJson(const {
        'maintenance': true,
        'message': '  Mise à jour  ',
        'writes_blocked': true,
        'signups_open': false,
      });
      expect(status.message, 'Mise à jour');
      expect(status.writesBlocked, isTrue);
      expect(status.signupsOpen, isFalse);
      expect(PlatformStatus.fromJson(const {}).signupsOpen, isTrue);
    });

    test('exports : permissions, CSV pour Excel, nom du fichier', () {
      const finance = AdminMe(
        role: AdminRole.finance,
        permissions: {AdminPermission.billing},
      );
      expect(ExportKind.invoices.allowedFor(finance), isTrue);
      expect(ExportKind.accounts.allowedFor(finance), isFalse);
      expect(ExportKind.journal.allowedFor(finance), isTrue);
      expect(ExportKind.journal.allowedFor(null), isFalse);

      final export = ConsoleExport.fromJson(ExportKind.accounts, const {
        'columns': ['id', 'name', 'deleted', 'inconnue'],
        'rows': [
          ['u1', 'Awa; Ouédraogo', false, null],
          ['u2', '=HYPERLINK("x")', true, 3],
        ],
        'truncated': true,
      });
      expect(export.truncated, isTrue);
      final bytes = buildExportCsv(AppLocalizationsFr(), export);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      final text = utf8.decode(bytes);
      expect(text.split('\r\n'), [
        'Identifiant;Nom;Supprimé;inconnue',
        'u1;"Awa; Ouédraogo";non;',
        'u2;"\'=HYPERLINK(""x"")";oui;3',
        '',
      ]);
      expect(
        exportFileName(ExportKind.events, DateTime(2026, 11, 21)),
        'Tikeo-evenements-2026-11-21.csv',
      );
    });
  });

  group('écrans', () {
    late FakePlatformRepository platform;
    late FakeAdminToolsRepository tools;
    late FakeAdminAccountsRepository accounts;
    late FakeAuthRepository auth;
    late List<SharedFile> shared;

    setUp(() {
      platform = FakePlatformRepository();
      tools = FakeAdminToolsRepository();
      accounts = FakeAdminAccountsRepository();
      auth = FakeAuthRepository(user: user);
      shared = [];
    });

    Future<void> openApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: auth,
            admin: FakeAdminRepository(admin: true),
            adminAccounts: accounts,
            adminTools: tools,
            platform: platform,
            shareFiles: (files, {text}) async => shared.addAll(files),
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    void go(WidgetTester tester, String path) =>
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);

    Future<void> tap(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    testWidgets('maintenance : bandeau avec le message', (tester) async {
      platform.value = const PlatformStatus(
        maintenance: true,
        message: 'Mise à jour du serveur',
        writesBlocked: true,
      );
      auth = FakeAuthRepository();
      await openApp(tester);
      expect(find.byKey(const Key('maintenance-banner')), findsOneWidget);
      expect(find.textContaining('Mise à jour du serveur'), findsOneWidget);
      expect(
        find.textContaining("le contrôle à l'entrée continue"),
        findsOneWidget,
      );
    });

    testWidgets('inscriptions fermées : code obligatoire et transmis', (
      tester,
    ) async {
      platform.value = const PlatformStatus(signupsOpen: false);
      auth = FakeAuthRepository();
      await openApp(tester);
      go(tester, AppRoutes.signUp);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sign-up-closed')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('sign-up-name')), 'Awa');
      await tester.enterText(
        find.byKey(const Key('sign-up-email')),
        'awa@exemple.bf',
      );
      await tester.enterText(
        find.byKey(const Key('sign-up-password')),
        'motdepasse12',
      );
      await tap(tester, 'sign-up-submit');
      expect(find.text("Code d'invitation obligatoire."), findsOneWidget);
      expect(auth.signUpCalls, isEmpty);

      await tester.enterText(
        find.byKey(const Key('sign-up-code')),
        'TSI-ABCD-EFGH-JKLM',
      );
      auth.nextSignUpFailure = AuthFailure.signupsClosed;
      await tap(tester, 'sign-up-submit');
      expect(auth.signUpCodes.single, 'TSI-ABCD-EFGH-JKLM');
      expect(
        find.text(
          "Les inscriptions sont fermées : il faut un code d'invitation "
          'valable.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('console : maintenance et inscriptions enregistrées', (
      tester,
    ) async {
      await openApp(tester);
      go(tester, AppRoutes.consoleSettings);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-maintenance-writes')), findsNothing);
      await tap(tester, 'console-maintenance');
      await tester.enterText(
        find.byKey(const Key('console-maintenance-message')),
        'Mise à jour',
      );
      await tap(tester, 'console-maintenance-writes');
      await tap(tester, 'console-signups-open');
      await tap(tester, 'console-platform-save');
      expect(tools.calls.last, 'platform true true false Mise à jour');
      expect(tools.saved?.signupsOpen, isFalse);
    });

    testWidgets('console : rôle sans réglages, lecture seule', (tester) async {
      accounts.meValue = AdminMe(
        role: AdminRole.support,
        permissions: permissionsOf(AdminRole.support),
        mfaEnrolled: true,
      );
      await openApp(tester);
      go(tester, AppRoutes.consoleSettings);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('console-platform')), findsOneWidget);
      expect(find.byKey(const Key('console-platform-save')), findsNothing);
    });

    testWidgets('exports : fichier CSV partagé, permissions', (tester) async {
      await openApp(tester);
      go(tester, AppRoutes.console);
      await tester.pumpAndSettle();
      await tap(tester, 'console-nav-exports');
      await tap(tester, 'console-export-accounts');
      expect(tools.calls.last, 'export accounts');
      expect(shared.single.name, startsWith('Tikeo-comptes-'));
      expect(shared.single.mimeType, 'text/csv');
      expect(find.text('2 lignes exportées'), findsOneWidget);
    });

    testWidgets('exports : rôle finance, factures seulement', (tester) async {
      accounts.meValue = AdminMe(
        role: AdminRole.finance,
        permissions: permissionsOf(AdminRole.finance),
        mfaEnrolled: true,
      );
      await openApp(tester);
      go(tester, AppRoutes.consoleExports);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ListTile>(find.byKey(const Key('console-export-accounts')))
            .enabled,
        isFalse,
      );
      await tap(tester, 'console-export-invoices');
      expect(tools.calls.last, 'export invoices');
    });
  });
}
