import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';

/// Seuil WCAG 2.x niveau AA pour le texte courant.
const double _aa = 4.5;

void main() {
  group('contrastRatio', () {
    test('blanc sur noir vaut 21', () {
      expect(
        contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF000000)),
        closeTo(21, 0.01),
      );
    });

    test('est symétrique', () {
      expect(
        contrastRatio(TicketSurColors.navy, TicketSurColors.success),
        closeTo(
          contrastRatio(TicketSurColors.success, TicketSurColors.navy),
          1e-9,
        ),
      );
    });
  });

  group('palette de marque', () {
    test('le blanc est interdit sur le vert et le bleu électrique', () {
      // Ces mesures justifient les règles documentées dans TicketSurColors.
      expect(
        contrastRatio(TicketSurColors.white, TicketSurColors.success),
        lessThan(_aa),
      );
      expect(
        contrastRatio(TicketSurColors.white, TicketSurColors.blue),
        lessThan(_aa),
      );
    });

    test('les substituts retenus passent le niveau AA', () {
      expect(
        contrastRatio(TicketSurColors.white, TicketSurColors.blueText),
        greaterThanOrEqualTo(_aa),
      );
      expect(
        contrastRatio(TicketSurColors.white, TicketSurColors.successStrong),
        greaterThanOrEqualTo(_aa),
      );
    });
  });

  group('verdicts plein écran', () {
    for (final kind in VerdictKind.values) {
      test('${kind.name} : texte lisible (≥ 4,5:1)', () {
        const colors = VerdictColors.standard;
        expect(
          contrastRatio(colors.foreground(kind), colors.background(kind)),
          greaterThanOrEqualTo(_aa),
        );
      });
    }

    test('seul « admitted » utilise le vert de succès', () {
      const colors = VerdictColors.standard;
      for (final kind in VerdictKind.values) {
        expect(
          colors.background(kind) == TicketSurColors.success,
          kind == VerdictKind.admitted,
          reason: kind.name,
        );
      }
    });
  });

  for (final (name, theme) in [
    ('clair', TicketSurTheme.light()),
    ('sombre', TicketSurTheme.dark()),
  ]) {
    group('thème $name', () {
      final s = theme.colorScheme;
      final pairs = <String, (Color, Color)>{
        'onPrimary / primary': (s.onPrimary, s.primary),
        'onSecondary / secondary': (s.onSecondary, s.secondary),
        'onTertiary / tertiary': (s.onTertiary, s.tertiary),
        'onError / error': (s.onError, s.error),
        'onSurface / surface': (s.onSurface, s.surface),
        'onSurfaceVariant / surface': (s.onSurfaceVariant, s.surface),
        'onPrimaryContainer / primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
      };
      for (final MapEntry(key: label, value: pair) in pairs.entries) {
        test('$label ≥ 4,5:1', () {
          expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(_aa));
        });
      }

      test('embarque les couleurs de verdict', () {
        expect(theme.extension<VerdictColors>(), isNotNull);
      });
    });
  }
}
