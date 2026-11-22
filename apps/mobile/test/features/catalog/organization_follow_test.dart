import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/organization_share.dart';
import 'package:ticketsur/features/catalog/presentation/public_organization_page.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_organization_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  final page = PublicOrganization(
    id: 'org-1',
    name: 'Faso Live',
    city: 'Ouagadougou',
    publicPhone: '+22670112233',
    createdAt: DateTime.utc(2026, 3, 2),
    pastEvents: 4,
    followers: 12,
    description: 'Concerts et festivals depuis 2015.',
    facebookUrl: 'https://www.facebook.com/fasolive',
    tiktokUrl: 'https://www.tiktok.com/@fasolive',
    events: [
      publicEvent(id: 'p1'),
      publicEvent(id: 'p2', title: 'Gala'),
    ],
  );

  group('réseaux saisis', () {
    test('nom du compte ou adresse → adresse complète', () {
      expect(
        socialUrl(SocialNetwork.instagram, '@faso.live'),
        'https://www.instagram.com/faso.live',
      );
      expect(
        socialUrl(SocialNetwork.tiktok, 'fasolive'),
        'https://www.tiktok.com/@fasolive',
      );
      expect(
        socialUrl(SocialNetwork.facebook, 'facebook.com/fasolive'),
        'https://facebook.com/fasolive',
      );
      expect(
        socialUrl(SocialNetwork.facebook, 'http://m.facebook.com/fasolive'),
        'https://m.facebook.com/fasolive',
      );
      expect(socialUrl(SocialNetwork.facebook, '  '), isNull);
      expect(
        () => socialUrl(SocialNetwork.instagram, 'https://exemple.com/x'),
        throwsFormatException,
      );
      expect(
        () => socialUrl(SocialNetwork.tiktok, 'nom avec espaces'),
        throwsFormatException,
      );
    });

    test('notifications : fiche d’un événement et page d’une structure', () {
      const id = '0f8fad5b-d9cb-469f-a165-70867728950e';
      expect(isSafePushRoute('/evenement/$id'), isTrue);
      expect(isSafePushRoute('/organisateur/$id'), isTrue);
      expect(isSafePushRoute('/organisateur/autre'), isFalse);
    });

    test('texte de partage : structure, prochains événements', () {
      final text = organizationShareText(AppLocalizationsFr(), page);
      expect(text, startsWith('Découvrez Faso Live · Ouagadougou sur Tikéo.'));
      expect(text, contains('2 événements à venir :'));
      expect(text, contains('• Gala — '));
    });
  });

  group('page d’une structure', () {
    late FakeCatalogRepository catalog;
    late List<Uri> opened;
    late List<String> shared;

    Future<void> pump(WidgetTester tester, {bool signedIn = true}) async {
      opened = [];
      shared = [];
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(
              user: signedIn
                  ? const AuthUser(id: 'u1', email: 'curieux@exemple.bf')
                  : null,
            ),
            organizations: FakeOrganizationRepository(),
            catalog: catalog,
            openLink: (uri) async {
              opened.add(uri);
              return true;
            },
            share: (text) async => shared.add(text),
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        GoRouter.of(tester.element(find.byType(Navigator).first))
            .push(AppRoutes.publicOrganization('org-1')),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      catalog = FakeCatalogRepository([page.events.first])
        ..organizations['org-1'] = page;
    });

    testWidgets('suivre puis ne plus suivre ; structures suivies', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(PublicOrganizationPage), findsOneWidget);
      expect(find.text('12 abonnés'), findsOneWidget);
      await tester.tap(find.byKey(const Key('public-org-follow')));
      await tester.pumpAndSettle();
      expect(catalog.followCalls, ['follow org-1']);
      expect(find.text('13 abonnés'), findsOneWidget);
      expect(find.text('Suivie'), findsOneWidget);
      expect(
        find.text('Vous serez prévenu de ses nouveaux événements.'),
        findsOneWidget,
      );

      // Les structures suivies, depuis leur page dédiée.
      unawaited(
        GoRouter.of(tester.element(find.byType(Navigator).first))
            .push(AppRoutes.followedOrganizations),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('followed-org-1')), findsOneWidget);
      expect(find.text('2 événements à venir'), findsOneWidget);
      await tester.tap(find.byKey(const Key('followed-org-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('public-org-follow')).last);
      await tester.pumpAndSettle();
      expect(catalog.followCalls.last, 'unfollow org-1');
      expect(find.text('12 abonnés'), findsWidgets);
    });

    testWidgets('sans compte : « Suivre » ouvre la connexion', (tester) async {
      await pump(tester, signedIn: false);
      await tester.tap(find.byKey(const Key('public-org-follow')));
      await tester.pumpAndSettle();
      expect(catalog.followCalls, isEmpty);
      expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    });

    testWidgets('présentation, réseaux et partage', (tester) async {
      await pump(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('public-org-about')),
          matching: find.text('Concerts et festivals depuis 2015.'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('public-org-instagram')), findsNothing);
      final tiktok = find.byKey(const Key('public-org-tiktok'));
      await tester.ensureVisible(tiktok);
      await tester.pumpAndSettle();
      await tester.tap(tiktok);
      await tester.pumpAndSettle();
      expect(opened.single.toString(), 'https://www.tiktok.com/@fasolive');

      await tester.tap(find.byKey(const Key('public-org-share')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('org-share-sheet')), findsOneWidget);
      expect(find.byKey(const Key('org-share-preview')), findsOneWidget);
      final textOnly = find.byKey(const Key('org-share-text'));
      await tester.ensureVisible(textOnly);
      await tester.pumpAndSettle();
      await tester.tap(textOnly);
      await tester.pumpAndSettle();
      expect(shared.single, contains('Faso Live'));
    });
  });
}
