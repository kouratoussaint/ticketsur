import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ticketsur/design_system/brand_pdf.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_theme.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Texte compatible avec la police PDF standard (Helvetica, Latin-1) :
/// accents français conservés, ponctuation typographique simplifiée, tout
/// autre symbole remplacé par « ? ».
String pdfSafe(String text) {
  const replacements = {
    '–': '-',
    '—': '-',
    '→': '-',
    '‘': "'",
    '’': "'",
    '“': '"',
    '”': '"',
    '…': '...',
    'œ': 'oe',
    'Œ': 'OE',
    '€': 'EUR',
    '\u202F': ' ',
  };
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (rune < 0x80 || (rune >= 0xA0 && rune <= 0xFF)) {
      buffer.write(char);
    } else {
      buffer.write(replacements[char] ?? '?');
    }
  }
  return buffer.toString();
}

/// Date et heures de l'événement, dans son fuseau, pour le PDF.
String pdfEventDates(TicketEvent event) {
  final start = wallTimeIn(event.timezone, event.startsAt);
  final end = wallTimeIn(event.timezone, event.endsAt);
  final day = DateFormat('EEEE d MMMM y', 'fr');
  final time = DateFormat('HH:mm', 'fr');
  final sameDay =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  return sameDay
      ? '${day.format(start)}, ${time.format(start)} – ${time.format(end)}'
      : '${day.format(start)} ${time.format(start)} – '
            '${day.format(end)} ${time.format(end)}';
}

/// Clé du fond d'un ticket : sa catégorie (ou, à défaut, son nom).
String ticketBackgroundKey(TicketArt? art, TicketSecret ticket) =>
    art?.info[ticket.ticketId]?.categoryId ??
    '${ticket.categoryName}|${ticket.isInvitation}';

/// Largeur des pages : 18 cm, hauteur selon le modèle (2,4:1 pour les
/// thèmes intégrés).
const double _pageWidth = 180 * PdfPageFormat.mm;

PdfColor _pdfColor(int argb) => PdfColor.fromInt(argb);

/// Un ticket par page, au format du modèle de sa catégorie (ADR 0022).
///
/// [backgrounds] : fond de chaque catégorie ([ticketBackgroundKey]), rendu
/// une seule fois en image ; sans lui, un fond simple est dessiné. Le QR,
/// le numéro, la référence et le titulaire sont dessinés par-dessus, en
/// vecteurs. [logo] : logo Tikéo du fond simple.
Future<Uint8List> buildTicketsPdf({
  required TicketEvent event,
  required List<TicketSecret> tickets,
  required String organizationName,
  Uint8List? logo,
  TicketArt? art,
  Map<String, Uint8List> backgrounds = const {},
  String Function(String number) numberText = _frenchNumber,
  String Function(String name) holderText = _frenchHolder,
}) async {
  final doc = pw.Document(
    title: pdfSafe('Tickets - ${event.title}'),
    author: pdfSafe(organizationName),
    creator: 'Tikeo',
  );
  // Une image par fond et une pour le logo, même avec 500 tickets.
  final mark = logo == null ? null : pw.MemoryImage(logo);
  final images = {
    for (final entry in backgrounds.entries)
      entry.key: pw.MemoryImage(entry.value),
  };
  final fallbackTemplate = BuiltinTemplate(defaultThemeFor(event.kind));
  final dates = pdfSafe(pdfEventDates(event));
  for (final ticket in tickets) {
    final template = art?.templateOfTicket(ticket.ticketId) ?? fallbackTemplate;
    final geometry = TicketGeometry.of(template);
    const scale = _pageWidth / TicketGeometry.width;
    final height = geometry.size.height * scale;
    final background = images[ticketBackgroundKey(art, ticket)];
    final number = art?.info[ticket.ticketId]?.number;
    final qr = geometry.qr;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_pageWidth, height),
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Stack(
          children: [
            if (background != null)
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Image(
                  background,
                  width: _pageWidth,
                  height: height,
                  fit: pw.BoxFit.fill,
                ),
              )
            else
              ..._fallbackBackground(
                template,
                scale: scale,
                height: height,
                event: event,
                dates: dates,
                categoryName: ticket.categoryName,
                mark: mark,
              ),
            pw.Positioned(
              left: qr.left * scale,
              top: qr.top * scale,
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(
                  errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
                ),
                data: ticket.token,
                width: qr.width * scale,
                height: qr.height * scale,
                padding: pw.EdgeInsets.all(
                  TicketGeometry.quietZone(qr.width) * scale,
                ),
                backgroundColor: PdfColors.white,
              ),
            ),
            if (template is CustomTemplate)
              pw.Positioned(
                left:
                    (template.placement.refX * geometry.size.width -
                        TicketGeometry.customBlockWidth / 2) *
                    scale,
                top: template.placement.refY * geometry.size.height * scale,
                child: pw.SizedBox(
                  width: TicketGeometry.customBlockWidth * scale,
                  child: pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14 * scale,
                        vertical: 8 * scale,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(10 * scale),
                        ),
                      ),
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          if (number != null)
                            pw.Text(
                              pdfSafe(numberText(formatTicketNumber(number))),
                              style: const pw.TextStyle(
                                fontSize: 22 * scale,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          pw.Text(
                            ticket.reference,
                            style: pw.TextStyle(
                              fontSize: 16 * scale,
                              color: _pdfColor(0xFF4B5563),
                            ),
                          ),
                          if (ticket.holderName case final name?)
                            pw.Text(
                              pdfSafe(name),
                              maxLines: 1,
                              style: const pw.TextStyle(
                                fontSize: 16 * scale,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              if (number != null)
                pw.Positioned(
                  left: TicketGeometry.stubLeft * scale,
                  top: TicketGeometry.numberTop * scale,
                  child: pw.SizedBox(
                    width: TicketGeometry.stubWidth * scale,
                    child: pw.Text(
                      pdfSafe(numberText(formatTicketNumber(number))),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: pw.FontWeight.bold,
                        color: _pdfColor(0xFF111827),
                      ),
                    ),
                  ),
                ),
              pw.Positioned(
                left: TicketGeometry.stubLeft * scale,
                top: TicketGeometry.referenceTop * scale,
                child: pw.SizedBox(
                  width: TicketGeometry.stubWidth * scale,
                  child: pw.Text(
                    ticket.reference,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 12 * scale,
                      color: _pdfColor(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              if (ticket.holderName case final name?)
                pw.Positioned(
                  left: TicketGeometry.holder.left * scale,
                  top: TicketGeometry.holder.top * scale,
                  child: pw.SizedBox(
                    width: TicketGeometry.holder.width * scale,
                    child: pw.Text(
                      pdfSafe(holderText(name)),
                      maxLines: 1,
                      style: const pw.TextStyle(
                        fontSize: 15 * scale,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
  return await doc.save();
}

String _frenchNumber(String number) => 'N° $number';

String _frenchHolder(String name) => 'Titulaire : $name';

/// Fond simple, sans image : couleurs du thème, titre, dates, talon blanc.
List<pw.Widget> _fallbackBackground(
  TicketTemplate template, {
  required double scale,
  required double height,
  required TicketEvent event,
  required String dates,
  required String categoryName,
  required pw.ImageProvider? mark,
}) {
  if (template is! BuiltinTemplate) {
    return [
      pw.Positioned(
        left: 0,
        top: 0,
        child: pw.Container(
          width: _pageWidth,
          height: height,
          color: _pdfColor(0xFFE5E7EB),
        ),
      ),
    ];
  }
  final theme = template.theme;
  final dark = _pdfColor(theme.dark.toARGB32());
  final accent = _pdfColor(theme.accent.toARGB32());
  return [
    pw.Positioned(
      left: 0,
      top: 0,
      child: pw.Container(width: _pageWidth, height: height, color: dark),
    ),
    pw.Positioned(
      left: (TicketGeometry.stubLeft - TicketGeometry.accentBarWidth) * scale,
      top: 0,
      child: pw.Container(
        width: TicketGeometry.accentBarWidth * scale,
        height: height,
        color: accent,
      ),
    ),
    pw.Positioned(
      left: TicketGeometry.stubLeft * scale,
      top: 0,
      child: pw.Container(
        width: TicketGeometry.stubWidth * scale,
        height: height,
        color: PdfColors.white,
      ),
    ),
    pw.Positioned(
      left: 40 * scale,
      top: 120 * scale,
      child: pw.SizedBox(
        width: 700 * scale,
        child: pw.Text(
          pdfSafe(event.title),
          maxLines: 2,
          style: pw.TextStyle(
            fontSize: 40 * scale,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ),
    ),
    pw.Positioned(
      left: 40 * scale,
      top: 378 * scale,
      child: pw.Text(
        dates,
        style: pw.TextStyle(fontSize: 15 * scale, color: PdfColors.white),
      ),
    ),
    pw.Positioned(
      left: TicketGeometry.stubLeft * scale,
      top: 346 * scale,
      child: pw.SizedBox(
        width: TicketGeometry.stubWidth * scale,
        child: pw.Text(
          pdfSafe(categoryName.toUpperCase()),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 14 * scale,
            fontWeight: pw.FontWeight.bold,
            color: _pdfColor(theme.ink.toARGB32()),
          ),
        ),
      ),
    ),
    if (mark != null)
      pw.Positioned(
        left:
            (TicketGeometry.stubLeft + (TicketGeometry.stubWidth - 70) / 2) *
            scale,
        top: 398 * scale,
        child: pw.Container(
          color: BrandPdf.navy,
          padding: pw.EdgeInsets.all(2 * scale),
          child: pw.Image(mark, width: 66 * scale, height: 24 * scale),
        ),
      ),
  ];
}
