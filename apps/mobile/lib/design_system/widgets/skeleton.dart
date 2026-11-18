import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';

/// Reflet animé partagé par les blocs [SkeletonBox] descendants.
class Shimmer extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TicketSurMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.lerp(base, scheme.surface, 0.7)!;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final dx = (_controller.value * 3 - 1) * bounds.width;
          return LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
            transform: _Slide(dx),
          ).createShader(bounds);
        },
        child: child,
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const new(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// Bloc gris arrondi, silhouette d'un contenu en chargement.
class SkeletonBox extends StatelessWidget {
  const new({this.width, this.height = 14, this.radius = 6, super.key});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Liste de cartes fantômes pendant un chargement (remplace la roue).
class SkeletonList extends StatelessWidget {
  const new({this.count = 4, this.leading = true, super.key});

  final int count;

  /// Avec un bloc carré à gauche (date, avatar).
  final bool leading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: Shimmer(
        child: ListView.separated(
          key: const Key('skeleton-list'),
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          itemCount: count,
          separatorBuilder: (_, _) =>
              const SizedBox(height: TicketSurSpacing.sm),
          itemBuilder: (context, index) => Card(
            child: Padding(
              padding: const EdgeInsets.all(TicketSurSpacing.md),
              child: Row(
                children: [
                  if (leading) ...[
                    const SkeletonBox(width: 52, height: 52, radius: 12),
                    const SizedBox(width: TicketSurSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.75 - (index % 3) * 0.12,
                          child: const SkeletonBox(height: 16),
                        ),
                        const SizedBox(height: TicketSurSpacing.xs),
                        const FractionallySizedBox(
                          widthFactor: 0.5,
                          child: SkeletonBox(height: 12),
                        ),
                        const SizedBox(height: TicketSurSpacing.xs),
                        const SkeletonBox(width: 72, height: 20, radius: 999),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
