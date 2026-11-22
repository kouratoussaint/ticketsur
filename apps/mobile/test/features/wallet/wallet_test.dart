import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/public_event_page.dart';
import 'package:ticketsur/features/catalog/presentation/public_organization_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/wallet/application/wallet_providers.dart';
import 'package:ticketsur/features/wallet/data/supabase_wallet_repository.dart';
import 'package:ticketsur/features/wallet/domain/wallet.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_scan_camera.dart';
import '../../helpers/fake_ticket_repository.dart';
import '../../helpers/fake_wallet_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'awa@exemple.bf');
  final token = fakeToken(7);
  final other = fakeToken(8);

  group('domaine', () {
    test('ligne lue, puis relue depuis le cache de l’appareil', () {
      final ticket = WalletTicket.fromJson(walletRow());
      expect(ticket.event.title, 'Soirée Afro-Jazz');
      expect(ticket.token, token);
      final again = WalletTicket.fromJson(
        jsonDecode(jsonEncode(ticket.toJson())) as Map<String, Object?>,
      );
      expect(again.reference, ticket.reference);
      expect(again.event.startsAt, ticket.event.startsAt);
      expect(again.token, token);
    });

    test('modèle, numéro et images gardés dans le cache', () {
      final ticket = WalletTicket.fromJson(
        {
          ...walletRow(
            template: const {
              'kind': 'custom',
              'image_path': 'o/e/Modele_x.jpg',
              'image_width': 2400,
              'image_height': 1000,
              'qr_x': 0.7,
              'qr_y': 0.1,
              'qr_size': 0.5,
              'ref_x': 0.8,
              'ref_y': 0.7,
            },
          ),
          'organization_logo_path': 'org/logo.png',
          'tagline': 'Une nuit de jazz',
        },
        coverUrlOf: (path) => 'https://couv.test/$path',
        logoUrlOf: (path) => 'https://logo.test/$path',
      );
      final again = WalletTicket.fromJson(
        jsonDecode(jsonEncode(ticket.toJson())) as Map<String, Object?>,
      );
      expect(again.eventNumber, 12);
      expect(again.event.tagline, 'Une nuit de jazz');
      expect(again.organizationLogoUrl, 'https://logo.test/org/logo.png');
      final template = again.template! as CustomTemplate;
      expect(template.imageUrl, 'https://couv.test/o/e/Modele_x.jpg');
      expect(again.art.templateOfTicket(again.id), template);
      expect(again.art.info[again.id]?.number, 12);
    });

    test('erreurs serveur traduites', () {
      supabase.PostgrestException error(String m) =>
          supabase.PostgrestException(message: m, code: '55000');
      expect(mapWalletError(error('ticket_claimed')), WalletFailure.claimed);
      expect(mapWalletError(error('ticket_revoked')), WalletFailure.revoked);
      expect(mapWalletError(error('ticket_unknown')), WalletFailure.unknown);
      expect(mapWalletError(error('qr_invalid')), WalletFailure.invalidCode);
    });
  });

  group('écrans', () {
    late FakeWalletRepository wallet;
    final calendared = <CalendarEntry>[];
    late FakeCameraFeed camera;
    String? imageCode;

    setUp(() {
      wallet = FakeWalletRepository(known: {token: walletRow(token: token)});
      camera = FakeCameraFeed();
      imageCode = null;
      calendared.clear();
    });

    Future<ProviderContainer> openApp(
      WidgetTester tester, {
      bool classic = true,
      Map<String, Object> preferences = const {},
      FakeCatalogRepository? catalog,
    }) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository(
              classic ? [] : [testOrganization],
            ),
            wallet: wallet,
            catalog: catalog,
            camera: camera,
            qrFromImage: () async => imageCode,
            preferences: preferences,
            calendar: (entry) async {
              calendared.add(entry);
              return true;
            },
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(TicketSurApp)),
      );
    }

    Future<void> openWalletTab(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Mes tickets'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('compte classique : onglet, vide, puis ajout par le code', (
      tester,
    ) async {
      await openApp(tester);
      await openWalletTab(tester);
      expect(find.byKey(const Key('wallet-empty')), findsOneWidget);
      await tester.tap(find.byKey(const Key('wallet-empty-add')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('wallet-add-code')),
        'pas un ticket',
      );
      await tester.tap(find.byKey(const Key('wallet-add-submit')));
      await tester.pumpAndSettle();
      expect(find.text("Ce code n'est pas un ticket Tikéo."), findsOneWidget);
      expect(wallet.calls, isNot(contains('claim')));

      await tester.enterText(find.byKey(const Key('wallet-add-code')), token);
      await tester.tap(find.byKey(const Key('wallet-add-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wallet-detail-w1')), findsOneWidget);
      expect(find.byKey(const Key('ticket-qr')), findsOneWidget);
      // Le ticket dessiné avec le modèle de sa catégorie, et son numéro.
      expect(find.byKey(const Key('wallet-artwork')), findsOneWidget);
      expect(find.text('N° 000012'), findsOneWidget);
      expect(
        find.text(
          "Présentez ce QR à l'entrée. Montez la luminosité de l'écran.",
        ),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wallet-ticket-w1')), findsOneWidget);
      expect(find.text('À venir'), findsOneWidget);
    });

    testWidgets('ajout par la caméra', (tester) async {
      camera.code = token;
      await openApp(tester);
      await openWalletTab(tester);
      await tester.tap(find.byKey(const Key('wallet-empty-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wallet-add-scan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fake-camera-read')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wallet-detail-w1')), findsOneWidget);
    });

    testWidgets('ajout par une image ; image sans QR', (tester) async {
      await openApp(tester);
      await openWalletTab(tester);
      await tester.tap(find.byKey(const Key('wallet-empty-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wallet-add-image')));
      await tester.pumpAndSettle();
      expect(find.text('Aucun QR lisible dans cette image.'), findsOneWidget);
      imageCode = token;
      await tester.tap(find.byKey(const Key('wallet-add-image')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wallet-detail-w1')), findsOneWidget);
    });

    testWidgets('ticket déjà dans un autre compte : refus clair', (
      tester,
    ) async {
      wallet.claimedElsewhere.add(other);
      await openApp(tester);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push<void>(AppRoutes.walletAdd)
          .ignore();
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('wallet-add-code')), other);
      await tester.tap(find.byKey(const Key('wallet-add-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text("Ce ticket est déjà dans le compte d'une autre personne."),
        findsOneWidget,
      );
    });

    testWidgets('sans réseau : liste et QR lus sur l’appareil', (tester) async {
      final cached = jsonEncode({
        'saved_at': '2030-06-19T10:00:00Z',
        'tickets': [walletRow()],
      });
      wallet.failure = WalletFailure.network;
      await openApp(tester, preferences: {walletCacheKey('u1'): cached});
      await openWalletTab(tester);
      expect(find.byKey(const Key('wallet-offline')), findsOneWidget);
      await tester.tap(find.byKey(const Key('wallet-ticket-w1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-qr')), findsOneWidget);
      expect(find.byKey(const Key('wallet-release')), findsNothing);
    });

    testWidgets('ticket utilisé : pas de QR, date d’entrée', (tester) async {
      wallet = FakeWalletRepository(
        mine: [walletRow(status: TicketStatus.redeemed)],
      );
      await openApp(tester);
      await openWalletTab(tester);
      await tester.tap(find.byKey(const Key('wallet-ticket-w1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-qr')), findsNothing);
      expect(find.textContaining('Utilisé le'), findsOneWidget);
    });

    testWidgets('Mon ticket : fiche de l’événement, structure, agenda', (
      tester,
    ) async {
      wallet = FakeWalletRepository(mine: [walletRow()]);
      await openApp(tester);
      await openWalletTab(tester);
      await tester.tap(find.byKey(const Key('wallet-ticket-w1')));
      await tester.pumpAndSettle();
      final links = find.byKey(const Key('wallet-links'));
      await tester.ensureVisible(links);
      await tester.pumpAndSettle();
      expect(find.text('Organisé par Kwabo Événements'), findsOneWidget);

      await tester.tap(find.byKey(const Key('wallet-calendar')));
      await tester.pumpAndSettle();
      expect(calendared.single.title, 'Soirée Afro-Jazz');
      expect(calendared.single.location, 'Jardin de la musique, Ouagadougou');

      await tester.tap(find.byKey(const Key('wallet-open-event')));
      await tester.pumpAndSettle();
      expect(find.byType(PublicEventPage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.ensureVisible(links);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wallet-open-organizer')));
      await tester.pumpAndSettle();
      expect(find.byType(PublicOrganizationPage), findsOneWidget);
    });

    testWidgets('Mon ticket : compte à rebours et partage de l’événement', (
      tester,
    ) async {
      wallet = FakeWalletRepository(mine: [walletRow()]);
      final catalog = FakeCatalogRepository([], {
        'ev-w1': PublicEventDetail(
          summary: publicEvent(id: 'ev-w1'),
          categories: const [],
        ),
      });
      await openApp(tester, catalog: catalog);
      await openWalletTab(tester);
      await tester.tap(find.byKey(const Key('wallet-ticket-w1')));
      await tester.pumpAndSettle();
      // Événement de 2030 : quelques jours ou années d'ici.
      expect(
        find.descendant(
          of: find.byKey(const Key('wallet-countdown')),
          matching: find.textContaining('Dans '),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const Key('wallet-share-event')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wallet-share-event')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event-share-sheet')), findsOneWidget);
    });

    testWidgets('Mon ticket : événement privé, ancien cache : rien à ouvrir', (
      tester,
    ) async {
      wallet = FakeWalletRepository(
        mine: [walletRow(listed: false, organizationId: null)],
      );
      await openApp(tester);
      await openWalletTab(tester);
      await tester.tap(find.byKey(const Key('wallet-ticket-w1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('wallet-links')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wallet-open-event')), findsNothing);
      expect(find.byKey(const Key('wallet-share-event')), findsNothing);
      await tester.tap(find.byKey(const Key('wallet-open-organizer')));
      await tester.pumpAndSettle();
      expect(find.byType(PublicOrganizationPage), findsNothing);
    });

    testWidgets('retirer un ticket', (tester) async {
      wallet = FakeWalletRepository(mine: [walletRow()]);
      final container = await openApp(tester);
      await openWalletTab(tester);
      await tester.tap(find.byKey(const Key('wallet-ticket-w1')));
      await tester.pumpAndSettle();
      // Le bouton est sous le ticket et son QR : on le fait défiler.
      await tester.ensureVisible(find.byKey(const Key('wallet-release')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wallet-release')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wallet-release-confirm')));
      await tester.pumpAndSettle();
      expect(wallet.calls, contains('release w1'));
      expect(find.byKey(const Key('wallet-empty')), findsOneWidget);
      // Le cache suit le serveur.
      final saved = jsonDecode(
        container
            .read(sharedPreferencesProvider)
            .getString(walletCacheKey('u1'))!,
      ) as Map<String, Object?>;
      expect(saved['tickets'], isEmpty);
    });

    testWidgets('membre d’une structure : entrée depuis le Profil', (
      tester,
    ) async {
      wallet = FakeWalletRepository(mine: [walletRow()]);
      await openApp(tester, classic: false);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .go(AppRoutes.profile);
      await tester.pumpAndSettle();
      final entry = find.byKey(const Key('profile-wallet'));
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wallet-ticket-w1')), findsOneWidget);
    });
  });
}
