import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/l10n/gen/app_localizations_en.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_legal_repository.dart';

/// Corrections du 21/11 (améliorations du 20/11, PR 1).
void main() {
  test('« Chargement… » (#20)', () {
    expect(AppLocalizationsFr().orgLoading, 'Chargement…');
    expect(AppLocalizationsEn().orgLoading, 'Loading…');
  });

  testWidgets('résumés centrés, même en très grand texte (#19)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TicketSurTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: SizedBox(
              width: 360,
              child: StatStrip(
                centered: true,
                items: [
                  (value: '2', label: 'Ouverts', color: null),
                  (value: '10', label: 'À venir', color: null),
                  (value: '3', label: 'Porte', color: null),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (final (value, label) in [('2', 'Ouverts'), ('10', 'À venir')]) {
      final number = tester.getCenter(find.text(value)).dx;
      final caption = tester.getCenter(find.text(label)).dx;
      expect((number - caption).abs(), lessThan(1));
    }
  });

  testWidgets('mise à jour au lancement : Télécharger ouvre la dernière APK '
      '(#9)', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(),
          updates: FakeUpdateChecker(latest: 140),
          installedBuild: 131,
          openLink: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('update-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('update-dialog-download')));
    await tester.pumpAndSettle();
    expect(opened.single.path, endsWith('.apk'));
    expect(find.byKey(const Key('update-dialog')), findsNothing);
  });
}
