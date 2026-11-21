import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/org_settings/domain/org_settings.dart';
import 'package:ticketsur/features/org_settings/presentation/org_settings_page.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/ticket_send/application/send_providers.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_org_settings_repository.dart';
import '../../helpers/fake_organization_repository.dart';

void main() {
  group('domaine', () {
    test('champs remplis ; champ vide retiré proprement', () {
      expect(
        fillSendMessage(
          'Bonjour {prenom}, ticket {categorie} pour {evenement}, {date} '
          '— {lieu}.',
          firstName: 'Awa',
          event: 'Gala',
          date: 'samedi',
          place: 'Ouaga',
          category: 'VIP',
        ),
        'Bonjour Awa, ticket VIP pour Gala, samedi — Ouaga.',
      );
      expect(
        fillSendMessage(
          'Bonjour {prenom}, à {evenement} ({categorie}) !',
          event: 'Gala',
          date: 'samedi',
        ),
        'Bonjour, à Gala !',
      );
      expect(firstNameOf('  Awa  Ouédraogo '), 'Awa');
      expect(firstNameOf('  '), isNull);
      expect(firstNameOf(null), isNull);
    });

    test('lecture du serveur', () {
      final settings = OrgSettings.fromJson(const {
        'ticket_message': 'Salut {prenom}',
        'invitation_message': null,
        'default_timezone': 'Africa/Abidjan',
        'default_city': 'Bobo-Dioulasso',
        'default_kind': 'concert',
        'default_categories': [
          {'name': 'VIP', 'capacity': 50, 'price': 10000, 'invitation': false},
          {
            'name': 'Invités',
            'capacity': null,
            'price': null,
            'invitation': true,
          },
        ],
        'default_checkpoints': ['Entrée'],
      });
      expect(settings.defaultKind, EventKind.concert);
      expect(settings.defaultCategories.last.invitation, isTrue);
      expect(settings.defaultCategories.first.price, 10000);
      expect(settings.hasProposals, isTrue);
      expect(const OrgSettings().hasProposals, isFalse);
    });

    test('message de la structure, sinon celui de Tikéo', () async {
      await initializeDateFormatting('fr');
      final l10n = AppLocalizationsFr();
      final event = testEvent(title: 'Gala', city: 'Bobo-Dioulasso');
      expect(
        ticketMessage(
          l10n,
          event,
          holderName: 'Awa Ouédraogo',
          template: 'Hey {prenom} : {evenement} à {lieu}',
        ),
        'Hey Awa : Gala à Palais des sports, Bobo-Dioulasso',
      );
      expect(
        ticketMessage(l10n, event, holderName: 'Awa', template: '   '),
        startsWith('Bonjour Awa, voici votre ticket'),
      );
    });
  });

  group('écrans', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late FakeOrgSettingsRepository repo;
    late FakeEventRepository events;

    Future<void> openApp(
      WidgetTester tester, {
      MemberRole role = MemberRole.owner,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([
              testOrganization.withRole(role),
            ]),
            events: events,
            orgSettings: repo,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> go(WidgetTester tester, String path) async {
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
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

    setUp(() {
      repo = FakeOrgSettingsRepository();
      events = FakeEventRepository();
    });

    testWidgets('Profil → réglages : message, catégorie, porte, enregistrer', (
      tester,
    ) async {
      await openApp(tester);
      await go(tester, AppRoutes.profile);
      await tapVisible(tester, find.byKey(const Key('profile-org-settings')));
      expect(find.byType(OrgSettingsPage), findsOneWidget);

      // Message vide : aperçu du message par défaut.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('org-settings-ticket-preview')))
            .data,
        startsWith('Bonjour Aïcha Ouédraogo, voici votre ticket'),
      );
      await tester.enterText(
        find.byKey(const Key('org-settings-ticket-message')),
        'Salut ',
      );
      await tapVisible(
        tester,
        find.byKey(const Key('org-settings-ticket-insert-firstName')),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('org-settings-ticket-preview')))
            .data,
        'Salut Aïcha',
      );

      // Catégorie proposée.
      await tapVisible(
        tester,
        find.byKey(const Key('org-settings-category-add')),
      );
      await tester.enterText(
        find.byKey(const Key('org-settings-category-name')),
        'VIP',
      );
      await tester.enterText(
        find.byKey(const Key('org-settings-category-price')),
        '10000',
      );
      await tester.tap(find.byKey(const Key('org-settings-category-submit')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(RegExp(r'^Quota illimité · 10\s000 FCFA$')),
        findsOneWidget,
      );

      // Porte proposée ; doublon refusé.
      for (final name in ['Entrée', 'entrée']) {
        await tester.enterText(
          find.byKey(const Key('org-settings-door-field')),
          name,
        );
        await tapVisible(
          tester,
          find.byKey(const Key('org-settings-door-add')),
        );
      }
      expect(find.text('Ce nom est déjà dans la liste.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('org-settings-city')),
        'Bobo-Dioulasso',
      );

      await tapVisible(tester, find.byKey(const Key('org-settings-save')));
      final saved = repo.settings[testOrganization.id]!;
      expect(saved.ticketMessage, 'Salut {prenom}');
      expect(saved.invitationMessage, isNull);
      expect(saved.defaultCity, 'Bobo-Dioulasso');
      expect(saved.defaultCategories, const [
        DefaultCategory(name: 'VIP', price: 10000),
      ]);
      expect(saved.defaultCheckpoints, ['Entrée']);
      expect(find.text('Réglages enregistrés'), findsOneWidget);
    });

    testWidgets('« Revenir au message par défaut » vide le message', (
      tester,
    ) async {
      repo.settings[testOrganization.id] = const OrgSettings(
        invitationMessage: 'Venez à {evenement}',
      );
      await openApp(tester);
      await go(tester, AppRoutes.organizationSettings);
      await tapVisible(
        tester,
        find.byKey(const Key('org-settings-invitation-reset')),
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('org-settings-invitation-preview')),
            )
            .data,
        startsWith('Bonjour Aïcha Ouédraogo, vous êtes invité(e)'),
      );
      await tapVisible(tester, find.byKey(const Key('org-settings-save')));
      expect(repo.settings[testOrganization.id]!.invitationMessage, isNull);
    });

    testWidgets('contrôleur : ni ligne ni page', (tester) async {
      await openApp(tester, role: MemberRole.controller);
      await go(tester, AppRoutes.profile);
      expect(find.byKey(const Key('profile-org-settings')), findsNothing);
      await go(tester, AppRoutes.organizationSettings);
      expect(find.byType(OrgSettingsPage), findsNothing);
      expect(repo.calls, isEmpty);
    });

    group('nouvel événement', () {
      setUp(() {
        repo.settings[testOrganization.id] = const OrgSettings(
          defaultCity: 'Bobo-Dioulasso',
          defaultKind: EventKind.concert,
          defaultCategories: [DefaultCategory(name: 'Standard')],
          defaultCheckpoints: ['Entrée'],
        );
      });

      Future<void> fillAndReview(WidgetTester tester) async {
        await tapVisible(tester, find.byKey(const Key('quick-new-event')));
        await tester.enterText(find.byKey(const Key('event-title')), 'Gala');
        final concert = tester.widget<ChoiceChip>(
          find.byKey(const Key('event-kind-concert')),
        );
        expect(concert.selected, isTrue);
        for (var i = 0; i < 3; i++) {
          await tapVisible(tester, find.byKey(const Key('event-next')));
        }
        expect(find.byKey(const Key('event-apply-defaults')), findsOneWidget);
        expect(
          find.text('Catégories : Standard\nPortes : Entrée'),
          findsOneWidget,
        );
      }

      testWidgets('valeurs reprises, propositions ajoutées', (tester) async {
        await openApp(tester);
        await fillAndReview(tester);
        await tapVisible(tester, find.byKey(const Key('event-submit')));
        final draft = events.createCalls.single;
        expect(draft.city, 'Bobo-Dioulasso');
        expect(draft.kind, EventKind.concert);
        expect(repo.calls.where((c) => c.startsWith('apply ')), hasLength(1));
      });

      testWidgets('case décochée : rien n’est ajouté', (tester) async {
        await openApp(tester);
        await fillAndReview(tester);
        await tapVisible(tester, find.byKey(const Key('event-apply-defaults')));
        await tapVisible(tester, find.byKey(const Key('event-submit')));
        expect(events.createCalls, hasLength(1));
        expect(repo.calls.where((c) => c.startsWith('apply ')), isEmpty);
      });
    });
  });
}
