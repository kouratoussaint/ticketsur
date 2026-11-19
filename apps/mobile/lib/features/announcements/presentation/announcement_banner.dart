import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/features/announcements/application/announcement_providers.dart';
import 'package:ticketsur/features/announcements/domain/announcement.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Annonces de l'équipe Tikéo pour l'utilisateur (au plus deux), masquables.
class AnnouncementBanner extends ConsumerWidget {
  const new({
    this.padding = const EdgeInsets.only(bottom: TicketSurSpacing.sm),
    super.key,
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dismissed = ref.watch(dismissedAnnouncementsProvider);
    final visible = [
      for (final a
          in ref.watch(myAnnouncementsProvider).value ?? const <Announcement>[])
        if (!dismissed.contains(a.id)) a,
    ].take(2).toList();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return MotionSize(
      child: visible.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final a in visible)
                    Card(
                      key: Key('announcement-${a.id}'),
                      color: a.important
                          ? scheme.errorContainer
                          : scheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TicketSurSpacing.md,
                          TicketSurSpacing.sm,
                          TicketSurSpacing.xxs,
                          TicketSurSpacing.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: TicketSurSpacing.xs,
                              ),
                              child: Icon(
                                a.important
                                    ? Icons.campaign_rounded
                                    : Icons.info_outline_rounded,
                                color: a.important
                                    ? scheme.onErrorContainer
                                    : scheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: TicketSurSpacing.sm),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: TicketSurSpacing.xs,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.title,
                                      style: textTheme.titleSmall?.copyWith(
                                        color: a.important
                                            ? scheme.onErrorContainer
                                            : scheme.onSecondaryContainer,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: TicketSurSpacing.xxs,
                                    ),
                                    Text(
                                      a.body,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: a.important
                                            ? scheme.onErrorContainer
                                            : scheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              key: Key('announcement-dismiss-${a.id}'),
                              tooltip: l10n.announcementDismiss,
                              color: a.important
                                  ? scheme.onErrorContainer
                                  : scheme.onSecondaryContainer,
                              onPressed: () => unawaited(
                                ref
                                    .read(
                                      dismissedAnnouncementsProvider.notifier,
                                    )
                                    .dismiss(a.id),
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
