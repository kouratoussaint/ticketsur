import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ticketsur/design_system/brand_pdf.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
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

/// Un ticket par page A6 (10,5 × 14,8 cm), prêt à imprimer ou à envoyer.
///
/// [logo] : octets du logo Tikéo ([loadPdfLogo]) ; sans lui, le nom s'écrit
/// en texte.
Future<Uint8List> buildTicketsPdf({
  required TicketEvent event,
  required List<TicketSecret> tickets,
  required String organizationName,
  Uint8List? logo,
}) async {
  final doc = pw.Document(
    title: pdfSafe('Tickets - ${event.title}'),
    author: pdfSafe(organizationName),
    creator: 'Tikeo',
  );
  // Une seule image pour tout le document, même avec 500 tickets.
  final mark = logo == null ? null : pw.MemoryImage(logo);
  final dates = pdfSafe(pdfEventDates(event));
  final footer = pdfSafe(
    'Ticket à usage unique. Ne le publiez pas : '
    "la première présentation à l'entrée fait foi.",
  );
  final invitationFooter = pdfSafe(
    'Invitation personnelle à usage unique. Ne la publiez pas : '
    "la première présentation à l'entrée fait foi.",
  );
  const white = pw.TextStyle(color: PdfColors.white, fontSize: 8);
  for (final ticket in tickets) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: BrandPdf.navy,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pdfBrandMark(mark),
                      pw.Spacer(),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: BrandPdf.mint,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Text(
                          pdfSafe(ticket.categoryName),
                          style: const pw.TextStyle(
                            color: BrandPdf.navy,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  if (ticket.isInvitation)
                    pw.Text(
                      'INVITATION',
                      style: const pw.TextStyle(
                        color: BrandPdf.spark,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  pw.Text(
                    pdfSafe(event.title),
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(dates, style: white),
                  if (event.venue case final venue?)
                    pw.Text(
                      pdfSafe([venue, ?event.city].join(' - ')),
                      style: white,
                    ),
                  if (ticket.holderName case final name?) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      pdfSafe('Titulaire : $name'),
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Invitation : filet orange sous le bandeau.
            if (ticket.isInvitation)
              pw.Container(
                height: 3,
                margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                color: BrandPdf.spark,
              ),
            // Ligne de découpe, façon ticket détachable.
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Divider(
                color: BrandPdf.line,
                thickness: 1,
                borderStyle: pw.BorderStyle.dashed,
                height: 1,
              ),
            ),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(
                  errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
                ),
                data: ticket.token,
                width: 165,
                height: 165,
                padding: const pw.EdgeInsets.all(8),
                backgroundColor: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                ticket.reference,
                style: const pw.TextStyle(
                  color: BrandPdf.navy,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            pw.Spacer(),
            pw.Text(
              ticket.isInvitation ? invitationFooter : footer,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(color: BrandPdf.muted, fontSize: 7),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              pdfSafe(organizationName),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                color: BrandPdf.mintDeep,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  return await doc.save();
}
