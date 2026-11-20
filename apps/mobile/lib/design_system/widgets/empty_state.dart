import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';

/// Petite illustration de marque : l'icône dans un disque, deux pastilles
/// (Menthe et Étincelle) en orbite. Décorative, ignorée par les lecteurs
/// d'écran.
class BrandSpot extends StatelessWidget {
  const new({required this.icon, this.size = 112, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disc = size * 0.8;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: disc,
              height: disc,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: disc * 0.46,
                color: scheme.onPrimaryContainer,
              ),
            ),
            Positioned(
              top: size * 0.06,
              right: size * 0.08,
              child: _Dot(size: size * 0.16, color: TicketSurColors.spark),
            ),
            Positioned(
              bottom: size * 0.1,
              left: size * 0.04,
              child: _Dot(size: size * 0.11, color: TicketSurColors.mint),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const new({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).colorScheme.surface,
        width: 3,
      ),
    ),
  );
}

/// État vide commun : illustration, titre, explication et action facultative.
///
/// [illustration] : dessin de marque 160 × 120 (direction artistique,
/// section 6) à la place de l'icône dans son disque.
class EmptyState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    this.illustration,
    this.body,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.titleKey,
    this.scrollable = false,
    super.key,
  });

  final IconData icon;
  final TikeoIllustration? illustration;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  /// Clé posée sur le titre (repère des tests).
  final Key? titleKey;

  /// Dans une liste à tirer pour actualiser : défile toujours.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = FadeSlideIn(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration case final kind?)
            TikeoIllustrationView(kind)
          else
            BrandSpot(icon: icon),
          const SizedBox(height: TicketSurSpacing.lg),
          Text(
            title,
            key: titleKey,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (body case final text?) ...[
            const SizedBox(height: TicketSurSpacing.xs),
            Text(
              text,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel case final label? when onAction != null) ...[
            const SizedBox(height: TicketSurSpacing.lg),
            FilledButton.tonal(
              key: actionKey,
              onPressed: onAction,
              child: Text(label),
            ),
          ],
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: scrollable ? const AlwaysScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(TicketSurSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? (constraints.maxHeight - 2 * TicketSurSpacing.xl).clamp(
                    0,
                    double.infinity,
                  )
                : 0,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
