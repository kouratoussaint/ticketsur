import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/domain/cities.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_detail_page.dart';
import 'package:ticketsur/features/events/presentation/event_form_page.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/navigation.dart';

/// PNG 1×1 valide : décodable par le moteur de test.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB'
  '0C8AAAAASUVORK5CYII=',
);

void main() {
  group('domaine', () {
    test('fromJson lit ville, type, description, photo', () {
      final event = TicketEvent.fromJson(const {
        'id': 'e1',
        'organization_id': 'o1',
        'title': 'Festival',
        'timezone': 'Africa/Ouagadougou',
        'starts_at': '2030-01-01T18:00:00Z',
        'ends_at': '2030-01-01T23:00:00Z',
        'status': 'draft',
        'city': 'Bobo-Dioulasso',
        'country_code': 'BF',
        'venue_address': 'Secteur 22',
        'description': 'Trois jours',
        'kind': 'concert',
        'cover_path': 'o1/e1/abc.jpg',
      }, coverUrlOf: (path) => 'https://cdn/$path');
      expect(event.city, 'Bobo-Dioulasso');
      expect(event.kind, EventKind.concert);
      expect(event.coverUrl, 'https://cdn/o1/e1/abc.jpg');
      expect(event.readyToPublish, isTrue);
      expect(event.withCover(null, null).readyToPublish, isFalse);
    });

    test('type inconnu : « autre »', () {
      expect(EventKind.fromWire('rave'), EventKind.other);
    });

    test('toParams : champs vides → null, type transmis', () {
      final params = EventDraft(
        title: ' Gala ',
        timezone: 'Africa/Ouagadougou',
        startsAt: DateTime.utc(2030),
        endsAt: DateTime.utc(2030, 1, 2),
        city: '  ',
        description: ' Soirée ',
        venueAddress: '',
        kind: EventKind.gala,
      ).toParams();
      expect(params['p_city'], isNull);
      expect(params['p_venue_address'], isNull);
      expect(params['p_description'], 'Soirée');
      expect(params['p_kind'], 'gala');
      expect(params['p_country_code'], 'BF');
    });

    test('villes : sans accents ni casse, débuts de mot d’abord', () {
      expect(suggestCities('ouaga'), ['Ouagadougou']);
      expect(suggestCities('DEDOU'), ['Dédougou']);
      expect(suggestCities('kou'), ['Koudougou', 'Koupéla']);
      expect(suggestCities('').length, 6);
      expect(foldAccents('Fada N’Gourma'), "fada n'gourma");
    });

    test('type MIME déduit de l’extension', () {
      expect(coverMimeType(null, 'IMG_1.JPG'), 'image/jpeg');
      expect(coverMimeType('', 'a.webp'), 'image/webp');
      expect(coverMimeType('image/png', 'a.jpg'), 'image/png');
      expect(coverMimeType(null, 'a.gif'), 'application/octet-stream');
    });
  });

  group('assistant de création', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late FakeEventRepository events;
    late List<CoverSource> pickerCalls;
    CoverImage? nextImage;

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            events: events,
            coverPicker: (source) async {
              pickerCalls.add(source);
              return nextImage;
            },
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> next(WidgetTester tester) =>
        tapVisible(tester, find.byKey(const Key('event-next')));

    Future<void> openForm(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('quick-new-event')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick-new-event')));
      await tester.pumpAndSettle();
      expect(find.byType(EventFormPage), findsOneWidget);
    }

    setUp(() {
      events = FakeEventRepository();
      pickerCalls = [];
      nextImage = CoverImage(bytes: _png, mimeType: 'image/png');
    });

    testWidgets('quatre étapes complètes : contenu, ville, photo, envoi', (
      tester,
    ) async {
      await pumpApp(tester);
      await openForm(tester);

      // 1. Infos
      await tester.enterText(find.byKey(const Key('event-title')), 'Festival');
      await tapVisible(tester, find.byKey(const Key('event-kind-concert')));
      await tester.enterText(
        find.byKey(const Key('event-description')),
        'Trois jours de musique',
      );
      await next(tester);

      // 2. Date et lieu : ville choisie dans les suggestions.
      expect(find.byKey(const Key('event-step-whenWhere')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('event-city')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-city')));
      await tester.enterText(find.byKey(const Key('event-city')), 'bobo');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('event-city-option-Bobo-Dioulasso')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('event-address')),
        'Secteur 22',
      );
      await next(tester);

      // 3. Photo depuis la galerie.
      await tapVisible(tester, find.byKey(const Key('event-cover-gallery')));
      expect(pickerCalls, [CoverSource.gallery]);
      expect(find.byKey(const Key('event-cover-local')), findsOneWidget);
      await next(tester);

      // 4. Aperçu : rien ne manque.
      expect(find.byKey(const Key('event-review-card')), findsOneWidget);
      expect(find.byKey(const Key('event-missing')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('event-submit')));

      final draft = events.createCalls.single;
      expect(draft.kind, EventKind.concert);
      expect(draft.city, 'Bobo-Dioulasso');
      expect(draft.venueAddress, 'Secteur 22');
      expect(draft.description, 'Trois jours de musique');
      expect(events.coverCalls, hasLength(1));
      expect(events.coverCalls.single.$2.mimeType, 'image/png');

      expect(find.byType(EventDetailPage), findsOneWidget);
      expect(find.byKey(const Key('event-city-line')), findsOneWidget);
      expect(find.byKey(const Key('event-complete')), findsNothing);
      expect(find.byKey(const Key('event-description-card')), findsOneWidget);
    });

    testWidgets('sans photo ni ville : aperçu et fiche signalent le manque', (
      tester,
    ) async {
      await pumpApp(tester);
      await openForm(tester);
      await tester.enterText(find.byKey(const Key('event-title')), 'Culte');
      await next(tester);
      await next(tester);
      await next(tester);
      expect(find.byKey(const Key('event-missing')), findsOneWidget);
      expect(find.text('• Photo de couverture'), findsOneWidget);
      expect(find.text('• Ville'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('event-submit')));
      expect(events.coverCalls, isEmpty);

      // Fiche : raccourci pour ajouter la photo.
      expect(find.byKey(const Key('event-complete')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('event-complete-cover')));
      expect(find.byKey(const Key('cover-source-camera')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cover-source-camera')));
      await tester.pumpAndSettle();
      expect(pickerCalls, [CoverSource.camera]);
      expect(events.coverCalls, hasLength(1));
      expect(find.text('Photo enregistrée'), findsOneWidget);
      expect(find.byKey(const Key('event-complete-cover')), findsNothing);
      expect(find.byKey(const Key('event-complete-city')), findsOneWidget);
    });

    testWidgets('photo refusée à l’envoi : événement créé, message clair', (
      tester,
    ) async {
      events.nextCoverFailure = EventFailure.coverInvalid;
      await pumpApp(tester);
      await openForm(tester);
      await tester.enterText(find.byKey(const Key('event-title')), 'Gala');
      await next(tester);
      await next(tester);
      await tapVisible(tester, find.byKey(const Key('event-cover-gallery')));
      await next(tester);
      await tapVisible(tester, find.byKey(const Key('event-submit')));
      expect(events.createCalls, hasLength(1));
      expect(find.byType(EventDetailPage), findsOneWidget);
      expect(
        find.textContaining("la photo n'a pas pu être envoyée"),
        findsOneWidget,
      );
    });

    testWidgets('format non accepté : refus local, aucune photo retenue', (
      tester,
    ) async {
      nextImage = CoverImage(bytes: _png, mimeType: 'image/gif');
      await pumpApp(tester);
      await openForm(tester);
      await tester.enterText(find.byKey(const Key('event-title')), 'Gala');
      await next(tester);
      await next(tester);
      await tapVisible(tester, find.byKey(const Key('event-cover-gallery')));
      expect(find.byKey(const Key('event-cover-local')), findsNothing);
      expect(find.textContaining('Photo refusée'), findsOneWidget);
    });

    testWidgets('Retour système : étape précédente, puis sortie', (
      tester,
    ) async {
      await pumpApp(tester);
      await openForm(tester);
      await tester.enterText(find.byKey(const Key('event-title')), 'Gala');
      await next(tester);
      expect(find.byKey(const Key('event-step-whenWhere')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event-step-info')), findsOneWidget);
      // Saisie conservée en revenant.
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('event-title')))
            .controller!
            .text,
        'Gala',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(EventFormPage), findsNothing);
    });

    testWidgets('ville d’un seul caractère : bloquée à l’étape 2', (
      tester,
    ) async {
      await pumpApp(tester);
      await openForm(tester);
      await tester.enterText(find.byKey(const Key('event-title')), 'Gala');
      await next(tester);
      await tester.ensureVisible(find.byKey(const Key('event-city')));
      await tester.enterText(find.byKey(const Key('event-city')), 'O');
      await next(tester);
      expect(find.byKey(const Key('event-step-whenWhere')), findsOneWidget);
      expect(
        find.text('Indiquez une ville de 2 à 80 caractères.'),
        findsOneWidget,
      );
    });
  });

  group('liste', () {
    testWidgets('brouillon incomplet signalé sur sa carte', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final events = FakeEventRepository([
        testEvent(id: 'a', title: 'Incomplet'),
        testEvent(
          id: 'b',
          title: 'Complet',
          city: 'Koudougou',
          coverPath: 'org-test/b/x.jpg',
        ),
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(
              user: const AuthUser(id: 'u1', email: 'a@b.bf'),
            ),
            events: events,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await openEventsList(tester);
      await tester.pumpAndSettle();
      Finder inTab(Finder finder) =>
          find.descendant(of: find.byType(EventsTabPage), matching: finder);
      expect(
        inTab(find.byKey(const Key('event-card-incomplete-a'))),
        findsOneWidget,
      );
      expect(
        inTab(find.byKey(const Key('event-card-incomplete-b'))),
        findsNothing,
      );
      expect(find.textContaining('Koudougou'), findsWidgets);
    });
  });
}
