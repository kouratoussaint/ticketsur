import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/daily_bars.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/tabular_figures.dart';
import 'package:ticketsur/features/audience/application/audience_providers.dart';
import 'package:ticketsur/features/audience/domain/audience.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Fiche de l'événement (promoteur) : vues de la fiche publique sur 7 jours,
/// au total, et barres des 30 derniers jours (ADR 0051). Rien en cas
/// d'échec : la fiche reste utilisable.
class EventViewsCard extends ConsumerWidget {
  const new({required this.event, super.key});

  final TicketEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final views = ref.watch(eventViewsProvider(event.id)).value;
    if (views == null) return const SizedBox.shrink();
    return TikeoCard(
      key: const Key('event-views'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.audienceViewsTitle,
            icon: Icons.visibility_rounded,
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          TabularFigures(
            child: Text(
              l10n.audienceViewsSummary(views.recent, views.total),
              key: const Key('event-views-summary'),
              style: textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: TicketSurSpacing.sm),
          DailyBars(
            values: [for (final d in views.days) d.count],
            color: context.tints.mint.icon,
          ),
          const SizedBox(height: TicketSurSpacing.xxs),
          Text(
            event.isPublic ? l10n.audienceViewsHint : l10n.audienceViewsPrivate,
            key: const Key('event-views-hint'),
            style: textTheme.bodySmall?.copyWith(
              color: context.palette.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Résumé « 12 abonnés · +3 sur 30 jours » (`null` tant que rien n'est lu).
String? followerSummary(BuildContext context, AudienceSeries? stats) =>
    stats == null
    ? null
    : context.l10n.audienceFollowersSummary(stats.total, stats.recent);

/// Abonnés de la structure : nombre, arrivées sur 30 jours, barres, lien
/// vers la page publique.
Future<void> showFollowerStatsSheet(
  BuildContext context, {
  required String organizationId,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _FollowerStatsSheet(organizationId: organizationId),
);

class _FollowerStatsSheet extends ConsumerWidget {
  const new({required this.organizationId});

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final stats = ref.watch(followerStatsProvider(organizationId));
    return SingleChildScrollView(
      key: const Key('follower-stats'),
      padding: const EdgeInsets.fromLTRB(
        TikeoSizes.screenMargin,
        0,
        TikeoSizes.screenMargin,
        TikeoSizes.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.audienceFollowersTitle, style: textTheme.titleLarge),
          const SizedBox(height: TicketSurSpacing.sm),
          switch (stats) {
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabularFigures(
                  child: Text(
                    l10n.audienceFollowersCount(value.total),
                    key: const Key('follower-stats-count'),
                    style: TikeoTextStyles.bigNumber.copyWith(
                      color: textTheme.titleLarge?.color,
                    ),
                  ),
                ),
                Text(
                  l10n.audienceFollowersNew(value.recent),
                  key: const Key('follower-stats-new'),
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: TicketSurSpacing.sm),
                DailyBars(
                  values: [for (final d in value.days) d.count],
                  color: context.tints.violet.icon,
                  height: 72,
                ),
                const SizedBox(height: TicketSurSpacing.xxs),
                Text(
                  l10n.audienceFollowersHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.mutedText,
                  ),
                ),
              ],
            ),
            AsyncError() => Text(
              l10n.audienceLoadError,
              key: const Key('follower-stats-error'),
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
          const SizedBox(height: TicketSurSpacing.md),
          TikeoPrimaryButton(
            key: const Key('follower-stats-page'),
            label: l10n.audienceOpenPublicPage,
            icon: Icons.storefront_rounded,
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              unawaited(
                router.push(AppRoutes.publicOrganization(organizationId)),
              );
            },
          ),
        ],
      ),
    );
  }
}
