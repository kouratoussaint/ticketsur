import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Couleurs Tikéo pour les PDF (tickets, bilans), alignées sur
/// `TicketSurColors`.
abstract final class BrandPdf {
  static const PdfColor navy = PdfColor.fromInt(0xFF022445);
  static const PdfColor mint = PdfColor.fromInt(0xFF00C9A7);

  /// Menthe lisible en texte sur fond clair (≥ 4,5:1).
  static const PdfColor mintDeep = PdfColor.fromInt(0xFF006B5B);
  static const PdfColor spark = PdfColor.fromInt(0xFFFF6B3D);
  static const PdfColor muted = PdfColor.fromInt(0xFF52627A);
  static const PdfColor line = PdfColor.fromInt(0xFFD5DCE6);
  static const PdfColor soft = PdfColor.fromInt(0xFFF1F5F8);
  static const PdfColor red = PdfColor.fromInt(0xFFDC3545);

  /// Logo pour fond bleu nuit (texte blanc), allégé pour les PDF.
  static const String logoAsset = 'assets/branding/Tikeo_Logo_Clair_480.png';

  /// Rapport largeur / hauteur du logo.
  static const double logoAspect = 480 / 193;
}

/// Octets du logo, ou `null` s'il est illisible : le PDF affiche alors le
/// nom en texte.
Future<Uint8List?> loadPdfLogo() async {
  try {
    final data = await rootBundle.load(BrandPdf.logoAsset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } on Object {
    return null;
  }
}

/// Logo Tikéo (blanc) pour un bandeau bleu nuit, ou le nom en texte.
pw.Widget pdfBrandMark(pw.ImageProvider? logo, {double height = 18}) =>
    logo == null
    ? pw.Text(
        'Tikéo',
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: height * 0.7,
        ),
      )
    : pw.Image(logo, height: height, width: height * BrandPdf.logoAspect);
