import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, immutable;
import 'package:image/image.dart' as img;

/// Règles des images envoyées par les utilisateurs (direction artistique,
/// section 5) : taille conseillée, minimum, poids maximal et vignette.
@immutable
final class ImageRule {
  const new({
    required this.maxLong,
    required this.maxShort,
    required this.minLong,
    required this.minShort,
    required this.maxBytes,
    required this.thumbWidth,
    required this.thumbHeight,
    this.cropThumbnail = true,
    this.keepTransparency = false,
  });

  /// Dimensions maximales (grand côté, petit côté) après réduction.
  final int maxLong;
  final int maxShort;

  /// Dimensions minimales conseillées ; en dessous, l'image reste acceptée
  /// (aucune fonction retirée) mais [PreparedImage.belowMinimum] le signale.
  final int minLong;
  final int minShort;

  /// Poids maximal du fichier principal.
  final int maxBytes;

  /// Vignette, chargée par les listes.
  final int thumbWidth;
  final int thumbHeight;

  /// Vignette recadrée au centre à ses proportions (sinon : contenue).
  final bool cropThumbnail;

  /// Garde la transparence d'un PNG (logo).
  final bool keepTransparency;
}

/// Règles par type d'image.
abstract final class ImageRules {
  /// Couverture d'un événement : 16:9, 1600 × 900, au moins 1200 × 675,
  /// JPEG ≤ 400 Ko, vignette 480 × 270.
  static const cover = ImageRule(
    maxLong: 1600,
    maxShort: 900,
    minLong: 1200,
    minShort: 675,
    maxBytes: 400 * 1024,
    thumbWidth: 480,
    thumbHeight: 270,
  );

  /// Logo de structure : carré 512, au moins 256, ≤ 200 Ko, transparence
  /// acceptée, vignette 128.
  static const logo = ImageRule(
    maxLong: 512,
    maxShort: 512,
    minLong: 256,
    minShort: 256,
    maxBytes: 200 * 1024,
    thumbWidth: 128,
    thumbHeight: 128,
    cropThumbnail: false,
    keepTransparency: true,
  );

  /// Photo de profil : carré 400, au moins 200, JPEG ≤ 150 Ko, vignette 128.
  static const avatar = ImageRule(
    maxLong: 400,
    maxShort: 400,
    minLong: 200,
    minShort: 200,
    maxBytes: 150 * 1024,
    thumbWidth: 128,
    thumbHeight: 128,
  );
}

/// Image prête à l'envoi : fichier principal réduit et compressé, vignette.
@immutable
final class PreparedImage {
  const new({
    required this.bytes,
    required this.mimeType,
    this.thumbnail,
    this.belowMinimum = false,
  });

  final Uint8List bytes;

  /// `image/jpeg` ou `image/png` (aussi celui de la vignette) ; le type
  /// d'origine si l'image n'a pas pu être lue.
  final String mimeType;

  /// Vignette, `null` si l'image n'a pas pu être lue.
  final Uint8List? thumbnail;

  /// Plus petite que le minimum conseillé.
  final bool belowMinimum;

  /// Extension du fichier.
  String get extension => switch (mimeType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
  };
}

/// Prépare une image dans un isolat (décodage et compression hors de
/// l'interface).
Future<PreparedImage> prepareImage(
  Uint8List bytes,
  String mimeType,
  ImageRule rule,
) => compute(_prepare, (bytes, mimeType, rule));

PreparedImage _prepare((Uint8List, String, ImageRule) input) =>
    prepareImageSync(input.$1, input.$2, input.$3);

/// Version synchrone de [prepareImage] (tests).
PreparedImage prepareImageSync(
  Uint8List bytes,
  String mimeType,
  ImageRule rule,
) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } on Object {
    return PreparedImage(bytes: bytes, mimeType: mimeType);
  }
  if (decoded == null) return PreparedImage(bytes: bytes, mimeType: mimeType);
  final source = img.bakeOrientation(decoded);
  final long = math.max(source.width, source.height);
  final short = math.min(source.width, source.height);
  final png =
      rule.keepTransparency && source.hasAlpha && _usesTransparency(source);

  // Réduction aux dimensions maximales, puis compression jusqu'au poids
  // maximal (qualité décroissante, puis nouvelle réduction si besoin).
  var scale = math
      .min(1, math.min(rule.maxLong / long, rule.maxShort / short))
      .toDouble();
  Uint8List main;
  var attempt = 0;
  while (true) {
    final resized = _resize(source, scale);
    main = png ? _png(resized) : _jpegUnder(resized, rule.maxBytes);
    if (main.length <= rule.maxBytes || attempt >= 6) break;
    scale *= 0.85;
    attempt++;
  }

  final thumbnail = _thumbnail(source, rule);
  return PreparedImage(
    bytes: main,
    mimeType: png ? 'image/png' : 'image/jpeg',
    thumbnail: png ? _png(thumbnail) : img.encodeJpg(thumbnail, quality: 78),
    belowMinimum: long < rule.minLong || short < rule.minShort,
  );
}

/// Chemin de la vignette d'un fichier : `abc.jpg` → `abc_v.jpg`. Les noms
/// restent acceptés par les règles des buckets (lettres, chiffres, `_`).
String thumbnailPath(String path) {
  final slash = path.lastIndexOf('/');
  final dot = path.lastIndexOf('.');
  if (dot <= slash) return '${path}_v';
  return '${path.substring(0, dot)}_v${path.substring(dot)}';
}

/// Adresse de la vignette d'une image publique (requête conservée).
String thumbnailUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.path.isEmpty) return url;
  return uri.replace(path: thumbnailPath(uri.path)).toString();
}

img.Image _resize(img.Image source, double scale) => scale >= 1
    ? source
    : img.copyResize(
        source,
        width: math.max(1, (source.width * scale).round()),
        height: math.max(1, (source.height * scale).round()),
        interpolation: img.Interpolation.average,
      );

Uint8List _jpegUnder(img.Image image, int maxBytes) {
  // JPEG sans transparence : fond blanc sous les zones transparentes.
  final opaque = image.hasAlpha ? _onWhite(image) : image;
  late Uint8List bytes;
  for (final quality in const [85, 78, 70, 62, 55, 48]) {
    bytes = img.encodeJpg(opaque, quality: quality);
    if (bytes.length <= maxBytes) break;
  }
  return bytes;
}

Uint8List _png(img.Image image) => img.encodePng(image, level: 9);

img.Image _thumbnail(img.Image source, ImageRule rule) {
  if (!rule.cropThumbnail) {
    final scale = math
        .min(
          1,
          math.min(
            rule.thumbWidth / source.width,
            rule.thumbHeight / source.height,
          ),
        )
        .toDouble();
    return _resize(source, scale);
  }
  // Recadrage au centre aux proportions de la vignette.
  final ratio = rule.thumbWidth / rule.thumbHeight;
  var width = source.width;
  var height = (width / ratio).round();
  if (height > source.height) {
    height = source.height;
    width = (height * ratio).round();
  }
  final cropped = img.copyCrop(
    source,
    x: (source.width - width) ~/ 2,
    y: (source.height - height) ~/ 2,
    width: width,
    height: height,
  );
  return _resize(cropped, math.min(1, rule.thumbWidth / width).toDouble());
}

bool _usesTransparency(img.Image image) {
  for (final pixel in image) {
    if (pixel.a < pixel.maxChannelValue) return true;
  }
  return false;
}

img.Image _onWhite(img.Image image) {
  final background = img.Image(width: image.width, height: image.height)
    ..clear(img.ColorRgb8(255, 255, 255));
  return img.compositeImage(background, image);
}
