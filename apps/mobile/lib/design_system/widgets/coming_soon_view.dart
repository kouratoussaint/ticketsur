import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';

/// État vide d'un module pas encore livré : ce qui arrive et quand.
class ComingSoonView extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.body,
    required this.badge,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Étiquette courte, par exemple « Phase 2 ».
  final String badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TicketSurSpacing.xl),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.md),
              Chip(
                label: Text(badge),
                avatar: Icon(Icons.schedule_rounded, color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
