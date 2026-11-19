import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
Future<Uint8List> buildTicketsPdf({
  required TicketEvent event,
  required List<TicketSecret> tickets,
  required String organizationName,
}) async {
  final doc = pw.Document(
    title: pdfSafe('Tickets - ${event.title}'),
    author: pdfSafe(organizationName),
    creator: 'Tikeo',
  );
  const navy = PdfColor.fromInt(0xFF082D60);
  const muted = PdfColor.fromInt(0xFF52627A);
  final dates = pdfSafe(pdfEventDates(event));
  final footer = pdfSafe(
    'Ticket à usage unique. Ne le publiez pas : '
    "la première présentation à l'entrée fait foi.",
  );
  final invitationFooter = pdfSafe(
    'Invitation personnelle à usage unique. Ne la publiez pas : '
    "la première présentation à l'entrée fait foi.",
  );
  const gold = PdfColor.fromInt(0xFFF5B301);
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
                color: navy,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Tikéo',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        pdfSafe(
                          ticket.isInvitation
                              ? 'Invitation · ${ticket.categoryName}'
                              : ticket.categoryName,
                        ),
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  if (ticket.isInvitation)
                    pw.Text(
                      'INVITATION',
                      style: const pw.TextStyle(
                        color: gold,
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
                  pw.Text(
                    dates,
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                    ),
                  ),
                  if (event.venue case final venue?)
                    pw.Text(
                      pdfSafe(venue),
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8,
                      ),
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
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(
                  errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
                ),
                data: ticket.token,
                width: 170,
                height: 170,
                padding: const pw.EdgeInsets.all(8),
                backgroundColor: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                ticket.reference,
                style: const pw.TextStyle(
                  color: navy,
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
              style: const pw.TextStyle(color: muted, fontSize: 7),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              pdfSafe(organizationName),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(color: muted, fontSize: 7),
            ),
          ],
        ),
      ),
    );
  }
  return await doc.save();
}
