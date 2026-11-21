import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/favorites/application/favorites_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Cœur « Ajouter aux favoris » d'un événement public.
class FavoriteButton extends ConsumerWidget {
  const new({
    required this.event,
    this.color,
    this.selectedColor,
    this.undoable = false,
    super.key,
  });

  final PublicEventSummary event;

  /// Couleur du cœur vide (par défaut, celle du thème).
  final Color? color;

  /// Couleur du cœur plein (par défaut, l'accent).
  final Color? selectedColor;

  /// Retrait annulable depuis le message (« Mes favoris »).
  final bool undoable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final favorite = ref.watch(
      favoritesProvider.select((list) => list.any((e) => e.id == event.id)),
    );
    return IconButton(
      key: Key('favorite-${event.id}'),
      tooltip: favorite ? l10n.favoriteRemove : l10n.favoriteAdd,
      isSelected: favorite,
      icon: Icon(Icons.favorite_border_rounded, color: color),
      selectedIcon: Icon(
        Icons.favorite_rounded,
        color: selectedColor ?? TicketSurColors.spark,
      ),
      onPressed: () async {
        final toast = Toaster.of(context);
        final favorites = ref.read(favoritesProvider.notifier);
        ref.read(feedbackProvider).tap();
        final added = await favorites.toggle(event);
        toast.info(
          added ? l10n.favoriteAdded : l10n.favoriteRemoved,
          action: !added && undoable
              ? SnackBarAction(
                  key: const Key('favorite-undo'),
                  label: l10n.favoriteUndo,
                  onPressed: () {
                    if (!favorites.contains(event.id)) {
                      unawaited(favorites.toggle(event));
                    }
                  },
                )
              : null,
        );
      },
    );
  }
}
