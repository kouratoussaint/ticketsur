import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/features/scanner/presentation/scan_verdict_view.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_copy.dart';

import '../../helpers/pump_app.dart';

void main() {
  ScanVerdict verdict(
    ScanResult result, {
    DateTime? first,
    String? checkpoint,
    PassEntries? entries,
  }) => ScanVerdict(
    requestId: 'r1',
    result: result,
    validationId: result == ScanResult.accepted ? 'v1' : null,
    publicReference: 'TS-7K3P-9QXM',
    category: 'VIP',
    firstValidatedAt: first,
    checkpointLabel: checkpoint,
    entries: entries,
  );

  Color background(WidgetTester tester) => tester
      .widget<Material>(
        find
            .descendant(
              of: find.byType(ScanVerdictView),
              matching: find.byType(Material),
            )
            .first,
      )
      .color!;

  testWidgets('accepté : vert, coche, ENTRÉE AUTORISÉE', (tester) async {
    await tester.pumpApp(
      ScanVerdictView(verdict: verdict(ScanResult.accepted), onNext: () {}),
    );
    expect(find.text('ENTRÉE AUTORISÉE'), findsOneWidget);
    expect(find.text('Ticket valide — entrée autorisée'), findsOneWidget);
    expect(find.text('Réf. TS-7K3P-9QXM · VIP'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(background(tester), TicketSurColors.success);
  });

  testWidgets('déjà utilisé : rouge, heure et porte du premier passage', (
    tester,
  ) async {
    await tester.pumpApp(
      ScanVerdictView(
        verdict: verdict(
          ScanResult.alreadyUsed,
          first: DateTime.utc(2026, 11, 18, 19, 42, 5),
          checkpoint: 'Entrée principale',
        ),
        onNext: () {},
      ),
    );
    expect(find.text('ENTRÉE REFUSÉE'), findsOneWidget);
    expect(find.text('Ticket déjà utilisé'), findsOneWidget);
    expect(
      find.text('Premier passage à 19:42 · Entrée principale'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(background(tester), TicketSurColors.error);
  });

  group('pass à plusieurs entrées', () {
    final at = DateTime.utc(2026, 11, 18, 19, 42);

    for (final (label, result, entries, lines) in [
      (
        'pass limité accepté',
        ScanResult.accepted,
        const PassEntries(policy: EntryPolicy.limited, used: 2, max: 3),
        ['Entrée 2 sur 3'],
      ),
      (
        'dernière entrée',
        ScanResult.accepted,
        const PassEntries(policy: EntryPolicy.limited, used: 3, max: 3),
        ['Dernière entrée du pass (3 sur 3)'],
      ),
      (
        'pass épuisé',
        ScanResult.alreadyUsed,
        const PassEntries(policy: EntryPolicy.limited, used: 3, max: 3),
        ['Pass épuisé : 3 entrées utilisées', 'Dernière entrée à 19:42 · Nord'],
      ),
      (
        'journalier accepté',
        ScanResult.accepted,
        const PassEntries(policy: EntryPolicy.perDay, used: 2),
        ["Pass journalier · jour d'entrée n° 2"],
      ),
      (
        'journalier déjà entré',
        ScanResult.alreadyUsed,
        const PassEntries(policy: EntryPolicy.perDay, used: 2),
        [
          "Pass journalier · déjà entré aujourd'hui (2 jours au total)",
          "Entré aujourd'hui à 19:42 · Nord",
        ],
      ),
    ]) {
      testWidgets(label, (tester) async {
        await tester.pumpApp(
          ScanVerdictView(
            verdict: verdict(
              result,
              first: at,
              checkpoint: 'Nord',
              entries: entries,
            ),
            onNext: () {},
          ),
        );
        for (final line in lines) {
          expect(find.text(line), findsOneWidget, reason: line);
        }
        expect(find.textContaining('Premier passage'), findsNothing);
        expect(
          background(tester),
          result == ScanResult.accepted
              ? TicketSurColors.success
              : TicketSurColors.error,
        );
      });
    }
  });

  testWidgets('indéterminé : orange, conseil, réessai du même request_id', (
    tester,
  ) async {
    var retried = 0;
    var next = 0;
    await tester.pumpApp(
      ScanVerdictView(
        verdict: const ScanVerdict.unavailable('r1'),
        onNext: () => next++,
        onRetry: () => retried++,
      ),
    );
    expect(find.text('ÉTAT À CONFIRMER'), findsOneWidget);
    expect(
      find.text("Ne laissez pas entrer sur la base de l'application seule."),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    expect(background(tester), TicketSurColors.warning);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    await tester.tap(find.byKey(const Key('verdict-retry')));
    await tester.tap(find.byKey(const Key('verdict-next')));
    expect((retried, next), (1, 1));
  });

  for (final result in ScanResult.values) {
    testWidgets('${result.wireName} : vert uniquement si accepted', (
      tester,
    ) async {
      await tester.pumpApp(
        ScanVerdictView(verdict: verdict(result), onNext: () {}),
      );
      expect(
        background(tester) == TicketSurColors.success,
        result == ScanResult.accepted,
      );
    });
  }

  testWidgets('le verdict est annoncé à TalkBack (live region)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(
      ScanVerdictView(verdict: verdict(ScanResult.revoked), onNext: () {}),
    );
    final node = tester.getSemantics(
      find
          .ancestor(
            of: find.byKey(const Key('verdict-title')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(node.label, startsWith('ENTRÉE REFUSÉE. Ticket annulé'));
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });

  testWidgets('reste utilisable à 200 % de taille de texte', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpApp(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(2),
        ),
        child: ScanVerdictView(
          verdict: verdict(
            ScanResult.alreadyUsed,
            first: DateTime.utc(2026, 11, 18, 19, 42),
            checkpoint: 'Entrée principale',
          ),
          onNext: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('verdict-next')).hitTestable(), findsOneWidget);
  });

  testWidgets('vérification : écran neutre, aucune couleur de verdict', (
    tester,
  ) async {
    await tester.pumpApp(const ScanVerifyingView());
    expect(find.text('Vérification…'), findsOneWidget);
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(ScanVerifyingView),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, TicketSurColors.verifying);
  });

  // L'encart des détails ne doit jamais faire baisser le contraste du texte.
  for (final result in [
    ScanResult.accepted,
    ScanResult.alreadyUsed,
    ScanResult.pending,
  ]) {
    testWidgets('encart des détails lisible : ${result.wireName}', (
      tester,
    ) async {
      await tester.pumpApp(
        ScanVerdictView(verdict: verdict(result), onNext: () {}),
      );
      final box = tester.widget<DecoratedBox>(
        find.byKey(const Key('verdict-details')),
      );
      final tint = (box.decoration as BoxDecoration).color!;
      final page = background(tester);
      final card = Color.alphaBlend(tint, page);
      final text = tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(const Key('verdict-details')),
                  matching: find.byType(Text),
                )
                .first,
          )
          .style!
          .color!;
      double ratio(Color a, Color b) {
        final (x, y) = (a.computeLuminance(), b.computeLuminance());
        return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
      }

      expect(ratio(text, card), greaterThanOrEqualTo(ratio(text, page)));
      expect(ratio(text, card), greaterThanOrEqualTo(4.5));
    });
  }

  group('formatEventTime', () {
    test('utilise le fuseau de l’événement, pas celui du téléphone', () {
      final instant = DateTime.utc(2026, 11, 18, 23, 30);
      expect(formatEventTime(instant), '23:30');
      expect(
        formatEventTime(instant, eventUtcOffset: const Duration(hours: 1)),
        '00:30',
      );
    });
  });
}
