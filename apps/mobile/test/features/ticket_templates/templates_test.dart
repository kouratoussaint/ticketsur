import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/ticket_templates/application/template_providers.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_theme.dart';
import 'package:ticketsur/features/ticket_templates/presentation/ticket_artwork.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart';
import 'package:ticketsur/l10n/l10n.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_event_setup_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_ticket_repository.dart';
import '../../helpers/fake_ticket_template_repository.dart';
import '../../helpers/navigation.dart';

/// Image RGBA unie de [width] × [height], avec un carré blanc éventuel.
Uint8List _image(int width, int height, {(int, int, int)? white}) {
  final rgba = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final inside =
          white != null &&
          x >= white.$1 &&
          x < white.$1 + white.$3 &&
          y >= white.$2 &&
          y < white.$2 + white.$3;
      final value = inside ? 255 : 40;
      rgba
        ..[i] = value
        ..[i + 1] = value
        ..[i + 2] = value
        ..[i + 3] = 255;
    }
  }
  return rgba;
}

TicketSecret _secret(int i, {String category = 'VIP', String? holder}) =>
    TicketSecret(
      ticketId: 't$i',
      reference: 'TS-AAAA-000$i',
      token: fakeToken(i),
      categoryName: category,
      holderName: holder,
    );

void main() {
  group('domaine', () {
    test("thème proposé selon le type d'événement", () {
      expect(defaultThemeFor(EventKind.concert), 1);
      expect(defaultThemeFor(EventKind.conference), 6);
      expect(defaultThemeFor(EventKind.training), 9);
      expect(defaultThemeFor(EventKind.sport), 4);
      expect(defaultThemeFor(EventKind.worship), 2);
      expect(defaultThemeFor(EventKind.wedding), 12);
      expect(defaultThemeFor(EventKind.gala), 12);
      expect(defaultThemeFor(EventKind.other), 1);
      expect(ticketThemes.map((t) => t.id), [for (var i = 1; i <= 12; i++) i]);
    });

    test('12 thèmes lisibles : pastille, « Scannez ici », accent', () {
      const white = Color(0xFFFFFFFF);
      for (final theme in ticketThemes) {
        expect(
          contrastRatio(theme.chipText, theme.chip),
          greaterThanOrEqualTo(4.5),
          reason: 'pastille du thème ${theme.id}',
        );
        expect(
          contrastRatio(theme.ink, white),
          greaterThanOrEqualTo(4.5),
          reason: '« Scannez ici » du thème ${theme.id}',
        );
        expect(
          contrastRatio(theme.accent, theme.dark),
          greaterThanOrEqualTo(4.5),
          reason: 'accent sur le fond sombre du thème ${theme.id}',
        );
      }
    });

    test("modèle d'une catégorie : enregistré, sinon proposé", () {
      final art = TicketArt(
        event: testEvent(kind: EventKind.sport),
        organizationName: 'Faso',
        templates: const {'c1': BuiltinTemplate(5)},
        info: const {'t1': (categoryId: 'c1', number: 3)},
      );
      expect(art.templateFor('c1'), const BuiltinTemplate(5));
      expect(art.templateFor('c2'), const BuiltinTemplate(4));
      expect(art.templateOfTicket('t1'), const BuiltinTemplate(5));
      expect(art.templateOfTicket('inconnu'), const BuiltinTemplate(4));
      expect(formatTicketNumber(3), '000003');
      expect(formatTicketNumber(123456), '123456');
    });

    test('plus grand carré clair', () {
      expect(largestLightSquare(_image(40, 20), 40, 20), isNull);
      final square = largestLightSquare(
        _image(40, 20, white: (25, 4, 12)),
        40,
        20,
      );
      expect(square, (x: 25, y: 4, side: 12));
    });

    test('placement : dans le carré blanc, sinon à droite', () {
      // Carré blanc de 60 % de la hauteur : le QR s'y loge.
      final inSquare = defaultPlacement(
        width: 2400,
        height: 1000,
        square: (x: 160, y: 20, side: 60),
        sampleWidth: 240,
        sampleHeight: 100,
      );
      expect(inSquare.qrSize, closeTo(0.564, 0.001));
      final centerX = inSquare.qrX + inSquare.qrSize / 2.4 / 2;
      expect(centerX, closeTo(190 / 240, 0.001));
      expect(inSquare.qrY + inSquare.qrSize / 2, closeTo(0.5, 0.001));

      // Carré trop petit (20 %) : carré blanc de Tikéo, dernier quart droit.
      final fallback = defaultPlacement(
        width: 2400,
        height: 1000,
        square: (x: 10, y: 10, side: 20),
        sampleWidth: 240,
        sampleHeight: 100,
      );
      expect(fallback.qrSize, 0.6);
      expect(fallback.qrX + 0.6 / 2.4 / 2, closeTo(0.875, 0.001));
      // Référence centrée sur le QR ; au-dessus, faute de place dessous.
      expect(fallback.refX, closeTo(0.875, 0.001));
      expect(fallback.refY, 0);
    });

    test('placement ramené dans le ticket, jamais sous 35 %', () {
      const outside = QrPlacement(
        qrX: 0.95,
        qrY: 0.9,
        qrSize: 0.1,
        refX: 2,
        refY: -1,
      );
      final clamped = outside.clamped(2.4);
      expect(clamped.qrSize, QrPlacement.minSize);
      expect(clamped.qrX + clamped.qrSize / 2.4, lessThanOrEqualTo(1));
      expect(clamped.qrY + clamped.qrSize, lessThanOrEqualTo(1));
      expect(clamped.refX, 1);
      expect(clamped.refY, 0);
    });

    test('géométrie : QR des thèmes dans le talon, marge de 4 modules', () {
      final builtin = TicketGeometry.of(const BuiltinTemplate(1));
      expect(builtin.size, const Size(1080, 450));
      expect(builtin.qr.left, greaterThan(TicketGeometry.stubLeft));
      expect(builtin.qr.right, lessThan(1080));
      // 35 % de la hauteur au moins.
      expect(builtin.qr.height / 450, greaterThan(QrPlacement.minSize));
      expect(TicketGeometry.quietZone(205), 20);

      final custom = TicketGeometry.of(
        const CustomTemplate(
          width: 2000,
          height: 1000,
          placement: QrPlacement(
            qrX: 0.7,
            qrY: 0.1,
            qrSize: 0.5,
            refX: 0.8,
            refY: 0.7,
          ),
        ),
      );
      expect(custom.size, const Size(1080, 540));
      expect(custom.qr, const Rect.fromLTWH(756, 54, 270, 270));
    });
  });

  group('PDF', () {
    setUpAll(() => initializeDateFormatting('fr'));

    test('une page par ticket, au format du modèle', () async {
      final art = TicketArt(
        event: testEvent(title: 'Gala'),
        organizationName: 'Faso',
        templates: const {
          'custom': CustomTemplate(
            width: 2000,
            height: 1000,
            imagePath: 'o/e/Modele_x.jpg',
            placement: QrPlacement(
              qrX: 0.7,
              qrY: 0.1,
              qrSize: 0.5,
              refX: 0.8,
              refY: 0.7,
            ),
          ),
        },
        info: const {
          't1': (categoryId: 'vip', number: 1),
          't2': (categoryId: 'custom', number: 2),
        },
      );
      final bytes = await buildTicketsPdf(
        event: art.event,
        organizationName: 'Faso',
        art: art,
        tickets: [
          _secret(1, holder: 'Awa'),
          _secret(2, category: 'Design'),
        ],
      );
      final text = latin1.decode(bytes, allowInvalid: true);
      final boxes = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]')
          .allMatches(text)
          .toList();
      expect(boxes, hasLength(2));
      final ratios = [
        for (final box in boxes)
          double.parse(box.group(1)!) / double.parse(box.group(2)!),
      ]..sort();
      // Design importé 2:1, thème intégré 2,4:1.
      expect(ratios.first, closeTo(2, 0.01));
      expect(ratios.last, closeTo(2.4, 0.01));
    });

    test('un fond par catégorie, quel que soit le nombre de tickets', () async {
      final art = TicketArt(
        event: testEvent(title: 'Gala'),
        organizationName: 'Faso',
        info: {
          for (var i = 1; i <= 6; i++)
            't$i': (categoryId: i.isEven ? 'a' : 'b', number: i),
        },
      );
      // PNG 1 × 1 transparent.
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAj'
        'CB0C8AAAAASUVORK5CYII=',
      );
      Future<int> images(int count) async {
        final bytes = await buildTicketsPdf(
          event: art.event,
          organizationName: 'Faso',
          art: art,
          backgrounds: {'a': png, 'b': png},
          tickets: [for (var i = 1; i <= count; i++) _secret(i)],
        );
        final text = latin1.decode(bytes, allowInvalid: true);
        return RegExp(r'/Subtype\s*/Image').allMatches(text).length;
      }

      final two = await images(2);
      expect(two, greaterThan(0));
      expect(await images(6), two);
    });
  });

  group('dessin', () {
    Future<void> pumpArtwork(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: TicketSurTheme.light(),
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            body: Center(child: SizedBox(width: 1080, child: child)),
          ),
        ),
      );
      await tester.pump();
    }

    final art = TicketArt(
      event: testEvent(title: 'ASFA vs EFO', kind: EventKind.sport),
      organizationName: 'Faso Événements',
    );

    testWidgets('thème intégré : numéro, référence, titulaire, catégorie', (
      tester,
    ) async {
      await pumpArtwork(
        tester,
        TicketArtwork(
          art: art,
          template: const BuiltinTemplate(4),
          categoryName: 'Tribune',
          number: 42,
          reference: 'TS-AAAA-0001',
          token: fakeToken(1),
          holderName: 'Awa',
        ),
      );
      expect(find.text('N° 000042'), findsOneWidget);
      expect(find.text('TS-AAAA-0001'), findsOneWidget);
      expect(find.text('Titulaire : Awa'), findsOneWidget);
      expect(find.text('TRIBUNE'), findsOneWidget);
      expect(find.text('Scannez ici'), findsOneWidget);
      expect(find.byKey(const Key('artwork-qr')), findsOneWidget);
      // Match : losange VS entre les équipes.
      expect(find.byKey(const Key('artwork-versus')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fond seul : ni QR, ni numéro, ni titulaire', (tester) async {
      await pumpArtwork(
        tester,
        TicketArtwork(
          art: art,
          template: const BuiltinTemplate(4, singleFontTitle: true),
          categoryName: 'Tribune',
          number: 42,
          reference: 'TS-AAAA-0001',
          token: fakeToken(1),
          holderName: 'Awa',
          background: true,
        ),
      );
      expect(find.byKey(const Key('artwork-qr')), findsNothing);
      expect(find.byKey(const Key('artwork-number')), findsNothing);
      expect(find.byKey(const Key('artwork-holder')), findsNothing);
      // Une seule police : pas de losange.
      expect(find.byKey(const Key('artwork-versus')), findsNothing);
      expect(find.text('TRIBUNE'), findsOneWidget);
    });

    testWidgets('design importé : QR et bloc de la référence placés', (
      tester,
    ) async {
      await pumpArtwork(
        tester,
        TicketArtwork(
          art: art,
          template: const CustomTemplate(
            width: 2160,
            height: 900,
            placement: QrPlacement(
              qrX: 0.7,
              qrY: 0.1,
              qrSize: 0.5,
              refX: 0.8,
              refY: 0.7,
            ),
          ),
          categoryName: 'Tribune',
          number: 42,
          reference: 'TS-AAAA-0001',
          token: fakeToken(1),
        ),
      );
      expect(find.text('N° 000042'), findsOneWidget);
      final qr = tester.getRect(find.byKey(const Key('artwork-qr')));
      final ticket = tester.getRect(find.byType(TicketArtwork));
      // 0,5 × 450 = 225 px de côté, à 0,7 × 1080 du bord gauche.
      expect(qr.width, closeTo(225, 0.5));
      expect(qr.left - ticket.left, closeTo(756, 0.5));
    });
  });

  group('écrans', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late FakeEventRepository events;
    late FakeEventSetupRepository setup;
    late FakeTicketTemplateRepository templates;

    setUp(() {
      events = FakeEventRepository();
      setup = FakeEventSetupRepository(
        categories: const [
          TicketCategory(id: 'c1', eventId: 'e1', name: 'VIP'),
          TicketCategory(id: 'c2', eventId: 'e1', name: 'Standard'),
        ],
      );
      templates = FakeTicketTemplateRepository();
    });

    Future<void> openTemplates(
      WidgetTester tester, {
      List<Override> extra = const [],
    }) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      events.events.add(
        testEvent(
          id: 'e1',
          status: EventStatus.published,
          kind: EventKind.concert,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...await appOverrides(
              auth: FakeAuthRepository(user: user),
              organizations: FakeOrganizationRepository([
                Organization(
                  id: testOrganization.id,
                  name: testOrganization.name,
                  slug: testOrganization.slug,
                  role: MemberRole.owner,
                ),
              ]),
              events: events,
              setup: setup,
              templates: templates,
            ),
            ...extra,
          ],
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await openEventsList(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-card-e1')));
      await tester.pumpAndSettle();
      final entry = find.byKey(const Key('categories-templates'));
      await tester.scrollUntilVisible(entry, 200);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
    }

    testWidgets('liste : modèle proposé selon le type, par catégorie', (
      tester,
    ) async {
      await openTemplates(tester);
      expect(find.byKey(const Key('templates-category-c1')), findsOneWidget);
      expect(find.byKey(const Key('templates-category-c2')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('templates-label-c1'))).data,
        'Proposé : Concert',
      );
    });

    testWidgets('choisir un thème intégré, une seule police, enregistrer', (
      tester,
    ) async {
      await openTemplates(tester);
      await tester.tap(find.byKey(const Key('templates-category-c1')));
      await tester.pumpAndSettle();
      final theater = find.byKey(const Key('template-theme-5'));
      await tester.ensureVisible(theater);
      await tester.pumpAndSettle();
      await tester.tap(theater);
      await tester.pumpAndSettle();
      final single = find.byKey(const Key('template-single-font'));
      await tester.ensureVisible(single);
      await tester.pumpAndSettle();
      await tester.tap(single);
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('template-save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(templates.calls, ['save c1 builtin 5 une-police']);
      // Retour à la liste, libellé à jour.
      expect(
        tester.widget<Text>(find.byKey(const Key('templates-label-c1'))).data,
        'Modèle : Théâtre',
      );
    });

    testWidgets('importer un design : placement, minimum de 35 %, envoi', (
      tester,
    ) async {
      final bytes = Uint8List.fromList(const [1, 2, 3]);
      await openTemplates(
        tester,
        extra: [
          templateImagePickerProvider.overrideWithValue(
            () async => (bytes: bytes, mimeType: 'image/jpeg'),
          ),
          templateImageAnalyzerProvider.overrideWithValue(
            (_) async => (
              width: 2400,
              height: 1000,
              lightSquare: null,
              sampleWidth: 240,
              sampleHeight: 100,
            ),
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('templates-category-c2')));
      await tester.pumpAndSettle();
      final import = find.byKey(const Key('template-import'));
      await tester.ensureVisible(import);
      await tester.pumpAndSettle();
      await tester.tap(import);
      await tester.pumpAndSettle();
      // Aucune zone blanche : QR sur son carré blanc, à droite.
      expect(find.byKey(const Key('placement')), findsOneWidget);
      expect(find.byKey(const Key('placement-qr')), findsOneWidget);
      // Curseur tiré au minimum : message expliqué.
      final slider = find.byKey(const Key('placement-qr-size'));
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      await tester.drag(slider, const Offset(-2000, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('placement-min-message')), findsOneWidget);
      await tester.tap(find.byKey(const Key('placement-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('template-adjust')), findsOneWidget);
      final save = find.byKey(const Key('template-save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(templates.calls, ['upload', 'save c2 custom']);
      final saved = templates.templates['c2']! as CustomTemplate;
      expect(saved.imagePath, 'org-test/e1/Modele_test.jpg');
      expect(saved.placement.qrSize, QrPlacement.minSize);
      expect(
        tester.widget<Text>(find.byKey(const Key('templates-label-c2'))).data,
        'Design importé',
      );
    });

    testWidgets('design aux mauvaises proportions refusé', (tester) async {
      await openTemplates(
        tester,
        extra: [
          templateImagePickerProvider.overrideWithValue(
            () async =>
                (bytes: Uint8List.fromList(const [1]), mimeType: 'image/png'),
          ),
          templateImageAnalyzerProvider.overrideWithValue(
            (_) async => (
              width: 1000,
              height: 1000,
              lightSquare: null,
              sampleWidth: 240,
              sampleHeight: 240,
            ),
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('templates-category-c1')));
      await tester.pumpAndSettle();
      final import = find.byKey(const Key('template-import'));
      await tester.ensureVisible(import);
      await tester.pumpAndSettle();
      await tester.tap(import);
      await tester.pump();
      expect(find.byKey(const Key('template-import-error')), findsOneWidget);
      expect(find.byKey(const Key('placement')), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('revenir au modèle proposé', (tester) async {
      templates.templates['c1'] = const BuiltinTemplate(7);
      await openTemplates(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('templates-label-c1'))).data,
        'Modèle : Exposition',
      );
      await tester.tap(find.byKey(const Key('templates-category-c1')));
      await tester.pumpAndSettle();
      final reset = find.byKey(const Key('template-reset'));
      await tester.ensureVisible(reset);
      await tester.pumpAndSettle();
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(templates.calls, ['save c1 default']);
      expect(
        tester.widget<Text>(find.byKey(const Key('templates-label-c1'))).data,
        'Proposé : Concert',
      );
    });
  });
}
