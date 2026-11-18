import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Partage des billets en PDF (un par page A6).
Future<void> shareTicketsPdf(
  BuildContext context,
  WidgetRef ref, {
  required TicketEvent event,
  required List<TicketSecret> tickets,
}) async {
  final l10n = context.l10n;
  final share = ref.read(shareFilesProvider);
  final bytes = await buildTicketsPdf(
    event: event,
    tickets: tickets,
    organizationName: ref.read(activeOrganizationProvider)?.name ?? '',
  );
  final name = tickets.length == 1
      ? 'Billet-${tickets.single.reference}.pdf'
      : 'Billets-${tickets.length}.pdf';
  await share([
    (bytes: bytes, name: name, mimeType: 'application/pdf'),
  ], text: l10n.ticketShareText(event.title));
}

/// Partage de la carte du billet en image PNG, capturée depuis l'écran.
Future<void> shareTicketImage(
  BuildContext context,
  WidgetRef ref, {
  required GlobalKey boundaryKey,
  required TicketEvent event,
  required String reference,
}) async {
  final l10n = context.l10n;
  final share = ref.read(shareFilesProvider);
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) return;
  await share([
    (
      bytes: data.buffer.asUint8List(),
      name: 'Billet-$reference.png',
      mimeType: 'image/png',
    ),
  ], text: l10n.ticketShareText(event.title));
}
