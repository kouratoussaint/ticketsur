import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fichier choisi par l'utilisateur, lu en mémoire.
typedef PickedFile = ({String name, Uint8List bytes});

/// Taille maximale d'une liste importée.
const int maxImportFileBytes = 5 * 1024 * 1024;

/// Fichier trop volumineux.
final class ImportFileTooLarge implements Exception {
  const new();
}

/// Choix d'un fichier par le sélecteur Android (remplacé en test).
/// `null` : l'utilisateur a renoncé. Lève [ImportFileTooLarge] au-delà de
/// [maxImportFileBytes].
final importFilePickerProvider = Provider<Future<PickedFile?> Function()>(
  (ref) => () async {
    // Tous types : selon les appareils, Android ne reconnaît pas les CSV
    // par leur extension ; le format est vérifié à la lecture.
    final files = await FilePicker.pickFiles();
    final file = files.firstOrNull;
    if (file == null) return null;
    final size = await file.xFile.length();
    if (size > maxImportFileBytes) throw const ImportFileTooLarge();
    return (name: file.name, bytes: await file.xFile.readAsBytes());
  },
);
