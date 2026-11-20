import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
import 'package:ticketsur/features/ticket_templates/presentation/ticket_artwork.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Image PNG d'un ticket avec le modèle de sa catégorie, rendue hors de
/// l'écran (couche de l'Overlay décalée, jamais visible). 2160 px de large
/// par défaut : le QR reste lisible après la compression de WhatsApp.
Future<Uint8List> renderTicketPng(
  BuildContext context, {
  required TicketArt art,
  required TicketSecret ticket,
  double pixelRatio = 2,
}) {
  final template = art.templateOfTicket(ticket.ticketId);
  return renderArtworkPng(
    context,
    artwork: TicketArtwork(
      art: art,
      template: template,
      categoryName: ticket.categoryName,
      number: art.info[ticket.ticketId]?.number,
      reference: ticket.reference,
      token: ticket.token,
      holderName: ticket.holderName,
      invitation: ticket.isInvitation,
    ),
    pixelRatio: pixelRatio,
  );
}

/// Fond d'une catégorie (sans QR, numéro, référence ni titulaire), pour le
/// PDF : rendu une fois, partagé par tous ses tickets.
Future<Uint8List?> renderTicketBackground(
  BuildContext context, {
  required TicketArt art,
  required TicketTemplate template,
  required String categoryName,
  bool invitation = false,
}) => renderArtworkPng(
  context,
  artwork: TicketArtwork(
    art: art,
    template: template,
    categoryName: categoryName,
    invitation: invitation,
    background: true,
  ),
  pixelRatio: 1.5,
);

/// Rendu hors écran d'un [TicketArtwork], à sa taille de référence.
Future<Uint8List> renderArtworkPng(
  BuildContext context, {
  required TicketArtwork artwork,
  double pixelRatio = 2,
}) async {
  // Les images doivent être décodées avant l'unique cadre de rendu. Une
  // image absente (réseau) laisse son emplacement au fond uni.
  for (final image in TicketArtwork.imagesOf(artwork.art, artwork.template)) {
    if (!context.mounted) throw StateError('context unmounted');
    await precacheImage(image, context, onError: (_, _) {});
  }
  if (!context.mounted) throw StateError('context unmounted');
  final size = TicketGeometry.of(artwork.template).size;
  final overlay = Overlay.of(context, rootOverlay: true);
  final boundaryKey = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -20000,
      top: 0,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(key: boundaryKey, child: artwork),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    // Construction, mise en page et peinture au prochain cadre (l'insertion
    // en demande un). `debugNeedsPaint` n'existe pas en version publiée.
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
