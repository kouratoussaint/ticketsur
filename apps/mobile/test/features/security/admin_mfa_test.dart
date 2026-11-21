import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/security/data/supabase_admin_mfa_repository.dart';
import 'package:ticketsur/features/security/domain/admin_mfa.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_mfa_repository.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_organization_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'admin@exemple.bf');

  test('erreurs traduites, format du code', () {
    expect(
      mapMfaError(
        const supabase.AuthException(
          'Invalid',
          code: 'mfa_verification_failed',
        ),
      ),
      MfaFailure.invalidCode,
    );
    expect(
      mapMfaError(
        const supabase.PostgrestException(message: 'recovery_rate_limited'),
      ),
      MfaFailure.rateLimited,
    );
    expect(isTotpCode(' 123456 '), isTrue);
    expect(isTotpCode('12345'), isFalse);
    expect(
      AdminMfaStatus.fromJson(const {
        'enrolled': true,
        'aal': 'aal2',
        'recovery_codes_left': 3,
      }).aal2,
      isTrue,
    );
  });

  late FakeAdminMfaRepository mfa;
  late FakeAdminRepository admin;

  setUp(() {
    mfa = FakeAdminMfaRepository();
    admin = FakeAdminRepository(admin: true)..mfa = mfa;
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
          admin: admin,
          mfa: mfa,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Profil → activer : QR, mauvais code, bon code, codes de '
      'secours une fois', (tester) async {
    await openApp(tester);
    await go(tester, AppRoutes.profile);
    final row = find.byKey(const Key('profile-admin-mfa'));
    await tester.scrollUntilVisible(
      row,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Conseillée pour la console'), findsOneWidget);
    await tapVisible(tester, row);

    await tapVisible(tester, find.byKey(const Key('mfa-enable')));
    expect(find.byKey(const Key('mfa-qr')), findsOneWidget);
    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('mfa-code')), '000000');
    await tapVisible(tester, find.byKey(const Key('mfa-verify')));
    expect(
      find.text(
        'Code incorrect : saisissez les 6 chiffres affichés maintenant.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('mfa-code')), '123456');
    await tapVisible(tester, find.byKey(const Key('mfa-verify')));
    expect(mfa.calls, containsAllInOrder(['verify factor-1', 'codes']));
    expect(find.byKey(const Key('mfa-codes')), findsOneWidget);
    expect(find.text('ABCDE-FGHJK'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('mfa-codes-done')));
    // Les codes ne sont plus affichés.
    expect(find.text('ABCDE-FGHJK'), findsNothing);
    expect(find.byKey(const Key('mfa-on')), findsOneWidget);
    expect(find.text('8 codes de secours restants'), findsOneWidget);
    expect(find.byKey(const Key('mfa-disable')), findsOneWidget);
  });

  testWidgets('console : code demandé une fois, puis vue d’ensemble', (
    tester,
  ) async {
    mfa.enrolled = true;
    await openApp(tester);
    await go(tester, AppRoutes.console);
    expect(find.byKey(const Key('console-mfa')), findsOneWidget);
    expect(find.byKey(const Key('console-overview')), findsNothing);
    expect(find.byKey(const Key('console-nav-support')), findsNothing);

    await tester.enterText(find.byKey(const Key('console-mfa-code')), '123456');
    await tapVisible(tester, find.byKey(const Key('console-mfa-verify')));
    expect(mfa.calls, contains('verify session'));
    expect(find.byKey(const Key('console-mfa')), findsNothing);
    expect(find.byKey(const Key('console-overview')), findsOneWidget);
  });

  testWidgets('console : code de secours, refusé puis accepté', (tester) async {
    mfa
      ..enrolled = true
      ..codes = ['ABCDE-FGHJK'];
    await openApp(tester);
    await go(tester, AppRoutes.console);
    await tapVisible(tester, find.byKey(const Key('console-mfa-recovery')));
    await tester.enterText(
      find.byKey(const Key('mfa-recovery-code')),
      'zzzzz-zzzzz',
    );
    await tester.tap(find.byKey(const Key('mfa-recovery-submit')));
    await tester.pumpAndSettle();
    expect(
      find.text('Code de secours inconnu ou déjà utilisé.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('mfa-recovery-code')),
      'abcde-fghjk',
    );
    await tester.tap(find.byKey(const Key('mfa-recovery-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('console-overview')), findsOneWidget);
    expect(find.textContaining('Double authentification retirée'), findsOne);
  });

  testWidgets('compte non administrateur : pas de ligne', (tester) async {
    admin = FakeAdminRepository();
    await openApp(tester);
    await go(tester, AppRoutes.profile);
    expect(find.byKey(const Key('profile-admin-mfa')), findsNothing);
    expect(mfa.calls, isEmpty);
  });
}
