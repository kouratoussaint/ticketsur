import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Pastille de statut, animée quand le statut change.
class EventStatusChip extends StatelessWidget {
  const new({required this.status, super.key});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final style = eventStatusStyle(status, Theme.of(context).brightness);
    final duration = TicketSurMotion.reduced(context)
        ? Duration.zero
        : TicketSurMotion.medium;
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(status),
        constraints: const BoxConstraints(minHeight: TikeoSizes.chip),
        padding: const EdgeInsets.symmetric(
          horizontal: TicketSurSpacing.sm,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(TikeoRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.glyph, size: TikeoSizes.chipIcon, color: style.icon),
            const SizedBox(width: TicketSurSpacing.xxs),
            Flexible(
              child: Text(
                eventStatusLabel(context.l10n, status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TikeoTextStyles.chip.copyWith(color: style.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
