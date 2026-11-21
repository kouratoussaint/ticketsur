import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Octets d'une image distante (remplacé en test).
final imageBytesProvider = Provider<Future<Uint8List> Function(String url)>(
  (ref) => networkImageBytes,
);

/// Enregistre une image dans la galerie du téléphone (remplacé en test).
final gallerySaverProvider =
    Provider<Future<void> Function(Uint8List bytes, String name)>(
      (ref) => (bytes, name) async {
        if (!await Gal.hasPermission()) await Gal.requestPermission();
        await Gal.putImageBytes(bytes, name: name);
      },
    );

/// Nom de fichier lisible et sûr à partir d'un titre.
String imageFileName(String title) {
  final slug = title
      .toLowerCase()
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final short = slug.length > 40 ? slug.substring(0, 40) : slug;
  return 'Tikeo-${short.isEmpty ? 'evenement' : short}';
}

/// Ouvre la photo d'un événement en plein écran (#2).
Future<void> openEventPhoto(
  BuildContext context, {
  required String url,
  required String title,
}) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder<void>(
    barrierColor: Colors.black,
    pageBuilder: (context, animation, secondary) => FadeTransition(
      opacity: animation,
      child: EventPhotoViewer(url: url, title: title),
    ),
  ),
);

/// Bouton « Voir la photo en grand » posé sur une photo d'événement.
class PhotoZoomButton extends StatelessWidget {
  const new({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x99000000),
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: IconButton(
      tooltip: context.l10n.photoOpen,
      onPressed: onPressed,
      color: TicketSurColors.white,
      icon: const Icon(Icons.zoom_out_map_rounded),
    ),
  );
}

/// Photo entière sur fond noir : zoom par pincement, Fermer, Partager,
/// Télécharger (galerie).
class EventPhotoViewer extends ConsumerStatefulWidget {
  const new({required this.url, required this.title, super.key});

  final String url;
  final String title;

  @override
  ConsumerState<EventPhotoViewer> createState() => _EventPhotoViewerState();
}

class _EventPhotoViewerState extends ConsumerState<EventPhotoViewer> {
  bool _busy = false;

  Future<void> _withBytes(
    Future<void> Function(Uint8List bytes) action,
    String Function() success,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(imageBytesProvider)(widget.url);
      await action(bytes);
      final message = success();
      if (message.isNotEmpty) toast.success(message);
    } on Object {
      toast.error(l10n.photoSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() {
    final l10n = context.l10n;
    final save = ref.read(gallerySaverProvider);
    return _withBytes(
      (bytes) => save(bytes, imageFileName(widget.title)),
      () => l10n.photoSaved,
    );
  }

  Future<void> _share() {
    final share = ref.read(shareFilesProvider);
    return _withBytes(
      (bytes) => share([
        (
          bytes: bytes,
          name: '${imageFileName(widget.title)}.jpg',
          mimeType: 'image/jpeg',
        ),
      ], text: widget.title),
      () => '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const white = TicketSurColors.white;
    return Scaffold(
      key: const Key('photo-viewer'),
      backgroundColor: Colors.black,
      // Pile à la taille de l'écran : sans `fit`, elle prenait la hauteur de
      // la barre des boutons et la photo s'affichait toute petite en haut
      // (constaté sur téléphone le 21/11).
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              key: const Key('photo-viewer-zoom'),
              maxScale: 5,
              // Photo à la taille de l'écran, centrée, entière.
              child: SizedBox.expand(
                child: Image(
                  key: const Key('photo-viewer-image'),
                  image: networkImage(widget.url),
                  fit: BoxFit.contain,
                  semanticLabel: widget.title,
                  errorBuilder: (context, error, stack) => const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      key: const Key('photo-viewer-close'),
                      tooltip: l10n.photoClose,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Spacer(),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: white,
                          ),
                        ),
                      )
                    else ...[
                      IconButton.filledTonal(
                        key: const Key('photo-viewer-share'),
                        tooltip: l10n.photoShare,
                        onPressed: () => unawaited(_share()),
                        icon: const Icon(Icons.share_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        key: const Key('photo-viewer-download'),
                        tooltip: l10n.photoDownload,
                        onPressed: () => unawaited(_download()),
                        icon: const Icon(Icons.download_rounded),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
