import 'package:material_ui/material_ui.dart';

/// Petites barres d'une série quotidienne (la plus haute à pleine hauteur),
/// sur une ligne de base. Décoratives : le chiffre est écrit à côté.
class DailyBars extends StatelessWidget {
  const new({
    required this.values,
    required this.color,
    this.height = 56,
    super.key,
  });

  final List<int> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DailyBarsPainter(
          values: values,
          color: color,
          baseline: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    ),
  );
}

class _DailyBarsPainter extends CustomPainter {
  new({required this.values, required this.color, required this.baseline});

  final List<int> values;
  final Color color;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = baseline
        ..strokeWidth = 1,
    );
    if (values.isEmpty) return;
    final top = values.reduce((a, b) => a > b ? a : b);
    if (top <= 0) return;
    final slot = size.width / values.length;
    final width = (slot * 0.7).clamp(1.0, 12.0);
    final bar = Paint()..color = color;
    for (final (index, value) in values.indexed) {
      if (value <= 0) continue;
      final h = (size.height - 2) * value / top;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            slot * index + (slot - width) / 2,
            size.height - 1 - h,
            width,
            h,
          ),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        bar,
      );
    }
  }

  @override
  bool shouldRepaint(_DailyBarsPainter old) =>
      old.values != values || old.color != color || old.baseline != baseline;
}
