import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/auth_widgets.dart';
import 'package:ticketsur/features/auth/presentation/new_password_page.dart';
import 'package:ticketsur/features/home/home_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';

/// Écrans de connexion et de compte (direction artistique, écrans A à L).
void main() {
  late FakeAuthRepository auth;
  late int mailboxCalls;

  setUp(() {
    auth = FakeAuthRepository();
    mailboxCalls = 0;
  });

  Future<void> pumpApp(WidgetTester tester, {bool mailbox = true}) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await appOverrides(auth: auth),
          mailboxOpenerProvider.overrideWithValue(() async {
            mailboxCalls++;
            return mailbox;
          }),
        ],
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  void go(WidgetTester tester, String location) =>
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(location);

  group('solidité du mot de passe', () {
    test('de faible à excellent', () {
      expect(passwordStrength(''), 0);
      expect(passwordStrength('abc'), 1);
      expect(passwordStrength('abcdefgh'), 1);
      expect(passwordStrength('abcdef12'), 2);
      expect(passwordStrength('abcdef12!'), 3);
      expect(passwordStrength('Abcdef12!xyz'), 4);
    });

    testWidgets('indicateur sous le mot de passe de l’inscription', (
      tester,
    ) async {
      await pumpApp(tester);
      go(tester, AppRoutes.signUp);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('password-strength')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('sign-up-password')),
        'abcdef12',
      );
      await tester.pump();
      expect(find.text('Moyen'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('sign-up-password')),
        'Abcdef12!xyz',
      );
      await tester.pump();
      expect(find.text('Excellent'), findsOneWidget);
    });
  });

  group('confirmation de l’adresse (F)', () {
    testWidgets('étapes, messagerie, renvoi après 60 s', (tester) async {
      auth.signUpNeedsConfirmation = true;
      await pumpApp(tester);
      go(tester, AppRoutes.signUp);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('sign-up-name')), 'Awa');
      await tester.enterText(
        find.byKey(const Key('sign-up-email')),
        'awa@faso.bf',
      );
      await tester.enterText(
        find.byKey(const Key('sign-up-password')),
        'motdepasse1',
      );
      await tester.ensureVisible(find.byKey(const Key('sign-up-submit')));
      await tester.tap(find.byKey(const Key('sign-up-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sign-up-confirm')), findsOneWidget);
      expect(find.text('awa@faso.bf'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sign-up-open-mailbox')));
      await tester.pump();
      expect(mailboxCalls, 1);

      // Renvoi bloqué 60 s après le premier envoi.
      final resend = find.byKey(const Key('auth-resend'));
      await tester.ensureVisible(resend);
      expect(tester.widget<TextButton>(resend).onPressed, isNull);
      expect(find.textContaining('dans 60 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
      expect(tester.widget<TextButton>(resend).onPressed, isNotNull);
      await tester.tap(resend);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(auth.resendCalls, ['awa@faso.bf']);
      expect(find.text('E-mail renvoyé.'), findsOneWidget);
      // Toast et compte à rebours : on laisse le temps s'écouler.
      await tester.pump(const Duration(seconds: 61));
    });
  });

  group('mot de passe oublié (G, H)', () {
    testWidgets('lien envoyé : rien reçu, messagerie absente', (tester) async {
      await pumpApp(tester, mailbox: false);
      go(tester, AppRoutes.forgotPassword);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('forgot-email')),
        'awa@faso.bf',
      );
      await tester.tap(find.byKey(const Key('forgot-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('forgot-nothing')), findsOneWidget);
      await tester.tap(find.byKey(const Key('forgot-open-mailbox')));
      await tester.pump();
      expect(mailboxCalls, 1);
      expect(
        find.text("Ouvrez votre messagerie pour trouver l'e-mail de Tikéo."),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
    });
  });

  group('nouveau mot de passe (I)', () {
    testWidgets('le lien de l’e-mail ouvre l’écran ; règles ; enregistrer', (
      tester,
    ) async {
      auth = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'awa@faso.bf'),
      );
      await pumpApp(tester);
      auth.recovery.add(null);
      await tester.pumpAndSettle();
      expect(find.byType(NewPasswordPage), findsOneWidget);

      await tester.enterText(find.byKey(const Key('new-password')), 'court');
      await tester.enterText(
        find.byKey(const Key('new-password-confirm')),
        'autre',
      );
      await tester.tap(find.byKey(const Key('new-password-submit')));
      await tester.pumpAndSettle();
      expect(find.text('8 caractères au moins.'), findsWidgets);
      expect(find.text('Les deux mots de passe diffèrent.'), findsOneWidget);
      expect(auth.newPasswords, isEmpty);

      await tester.enterText(
        find.byKey(const Key('new-password')),
        'Nouveau2026!',
      );
      await tester.enterText(
        find.byKey(const Key('new-password-confirm')),
        'Nouveau2026!',
      );
      await tester.tap(find.byKey(const Key('new-password-submit')));
      await tester.pumpAndSettle();
      expect(auth.newPasswords, ['Nouveau2026!']);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('refus du serveur : bandeau, on reste sur l’écran', (
      tester,
    ) async {
      auth = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'awa@faso.bf'),
      )..nextNewPasswordFailure = AuthFailure.samePassword;
      await pumpApp(tester);
      auth.recovery.add(null);
      await tester.pumpAndSettle();
      for (final key in ['new-password', 'new-password-confirm']) {
        await tester.enterText(find.byKey(Key(key)), 'Nouveau2026!');
      }
      await tester.tap(find.byKey(const Key('new-password-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth-error')), findsOneWidget);
      expect(find.byType(NewPasswordPage), findsOneWidget);
    });
  });
}
