import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/design_system/widgets/animated_count.dart';
import 'package:ticketsur/design_system/widgets/success_burst.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_sound_player.dart';
import '../helpers/pump_app.dart';

void main() {
  group('retours sonores et haptiques', () {
    late FakeSoundPlayer sounds;
    late ProviderContainer container;

    Future<void> setUpContainer([Map<String, Object> prefs = const {}]) async {
      SharedPreferences.setMockInitialValues(prefs);
      final preferences = await SharedPreferences.getInstance();
      sounds = FakeSoundPlayer();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          soundPlayerProvider.overrideWithValue(sounds),
        ],
      );
      addTearDown(container.dispose);
    }

    test('un son distinct par verdict', () async {
      await setUpContainer();
      final feedback = container.read(feedbackProvider)
        ..verdict(VerdictKind.admitted)
        ..verdict(VerdictKind.refused)
        ..verdict(VerdictKind.indeterminate)
        ..verdict(VerdictKind.verifying);
      await Future<void>.delayed(Duration.zero);
      expect(sounds.played, [
        UiSound.admitted,
        UiSound.refused,
        UiSound.indeterminate,
      ]);
      feedback
        ..success()
        ..error()
        ..tap();
      await Future<void>.delayed(Duration.zero);
      expect(sounds.played.skip(3), [
        UiSound.success,
        UiSound.error,
        UiSound.tap,
      ]);
    });

    test('réglages respectés et mémorisés sur l’appareil', () async {
      await setUpContainer();
      await container
          .read(feedbackSettingsProvider.notifier)
          .update(const FeedbackSettings(scanSounds: false, uiSounds: false));
      container.read(feedbackProvider)
        ..verdict(VerdictKind.admitted)
        ..success()
        ..preview(UiSound.refused); // l'écoute ignore les interrupteurs
      await Future<void>.delayed(Duration.zero);
      expect(sounds.played, [UiSound.refused]);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getBool('feedback.scan_sounds'), isFalse);
      expect(prefs.getBool('feedback.ui_sounds'), isFalse);
      expect(prefs.getBool('feedback.haptics'), isTrue);
    });

    test('réglages relus au démarrage', () async {
      await setUpContainer({'feedback.haptics': false});
      expect(container.read(feedbackSettingsProvider).haptics, isFalse);
      expect(container.read(feedbackSettingsProvider).scanSounds, isTrue);
    });

    test('chaque son existe dans les assets', () {
      for (final sound in UiSound.values) {
        expect(sound.asset, 'sounds/${sound.name}.wav');
      }
    });
  });

  group('dans l’application', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');

    testWidgets('clic doux au changement d’onglet ; onglet « Tickets »', (
      tester,
    ) async {
      final sounds = FakeSoundPlayer();
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            sounds: sounds,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      final tickets = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Tickets'),
      );
      expect(tickets, findsOneWidget);
      await tester.tap(tickets);
      await tester.pumpAndSettle();
      expect(sounds.played, [UiSound.tap]);
    });

    testWidgets('réglages dans le Profil : interrupteurs et écoute', (
      tester,
    ) async {
      final sounds = FakeSoundPlayer();
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            sounds: sounds,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Profil'),
        ),
      );
      await tester.pumpAndSettle();
      // Réglages déplacés dans Paramètres (lot 3c).
      final settings = find.byKey(const Key('profile-settings'));
      await tester.ensureVisible(settings);
      await tester.pumpAndSettle();
      await tester.tap(settings);
      await tester.pumpAndSettle();
      sounds.played.clear();

      final preview = find.byKey(const Key('preview-admitted'));
      await tester.ensureVisible(preview);
      await tester.pumpAndSettle();
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(sounds.played, [UiSound.admitted]);

      final uiSounds = find.byKey(const Key('feedback-ui-sounds'));
      await tester.ensureVisible(uiSounds);
      await tester.pumpAndSettle();
      await tester.tap(uiSounds);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(uiSounds).value, isFalse);
    });
  });

  group('composants animés', () {
    testWidgets('message de réussite : texte et son', (tester) async {
      final sounds = FakeSoundPlayer();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            soundPlayerProvider.overrideWithValue(sounds),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Toaster.of(context).success('Enregistré'),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('Enregistré'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(sounds.played, [UiSound.success]);
    });

    testWidgets('compteur animé : arrive à la valeur finale', (tester) async {
      await tester.pumpApp(
        AnimatedCount(
          value: 42,
          builder: (context, value) => Text('$value tickets'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('42 tickets'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('42 tickets'), findsOneWidget);
    });

    testWidgets('éclat de réussite : se termine (pas d’animation infinie)', (
      tester,
    ) async {
      await tester.pumpApp(const SuccessBurst());
      await tester.pumpAndSettle();
      expect(find.byType(SuccessBurst), findsOneWidget);
    });
  });
}
