import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Demande d'où vient l'image : galerie ou appareil photo. `null` si
/// l'utilisateur ferme la feuille.
Future<CoverSource?> showImageSourceSheet(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<CoverSource>(
    context: context,
    // La page peut être au-dessus du shell : la feuille doit l'être aussi.
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('cover-source-gallery'),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.eventCoverGallery),
            onTap: () => Navigator.of(context).pop(CoverSource.gallery),
          ),
          ListTile(
            key: const Key('cover-source-camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.eventCoverCamera),
            onTap: () => Navigator.of(context).pop(CoverSource.camera),
          ),
        ],
      ),
    ),
  );
}
