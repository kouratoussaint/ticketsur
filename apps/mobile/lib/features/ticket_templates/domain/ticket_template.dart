import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_theme.dart';

/// Modèle visuel d'une catégorie de tickets (ADR 0022). Ce n'est qu'un fond :
/// le QR, son format et la validation à la porte ne changent pas.
sealed class TicketTemplate {
  const new();
}

/// Un des 12 thèmes intégrés.
@immutable
final class BuiltinTemplate extends TicketTemplate {
  const new(this.themeId, {this.singleFontTitle = false});

  final int themeId;

  /// Titre écrit d'une seule police (pas de manuscrit ni de condensé).
  final bool singleFontTitle;

  TicketTheme get theme => themeById(themeId);

  @override
  bool operator ==(Object other) =>
      other is BuiltinTemplate &&
      other.themeId == themeId &&
      other.singleFontTitle == singleFontTitle;

  @override
  int get hashCode => Object.hash(themeId, singleFontTitle);
}

/// Design importé par le promoteur, QR et référence posés dessus.
final class CustomTemplate extends TicketTemplate {
  const new({
    required this.width,
    required this.height,
    required this.placement,
    this.imagePath,
    this.imageUrl,
    this.localBytes,
  });

  /// Chemin dans le bucket `event-covers` (`null` avant l'envoi).
  final String? imagePath;

  /// Adresse publique de l'image enregistrée.
  final String? imageUrl;

  /// Image choisie sur le téléphone, pas encore envoyée.
  final Uint8List? localBytes;

  /// Taille de l'image en pixels.
  final int width;
  final int height;

  final QrPlacement placement;

  double get aspectRatio => width / height;

  CustomTemplate withPlacement(QrPlacement next) => CustomTemplate(
    width: width,
    height: height,
    placement: next,
    imagePath: imagePath,
    imageUrl: imageUrl,
    localBytes: localBytes,
  );

  CustomTemplate uploaded(String path, String url) => CustomTemplate(
    width: width,
    height: height,
    placement: placement,
    imagePath: path,
    imageUrl: url,
  );
}

/// Position du QR et de la référence sur un design importé, en proportions :
/// [qrX] et [refX] de la largeur, [qrY], [refY] et [qrSize] de la hauteur.
@immutable
final class QrPlacement {
  const new({
    required this.qrX,
    required this.qrY,
    required this.qrSize,
    required this.refX,
    required this.refY,
  });

  /// Le QR occupe au moins 35 % de la hauteur du ticket (lisibilité).
  static const double minSize = 0.35;

  final double qrX;
  final double qrY;
  final double qrSize;

  /// Centre horizontal et haut du bloc de la référence.
  final double refX;
  final double refY;

  /// Taille maximale du QR pour un ticket de proportions [aspect].
  static double maxSize(double aspect) => math.min(1, aspect);

  /// Placement ramené dans le ticket (taille comprise entre le minimum et
  /// le maximum, QR entièrement visible).
  QrPlacement clamped(double aspect) {
    final size = qrSize.clamp(minSize, maxSize(aspect));
    final widthShare = size / aspect;
    return QrPlacement(
      qrX: qrX.clamp(0, 1 - widthShare),
      qrY: qrY.clamp(0, 1 - size),
      qrSize: size,
      refX: refX.clamp(0, 1),
      refY: refY.clamp(0, 0.9),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QrPlacement &&
      other.qrX == qrX &&
      other.qrY == qrY &&
      other.qrSize == qrSize &&
      other.refX == refX &&
      other.refY == refY;

  @override
  int get hashCode => Object.hash(qrX, qrY, qrSize, refX, refY);
}

/// Plus grand carré clair d'une image réduite (pixels RGBA), en pixels :
/// coin haut gauche et côté. `null` si l'image n'a aucun pixel clair.
({int x, int y, int side})? largestLightSquare(
  Uint8List rgba,
  int width,
  int height, {
  int threshold = 235,
}) {
  var best = 0;
  var bestX = 0;
  var bestY = 0;
  var previous = List<int>.filled(width, 0);
  var current = List<int>.filled(width, 0);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final light =
          rgba[i] >= threshold &&
          rgba[i + 1] >= threshold &&
          rgba[i + 2] >= threshold;
      if (!light) {
        current[x] = 0;
        continue;
      }
      final int value;
      if (x == 0 || y == 0) {
        value = 1;
      } else {
        value =
            1 +
            math.min(previous[x], math.min(current[x - 1], previous[x - 1]));
      }
      current[x] = value;
      if (value > best) {
        best = value;
        bestX = x - value + 1;
        bestY = y - value + 1;
      }
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return best == 0 ? null : (x: bestX, y: bestY, side: best);
}

/// Placement proposé sur un design de [width] × [height] pixels : dans le
/// plus grand carré clair [square] (mesuré sur une image réduite de
/// [sampleWidth] × [sampleHeight]) s'il fait au moins 35 % de la hauteur,
/// sinon sur le carré blanc de Tikéo, centré dans le dernier quart droit.
QrPlacement defaultPlacement({
  required int width,
  required int height,
  ({int x, int y, int side})? square,
  int? sampleWidth,
  int? sampleHeight,
}) {
  final aspect = width / height;
  double qrX;
  double qrY;
  double size;
  final share = (square != null && sampleHeight != null)
      ? square.side / sampleHeight
      : 0.0;
  if (square != null &&
      sampleWidth != null &&
      sampleHeight != null &&
      share >= QrPlacement.minSize) {
    // Petite marge à l'intérieur du carré clair.
    size = math.max(QrPlacement.minSize, share * 0.94);
    final centerX = (square.x + square.side / 2) / sampleWidth;
    final centerY = (square.y + square.side / 2) / sampleHeight;
    qrX = centerX - size / aspect / 2;
    qrY = centerY - size / 2;
  } else {
    size = math.min(0.6, QrPlacement.maxSize(aspect));
    qrX = 0.875 - size / aspect / 2;
    qrY = (1 - size) / 2;
  }
  final placed = QrPlacement(
    qrX: qrX,
    qrY: qrY,
    qrSize: size,
    refX: 0,
    refY: 0,
  ).clamped(aspect);
  final below = placed.qrY + placed.qrSize + 0.02;
  return QrPlacement(
    qrX: placed.qrX,
    qrY: placed.qrY,
    qrSize: placed.qrSize,
    refX: placed.qrX + placed.qrSize / aspect / 2,
    refY: below <= 0.8 ? below : math.max(0, placed.qrY - 0.22),
  ).clamped(aspect);
}

/// Mise en page d'un ticket, en unités de référence (largeur 1080) :
/// partagée par le rendu Flutter et le PDF pour placer les éléments propres
/// à chaque ticket (QR, numéro, référence, titulaire).
@immutable
final class TicketGeometry {
  const new raw({required this.size, required this.qr, required this.custom});

  factory of(TicketTemplate template) => switch (template) {
    BuiltinTemplate() => const TicketGeometry.raw(
      size: Size(width, builtinHeight),
      qr: Rect.fromLTWH(stubLeft + 34, 76, 200, 200),
      custom: false,
    ),
    CustomTemplate(:final placement, :final aspectRatio) => () {
      final height = width / aspectRatio;
      final side = placement.qrSize * height;
      return TicketGeometry.raw(
        size: Size(width, height),
        qr: Rect.fromLTWH(
          placement.qrX * width,
          placement.qrY * height,
          side,
          side,
        ),
        custom: true,
      );
    }(),
  };

  /// Largeur de référence de tous les tickets.
  static const double width = 1080;

  /// Hauteur des thèmes intégrés (format 2,4:1).
  static const double builtinHeight = 450;

  /// Début du talon des thèmes intégrés (largeur 268).
  static const double stubLeft = 812;
  static const double stubWidth = 268;

  /// Trait vertical d'accent, juste avant le talon.
  static const double accentBarWidth = 7;

  /// Ligne du titulaire (thèmes intégrés) : à gauche, au-dessus du filet.
  static const Rect holder = Rect.fromLTWH(40, 312, 740, 26);

  /// Numéro et référence (thèmes intégrés), centrés dans le talon.
  static const double numberTop = 288;
  static const double referenceTop = 312;

  /// Bloc de la référence sur un design importé : largeur et tailles.
  static const double customBlockWidth = 320;

  /// Taille du ticket.
  final Size size;

  /// Carré du QR, marge blanche de 4 modules comprise.
  final Rect qr;
  final bool custom;

  /// Marge blanche de 4 modules d'un QR de 33 modules (format `TS1.`).
  static double quietZone(double side) => side * 4 / 41;
}

/// Numéro d'ordre affiché : « 000123 ».
String formatTicketNumber(int number) => number.toString().padLeft(6, '0');

/// Catégorie et numéro d'ordre d'un ticket (`ticket_art_info`).
typedef TicketArtInfo = ({String categoryId, int number});

/// Tout ce qu'il faut pour dessiner les tickets d'un événement.
@immutable
final class TicketArt {
  const new({
    required this.event,
    required this.organizationName,
    this.organizationLogoUrl,
    this.templates = const {},
    this.info = const {},
  });

  final TicketEvent event;
  final String organizationName;
  final String? organizationLogoUrl;

  /// Modèles enregistrés, par catégorie.
  final Map<String, TicketTemplate> templates;

  /// Catégorie et numéro, par ticket.
  final Map<String, TicketArtInfo> info;

  /// Modèle d'une catégorie : enregistré, sinon proposé selon le type.
  TicketTemplate templateFor(String? categoryId) =>
      templates[categoryId] ?? BuiltinTemplate(defaultThemeFor(event.kind));

  /// Modèle du ticket [ticketId].
  TicketTemplate templateOfTicket(String ticketId) =>
      templateFor(info[ticketId]?.categoryId);
}

/// Échecs présentés au promoteur (codes de la migration 3100).
enum TemplateFailure implements Exception {
  /// QR sous 35 % de la hauteur (`template_qr_too_small`).
  qrTooSmall,

  /// Image absente ou mal placée (`template_image_invalid`).
  imageInvalid,

  /// Image trop lourde (plus de 2 Mo).
  imageTooLarge,

  /// Image illisible ou de mauvaises proportions.
  imageFormat,

  /// Événement clôturé (`event_locked`).
  locked,

  /// Droits insuffisants (`category_not_found`, `event_not_found`).
  notFound,

  /// Placement refusé (`template_invalid`).
  invalid,

  /// Réseau.
  network;

  static TemplateFailure fromCode(String code) => switch (code) {
    'template_qr_too_small' => qrTooSmall,
    'template_image_invalid' => imageInvalid,
    'event_locked' => locked,
    'category_not_found' || 'event_not_found' => notFound,
    'template_invalid' => invalid,
    _ => network,
  };
}

/// Modèles de tickets (migration 3100) et images importées.
abstract interface class TicketTemplateRepository {
  /// Modèles enregistrés des catégories de l'événement.
  Future<Map<String, TicketTemplate>> forEvent(String eventId);

  /// Enregistre le modèle d'une catégorie ; `null` : retour au modèle
  /// proposé. Lève [TemplateFailure].
  Future<void> save(String categoryId, TicketTemplate? template);

  /// Envoie l'image d'un design et renvoie son chemin. Lève
  /// [TemplateFailure].
  Future<String> uploadImage(
    TicketEvent event,
    Uint8List bytes,
    String mimeType,
  );

  /// Adresse publique d'une image enregistrée.
  String imageUrl(String path);

  /// Catégorie et numéro d'ordre des tickets.
  Future<Map<String, TicketArtInfo>> artInfo(List<String> ticketIds);
}
