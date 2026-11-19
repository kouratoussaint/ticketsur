import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ticketsur/features/events/domain/event.dart';

/// Origine de la photo de couverture.
enum CoverSource {
  /// Appareil photo du téléphone.
  camera,

  /// Galerie de photos.
  gallery,
}

/// Choisit une photo et la renvoie réduite (1600 px au plus, JPEG compressé),
/// ou `null` si l'utilisateur annule.
typedef CoverPicker = Future<CoverImage?> Function(CoverSource source);

/// Sélecteur de photo (image_picker en vrai, faux sélecteur en test).
final coverPickerProvider = Provider<CoverPicker>((ref) => pickCoverImage);

/// Types d'image acceptés par le bucket `event-covers`.
const acceptedCoverTypes = {'image/jpeg', 'image/png', 'image/webp'};

/// Implémentation réelle : la réduction et la compression sont faites par le
/// système (plus rapide et moins gourmand en mémoire qu'en Dart).
Future<CoverImage?> pickCoverImage(CoverSource source) async {
  final file = await ImagePicker().pickImage(
    source: source == CoverSource.camera
        ? ImageSource.camera
        : ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 82,
    requestFullMetadata: false,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return CoverImage(
    bytes: bytes,
    mimeType: coverMimeType(file.mimeType, file.name),
  );
}

/// Type MIME d'une image, déduit de l'extension quand le système ne le donne
/// pas.
String coverMimeType(String? reported, String name) {
  if (reported != null && reported.isNotEmpty) return reported;
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}
