import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_card.dart';

/// Image PNG d'un ticket, identique à celle partagée depuis sa fiche, rendue
/// hors de l'écran (couche de l'Overlay décalée, jamais visible).
Future<Uint8List> renderTicketPng(
  BuildContext context, {
  required TicketEvent event,
  required TicketSecret ticket,
  double pixelRatio = 3,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final boundaryKey = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -10000,
      top: 0,
      width: 360,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: TicketSurColors.surfaceLight,
              child: Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.sm),
                child: TicketCard(
                  event: event,
                  reference: ticket.reference,
                  categoryName: ticket.categoryName,
                  token: ticket.token,
                  status: ticket.status,
                  holderName: ticket.holderName,
                ),
              ),
            ),
          ),
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
