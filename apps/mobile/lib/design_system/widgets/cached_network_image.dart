import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/image_rules.dart';

/// Dossier du cache disque des images distantes (couvertures, photos de
/// profil). Posé par `main.dart` ; `null` dans les tests : on retombe alors
/// sur [NetworkImage].
///
/// Les fichiers du stockage portent un nom aléatoire à chaque envoi : une
/// adresse ne change jamais de contenu, on peut donc la garder sans date
/// d'expiration.
Directory? networkImageCacheDirectory;

/// Taille maximale du cache disque, ramenée au démarrage.
const int networkImageCacheMaxBytes = 80 * 1024 * 1024;

/// Image distante, gardée sur le téléphone après le premier chargement.
///
/// [thumbnail] : charge la vignette (`…_v.jpg`, règles des images de
/// l'ADR 0026) et, si elle n'existe pas (image envoyée avant les
/// vignettes), l'image complète à la place.
ImageProvider networkImage(
  String url, {
  int? cacheWidth,
  bool thumbnail = false,
}) {
  final directory = networkImageCacheDirectory;
  final provider = switch (directory) {
    null => NetworkImage(url) as ImageProvider,
    final dir when thumbnail => DiskCachedNetworkImage(
      thumbnailUrl(url),
      dir,
      fallbackUrl: url,
    ),
    final dir => DiskCachedNetworkImage(url, dir),
  };
  return ResizeImage.resizeIfNeeded(cacheWidth, null, provider);
}

/// [ImageProvider] qui lit le fichier du cache s'il existe, sinon télécharge
/// l'image et l'enregistre.
@immutable
class DiskCachedNetworkImage extends ImageProvider<DiskCachedNetworkImage> {
  const new(this.url, this.directory, {this.fallbackUrl});

  final String url;
  final Directory directory;

  /// Adresse lue si [url] répond par une erreur (vignette absente). Le
  /// résultat est gardé sous [url] : l'erreur ne se répète pas.
  final String? fallbackUrl;

  @override
  Future<DiskCachedNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    DiskCachedNetworkImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(decode),
    scale: 1,
    debugLabel: url,
  );

  File get _file => File('${directory.path}/${cacheFileName(url)}');

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final file = _file;
    if (file.existsSync()) {
      try {
        final bytes = await file.readAsBytes();
        // Date d'accès pour l'élagage (les plus anciens partent d'abord).
        unawaited(
          file.setLastModified(DateTime.now()).then((_) {}, onError: (_) {}),
        );
        return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      } on Object {
        // Fichier abîmé : on le retire et on retélécharge.
        try {
          file.deleteSync();
        } on Object {
          // Déjà parti.
        }
      }
    }
    var uri = Uri.parse(url);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      var response = await (await client.getUrl(uri)).close();
      if (response.statusCode != HttpStatus.ok && fallbackUrl != null) {
        await response.drain<void>();
        uri = Uri.parse(fallbackUrl!);
        response = await (await client.getUrl(uri)).close();
      }
      if (response.statusCode != HttpStatus.ok) {
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: uri,
        );
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isEmpty) {
        throw NetworkImageLoadException(statusCode: 0, uri: uri);
      }
      final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      unawaited(_store(file, bytes));
      return codec;
    } finally {
      client.close();
    }
  }

  static Future<void> _store(File file, Uint8List bytes) async {
    try {
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.part');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
    } on Object {
      // Disque plein ou dossier retiré : l'image reste affichée.
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DiskCachedNetworkImage &&
      other.url == url &&
      other.fallbackUrl == fallbackUrl &&
      other.directory.path == directory.path;

  @override
  int get hashCode => Object.hash(url, fallbackUrl, directory.path);
}

/// Nom de fichier stable pour une adresse (deux FNV-1a 32 bits + extension).
String cacheFileName(String url) {
  int fnv(Iterable<int> units) {
    var hash = 0x811c9dc5;
    for (final unit in units) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  final units = url.codeUnits;
  String hex(int value) => value.toRadixString(16).padLeft(8, '0');
  final name = hex(fnv(units)) + hex(fnv(units.reversed));
  final path = Uri.tryParse(url)?.path ?? '';
  final dot = path.lastIndexOf('.');
  final extension = dot >= 0 && path.length - dot <= 5
      ? path.substring(dot).toLowerCase()
      : '';
  return '$name$extension';
}

/// Ramène le cache sous [maxBytes] en retirant les fichiers les plus anciens.
Future<void> pruneNetworkImageCache(
  Directory directory, {
  int maxBytes = networkImageCacheMaxBytes,
}) async {
  try {
    if (!directory.existsSync()) return;
    final files = [
      for (final entity in directory.listSync())
        if (entity is File) entity,
    ];
    var total = 0;
    final stats = <(File, FileStat)>[];
    for (final file in files) {
      final stat = file.statSync();
      total += stat.size;
      stats.add((file, stat));
    }
    if (total <= maxBytes) return;
    stats.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    for (final (file, stat) in stats) {
      if (total <= maxBytes * 0.8) break;
      try {
        file.deleteSync();
        total -= stat.size;
      } on Object {
        // Fichier en cours d'écriture : on passe.
      }
    }
  } on Object {
    // Le cache n'est jamais bloquant.
  }
}
