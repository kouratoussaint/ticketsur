import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';

/// Photo de couverture d'un événement au format 16:9.
///
/// Affiche, par ordre de priorité : l'image locale [bytes] (pas encore
/// envoyée), l'image distante [url], ou une illustration aux couleurs de la
/// marque avec l'icône du type d'événement.
class EventCover extends StatelessWidget {
  const new({
    required this.kind,
    this.url,
    this.bytes,
    this.borderRadius = BorderRadius.zero,
    this.aspectRatio = 16 / 9,
    this.overlay,
    super.key,
  });

  /// Couverture d'un événement existant.
  factory forEvent(
    TicketEvent event, {
    BorderRadius borderRadius = BorderRadius.zero,
    double aspectRatio = 16 / 9,
    Widget? overlay,
    Key? key,
  }) => EventCover(
    kind: event.kind,
    url: event.coverUrl,
    borderRadius: borderRadius,
    aspectRatio: aspectRatio,
    overlay: overlay,
    key: key,
  );

  final EventKind kind;
  final String? url;
  final Uint8List? bytes;
  final BorderRadius borderRadius;
  final double aspectRatio;

  /// Contenu superposé (dégradé, titre, pastilles…).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final placeholder = _CoverPlaceholder(kind: kind);
    final Widget image;
    if (bytes case final data?) {
      image = Image.memory(
        data,
        key: const Key('event-cover-local'),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (url case final link?) {
      image = LayoutBuilder(
        builder: (context, constraints) => Image(
          image: networkImage(
            link,
            cacheWidth: _decodeWidth(context, constraints.maxWidth),
          ),
          key: const Key('event-cover-remote'),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSync) => wasSync
              ? child
              : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: child,
                ),
          errorBuilder: (context, error, stack) => placeholder,
        ),
      );
    } else {
      image = placeholder;
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fond visible pendant le chargement de l'image distante.
            if (url != null && bytes == null) placeholder,
            image,
            ?overlay,
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const new({required this.kind});

  final EventKind kind;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('event-cover-placeholder'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TicketSurColors.navy, TicketSurColors.navyLight],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxHeight * 0.36;
          return Stack(
            children: [
              Positioned(
                right: -size * 0.35,
                bottom: -size * 0.35,
                child: Icon(
                  eventKindIcon(kind),
                  size: size * 2.2,
                  color: TicketSurColors.white.withValues(alpha: 0.07),
                ),
              ),
              Center(
                child: Icon(
                  eventKindIcon(kind),
                  size: size,
                  color: TicketSurColors.mint.withValues(alpha: 0.85),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Dégradé sombre en bas d'une couverture, pour y poser du texte blanc
/// lisible quelle que soit la photo.
class CoverScrim extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.35, 1],
          colors: [
            TicketSurColors.navy.withValues(alpha: 0),
            TicketSurColors.navy.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Largeur de décodage : celle de l'affichage en pixels réels, sans
/// décoder une photo de 4 000 pixels pour une vignette.
int? _decodeWidth(BuildContext context, double width) {
  if (!width.isFinite || width <= 0) return null;
  return (width * MediaQuery.devicePixelRatioOf(context)).ceil();
}
