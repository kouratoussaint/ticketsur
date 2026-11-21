import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';

/// Léger enfoncement au toucher (0,97), relâché en douceur.
///
/// N'intercepte aucun geste : le widget enfant garde son `onTap` et son
/// ondulation. Désactivé si les animations sont réduites.
class PressableScale extends StatefulWidget {
  const new({required this.child, this.scale = 0.97, super.key});

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    // La ligne peut être reconstruite ailleurs pendant l'appui (entrée en
    // sélection) : le relâchement arrive alors après sa disparition.
    if (!mounted) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (TicketSurMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: _pressed
            ? const Duration(milliseconds: 90)
            : TicketSurMotion.medium,
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
