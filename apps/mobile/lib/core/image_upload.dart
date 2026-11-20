import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/design_system/image_rules.dart';

/// Envoie une image préparée (règles de l'ADR 0026) puis sa vignette à côté
/// (`…_v.jpg`). La vignette est envoyée au mieux : sans elle, les listes
/// chargent l'image complète.
Future<void> uploadWithThumbnail(
  supabase.StorageFileApi bucket,
  String path,
  PreparedImage image,
) async {
  final options = supabase.FileOptions(
    contentType: image.mimeType,
    cacheControl: '31536000',
  );
  await bucket.uploadBinary(path, image.bytes, fileOptions: options);
  if (image.thumbnail case final thumbnail?) {
    try {
      await bucket.uploadBinary(
        thumbnailPath(path),
        thumbnail,
        fileOptions: options,
      );
    } on Object {
      // Les listes retomberont sur l'image complète.
    }
  }
}

/// Supprime un fichier et sa vignette, sans échec : un fichier orphelin ne
/// gêne personne.
Future<void> removeWithThumbnail(
  supabase.StorageFileApi bucket,
  String path,
) async {
  try {
    await bucket.remove([path, thumbnailPath(path)]);
  } on Object {
    // Ignoré volontairement.
  }
}

/// Recopie la vignette d'un fichier copié, au mieux.
Future<void> copyThumbnail(
  supabase.StorageFileApi bucket,
  String from,
  String to,
) async {
  try {
    await bucket.copy(thumbnailPath(from), thumbnailPath(to));
  } on Object {
    // Image envoyée avant les vignettes : les listes liront l'originale.
  }
}
