import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Tableau lu dans un fichier : lignes de cellules (texte brut). L'index
/// d'une ligne + 1 est son numéro dans le fichier : les lignes vides sont
/// gardées (vides) pour que les numéros cités correspondent au tableur.
typedef CellTable = List<List<String>>;

/// Fichier illisible ou format non pris en charge.
enum TableReadFailure implements Exception {
  /// Extension inconnue (ni .csv, .txt, ni .xlsx).
  unsupported,

  /// Ancien format Excel (.xls) : à réenregistrer en .xlsx ou .csv.
  legacyExcel,

  /// Fichier endommagé ou vide.
  unreadable,
}

/// Lit un fichier CSV ou Excel (.xlsx) selon son extension.
CellTable readTable(String fileName, Uint8List bytes) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.xls')) throw TableReadFailure.legacyExcel;
  if (lower.endsWith('.xlsx')) return readXlsx(bytes);
  if (lower.endsWith('.csv') || lower.endsWith('.txt')) {
    return readCsv(decodeText(bytes));
  }
  throw TableReadFailure.unsupported;
}

// -----------------------------------------------------------------------------
// Texte : UTF-8 (avec ou sans BOM), sinon Windows-1252 (Excel « CSV » français)
// -----------------------------------------------------------------------------

/// Caractères de Windows-1252 entre 0x80 et 0x9F (le reste = Latin-1).
const Map<int, int> _cp1252 = {
  0x80: 0x20AC,
  0x82: 0x201A,
  0x83: 0x0192,
  0x84: 0x201E,
  0x85: 0x2026,
  0x86: 0x2020,
  0x87: 0x2021,
  0x88: 0x02C6,
  0x89: 0x2030,
  0x8A: 0x0160,
  0x8B: 0x2039,
  0x8C: 0x0152,
  0x8E: 0x017D,
  0x91: 0x2018,
  0x92: 0x2019,
  0x93: 0x201C,
  0x94: 0x201D,
  0x95: 0x2022,
  0x96: 0x2013,
  0x97: 0x2014,
  0x98: 0x02DC,
  0x99: 0x2122,
  0x9A: 0x0161,
  0x9B: 0x203A,
  0x9C: 0x0153,
  0x9E: 0x017E,
  0x9F: 0x0178,
};

/// Décode un fichier texte : UTF-8 s'il est valide, sinon Windows-1252.
String decodeText(Uint8List bytes) {
  var data = bytes;
  if (data.length >= 3 &&
      data[0] == 0xEF &&
      data[1] == 0xBB &&
      data[2] == 0xBF) {
    data = Uint8List.sublistView(data, 3);
  }
  try {
    return utf8.decode(data);
  } on FormatException {
    return String.fromCharCodes([for (final b in data) _cp1252[b] ?? b]);
  }
}

// -----------------------------------------------------------------------------
// CSV (RFC 4180) : séparateur « ; », « , » ou tabulation, détecté
// -----------------------------------------------------------------------------

/// Séparateur le plus fréquent, hors guillemets, sur la première ligne non
/// vide. Excel en français écrit « ; ».
String detectSeparator(String text) {
  final counts = {';': 0, ',': 0, '\t': 0};
  var quoted = false;
  var seen = false;
  for (final char in text.split('')) {
    if (char == '"') quoted = !quoted;
    if (quoted) continue;
    if (char == '\n' || char == '\r') {
      if (seen) break;
      continue;
    }
    seen = true;
    if (counts.containsKey(char)) counts[char] = counts[char]! + 1;
  }
  final best = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
  return best.value == 0 ? ';' : best.key;
}

/// Découpe un texte CSV ; les lignes vides restent (vides), sauf à la fin.
CellTable readCsv(String text, {String? separator}) {
  final sep = separator ?? detectSeparator(text);
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  var i = 0;

  void endCell() {
    row.add(cell.toString());
    cell.clear();
  }

  void endRow() {
    endCell();
    rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final char = text[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(char);
      }
    } else if (char == '"' && cell.isEmpty) {
      quoted = true;
    } else if (char == sep) {
      endCell();
    } else if (char == '\r' || char == '\n') {
      if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else {
      cell.write(char);
    }
    i++;
  }
  if (cell.isNotEmpty || row.isNotEmpty) endRow();
  return _trimEnd(rows);
}

bool _blank(List<String> row) => row.every((value) => value.trim().isEmpty);

CellTable _trimEnd(CellTable rows) {
  var end = rows.length;
  while (end > 0 && _blank(rows[end - 1])) {
    end--;
  }
  return rows.sublist(0, end);
}

// -----------------------------------------------------------------------------
// Excel .xlsx : première feuille, textes partagés, nombres, cellules en ligne
// -----------------------------------------------------------------------------

/// Lit la première feuille d'un classeur .xlsx.
CellTable readXlsx(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    XmlDocument? part(String name) {
      final file = archive.findFile(name);
      return file == null ? null : XmlDocument.parse(utf8.decode(file.content));
    }

    final shared = <String>[
      for (final item
          in part('xl/sharedStrings.xml')?.findAllElements('si') ??
              const <XmlElement>[])
        _text(item),
    ];
    final sheet =
        part(_firstSheetPath(part)) ?? part('xl/worksheets/sheet1.xml');
    if (sheet == null) throw TableReadFailure.unreadable;

    final rows = <List<String>>[];
    for (final rowElement in sheet.findAllElements('row')) {
      // Lignes absentes du fichier (vides dans Excel) : gardées vides.
      final number = int.tryParse(rowElement.getAttribute('r') ?? '');
      while (number != null && rows.length < number - 1) {
        rows.add(const []);
      }
      final row = <String>[];
      for (final c in rowElement.findElements('c')) {
        // Chaque valeur à sa colonne (« B4 » → 1), quel que soit l'ordre.
        final column = _columnIndex(c.getAttribute('r')) ?? row.length;
        while (row.length <= column) {
          row.add('');
        }
        row[column] = _cellValue(c, shared);
      }
      rows.add(row);
    }
    return _trimEnd(rows);
  } on TableReadFailure {
    rethrow;
  } on Object {
    throw TableReadFailure.unreadable;
  }
}

/// Chemin de la première feuille déclarée dans le classeur.
String _firstSheetPath(XmlDocument? Function(String) part) {
  const fallback = 'xl/worksheets/sheet1.xml';
  final sheet = part('xl/workbook.xml')?.findAllElements('sheet').firstOrNull;
  final relId = sheet?.attributes
      .where((a) => a.name.local == 'id')
      .firstOrNull
      ?.value;
  if (relId == null) return fallback;
  final rel = part('xl/_rels/workbook.xml.rels')
      ?.findAllElements('Relationship')
      .where((r) => r.getAttribute('Id') == relId)
      .firstOrNull;
  final target = rel?.getAttribute('Target');
  if (target == null) return fallback;
  return target.startsWith('/') ? target.substring(1) : 'xl/$target';
}

/// Texte d'un élément `si` ou `is` (texte simple ou enrichi, sans phonétique).
String _text(XmlElement element) => element.descendantElements
    .where(
      (e) =>
          e.name.local == 't' &&
          e.ancestorElements.every((a) => a.name.local != 'rPh'),
    )
    .map((e) => e.innerText)
    .join();

/// Index (0, 1…) de la colonne d'une référence « B12 ».
int? _columnIndex(String? reference) {
  if (reference == null) return null;
  var index = 0;
  var letters = 0;
  for (final unit in reference.codeUnits) {
    if (unit < 0x41 || unit > 0x5A) break;
    index = index * 26 + (unit - 0x40);
    letters++;
  }
  return letters == 0 ? null : index - 1;
}

String _cellValue(XmlElement c, List<String> shared) {
  final type = c.getAttribute('t');
  if (type == 'inlineStr') {
    final inline = c.getElement('is');
    return inline == null ? '' : _text(inline);
  }
  final raw = c.getElement('v')?.innerText ?? '';
  return switch (type) {
    's' => switch (int.tryParse(raw)) {
      final index? when index >= 0 && index < shared.length => shared[index],
      _ => '',
    },
    'b' => raw == '1' ? 'VRAI' : 'FAUX',
    'str' || 'e' => raw,
    _ => _number(raw),
  };
}

/// Nombre tel qu'Excel l'afficherait : un téléphone saisi comme nombre
/// (70112233, 2.2670112233E10) redevient une suite de chiffres.
String _number(String raw) {
  final value = double.tryParse(raw);
  if (value == null) return raw;
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toInt().toString();
  }
  return raw;
}
