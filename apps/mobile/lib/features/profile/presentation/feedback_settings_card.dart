import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Réglages des sons et vibrations (S28), propres à cet appareil.
class FeedbackSettingsCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(feedbackSettingsProvider);
    final controller = ref.read(feedbackSettingsProvider.notifier);
    final feedback = ref.read(feedbackProvider);
    return Card(
      key: const Key('profile-feedback'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              0,
            ),
            child: Text(
              l10n.feedbackTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            key: const Key('feedback-scan-sounds'),
            secondary: const Icon(Icons.campaign_rounded),
            title: Text(l10n.feedbackScanSounds),
            subtitle: Text(l10n.feedbackScanSoundsHelp),
            value: settings.scanSounds,
            onChanged: (value) =>
                controller.update(settings.copyWith(scanSounds: value)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TicketSurSpacing.md,
            ),
            child: Wrap(
              spacing: TicketSurSpacing.xs,
              children: [
                for (final (key, sound, label, icon) in [
                  (
                    'preview-admitted',
                    UiSound.admitted,
                    l10n.feedbackPreviewAdmitted,
                    Icons.check_circle_outline_rounded,
                  ),
                  (
                    'preview-refused',
                    UiSound.refused,
                    l10n.feedbackPreviewRefused,
                    Icons.cancel_rounded,
                  ),
                  (
                    'preview-indeterminate',
                    UiSound.indeterminate,
                    l10n.feedbackPreviewIndeterminate,
                    Icons.help_outline_rounded,
                  ),
                ])
                  ActionChip(
                    key: Key(key),
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    onPressed: () => feedback.preview(sound),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            key: const Key('feedback-ui-sounds'),
            secondary: const Icon(Icons.music_note_rounded),
            title: Text(l10n.feedbackUiSounds),
            subtitle: Text(l10n.feedbackUiSoundsHelp),
            value: settings.uiSounds,
            onChanged: (value) =>
                controller.update(settings.copyWith(uiSounds: value)),
          ),
          SwitchListTile(
            key: const Key('feedback-haptics'),
            secondary: const Icon(Icons.vibration_rounded),
            title: Text(l10n.feedbackHaptics),
            value: settings.haptics,
            onChanged: (value) =>
                controller.update(settings.copyWith(haptics: value)),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
        ],
      ),
    );
  }
}
