import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';

/// Apparition douce (fondu + montée de 16 dp), éventuellement décalée pour
/// enchaîner plusieurs éléments. Sans minuterie : le décalage fait partie de
/// la même animation, rien ne reste en attente si l'écran disparaît.
class FadeSlideIn extends StatefulWidget {
  const new({
    required this.child,
    this.delay = Duration.zero,
    this.duration = TicketSurMotion.medium,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds /
          (widget.delay + widget.duration).inMicroseconds,
      1,
      curve: TicketSurMotion.enter,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TicketSurMotion.reduced(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
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
    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 16 * (1 - _progress.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
