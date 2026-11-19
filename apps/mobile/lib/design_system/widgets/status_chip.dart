import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';

/// Tonalité d'une pastille d'état.
enum StatusTone {
  /// Neutre : fermé, hors ligne, terminé.
  neutral,

  /// Information : en attente, à venir.
  info,

  /// Positif : actif, répondu, en ligne.
  positive,

  /// Attention : à échéance, incomplet.
  warning,

  /// Danger : suspendu, retiré, annulé.
  danger,
}

/// Pastille d'état commune à toute l'application (lot 3c) : mêmes formes,
/// mêmes couleurs pour un même sens, en clair comme en sombre.
class StatusChip extends StatelessWidget {
  const new({required this.label, required this.tone, this.icon, super.key});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final (background, foreground) = switch (tone) {
      StatusTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      StatusTone.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      StatusTone.positive => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      StatusTone.warning => (palette.warningContainer, palette.warningText),
      StatusTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        // Neutre : un filet pour rester visible sur une carte de même teinte.
        border: tone == StatusTone.neutral
            ? Border.all(color: scheme.outlineVariant)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TicketSurSpacing.sm,
          vertical: TicketSurSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final glyph?) ...[
              Icon(glyph, size: 14, color: foreground),
              const SizedBox(width: TicketSurSpacing.xxs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
