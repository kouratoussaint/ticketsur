import 'package:material_ui/material_ui.dart';

/// Chiffres à chasse fixe (Inter `tnum`) pour tous les textes de [child] :
/// un compteur qui change ne fait pas bouger ce qui l'entoure.
class TabularFigures extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  static const List<FontFeature> features = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: const TextStyle(fontFeatures: features),
    child: child,
  );
}
