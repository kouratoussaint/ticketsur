import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/updates/application/update_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Carte « Nouvelle version disponible », rien sinon.
class UpdateBanner extends ConsumerWidget {
  const new({
    this.padding = const EdgeInsets.only(bottom: TicketSurSpacing.md),
    super.key,
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final build = ref.watch(availableUpdateProvider).value;
    final scheme = Theme.of(context).colorScheme;
    return MotionSize(
      child: build == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: padding,
              child: Card(
                key: const Key('update-banner'),
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(TicketSurSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.system_update_rounded,
                            color: scheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: TicketSurSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.updateAvailableTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: scheme.onPrimaryContainer),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TicketSurSpacing.xs),
                      Text(
                        l10n.updateAvailableBody(build),
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: TicketSurSpacing.sm),
                      FilledButton.icon(
                        key: const Key('update-download'),
                        onPressed: () => unawaited(
                          ref.read(externalLinkProvider)(
                            Uri.parse(latestApkUrl()),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(l10n.updateDownload),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Fenêtre « Nouvelle version disponible », au lancement de l'application.
class UpdateDialog extends ConsumerWidget {
  const new({required this.version, super.key});

  final int version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AlertDialog(
      key: const Key('update-dialog'),
      icon: const Icon(Icons.system_update_rounded),
      title: Text(l10n.updateAvailableTitle),
      content: Text(l10n.updateAvailableBody(version)),
      actions: [
        TextButton(
          key: const Key('update-dialog-later'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.updateLater),
        ),
        FilledButton.icon(
          key: const Key('update-dialog-download'),
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(
              ref.read(externalLinkProvider)(Uri.parse(latestApkUrl())),
            );
          },
          icon: const Icon(Icons.download_rounded),
          label: Text(l10n.updateDownload),
        ),
      ],
    );
  }
}
