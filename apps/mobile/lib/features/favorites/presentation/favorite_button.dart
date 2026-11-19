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
  const new({required this.event, this.color, super.key});

  final PublicEventSummary event;

  /// Couleur du cœur vide (par défaut, celle du thème).
  final Color? color;

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
      selectedIcon: const Icon(
        Icons.favorite_rounded,
        color: TicketSurColors.spark,
      ),
      onPressed: () async {
        final toast = Toaster.of(context);
        ref.read(feedbackProvider).tap();
        final added = await ref.read(favoritesProvider.notifier).toggle(event);
        toast.info(added ? l10n.favoriteAdded : l10n.favoriteRemoved);
      },
    );
  }
}
