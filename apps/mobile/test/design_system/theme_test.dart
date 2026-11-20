import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/appearance.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_organization_repository.dart';

void main() {
  for (final (name, theme) in [
    ('clair', TicketSurTheme.light()),
    ('sombre', TicketSurTheme.dark()),
  ]) {
    group('thème $name', () {
      final s = theme.colorScheme;
      final surfaces = {
        'surface': s.surface,
        'surfaceContainerLowest': s.surfaceContainerLowest,
        'surfaceContainerLow': s.surfaceContainerLow,
        'surfaceContainer': s.surfaceContainer,
        'surfaceContainerHigh': s.surfaceContainerHigh,
        'surfaceContainerHighest': s.surfaceContainerHighest,
      };

      test('conteneurs de surface définis et ordonnés', () {
        // Aucun conteneur ne retombe sur la surface par défaut.
        expect(surfaces.values.skip(1).where((c) => c == s.surface), isEmpty);
        final levels = [
          s.surfaceContainerLow,
          s.surfaceContainer,
          s.surfaceContainerHigh,
          s.surfaceContainerHighest,
        ].map((c) => c.computeLuminance()).toList();
        final sorted = [...levels]..sort();
        expect(
          levels,
          theme.brightness == Brightness.dark ? sorted : sorted.reversed,
        );
      });

      final palette = theme.extension<TicketSurPalette>()!;
      final inks = {
        'onSurface': s.onSurface,
        'onSurfaceVariant': s.onSurfaceVariant,
        'primary': s.primary,
        'secondary': s.secondary,
        'error': s.error,
        ...palette.textColors,
      };
      for (final MapEntry(key: ink, value: color) in inks.entries) {
        for (final MapEntry(key: surface, value: background)
            in surfaces.entries) {
          test('$ink sur $surface ≥ 4,5:1', () {
            expect(contrastRatio(color, background), greaterThanOrEqualTo(4.5));
          });
        }
      }

      for (final (label, ink, background) in [
        ('onPrimary / primary', s.onPrimary, s.primary),
        ('onSecondary / secondary', s.onSecondary, s.secondary),
        (
          'onPrimaryContainer / primaryContainer',
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        (
          'onSecondaryContainer / secondaryContainer',
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        (
          'onTertiaryContainer / tertiaryContainer',
          s.onTertiaryContainer,
          s.tertiaryContainer,
        ),
        ('onError / error', s.onError, s.error),
        (
          'onErrorContainer / errorContainer',
          s.onErrorContainer,
          s.errorContainer,
        ),
        (
          'onInverseSurface / inverseSurface',
          s.onInverseSurface,
          s.inverseSurface,
        ),
        ('inversePrimary / inverseSurface', s.inversePrimary, s.inverseSurface),
        (
          'warningText / warningContainer',
          palette.warningText,
          palette.warningContainer,
        ),
        ('onSurface / warningContainer', s.onSurface, palette.warningContainer),
      ]) {
        test('$label ≥ 4,5:1', () {
          expect(contrastRatio(ink, background), greaterThanOrEqualTo(4.5));
        });
      }

      test('contours visibles (≥ 3:1)', () {
        expect(contrastRatio(s.outline, s.surface), greaterThanOrEqualTo(3));
      });
    });
  }

  group('choix du thème', () {
    test('lu et enregistré dans les préférences', () async {
      SharedPreferences.setMockInitialValues({'appearance.theme_mode': 'dark'});
      final overrides = await appOverrides(
        auth: FakeAuthRepository(),
        preferences: {'appearance.theme_mode': 'dark'},
      );
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      await container.read(themeModeProvider.notifier).select(ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appearance.theme_mode'), 'light');
    });

    testWidgets('Profil : passer en sombre puis revenir au système', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(
              user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
            ),
            organizations: FakeOrganizationRepository([testOrganization]),
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
      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app().themeMode, ThemeMode.system);

      final dark = find.byKey(const Key('appearance-dark'));
      await tester.scrollUntilVisible(
        dark,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(dark);
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.dark);
      expect(Theme.of(tester.element(dark)).brightness, Brightness.dark);

      await tester.tap(find.byKey(const Key('appearance-system')));
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.system);
    });
  });
}
