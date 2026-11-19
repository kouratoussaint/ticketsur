import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/favorites/application/favorites_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Événements mis en favori sur cet appareil : à venir d'abord, puis passés.
class FavoritesPage extends ConsumerWidget {
  const new({this.showBack = true, super.key});

  /// Faux dans l'onglet Favoris (pas de flèche de retour).
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final favorites = ref.watch(favoritesProvider);
    final now = ref.watch(catalogClockProvider)().toUtc();
    final upcoming = [
      for (final e in favorites)
        if (!e.endsAt.isBefore(now)) e,
    ];
    final past = [
      for (final e in favorites.reversed)
        if (e.endsAt.isBefore(now)) e,
    ];
    final textTheme = Theme.of(context).textTheme;
    Widget header(String text, Key key) => Padding(
      padding: const EdgeInsets.only(
        top: TicketSurSpacing.sm,
        bottom: TicketSurSpacing.xs,
      ),
      child: Text(text, key: key, style: textTheme.titleMedium),
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        title: Text(l10n.favoritesTitle),
      ),
      body: favorites.isEmpty
          ? EmptyState(
              icon: Icons.favorite_rounded,
              title: l10n.favoritesEmptyTitle,
              titleKey: const Key('favorites-empty'),
              body: l10n.favoritesEmptyBody,
              actionLabel: l10n.favoritesExplore,
              actionKey: const Key('favorites-explore'),
              onAction: () => context.go(AppRoutes.explore),
            )
          : ListView(
              padding: const EdgeInsets.all(TicketSurSpacing.md),
              children: [
                if (upcoming.isNotEmpty) ...[
                  header(
                    l10n.favoritesUpcoming,
                    const Key('favorites-upcoming'),
                  ),
                  for (final event in upcoming)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: TicketSurSpacing.sm,
                      ),
                      child: PublicEventTile(event: event),
                    ),
                ],
                if (past.isNotEmpty) ...[
                  header(l10n.favoritesPast, const Key('favorites-past')),
                  for (final event in past)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: TicketSurSpacing.sm,
                      ),
                      child: PublicEventTile(event: event),
                    ),
                ],
              ],
            ),
    );
  }
}
