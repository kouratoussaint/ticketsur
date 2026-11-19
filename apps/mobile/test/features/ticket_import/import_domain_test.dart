// Fragments XML et CSV écrits bout à bout, sans espace voulu entre eux.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/ticket_import/domain/import_plan.dart';
import 'package:ticketsur/features/ticket_import/domain/table_reader.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

const _categories = [
  TicketCategory(
    id: 'vip',
    eventId: 'e1',
    name: 'VIP',
    capacity: 10,
    issued: 8,
  ),
  TicketCategory(id: 'std', eventId: 'e1', name: 'Standard'),
  TicketCategory(id: 'etu', eventId: 'e1', name: 'Étudiant'),
];

/// Classeur .xlsx minimal à textes partagés (comme Excel les écrit).
Uint8List _sharedStringsXlsx() {
  final archive = Archive();
  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  add(
    'xl/workbook.xml',
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="Liste" sheetId="1" r:id="rId7"/></sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId7" Target="worksheets/feuille.xml" Type="x"/>'
        '</Relationships>',
  );
  add(
    'xl/sharedStrings.xml',
    '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<si><t>Nom</t></si><si><t>Tél.</t></si>'
        '<si><r><t>Awa </t></r><r><t>Ouédraogo</t></r>'
        '<rPh><t>ignorer</t></rPh></si>'
        '<si><t xml:space="preserve"> VIP </t></si></sst>',
  );
  add(
    'xl/worksheets/feuille.xml',
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetData>'
        '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c>'
        '<c r="D1" t="str"><v>Catégorie</v></c></row>'
        '<row r="2"><c r="A2" t="s"><v>2</v></c><c r="B2"><v>2.2670112233E10</v></c>'
        '<c r="D2" t="s"><v>3</v></c></row>'
        '<row r="4"><c r="B4"><v>70112234</v></c><c r="A4" t="b"><v>1</v></c></row>'
        '</sheetData></worksheet>',
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  group('lecture CSV', () {
    test('séparateur détecté : « ; » (Excel français), « , », tabulation', () {
      expect(detectSeparator('Nom;Téléphone\nA;1'), ';');
      expect(detectSeparator('name,phone\na,1'), ',');
      expect(detectSeparator('nom\ttel\na\t1'), '\t');
      expect(detectSeparator('"Nom, prénom";tel'), ';');
      expect(detectSeparator('seul'), ';');
    });

    test('guillemets, guillemets doublés, retours à la ligne cités', () {
      final table = readCsv(
        'Nom;Note\r\n"Ouédraogo; Awa";"Il a dit ""oui"""\r\n'
        '"Sur\ndeux lignes";x\n',
      );
      expect(table, [
        ['Nom', 'Note'],
        ['Ouédraogo; Awa', 'Il a dit "oui"'],
        ['Sur\ndeux lignes', 'x'],
      ]);
    });

    test('lignes vides gardées (numéros), fin de fichier vide retirée', () {
      final table = readCsv('Nom\n\nAwa\n;\n\n');
      expect(table, [
        ['Nom'],
        [''],
        ['Awa'],
      ]);
    });

    test('encodage : UTF-8 avec BOM, sinon Windows-1252', () {
      final utf8Bom = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('Prénom'),
      ]);
      expect(decodeText(utf8Bom), 'Prénom');
      // « Prénom – Œuvre » en Windows-1252.
      final cp1252 = Uint8List.fromList([
        ...'Pr'.codeUnits,
        0xE9,
        ...'nom '.codeUnits,
        0x96,
        0x20,
        0x8C,
        ...'uvre'.codeUnits,
      ]);
      expect(decodeText(cp1252), 'Prénom – Œuvre');
    });

    test('extensions : .xls refusé, format inconnu refusé', () {
      expect(
        () => readTable('liste.xls', Uint8List(0)),
        throwsA(TableReadFailure.legacyExcel),
      );
      expect(
        () => readTable('liste.pdf', Uint8List(0)),
        throwsA(TableReadFailure.unsupported),
      );
      expect(
        () => readTable('liste.xlsx', Uint8List.fromList([1, 2, 3])),
        throwsA(TableReadFailure.unreadable),
      );
      expect(readTable('LISTE.CSV', utf8.encode('a;b')), [
        ['a', 'b'],
      ]);
    });
  });

  group('lecture Excel', () {
    test(
      'classeur réel (openpyxl) : 1re feuille, lignes et colonnes à leur place',
      () {
        final bytes = File('test/fixtures/liste_invites.xlsx')
            .readAsBytesSync();
        final table = readTable('Liste invités.xlsx', bytes);
        expect(table, hasLength(8));
        expect(table[0], ['Liste des invités — Gala 2026']);
        expect(table[1], isEmpty);
        expect(table[2], [
          'Prénom',
          'Nom',
          'Téléphone (WhatsApp)',
          'E-mail',
          'Catégorie',
        ]);
        // Téléphone saisi comme nombre : chiffres, sans « .0 ».
        expect(table[3], [
          'Awa',
          'Ouédraogo',
          '70112233',
          'awa@exemple.bf',
          'VIP',
        ]);
        expect(table[4], [
          'Issa',
          'Sawadogo',
          '+225 07 08 09 10 11',
          '',
          'standard',
        ]);
        expect(table[5], isEmpty);
        expect(table[6], ['Moussa', 'Traoré', '22670112233']);
        // Texte enrichi recomposé.
        expect(table[7].first, 'Fatou');
      },
    );

    test(
      'textes partagés, texte enrichi, notation scientifique, cases sautées',
      () {
        final table = readXlsx(_sharedStringsXlsx());
        expect(table, [
          ['Nom', 'Tél.', '', 'Catégorie'],
          ['Awa Ouédraogo', '22670112233', '', ' VIP '],
          <String>[],
          ['VRAI', '70112234'],
        ]);
      },
    );
  });

  group('plan d’import', () {
    test(
      'en-tête sous un titre, prénom + nom, catégories sans casse ni accents',
      () {
        final table = readTable(
          'liste.xlsx',
          File('test/fixtures/liste_invites.xlsx').readAsBytesSync(),
        );
        final plan = buildImportPlan(
          table,
          categories: _categories,
          defaultCategoryId: 'std',
        );
        expect(plan.headerLine, 3);
        expect(plan.columns, {
          ImportColumn.firstName: 0,
          ImportColumn.name: 1,
          ImportColumn.phone: 2,
          ImportColumn.email: 3,
          ImportColumn.category: 4,
        });
        expect([for (final r in plan.rows) r.line], [4, 5, 7, 8]);

        final awa = plan.rows[0];
        expect(awa.ok, isTrue);
        expect(
          awa.holder,
          const TicketHolder(
            name: 'Awa Ouédraogo',
            phone: '+22670112233',
            email: 'awa@exemple.bf',
          ),
        );
        expect(awa.categoryId, 'vip');
        expect(plan.rows[1].categoryId, 'std'); // « standard »
        // Sans catégorie : catégorie par défaut ; même téléphone qu'Awa.
        expect(plan.rows[2].categoryId, 'std');
        expect(plan.rows[2].warnings, {RowWarning.duplicatePhone});
        // Catégorie inconnue : bloquant, libellé gardé pour le message.
        expect(plan.rows[3].problem, RowProblem.categoryUnknown);
        expect(plan.rows[3].categoryLabel, 'Inconnue');

        expect(plan.valid, hasLength(3));
        expect(plan.errors.single.line, 8);
        expect(plan.perCategory, {'vip': 1, 'std': 2});
        expect(plan.ticketRows.map((r) => r.categoryId), ['vip', 'std', 'std']);
      },
    );

    test(
      'erreurs par ligne : nom manquant, téléphone, e-mail, nom trop long',
      () {
        final plan = buildImportPlan(
          readCsv(
            'Participant;Contact;Courriel\n'
            ';70112233;\n'
            'Awa;12;\n'
            'Issa;;pas-un-mail\n'
            '${'a' * 121};;\n'
            'Moussa;;moussa@exemple.bf\n'
            'Moussa bis;;MOUSSA@exemple.bf\n',
          ),
          categories: _categories,
          defaultCategoryId: 'etu',
        );
        expect(
          [for (final r in plan.rows) r.problem],
          [
            RowProblem.nameMissing,
            RowProblem.phoneInvalid,
            RowProblem.emailInvalid,
            RowProblem.nameTooLong,
            null,
            null,
          ],
        );
        expect([for (final r in plan.errors) r.line], [2, 3, 4, 5]);
        expect(plan.warned.single.warnings, {RowWarning.duplicateEmail});
        expect(plan.valid.first.categoryId, 'etu');
      },
    );

    test('sans en-tête : colonnes devinées d’après le contenu', () {
      final plan = buildImportPlan(
        readCsv(
          'awa@exemple.bf,Awa Ouédraogo,70 11 22 33\n'
          'issa@exemple.bf,Issa Sawadogo,0022576000000\n',
        ),
        categories: _categories,
        defaultCategoryId: 'std',
      );
      expect(plan.headerLine, isNull);
      expect(plan.columns, {
        ImportColumn.email: 0,
        ImportColumn.name: 1,
        ImportColumn.phone: 2,
      });
      expect(plan.valid, hasLength(2));
      expect(plan.rows.first.line, 1);
      expect(plan.valid[1].holder!.phone, '+22576000000');
    });

    test('pas de catégorie par défaut : lignes sans catégorie bloquées', () {
      final plan = buildImportPlan(
        readCsv('Nom;Catégorie\nAwa;\nIssa;Étudiant\n'),
        categories: _categories,
      );
      expect(plan.rows.first.problem, RowProblem.categoryUnknown);
      expect(plan.rows.last.categoryId, 'etu');
    });

    test('quotas prévus : catégorie et capacité de l’événement', () {
      final plan = buildImportPlan(
        readCsv('Nom;Catégorie\nA;VIP\nB;VIP\nC;VIP\nD;Standard\n'),
        categories: _categories,
        defaultCategoryId: 'std',
      );
      expect(plan.quotaIssues(_categories), [
        (categoryName: 'VIP', wanted: 3, remaining: 2),
      ]);
      expect(plan.quotaIssues(_categories, eventCapacity: 10), [
        (categoryName: 'VIP', wanted: 3, remaining: 2),
        (categoryName: null, wanted: 4, remaining: 2),
      ]);
    });

    test('libellés d’en-tête reconnus', () {
      expect(columnForHeader('Nom & Prénom(s)'), ImportColumn.name);
      expect(columnForHeader('NOM'), ImportColumn.name);
      expect(columnForHeader('Prénoms'), ImportColumn.firstName);
      expect(columnForHeader('N° Tél'), ImportColumn.phone);
      expect(columnForHeader('Téléphone WhatsApp'), ImportColumn.phone);
      expect(columnForHeader('Adresse e-mail'), ImportColumn.email);
      expect(columnForHeader('Type de ticket'), ImportColumn.category);
      expect(columnForHeader('Commentaire'), isNull);
      expect(columnForHeader(''), isNull);
    });

    test('modèle : en-tête reconnu, relu sans erreur', () {
      final csv = importTemplateCsv(_categories);
      final plan = buildImportPlan(
        readTable('modele.csv', Uint8List.fromList(utf8.encode(csv))),
        categories: _categories,
      );
      expect(plan.headerLine, 1);
      expect(plan.errors, isEmpty);
      expect(plan.perCategory, {'vip': 1, 'std': 1});
    });
  });
}
