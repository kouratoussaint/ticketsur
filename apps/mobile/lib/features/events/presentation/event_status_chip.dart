import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
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
      child: DecoratedBox(
        key: ValueKey(status),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TicketSurSpacing.sm,
            vertical: TicketSurSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.glyph, size: 16, color: style.icon),
              const SizedBox(width: TicketSurSpacing.xxs),
              Text(
                eventStatusLabel(context.l10n, status),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
