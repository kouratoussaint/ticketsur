import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';

/// [AnimatedSize] qui respecte « supprimer les animations ».
///
/// Animations réduites : l'enfant est affiché tel quel. Un [AnimatedSize] de
/// durée nulle se redemande une mise en page pendant la sienne (assertion
/// « RenderAnimatedSize was mutated in its own performLayout »).
class MotionSize extends StatelessWidget {
  const new({
    required this.child,
    this.duration = TicketSurMotion.medium,
    this.curve = TicketSurMotion.standard,
    this.alignment = Alignment.center,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (TicketSurMotion.reduced(context)) return child;
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}
