import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/events/domain/cities.dart' show foldAccents;
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/reports/domain/report.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_copy.dart';
import 'package:ticketsur/features/ticket_send/presentation/send_copy.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Nom de fichier sûr tiré du titre de l'événement (« Gala d'été » →
/// « Gala-d-ete »).
String fileSlug(String title) {
  final slug = foldAccents(title)
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final short = slug.length > 40 ? slug.substring(0, 40) : slug;
  return short.isEmpty ? 'evenement' : short;
}

String _when(TicketEvent event, DateTime? instant) => instant == null
    ? ''
    : DateFormat('dd/MM/yyyy HH:mm')
          .format(wallTimeIn(event.timezone, instant));

// -----------------------------------------------------------------------------
// Liste CSV (Excel en français : « ; », UTF-8 avec BOM, fins de ligne CRLF)
// -----------------------------------------------------------------------------

/// Téléphone lisible et gardé en texte par Excel : `+22670112233` →
/// `00226 70 11 22 33` (le « + » initial serait pris pour une formule et
/// un nombre pur perdrait ses zéros).
String csvPhone(String? phone) {
  if (phone == null) return '';
  final digits = phone.replaceAll(RegExp('[^0-9]'), '');
  if (digits.length <= 8) return digits;
  final head = digits.substring(0, digits.length - 8);
  final tail = digits.substring(digits.length - 8);
  final pairs = [
    for (var i = 0; i < tail.length; i += 2) tail.substring(i, i + 2),
  ];
  return '00$head ${pairs.join(' ')}';
}

/// Cellule CSV : neutralise les formules (=, +, -, @ en tête, injection
/// CSV) et met entre guillemets ce qui contient un séparateur.
String csvCell(String value) {
  var text = value;
  if (text.isNotEmpty && '=+-@\t\r'.contains(text[0])) text = "'$text";
  if (RegExp('[;"\r\n]').hasMatch(text)) {
    text = '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

/// Liste des tickets d'un événement, un par ligne, pour Excel.
Uint8List buildReportCsv(
  AppLocalizations l10n, {
  required TicketEvent event,
  required List<ReportRow> rows,
}) {
  final buffer = StringBuffer('﻿')
    ..write(l10n.reportCsvHeader)
    ..write('\r\n');
  for (final row in rows) {
    final cells = [
      row.reference,
      row.categoryName,
      ticketStatusLabel(l10n, row.status),
      row.holder.name ?? '',
      csvPhone(row.holder.phone),
      row.holder.email ?? '',
      _when(event, row.issuedAt),
      _when(event, row.redeemedAt),
      row.checkpointName ?? '',
      _when(event, row.revokedAt),
      if (row.lastDelivery case (:final channel, at: _))
        channelLabel(l10n, channel)
      else
        '',
      _when(event, row.lastDelivery?.at),
    ];
    buffer
      ..write(cells.map(csvCell).join(';'))
      ..write('\r\n');
  }
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}

// -----------------------------------------------------------------------------
// Bilan PDF (A4)
// -----------------------------------------------------------------------------

const PdfColor _navy = PdfColor.fromInt(0xFF082D60);
const PdfColor _muted = PdfColor.fromInt(0xFF52627A);
const PdfColor _line = PdfColor.fromInt(0xFFD5DCE6);
const PdfColor _soft = PdfColor.fromInt(0xFFF1F4F9);
const PdfColor _green = PdfColor.fromInt(0xFF17BE35);
const PdfColor _red = PdfColor.fromInt(0xFFDC3545);

String _percent(double ratio) => '${(ratio.clamp(0, 1) * 100).round()} %';

/// Bilan d'un événement, à partir du tableau de bord (heure du serveur).
Future<Uint8List> buildReportPdf(
  AppLocalizations l10n, {
  required TicketEvent event,
  required EventDashboard dashboard,
  required String organizationName,
}) async {
  final count = NumberFormat.decimalPattern('fr');
  String n(int value) => pdfSafe(count.format(value));
  final tickets = dashboard.tickets;
  final scans = dashboard.scans;
  final doc = pw.Document(
    title: pdfSafe('${l10n.reportTitle} - ${event.title}'),
    author: pdfSafe(organizationName),
    creator: 'TicketSur',
  );
  const small = pw.TextStyle(fontSize: 8, color: _muted);
  const body = pw.TextStyle(fontSize: 9);
  const heading = pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: _navy,
  );

  pw.Widget section(String title, pw.Widget child) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(pdfSafe(title), style: heading),
        pw.SizedBox(height: 6),
        child,
      ],
    ),
  );

  pw.Widget table(List<String> headers, List<List<String>> data) => data.isEmpty
      ? pw.Text(pdfSafe(l10n.reportNone), style: small)
      : pw.TableHelper.fromTextArray(
          headers: [for (final h in headers) pdfSafe(h)],
          data: [
            for (final row in data) [for (final cell in row) pdfSafe(cell)],
          ],
          headerStyle: const pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: _navy),
          cellStyle: body,
          oddRowDecoration: const pw.BoxDecoration(color: _soft),
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5),
          ),
          cellAlignments: {
            for (var i = 1; i < headers.length; i++)
              i: pw.Alignment.centerRight,
          },
        );

  pw.Widget kpi(String label, String value, {PdfColor? color}) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color ?? _navy,
            ),
          ),
          pw.Text(pdfSafe(label), style: small),
        ],
      ),
    ),
  );

  final timeline = dashboard.timeline;
  final peak = timeline.fold<int>(0, (m, b) => math.max(m, b.total));
  final place = [?event.venue, ?event.city].join(' - ');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 32),
      footer: (context) => pw.Row(
        children: [
          pw.Text(pdfSafe('TicketSûr - $organizationName'), style: small),
          pw.Spacer(),
          pw.Text(
            pdfSafe(l10n.reportPage(context.pageNumber, context.pagesCount)),
            style: small,
          ),
        ],
      ),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: const pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                pdfSafe(l10n.reportTitle),
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                pdfSafe(event.title),
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                pdfSafe(pdfEventDates(event)),
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
              if (place.isNotEmpty)
                pw.Text(
                  pdfSafe(place),
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          pdfSafe(
            l10n.reportStatsAt(
              DateFormat("dd/MM/yyyy 'à' HH:mm")
                  .format(wallTimeIn(event.timezone, dashboard.serverTime)),
            ),
          ),
          style: small,
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            kpi(l10n.reportIssued, n(tickets.issued)),
            kpi(l10n.reportAdmitted, n(tickets.admitted), color: _green),
            kpi(l10n.reportAttendance, pdfSafe(_percent(tickets.attendance))),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            kpi(l10n.reportNoShow, n(tickets.remaining)),
            kpi(l10n.reportRevoked, n(tickets.revoked)),
            kpi(
              l10n.reportRefused,
              n(scans.refused),
              color: scans.refused > 0 ? _red : null,
            ),
          ],
        ),
        if (timeline.isNotEmpty && peak > 0)
          section(
            l10n.reportTimeline,
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.SizedBox(
                  height: 90,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      for (final bucket in timeline)
                        pw.Expanded(
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 1,
                            ),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                if (bucket.refused > 0)
                                  pw.Container(
                                    height: 90 * bucket.refused / peak,
                                    color: _red,
                                  ),
                                if (bucket.accepted > 0)
                                  pw.Container(
                                    height: 90 * bucket.accepted / peak,
                                    color: _green,
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                pw.Container(height: 0.5, color: _line),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Text(
                      DateFormat(
                        'HH:mm',
                      ).format(wallTimeIn(event.timezone, timeline.first.at)),
                      style: small,
                    ),
                    pw.Spacer(),
                    pw.Text(
                      DateFormat('HH:mm')
                          .format(wallTimeIn(event.timezone, timeline.last.at)),
                      style: small,
                    ),
                  ],
                ),
              ],
            ),
          ),
        section(
          l10n.reportCategories,
          table(
            [
              l10n.reportColCategory,
              l10n.reportColQuota,
              l10n.reportColIssued,
              l10n.reportColAdmitted,
              l10n.reportColRate,
            ],
            [
              for (final c in dashboard.categories)
                [
                  c.name,
                  if (c.capacity == null)
                    l10n.reportUnlimited
                  else
                    n(c.capacity!),
                  n(c.issued),
                  n(c.admitted),
                  _percent(c.attendance),
                ],
            ],
          ),
        ),
        section(
          l10n.reportCheckpoints,
          table(
            [
              l10n.reportColCheckpoint,
              l10n.reportColAdmitted,
              l10n.reportColRefused,
              l10n.reportColLastScan,
            ],
            [
              for (final c in dashboard.checkpoints)
                [c.name, n(c.admitted), n(c.refused), _when(event, c.lastAt)],
            ],
          ),
        ),
        section(
          l10n.reportRefusals,
          table(
            [l10n.reportColReason, l10n.reportColCount],
            [
              for (final MapEntry(key: result, value: total) in scans.refusals)
                [
                  if (result == ScanResult.unavailable)
                    l10n.dashboardOtherReason
                  else
                    verdictReason(l10n, result),
                  n(total),
                ],
            ],
          ),
        ),
        section(
          l10n.reportControllers,
          table(
            [
              l10n.reportColController,
              l10n.reportColAdmitted,
              l10n.reportColRefused,
              l10n.reportColLastScan,
            ],
            [
              for (final c in dashboard.controllers)
                [
                  c.displayName,
                  n(c.accepted),
                  n(c.refused),
                  _when(event, c.lastAt),
                ],
            ],
          ),
        ),
      ],
    ),
  );
  return await doc.save();
}
