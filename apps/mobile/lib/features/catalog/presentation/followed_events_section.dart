import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Nombre d'événements montrés dans « De vos structures suivies ».
const int followedEventsShown = 3;

/// Explorer : « De vos structures suivies » (ADR 0049). Les prochains
/// événements publics des structures que le compte suit, sous « À la une ».
/// Rien sans compte, sans structure suivie, ou si la lecture échoue.
class FollowedEventsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(followedEventsProvider).value ?? const [];
    if (events.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const Key('explore-followed'),
      padding: const EdgeInsets.fromLTRB(
        TikeoSizes.screenMargin,
        0,
        TikeoSizes.screenMargin,
        TikeoSizes.sectionGap - 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.exploreFollowed,
            icon: Icons.storefront_rounded,
            actionLabel: l10n.exploreFollowedSeeAll,
            actionKey: const Key('explore-followed-all'),
            onAction: () =>
                unawaited(context.push(AppRoutes.followedOrganizations)),
          ),
          const SizedBox(height: 8),
          for (final event in events.take(followedEventsShown)) ...[
            PublicEventTile(
              key: Key('explore-followed-${event.id}'),
              event: event,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
