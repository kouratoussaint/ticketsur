import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/events/domain/cities.dart' show foldAccents;
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/ticket_import/domain/table_reader.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Colonnes reconnues dans une liste de participants.
enum ImportColumn {
  /// Nom complet (ou nom de famille si une colonne « Prénom » existe).
  name,

  /// Prénom, accolé au nom.
  firstName,

  phone,
  email,
  category,
}

/// Problème bloquant d'une ligne.
enum RowProblem {
  /// Aucun nom.
  nameMissing,

  /// Nom de plus de 120 caractères.
  nameTooLong,

  phoneInvalid,
  emailInvalid,

  /// Catégorie absente de l'événement (ou aucune catégorie par défaut).
  categoryUnknown,
}

/// Avertissement non bloquant d'une ligne.
enum RowWarning {
  /// Même téléphone qu'une ligne précédente.
  duplicatePhone,

  /// Même e-mail qu'une ligne précédente.
  duplicateEmail,
}

/// Ligne du fichier, prête à émettre ou en erreur.
@immutable
final class ImportRow {
  const new({
    required this.line,
    this.holder,
    this.categoryId,
    this.categoryLabel,
    this.problem,
    this.warnings = const {},
  });

  /// Numéro de ligne dans le fichier (1 = première ligne).
  final int line;

  /// Titulaire normalisé ; `null` si la ligne est en erreur.
  final TicketHolder? holder;
  final String? categoryId;

  /// Catégorie telle qu'écrite dans le fichier (vide : catégorie par défaut).
  final String? categoryLabel;
  final RowProblem? problem;
  final Set<RowWarning> warnings;

  bool get ok => problem == null;
}

/// Dépassement de quota prévu avant l'envoi (le serveur reste seul juge).
typedef QuotaIssue = ({String? categoryName, int wanted, int remaining});

/// Lecture d'une liste : colonnes trouvées et lignes contrôlées.
@immutable
final class ImportPlan {
  const new({
    required this.columns,
    required this.rows,
    this.headerLine,
    this.headers = const [],
  });

  /// Index de colonne de chaque champ reconnu.
  final Map<ImportColumn, int> columns;

  /// Ligne d'en-tête (numéro dans le fichier) ; `null` : pas d'en-tête,
  /// colonnes devinées d'après leur contenu.
  final int? headerLine;

  /// Libellés de l'en-tête (vides sans en-tête).
  final List<String> headers;
  final List<ImportRow> rows;

  List<ImportRow> get valid => [
    for (final row in rows)
      if (row.ok) row,
  ];

  List<ImportRow> get errors => [
    for (final row in rows)
      if (!row.ok) row,
  ];

  List<ImportRow> get warned => [
    for (final row in rows)
      if (row.ok && row.warnings.isNotEmpty) row,
  ];

  /// Nombre de tickets valides par catégorie.
  Map<String, int> get perCategory {
    final counts = <String, int>{};
    for (final row in valid) {
      counts[row.categoryId!] = (counts[row.categoryId!] ?? 0) + 1;
    }
    return counts;
  }

  /// Lignes à émettre (lignes en erreur exclues).
  List<TicketRow> get ticketRows => [
    for (final row in valid) (categoryId: row.categoryId!, holder: row.holder!),
  ];

  /// Quotas des catégories et capacité de l'événement que l'envoi dépasserait.
  List<QuotaIssue> quotaIssues(
    List<TicketCategory> categories, {
    int? eventCapacity,
  }) {
    final issues = <QuotaIssue>[];
    for (final MapEntry(key: id, value: wanted) in perCategory.entries) {
      final category = categories.where((c) => c.id == id).firstOrNull;
      final capacity = category?.capacity;
      if (category == null || capacity == null) continue;
      final remaining = capacity - category.issued;
      if (wanted > remaining) {
        issues.add((
          categoryName: category.name,
          wanted: wanted,
          remaining: remaining < 0 ? 0 : remaining,
        ));
      }
    }
    if (eventCapacity != null) {
      final issued = categories.fold(0, (sum, c) => sum + c.issued);
      final remaining = eventCapacity - issued;
      final wanted = valid.length;
      if (wanted > remaining) {
        issues.add((
          categoryName: null,
          wanted: wanted,
          remaining: remaining < 0 ? 0 : remaining,
        ));
      }
    }
    return issues;
  }
}

/// Texte comparable : minuscules, sans accents ni ponctuation.
String foldLabel(String text) =>
    foldAccents(text).replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();

const Map<ImportColumn, Set<String>> _synonyms = {
  ImportColumn.name: {
    'nom',
    'noms',
    'nom complet',
    'nom et prenom',
    'nom et prenoms',
    'nom prenom',
    'nom prenoms',
    'nom prenom s',
    'nom s',
    'nom et prenom s',
    'prenom et nom',
    'prenom nom',
    'prenoms et nom',
    'prenoms nom',
    'participant',
    'participants',
    'nom du participant',
    'invite',
    'invites',
    'nom de l invite',
    'titulaire',
    'nom du titulaire',
    'beneficiaire',
    'client',
    'name',
    'full name',
    'fullname',
    'nom de famille',
    'last name',
    'lastname',
    'surname',
  },
  ImportColumn.firstName: {'prenom', 'prenoms', 'first name', 'firstname'},
  ImportColumn.phone: {
    'telephone',
    'tel',
    'phone',
    'mobile',
    'portable',
    'whatsapp',
    'numero',
    'numeros',
    'contact',
    'contacts',
    'cellulaire',
    'gsm',
    'phone number',
    'numero de telephone',
    'numero whatsapp',
    'num',
    'n tel',
    'no tel',
  },
  ImportColumn.email: {
    'email',
    'e mail',
    'mail',
    'courriel',
    'adresse email',
    'adresse e mail',
    'adresse mail',
    'emails',
  },
  ImportColumn.category: {
    'categorie',
    'categories',
    'category',
    'type',
    'type de ticket',
    'type de billet',
    'ticket',
    'billet',
    'formule',
    'pass',
    'place',
    'tarif',
    'zone',
    'categorie de ticket',
  },
};

/// Mots qui suffisent en tête de libellé (« Téléphone (WhatsApp) »).
const Map<ImportColumn, Set<String>> _prefixes = {
  ImportColumn.phone: {'telephone', 'tel', 'phone', 'numero', 'whatsapp'},
  ImportColumn.email: {'email', 'e mail', 'mail', 'courriel', 'adresse e'},
  ImportColumn.category: {'categorie', 'category', 'type de'},
  ImportColumn.name: {'nom et', 'nom complet', 'participant', 'invite'},
  ImportColumn.firstName: {'prenom'},
};

/// Champ désigné par un libellé d'en-tête, s'il est reconnu.
ImportColumn? columnForHeader(String header) {
  final label = foldLabel(header);
  if (label.isEmpty) return null;
  for (final MapEntry(key: column, value: words) in _synonyms.entries) {
    if (words.contains(label)) return column;
  }
  for (final MapEntry(key: column, value: words) in _prefixes.entries) {
    if (words.any((w) => label.startsWith('$w ') || label == w)) return column;
  }
  return null;
}

final RegExp _phoneLike = RegExp(r'^[+0-9][0-9 ().\-/]{6,}$');

bool _looksLikePhone(String value) =>
    _phoneLike.hasMatch(value.trim()) &&
    value.replaceAll(RegExp('[^0-9]'), '').length >= 8;

/// Construit le plan d'import d'un tableau.
///
/// * En-tête : première des 5 premières lignes où un libellé est reconnu.
///   Sans en-tête, les colonnes sont devinées : e-mails (« @ »),
///   téléphones (8 chiffres ou plus), nom (première autre colonne remplie).
/// * Une ligne sans catégorie reçoit [defaultCategoryId].
/// * Les catégories se comparent sans casse, accents ni ponctuation.
ImportPlan buildImportPlan(
  CellTable table, {
  required List<TicketCategory> categories,
  String? defaultCategoryId,
}) {
  bool blank(List<String> row) => row.every((v) => v.trim().isEmpty);

  // En-tête : parmi les 5 premières lignes non vides.
  int? headerIndex;
  var columns = <ImportColumn, int>{};
  var inspected = 0;
  for (var r = 0; r < table.length && inspected < 5; r++) {
    if (blank(table[r])) continue;
    inspected++;
    final found = <ImportColumn, int>{};
    for (final (c, cell) in table[r].indexed) {
      final column = columnForHeader(cell);
      if (column != null && !found.containsKey(column)) found[column] = c;
    }
    if (found.containsKey(ImportColumn.name) ||
        found.containsKey(ImportColumn.firstName) ||
        found.length >= 2) {
      headerIndex = r;
      columns = found;
      break;
    }
  }
  final start = headerIndex == null ? 0 : headerIndex + 1;
  final data = table.sublist(start);
  if (headerIndex == null) columns = _guessColumns(data);

  final categoryByLabel = {for (final c in categories) foldLabel(c.name): c.id};
  final seenPhones = <String>{};
  final seenEmails = <String>{};
  final rows = <ImportRow>[];

  String cell(List<String> row, ImportColumn column) {
    final index = columns[column];
    return index == null || index >= row.length ? '' : row[index].trim();
  }

  for (final (offset, row) in data.indexed) {
    if (blank(row)) continue;
    final line = start + offset + 1;
    final name = [
      cell(row, ImportColumn.firstName),
      cell(row, ImportColumn.name),
    ].where((part) => part.isNotEmpty).join(' ');
    final label = cell(row, ImportColumn.category);
    final categoryId = label.isEmpty
        ? defaultCategoryId
        : categoryByLabel[foldLabel(label)];

    final check = validateHolder(
      name: name,
      phone: cell(row, ImportColumn.phone),
      email: cell(row, ImportColumn.email),
    );
    final holder = check.holder;
    final problem = switch (check.problem) {
      HolderProblem.nameTooLong => RowProblem.nameTooLong,
      HolderProblem.phoneInvalid => RowProblem.phoneInvalid,
      HolderProblem.emailInvalid => RowProblem.emailInvalid,
      null when holder?.name == null => RowProblem.nameMissing,
      null when categoryId == null => RowProblem.categoryUnknown,
      null => null,
    };
    final warnings = <RowWarning>{};
    if (problem == null) {
      if (holder!.phone case final phone? when !seenPhones.add(phone)) {
        warnings.add(RowWarning.duplicatePhone);
      }
      if (holder.email case final email? when !seenEmails.add(email)) {
        warnings.add(RowWarning.duplicateEmail);
      }
    }
    rows.add(
      ImportRow(
        line: line,
        holder: problem == null ? holder : null,
        categoryId: problem == null ? categoryId : null,
        categoryLabel: label.isEmpty ? null : label,
        problem: problem,
        warnings: warnings,
      ),
    );
  }

  return ImportPlan(
    columns: columns,
    rows: rows,
    headerLine: headerIndex == null ? null : headerIndex + 1,
    headers: headerIndex == null ? const [] : table[headerIndex],
  );
}

/// Colonnes devinées d'après le contenu (fichier sans en-tête).
Map<ImportColumn, int> _guessColumns(CellTable data) {
  final width = data.fold(0, (w, row) => row.length > w ? row.length : w);
  final columns = <ImportColumn, int>{};
  bool mostly(int c, bool Function(String) test) {
    final values = [
      for (final row in data)
        if (c < row.length && row[c].trim().isNotEmpty) row[c].trim(),
    ];
    return values.isNotEmpty && values.where(test).length * 2 > values.length;
  }

  for (var c = 0; c < width; c++) {
    if (!columns.containsKey(ImportColumn.email) &&
        mostly(c, (v) => v.contains('@'))) {
      columns[ImportColumn.email] = c;
    } else if (!columns.containsKey(ImportColumn.phone) &&
        mostly(c, _looksLikePhone)) {
      columns[ImportColumn.phone] = c;
    } else if (!columns.containsKey(ImportColumn.name) &&
        mostly(c, (v) => RegExp(r'\p{L}', unicode: true).hasMatch(v))) {
      columns[ImportColumn.name] = c;
    }
  }
  return columns;
}

/// Modèle de liste à remplir (CSV « ; », UTF-8 avec BOM pour Excel).
String importTemplateCsv(List<TicketCategory> categories) {
  final first = categories.firstOrNull?.name ?? 'Standard';
  final second = categories.length > 1 ? categories[1].name : first;
  return '﻿Nom;Téléphone;E-mail;Catégorie\r\n'
      'Awa Ouédraogo;70 11 22 33;awa@exemple.bf;$first\r\n'
      'Issa Sawadogo;+225 07 08 09 10 11;;$second\r\n';
}
