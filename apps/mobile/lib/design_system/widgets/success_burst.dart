import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';

/// Réussite marquante : disque qui apparaît, coche tracée, onde et éclats
/// de couleurs de la marque (≈ 0,9 s, une seule fois).
class SuccessBurst extends StatefulWidget {
  const new({
    this.size = 96,
    this.color = TicketSurColors.successStrong,
    super.key,
  });

  final double size;
  final Color color;

  @override
  State<SuccessBurst> createState() => _SuccessBurstState();
}

class _SuccessBurstState extends State<SuccessBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TicketSurMotion.reduced(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      child: SizedBox.square(
        dimension: widget.size * 1.8,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _BurstPainter(
              progress: _controller.value,
              color: widget.color,
              radius: widget.size / 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  new({required this.progress, required this.color, required this.radius});

  final double progress;
  final Color color;
  final double radius;

  static const List<Color> _sparkColors = [
    TicketSurColors.success,
    TicketSurColors.mint,
    Color(0xFFFFC233),
    TicketSurColors.navy,
  ];

  double _interval(double begin, double end, [Curve curve = Curves.linear]) =>
      curve.transform(((progress - begin) / (end - begin)).clamp(0, 1));

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // Onde qui s'élargit et s'efface.
    final wave = _interval(0.15, 0.8, Curves.easeOut);
    if (wave > 0 && wave < 1) {
      canvas.drawCircle(
        center,
        radius * (1 + wave * 0.7),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - wave)
          ..color = color.withValues(alpha: 1 - wave),
      );
    }

    // Éclats.
    final spark = _interval(0.2, 0.95, Curves.easeOutCubic);
    if (spark > 0 && spark < 1) {
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6 + 0.2;
        final distance = radius * (1.05 + spark * 0.65);
        final position =
            center + Offset(math.cos(angle), math.sin(angle)) * distance;
        canvas.drawCircle(
          position,
          (i.isEven ? 4.0 : 3.0) * (1 - spark),
          Paint()..color = _sparkColors[i % _sparkColors.length],
        );
      }
    }

    // Disque (léger rebond).
    final disc = _interval(0, 0.45, Curves.easeOutBack);
    canvas.drawCircle(center, radius * disc, Paint()..color = color);

    // Coche tracée.
    final tick = _interval(0.35, 0.75, Curves.easeInOut);
    if (tick > 0) {
      final path = Path()
        ..moveTo(center.dx - radius * 0.42, center.dy + radius * 0.02)
        ..lineTo(center.dx - radius * 0.12, center.dy + radius * 0.32)
        ..lineTo(center.dx + radius * 0.45, center.dy - radius * 0.3);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * tick),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.16
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = TicketSurColors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
