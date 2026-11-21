import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Rendu hors écran de [child] à la taille [size] (couche de l'Overlay
/// décalée, jamais visible), en PNG. Les [images] sont décodées avant
/// l'unique cadre de rendu ; une image absente laisse son emplacement vide.
Future<Uint8List> renderWidgetPng(
  BuildContext context, {
  required Widget child,
  required Size size,
  List<ImageProvider> images = const [],
  double pixelRatio = 1,
}) async {
  for (final image in images) {
    if (!context.mounted) throw StateError('context unmounted');
    await precacheImage(image, context, onError: (_, _) {});
  }
  if (!context.mounted) throw StateError('context unmounted');
  final overlay = Overlay.of(context, rootOverlay: true);
  final theme = Theme.of(context);
  final boundaryKey = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -20000,
      top: 0,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: MediaQuery(
            // Taille de texte fixe : l'image ne dépend pas du téléphone.
            data: const MediaQueryData(),
            child: Theme(
              data: theme,
              child: RepaintBoundary(
                key: boundaryKey,
                child: Material(type: MaterialType.transparency, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  } finally {
    entry.remove();
  }
}
