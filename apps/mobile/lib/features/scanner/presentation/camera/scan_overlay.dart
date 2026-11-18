import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';

/// Cadre de visée : voile sombre percé d'une fenêtre carrée arrondie, coins
/// qui pulsent doucement et ligne de balayage. Purement décoratif : ne capte
/// aucun geste.
class ScanOverlay extends StatefulWidget {
  const new({required this.window, super.key});

  /// Fenêtre de lecture, dans le repère de l'écran.
  final Rect window;

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TicketSurMotion.reduced(context)) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _OverlayPainter(
            window: widget.window,
            progress: Curves.easeInOut.transform(_controller.value),
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  new({required this.window, required this.progress});

  final Rect window;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(window, const Radius.circular(24));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(hole),
      ),
      Paint()..color = const Color(0xA6000000),
    );

    // Coins : légère respiration (épaisseur et longueur).
    final corner = Paint()
      ..color = TicketSurColors.success
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5 + progress * 1.5;
    final length = window.width * (0.14 + progress * 0.03);
    const r = 24.0;
    for (final (x, y, dx, dy) in [
      (window.left, window.top, 1.0, 1.0),
      (window.right, window.top, -1.0, 1.0),
      (window.left, window.bottom, 1.0, -1.0),
      (window.right, window.bottom, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + dy * (r + length))
          ..lineTo(x, y + dy * r)
          ..arcToPoint(
            Offset(x + dx * r, y),
            radius: const Radius.circular(r),
            clockwise: dx * dy > 0,
          )
          ..lineTo(x + dx * (r + length), y),
        corner,
      );
    }

    // Ligne de balayage avec halo.
    final y = window.top + 16 + (window.height - 32) * progress;
    final line = Rect.fromLTWH(window.left + 20, y - 1.5, window.width - 40, 3);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(line.inflate(6), const Radius.circular(6)),
        Paint()
          ..color = TicketSurColors.success.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(line, const Radius.circular(2)),
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0x0017BE35),
              TicketSurColors.success,
              Color(0x0017BE35),
            ],
          ).createShader(line),
      );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.progress != progress || old.window != window;
}

/// Fenêtre de lecture carrée, centrée un peu au-dessus du milieu.
Rect scanWindowFor(Size size) {
  final side = (size.shortestSide * 0.68).clamp(200.0, 340.0);
  final center = Offset(size.width / 2, size.height * 0.44);
  return Rect.fromCenter(center: center, width: side, height: side);
}
