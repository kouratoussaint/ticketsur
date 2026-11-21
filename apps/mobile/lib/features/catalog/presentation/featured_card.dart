import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart'
    show eventKindTag;
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/favorites/presentation/favorite_button.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Photo entière d'un événement (affiche verticale comprise) : les bords
/// sont comblés par la même image floutée et assombrie (#1).
class WholePhoto extends StatelessWidget {
  const new({
    required this.url,
    required this.kind,
    this.thumbnail = false,
    super.key,
  });

  final String? url;
  final EventKind kind;
  final bool thumbnail;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null) {
      return ColoredBox(
        color: eventKindColor(kind),
        child: Center(
          child: Icon(
            eventKindIcon(kind),
            size: 56,
            color: TicketSurColors.white.withValues(alpha: 0.85),
          ),
        ),
      );
    }
    final image = networkImage(url, thumbnail: thumbnail);
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Image(
            image: image,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) =>
                ColoredBox(color: eventKindColor(kind)),
          ),
        ),
        const ColoredBox(color: Color(0x73021A36)),
        Image(
          image: image,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Carte « À la une » d'Explorer : image entière en haut, texte et bouton
/// dessous, sur la carte (plus de texte ni de dégradé sur la photo).
class FeaturedEventCard extends StatelessWidget {
  const new({required this.event, super.key});

  final PublicEventSummary event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final price = summaryPrice(l10n, event);
    final place = summaryPlace(event);
    void open() => unawaited(context.push(AppRoutes.publicEvent(event.id)));
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tints.mint.text),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
    return TikeoCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(TikeoRadii.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(TikeoRadii.card),
              ),
              child: SizedBox(
                height: 210,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WholePhoto(url: event.coverUrl, kind: event.kind),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Color(0x99022445),
                            shape: BoxShape.circle,
                          ),
                          child: FavoriteButton(
                            event: event,
                            color: TicketSurColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      TikeoPill(
                        label: eventKindTag(l10n, event.kind),
                        tint: eventKindTint(event.kind, tints),
                      ),
                      if (price != null)
                        TikeoPill(label: price, tint: tints.mint),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                  line(Icons.event_rounded, summaryWhen(event)),
                  if (place.isNotEmpty) line(Icons.place_rounded, place),
                  const SizedBox(height: 12),
                  TikeoPrimaryButton(
                    key: Key('featured-get-ticket-${event.id}'),
                    onPressed: open,
                    icon: Icons.confirmation_number_rounded,
                    label: l10n.publicEventGetTicket,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section « À la une » d'Explorer : une carte, ou plusieurs côte à côte.
class FeaturedSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(featuredEventsProvider).value ?? const [];
    if (events.isEmpty) return const SizedBox.shrink();
    final width =
        MediaQuery.sizeOf(context).width - 2 * TikeoSizes.screenMargin;
    return Column(
      key: const Key('explore-featured-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TikeoSizes.screenMargin,
          ),
          child: SectionHeader(
            title: l10n.exploreFeatured,
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(height: 8),
        if (events.length == 1)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TikeoSizes.screenMargin,
            ),
            child: FeaturedEventCard(
              key: const Key('explore-featured'),
              event: events.single,
            ),
          )
        else
          SingleChildScrollView(
            key: const Key('explore-featured-list'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: TikeoSizes.screenMargin,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, event) in events.indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  SizedBox(
                    width: width - 32,
                    child: FeaturedEventCard(
                      key: i == 0
                          ? const Key('explore-featured')
                          : Key('explore-featured-${event.id}'),
                      event: event,
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: TikeoSizes.sectionGap - 8),
      ],
    );
  }
}
