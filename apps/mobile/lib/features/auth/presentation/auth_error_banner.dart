import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';

/// Bandeau d'erreur annoncé à TalkBack dès son apparition.
class AuthErrorBanner extends StatelessWidget {
  const new({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('auth-error'),
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(TicketSurRadii.sm),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: TicketSurSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
