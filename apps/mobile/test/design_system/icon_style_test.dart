import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Règle des icônes (lot 3c) : style arrondi partout. Seule la barre de
/// navigation utilise le contour pour un onglet inactif. Les pastilles
/// (`Icons.circle`) restent pleines.
void main() {
  test('icônes : style arrondi partout', () {
    final offenders = <String>[];
    final pattern = RegExp(r'Icons\.([a-z0-9_]+)');
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('/l10n/')) continue;
      final navigation = file.path.endsWith('app/app_shell.dart');
      final lines = file.readAsLinesSync();
      for (final (index, line) in lines.indexed) {
        for (final match in pattern.allMatches(line)) {
          final name = match.group(1)!;
          final ok =
              name.endsWith('_rounded') ||
              name == 'circle' ||
              (navigation && name.endsWith('_outlined'));
          if (!ok) offenders.add('${file.path}:${index + 1} $name');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
