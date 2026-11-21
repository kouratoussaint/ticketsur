import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ticketsur/app/app_locale.dart';
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
  final day = DateFormat.yMMMMEEEEd(appLocaleTag);
  final time = DateFormat('HH:mm', appLocaleTag);
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
  final resolved = _Resolved(
    event: event,
    art: art,
    mark: logo == null ? null : pw.MemoryImage(logo),
    images: {
      for (final entry in backgrounds.entries)
        entry.key: pw.MemoryImage(entry.value),
    },
    numberText: numberText,
    holderText: holderText,
  );
  for (final ticket in tickets) {
    final template = resolved.templateOf(ticket);
    final height = _pageWidth / TicketGeometry.of(template).size.aspectRatio;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_pageWidth, height),
        margin: pw.EdgeInsets.zero,
        build: (context) => _ticketArt(resolved, ticket, _pageWidth),
      ),
    );
  }
  return await doc.save();
}

/// Ce qui sert à dessiner tous les tickets d'un document.
final class _Resolved {
  new({
    required this.event,
    required this.art,
    required this.mark,
    required this.images,
    required this.numberText,
    required this.holderText,
  }) : dates = pdfSafe(pdfEventDates(event)),
       fallback = BuiltinTemplate(defaultThemeFor(event.kind));

  final TicketEvent event;
  final TicketArt? art;
  final pw.ImageProvider? mark;
  final Map<String, pw.ImageProvider> images;
  final String Function(String number) numberText;
  final String Function(String name) holderText;
  final String dates;
  final TicketTemplate fallback;

  TicketTemplate templateOf(TicketSecret ticket) =>
      art?.templateOfTicket(ticket.ticketId) ?? fallback;
}

/// Un ticket de [width] de large, au format de son modèle.
pw.Widget _ticketArt(_Resolved r, TicketSecret ticket, double width) {
  final event = r.event;
  final art = r.art;
  final mark = r.mark;
  final dates = r.dates;
  final numberText = r.numberText;
  final holderText = r.holderText;
  final template = r.templateOf(ticket);
  final geometry = TicketGeometry.of(template);
  final scale = width / TicketGeometry.width;
  final height = geometry.size.height * scale;
  final background = r.images[ticketBackgroundKey(art, ticket)];
  final number = art?.info[ticket.ticketId]?.number;
  final qr = geometry.qr;
  return pw.SizedBox(
    width: width,
    height: height,
    child: pw.Stack(
      children: [
        if (background != null)
          pw.Positioned(
            left: 0,
            top: 0,
            child: pw.Image(
              background,
              width: width,
              height: height,
              fit: pw.BoxFit.fill,
            ),
          )
        else
          ..._fallbackBackground(
            template,
            width: width,
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
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: 14 * scale,
                    vertical: 8 * scale,
                  ),
                  decoration: pw.BoxDecoration(
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
                          style: pw.TextStyle(
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
                      if (ticket.holderName case final name?
                          when !template.placement.holderPlaced)
                        pw.Text(
                          pdfSafe(name),
                          maxLines: 1,
                          style: pw.TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (template is CustomTemplate &&
            template.placement.holderPlaced &&
            ticket.holderName != null)
          pw.Positioned(
            left:
                (template.placement.holderX! * geometry.size.width -
                    TicketGeometry.customBlockWidth / 2) *
                scale,
            top: template.placement.holderY! * geometry.size.height * scale,
            child: pw.SizedBox(
              width: TicketGeometry.customBlockWidth * scale,
              child: pw.Center(
                child: pw.Container(
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: 14 * scale,
                    vertical: 6 * scale,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.all(
                      pw.Radius.circular(10 * scale),
                    ),
                  ),
                  child: pw.Text(
                    pdfSafe(ticket.holderName!),
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (template is! CustomTemplate) ...[
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
                  style: pw.TextStyle(
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
  );
}

/// Planche A4 à imprimer : tickets les uns sous les autres (3 par page
/// pour les thèmes intégrés), séparés par des traits de coupe.
/// Nombre maximal de tickets par feuille A4 : au-delà, le QR passerait
/// sous 2 cm (#4).
const maxTicketsPerSheet = 5;

/// Proportion largeur / hauteur des thèmes intégrés (1080 × 450).
const double builtinTicketAspect =
    TicketGeometry.width / TicketGeometry.builtinHeight;

/// Côté du QR des thèmes intégrés, rapporté à la largeur du ticket.
final double builtinQrRatio =
    TicketGeometry.of(const BuiltinTemplate(0)).qr.width / TicketGeometry.width;

const double _sheetMarginMm = 12;
const double _sheetGapMm = 8;
const double _sheetMaxWidthMm = 186;
const double _sheetUsableMm = 297 - 2 * _sheetMarginMm;

/// Largeur d'un ticket (mm) quand la feuille A4 en porte [perPage], pour
/// des tickets de proportion [aspectRatio] : la plus grande qui laisse
/// [perPage] tickets et leurs traits de coupe tenir dans la hauteur.
double sheetTicketWidthMm(
  int perPage, {
  double aspectRatio = builtinTicketAspect,
}) {
  final n = perPage.clamp(1, maxTicketsPerSheet);
  final slot = (_sheetUsableMm - (n + 1) * _sheetGapMm) / n;
  return math.min(_sheetMaxWidthMm, slot * aspectRatio);
}

/// Planche A4 : tickets les uns sous les autres, traits de coupe. Sans
/// [perPage], autant de tickets que la page en contient en pleine largeur ;
/// avec [perPage] (1 à [maxTicketsPerSheet]), ce nombre par feuille,
/// tickets réduits et centrés.
Future<Uint8List> buildTicketsSheetPdf({
  required TicketEvent event,
  required List<TicketSecret> tickets,
  required String organizationName,
  Uint8List? logo,
  TicketArt? art,
  Map<String, Uint8List> backgrounds = const {},
  String Function(String number) numberText = _frenchNumber,
  String Function(String name) holderText = _frenchHolder,
  int? perPage,
}) async {
  final doc = pw.Document(
    title: pdfSafe('Tickets - ${event.title}'),
    author: pdfSafe(organizationName),
    creator: 'Tikeo',
  );
  final resolved = _Resolved(
    event: event,
    art: art,
    mark: logo == null ? null : pw.MemoryImage(logo),
    images: {
      for (final entry in backgrounds.entries)
        entry.key: pw.MemoryImage(entry.value),
    },
    numberText: numberText,
    holderText: holderText,
  );
  const page = PdfPageFormat.a4;
  const margin = _sheetMarginMm * PdfPageFormat.mm;
  const gap = _sheetGapMm * PdfPageFormat.mm;
  const usable = _sheetUsableMm * PdfPageFormat.mm;
  var width = _sheetMaxWidthMm * PdfPageFormat.mm;
  // Répartition par page : chaque ticket entre deux traits de coupe.
  final pages = <List<TicketSecret>>[];
  var current = <TicketSecret>[];
  var used = gap;
  if (perPage != null) {
    final n = perPage.clamp(1, maxTicketsPerSheet);
    // Le ticket le plus haut décide de la largeur commune.
    final aspect = tickets.isEmpty
        ? builtinTicketAspect
        : tickets
              .map(
                (t) =>
                    TicketGeometry.of(resolved.templateOf(t)).size.aspectRatio,
              )
              .reduce(math.min);
    width = sheetTicketWidthMm(n, aspectRatio: aspect) * PdfPageFormat.mm;
    for (var i = 0; i < tickets.length; i += n) {
      pages.add(tickets.sublist(i, math.min(i + n, tickets.length)));
    }
  }
  for (final ticket in perPage == null ? tickets : const <TicketSecret>[]) {
    final height =
        width / TicketGeometry.of(resolved.templateOf(ticket)).size.aspectRatio;
    if (current.isNotEmpty && used + height + gap > usable) {
      pages.add(current);
      current = [];
      used = gap;
    }
    used += height + gap;
    current.add(ticket);
  }
  if (current.isNotEmpty) pages.add(current);
  for (final group in pages) {
    doc.addPage(
      pw.Page(
        pageFormat: page,
        margin: const pw.EdgeInsets.all(margin),
        build: (context) => pw.Column(
          children: [
            _cutLine(gap),
            for (final ticket in group) ...[
              _ticketArt(resolved, ticket, width),
              _cutLine(gap),
            ],
          ],
        ),
      ),
    );
  }
  return await doc.save();
}

/// Trait de coupe en pointillés, au milieu de l'espace entre deux tickets.
pw.Widget _cutLine(double gap) => pw.SizedBox(
  height: gap,
  child: pw.Center(
    child: pw.Divider(
      color: _pdfColor(0xFF9CA3AF),
      thickness: 0.6,
      borderStyle: pw.BorderStyle.dashed,
      height: 0.6,
    ),
  ),
);

String _frenchNumber(String number) => 'N° $number';

String _frenchHolder(String name) => 'Titulaire : $name';

/// Fond simple, sans image : couleurs du thème, titre, dates, talon blanc.
List<pw.Widget> _fallbackBackground(
  TicketTemplate template, {
  required double width,
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
          width: width,
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
      child: pw.Container(width: width, height: height, color: dark),
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
