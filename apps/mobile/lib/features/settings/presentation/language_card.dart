import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Choix de la langue : celle du téléphone, français ou anglais.
class LanguageCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = ref.watch(appLanguageProvider);
    return Card(
      key: const Key('settings-language'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TicketSurSpacing.xs),
        child: RadioGroup<AppLanguage>(
          groupValue: language,
          onChanged: (value) {
            if (value == null) return;
            unawaited(ref.read(appLanguageProvider.notifier).select(value));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  TicketSurSpacing.xs,
                  TicketSurSpacing.md,
                  0,
                ),
                child: Text(
                  l10n.settingsLanguage,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              for (final (value, label) in [
                (AppLanguage.system, l10n.settingsLanguageSystem),
                (AppLanguage.fr, l10n.settingsLanguageFr),
                (AppLanguage.en, l10n.settingsLanguageEn),
              ])
                RadioListTile<AppLanguage>(
                  key: Key('settings-language-${value.name}'),
                  value: value,
                  title: Text(label),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  0,
                  TicketSurSpacing.md,
                  TicketSurSpacing.xs,
                ),
                child: Text(
                  l10n.settingsLanguageHelp,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
