import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';

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

/// Pastille d'état commune à toute l'application : arrondi 999, hauteur
/// 28, icône 16 et texte 14 / 700 de la même teinte sur un fond pâle
/// (direction artistique, section 3). [tint] remplace la teinte du [tone].
class StatusChip extends StatelessWidget {
  const new({
    required this.label,
    required this.tone,
    this.icon,
    this.tint,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final TikeoTint? tint;

  /// Teinte d'une tonalité.
  static TikeoTint tintOf(TikeoTints tints, StatusTone tone) => switch (tone) {
    StatusTone.neutral => tints.gray,
    StatusTone.info => tints.blue,
    StatusTone.positive => tints.green,
    StatusTone.warning => tints.amber,
    StatusTone.danger => tints.red,
  };

  @override
  Widget build(BuildContext context) {
    final colors = tint ?? tintOf(context.tints, tone);
    return Container(
      constraints: const BoxConstraints(minHeight: TikeoSizes.chip),
      padding: const EdgeInsets.symmetric(
        horizontal: TicketSurSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(TikeoRadii.pill),
        // Neutre : un filet pour rester visible sur une tuile de même teinte.
        border: tint == null && tone == StatusTone.neutral
            ? Border.all(color: Theme.of(context).colorScheme.outlineVariant)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final glyph?) ...[
            Icon(glyph, size: TikeoSizes.chipIcon, color: colors.icon),
            const SizedBox(width: TicketSurSpacing.xxs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TikeoTextStyles.chip.copyWith(color: colors.text),
            ),
          ),
        ],
      ),
    );
  }
}
