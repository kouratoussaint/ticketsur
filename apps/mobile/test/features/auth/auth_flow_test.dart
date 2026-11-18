import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/auth/presentation/sign_in_page.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/welcome/welcome_page.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository auth;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSignIn(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('welcome-sign-in')));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    String email = 'agent@exemple.bf',
    String password = 'motdepasse-solide',
  }) async {
    await tester.enterText(find.byKey(const Key('sign-in-email')), email);
    await tester.enterText(find.byKey(const Key('sign-in-password')), password);
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
  }

  setUp(() => auth = FakeAuthRepository());

  group('connexion (S03)', () {
    testWidgets('champs vides : messages de validation, aucun appel', (
      tester,
    ) async {
      await openSignIn(tester);
      await tester.tap(find.byKey(const Key('sign-in-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Saisissez votre adresse e-mail'), findsOneWidget);
      expect(find.text('Saisissez votre mot de passe'), findsOneWidget);
      expect(auth.signInCalls, isEmpty);
    });

    testWidgets('adresse mal formée refusée localement', (tester) async {
      await openSignIn(tester);
      await fillAndSubmit(tester, email: 'agent@exemple');
      expect(find.text('Adresse e-mail invalide'), findsOneWidget);
      expect(auth.signInCalls, isEmpty);
    });

    testWidgets('succès : accueil connecté avec l’adresse', (tester) async {
      await openSignIn(tester);
      await fillAndSubmit(tester, email: '  agent@exemple.bf ');
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Connecté : agent@exemple.bf'), findsOneWidget);
      expect(auth.signInCalls.single.password, 'motdepasse-solide');
    });

    final failures = <AuthFailure, String>{
      AuthFailure.invalidCredentials:
          'Adresse e-mail ou mot de passe incorrect.',
      AuthFailure.emailNotConfirmed:
          'Adresse e-mail non confirmée. Ouvrez le lien reçu par e-mail.',
      AuthFailure.rateLimited:
          'Trop de tentatives. Patientez une minute avant de réessayer.',
      AuthFailure.network:
          'Connexion au serveur impossible. Vérifiez le réseau et réessayez.',
      AuthFailure.unknown: 'Une erreur est survenue. Réessayez.',
    };
    for (final MapEntry(key: failure, value: message) in failures.entries) {
      testWidgets('échec ${failure.name} : message, reste sur la page', (
        tester,
      ) async {
        auth.nextSignInFailure = failure;
        await openSignIn(tester);
        await fillAndSubmit(tester);
        expect(find.text(message), findsOneWidget);
        expect(find.byType(SignInPage), findsOneWidget);
        expect(auth.currentUser, isNull);
      });
    }

    testWidgets('un seul envoi pendant la vérification', (tester) async {
      auth.signInGate = Completer<void>();
      await openSignIn(tester);
      await tester.enterText(
        find.byKey(const Key('sign-in-email')),
        'agent@exemple.bf',
      );
      await tester.enterText(
        find.byKey(const Key('sign-in-password')),
        'motdepasse-solide',
      );
      await tester.tap(find.byKey(const Key('sign-in-submit')));
      await tester.pump();
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('sign-in-submit')),
      );
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      auth.signInGate!.complete();
      await tester.pumpAndSettle();
      expect(auth.signInCalls, hasLength(1));
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('afficher / masquer le mot de passe', (tester) async {
      await openSignIn(tester);
      EditableText field() => tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('sign-in-password')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Afficher le mot de passe'));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });
  });

  group('mot de passe oublié (S04)', () {
    Future<void> openForgot(WidgetTester tester) async {
      await openSignIn(tester);
      await tester.tap(find.byKey(const Key('sign-in-forgot')));
      await tester.pumpAndSettle();
    }

    testWidgets('confirmation neutre, que le compte existe ou non', (
      tester,
    ) async {
      await openForgot(tester);
      await tester.enterText(
        find.byKey(const Key('forgot-email')),
        'inconnu@exemple.bf',
      );
      await tester.tap(find.byKey(const Key('forgot-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Si un compte existe pour inconnu@exemple.bf, un e-mail de '
          "réinitialisation vient d'être envoyé.",
        ),
        findsOneWidget,
      );
      expect(auth.resetCalls, ['inconnu@exemple.bf']);
    });

    testWidgets('trop de demandes : message d’attente', (tester) async {
      auth.nextResetFailure = AuthFailure.rateLimited;
      await openForgot(tester);
      await tester.enterText(
        find.byKey(const Key('forgot-email')),
        'agent@exemple.bf',
      );
      await tester.tap(find.byKey(const Key('forgot-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Trop de tentatives. Patientez une minute avant de réessayer.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('forgot-sent')), findsNothing);
    });
  });

  group('session', () {
    testWidgets('déjà connecté au démarrage : accueil connecté direct', (
      tester,
    ) async {
      auth = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
      );
      await pumpApp(tester);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('déconnexion : retour à l’accueil public', (tester) async {
      auth = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
      );
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('home-sign-out')));
      await tester.pumpAndSettle();
      expect(auth.signOutCalls, 1);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('session expirée ou révoquée : sortie immédiate (AT-22)', (
      tester,
    ) async {
      auth = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
      );
      await pumpApp(tester);
      auth.expireSession();
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(SignInPage), findsOneWidget);
    });
  });
}
