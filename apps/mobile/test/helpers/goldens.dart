import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge les vraies polices de l'app (Inter, Nunito, icônes Material…)
/// déclarées dans le manifeste des polices : sans cela, les tests dessinent
/// des carrés à la place du texte.
Future<void> loadAppFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.replaceFirst(RegExp('^packages/[^/]+/'), ''),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final asset = font['asset'] as String;
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

/// Comparateur des captures de référence : refuse toute différence au-delà
/// d'une infime part des pixels ([tolerance], 0,1 % par défaut), pour
/// absorber le lissage du texte sans laisser passer un vrai changement.
class TolerantGoldenComparator extends LocalFileComparator {
  new(super.testFile, {this.tolerance = 0.001});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw TestFailure(error);
  }
}

/// Installe [TolerantGoldenComparator] pour le fichier de test courant.
void useTolerantGoldens() {
  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator(
      Uri.parse('${current.basedir}placeholder_test.dart'),
    );
  }
}

/// Attend le décodage de toutes les images affichées (logo, illustrations) :
/// sans cela, une image peut manquer d'une capture à l'autre.
Future<void> precacheVisibleImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  final elements = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final (i, image) in images.indexed) {
      await precacheImage(image.image, elements[i]);
    }
  });
  await tester.pumpAndSettle();
}
