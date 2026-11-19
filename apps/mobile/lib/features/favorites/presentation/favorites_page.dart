import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: TicketSurSpacing.md),
                    Text(
                      l10n.favoritesEmptyTitle,
                      key: const Key('favorites-empty'),
                      style: textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: TicketSurSpacing.xs),
                    Text(l10n.favoritesEmptyBody, textAlign: TextAlign.center),
                    const SizedBox(height: TicketSurSpacing.lg),
                    FilledButton.tonal(
                      key: const Key('favorites-explore'),
                      onPressed: () => context.go(AppRoutes.explore),
                      child: Text(l10n.favoritesExplore),
                    ),
                  ],
                ),
              ),
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
