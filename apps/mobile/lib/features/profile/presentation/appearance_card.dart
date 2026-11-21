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
            const SizedBox(height: TicketSurSpacing.md),
            const TextSizePicker(),
          ],
        ),
      ),
    );
  }
}

/// Taille du texte (#11) : Petite, Normale, Grande, Très grande, avec un
/// aperçu ; multipliée par la taille choisie sur le téléphone.
class TextSizePicker extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final size = ref.watch(textSizeProvider);
    return Column(
      key: const Key('settings-text-size'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.textSizeTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: TicketSurSpacing.xs),
        // Les libellés restent à la taille normale, pour rester lisibles
        // quelle que soit la taille choisie.
        MediaQuery.withNoTextScaling(
          child: SegmentedButton<TextSize>(
            showSelectedIcon: false,
            segments: [
              for (final (value, label) in [
                (TextSize.small, l10n.textSizeSmall),
                (TextSize.normal, l10n.textSizeNormal),
                (TextSize.large, l10n.textSizeLarge),
                (TextSize.extraLarge, l10n.textSizeExtraLarge),
              ])
                ButtonSegment(
                  value: value,
                  label: Text(
                    label,
                    key: Key('text-size-${value.name}'),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
            selected: {size},
            onSelectionChanged: (selection) => unawaited(
              ref.read(textSizeProvider.notifier).select(selection.single),
            ),
          ),
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        DecoratedBox(
          key: const Key('text-size-preview'),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.textSizePreviewTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.textSizePreviewBody,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: TicketSurSpacing.xxs),
        Text(l10n.textSizeHelp, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
