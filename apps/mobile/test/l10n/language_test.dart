import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_legal_repository.dart';
import '../helpers/fake_profile_repository.dart';

/// Variables de premier niveau d'un texte ARB (`{name}`, `{count, plural…}`).
Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)[,}]').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  tearDown(() => appLocaleTag = 'fr');

  group('traductions', () {
    final fr = jsonDecode(
      File('lib/l10n/arb/app_fr.arb').readAsStringSync(),
    ) as Map<String, Object?>;
    final en = jsonDecode(
      File('lib/l10n/arb/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;
    final keys = [
      for (final key in fr.keys)
        if (!key.startsWith('@')) key,
    ];

    test('chaque texte français a sa traduction anglaise', () {
      final missing = [
        for (final key in keys)
          if ((en[key] as String?)?.trim().isEmpty ?? true) key,
      ];
      expect(missing, isEmpty, reason: 'Traductions manquantes : $missing');
      final extra = [
        for (final key in en.keys)
          if (!key.startsWith('@') && !fr.containsKey(key)) key,
      ];
      expect(extra, isEmpty, reason: 'Textes anglais orphelins : $extra');
    });

    test('mêmes variables dans les deux langues', () {
      final mismatched = [
        for (final key in keys)
          if (!setEquals(
            _placeholders(fr[key]! as String),
            _placeholders(en[key]! as String),
          ))
            key,
      ];
      expect(mismatched, isEmpty);
    });
  });

  group('choix de la langue', () {
    test('langue du téléphone : français ou anglais, français sinon', () {
      Locale resolve(List<Locale> device) =>
          resolveAppLocale(AppLanguage.system, device);
      expect(resolve(const [Locale('en', 'GH')]), const Locale('en'));
      expect(resolve(const [Locale('fr', 'BF')]), const Locale('fr'));
      expect(resolve(const [Locale('es'), Locale('en')]), const Locale('en'));
      expect(resolve(const [Locale('mos')]), const Locale('fr'));
      expect(
        resolveAppLocale(AppLanguage.en, const [Locale('fr')]),
        const Locale('en'),
      );
    });

    test('dates des tickets et messages dans la langue de l’app', () async {
      await initializeDateFormatting();
      final wall = DateTime(2030, 6, 20, 21);
      expect(formatDateAtTime(wall), '20 juin 2030 à 21:00');
      expect(formatEventDay(wall), 'jeu. 20 juin 2030');
      appLocaleTag = 'en';
      expect(formatDateAtTime(wall), 'Jun 20, 2030 at 21:00');
      expect(formatEventDay(wall), 'Thu, Jun 20, 2030');
    });

    testWidgets('Paramètres › Langue : anglais, puis langue du téléphone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final profiles = FakeProfileRepository();
      final legal = FakeLegalRepository();
      final container = ProviderContainer(
        overrides: await appOverrides(
          auth: FakeAuthRepository(
            user: const AuthUser(id: 'u1', email: 'chef@exemple.bf'),
          ),
          profile: profiles,
          legal: legal,
        ),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.settings)
          .ignore();
      await tester.pumpAndSettle();
      expect(find.text('Apparence'), findsOneWidget);

      final english = find.byKey(const Key('settings-language-en'));
      await tester.scrollUntilVisible(
        english,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(english);
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
      expect(appLocaleTag, 'en');
      expect(
        container
            .read(sharedPreferencesProvider)
            .getString(AppLanguageController.key),
        'en',
      );
      // Langue du compte mise à jour (notifications écrites en anglais).
      expect(profiles.profile.locale, 'en');
      // Mentions légales lues en anglais.
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.legal(LegalSlug.terms))
          .ignore();
      await tester.pumpAndSettle();
      expect(legal.fetchedLocales.last, 'en');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final system = find.byKey(const Key('settings-language-system'));
      await tester.ensureVisible(system);
      await tester.pumpAndSettle();
      await tester.tap(system);
      await tester.pumpAndSettle();
      // Téléphone en français dans les tests.
      expect(find.text('Langue'), findsOneWidget);
      expect(appLocaleTag, 'fr');
    });
  });
}
