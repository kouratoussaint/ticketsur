import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/appearance.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Choix du thème (système, clair, sombre), propre à cet appareil.
class AppearanceCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    return Card(
      key: const Key('profile-appearance'),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.appearanceTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(l10n.appearanceHelp, style: theme.textTheme.bodySmall),
            const SizedBox(height: TicketSurSpacing.sm),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                for (final (value, icon, label) in [
                  (
                    ThemeMode.system,
                    Icons.brightness_auto_rounded,
                    l10n.appearanceSystem,
                  ),
                  (
                    ThemeMode.light,
                    Icons.light_mode_rounded,
                    l10n.appearanceLight,
                  ),
                  (
                    ThemeMode.dark,
                    Icons.dark_mode_rounded,
                    l10n.appearanceDark,
                  ),
                ])
                  ButtonSegment(
                    value: value,
                    icon: Icon(icon, key: Key('appearance-${value.name}')),
                    label: Text(label),
                  ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) => unawaited(
                ref.read(themeModeProvider.notifier).select(selection.single),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
