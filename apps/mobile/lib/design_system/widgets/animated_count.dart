import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/widgets/tabular_figures.dart';

/// Nombre qui défile jusqu'à sa nouvelle valeur.
///
/// [builder] reçoit la valeur intermédiaire (pour les textes localisés,
/// par exemple « 12 tickets émis »).
class AnimatedCount extends StatelessWidget {
  const new({
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
    super.key,
  });

  final int value;
  final Widget Function(BuildContext context, int value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (TicketSurMotion.reduced(context)) {
      return TabularFigures(child: builder(context, value));
    }
    return TabularFigures(
      child: TweenAnimationBuilder<double>(
        // Défile depuis 0 à la première apparition, puis d'une valeur à
        // l'autre.
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, current, _) => builder(context, current.round()),
      ),
    );
  }
}
