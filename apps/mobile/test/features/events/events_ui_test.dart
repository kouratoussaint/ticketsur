import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_detail_page.dart';
import 'package:ticketsur/features/events/presentation/event_form_page.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/home/home_page.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
  late FakeEventRepository events;

  Future<void> pumpApp(
    WidgetTester tester, {
    MemberRole role = MemberRole.owner,
  }) async {
    final organization = Organization(
      id: testOrganization.id,
      name: testOrganization.name,
      slug: testOrganization.slug,
      role: role,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(user: user),
          organizations: FakeOrganizationRepository([organization]),
          events: events,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openEventsTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Événements'),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Touche [finder] après l'avoir fait défiler à l'écran.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    // Clavier fermé : sinon le champ actif ramène l'écran vers lui.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Limite [finder] à l'onglet Événements (l'Accueil, monté en dessous,
  /// affiche aussi le prochain événement).
  Finder inEventsTab(Finder finder) =>
      find.descendant(of: find.byType(EventsTabPage), matching: finder);

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  setUp(() => events = FakeEventRepository());

  group('liste (S07)', () {
    testWidgets('vide : invitation à créer et bouton « Nouvel événement »', (
      tester,
    ) async {
      await pumpApp(tester);
      await openEventsTab(tester);
      expect(find.byKey(const Key('events-empty')), findsOneWidget);
      expect(find.byKey(const Key('events-new')), findsOneWidget);
    });

    testWidgets('filtres : à venir par défaut, terminés sur demande', (
      tester,
    ) async {
      events.events.addAll([
        testEvent(id: 'a', title: 'Brouillon à venir'),
        testEvent(id: 'b', title: 'Concert passé', status: EventStatus.closed),
      ]);
      await pumpApp(tester);
      await openEventsTab(tester);
      expect(inEventsTab(find.text('Brouillon à venir')), findsOneWidget);
      expect(inEventsTab(find.text('Concert passé')), findsNothing);

      await tester.tap(find.byKey(const Key('events-filter-done')));
      await tester.pumpAndSettle();
      expect(inEventsTab(find.text('Concert passé')), findsOneWidget);
      expect(inEventsTab(find.text('Brouillon à venir')), findsNothing);

      await tester.tap(find.byKey(const Key('events-filter-published')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('events-filter-empty')), findsOneWidget);
    });

    testWidgets('erreur de chargement : message et « Réessayer »', (
      tester,
    ) async {
      events.nextLoadFailure = EventFailure.network;
      events.events.add(testEvent(title: 'Revenu'));
      await pumpApp(tester);
      await openEventsTab(tester);
      expect(find.byKey(const Key('events-load-error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('events-retry')));
      await tester.pumpAndSettle();
      expect(inEventsTab(find.text('Revenu')), findsOneWidget);
    });
  });

  group('création (S08)', () {
    testWidgets('titre + valeurs par défaut → brouillon, fiche, puis liste', (
      tester,
    ) async {
      await pumpApp(tester);
      await openEventsTab(tester);
      await tester.tap(find.byKey(const Key('events-new')));
      await tester.pumpAndSettle();
      expect(find.byType(EventFormPage), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('event-title')),
        '  Nuit du   Jazz ',
      );
      await tester.ensureVisible(find.byKey(const Key('event-capacity')));
      await tester.enterText(find.byKey(const Key('event-capacity')), '450');
      await tapVisible(tester, find.byKey(const Key('event-submit')));

      expect(events.createCalls, hasLength(1));
      final draft = events.createCalls.single;
      expect(draft.timezone, 'Africa/Ouagadougou');
      expect(draft.capacity, 450);
      // Par défaut : 18:00 → 23:00 (UTC+0 à Ouagadougou).
      expect(draft.startsAt.hour, 18);
      expect(draft.endsAt.difference(draft.startsAt), const Duration(hours: 5));

      expect(find.byType(EventDetailPage), findsOneWidget);
      expect(find.byKey(const Key('event-detail-title')), findsOneWidget);
      expect(find.text('Nuit du Jazz'), findsWidgets);
      expect(find.text('Brouillon'), findsWidgets);

      // Retour : la liste (le formulaire a été remplacé par la fiche).
      await pressBack(tester);
      expect(find.byType(EventFormPage), findsNothing);
      expect(find.byKey(const Key('event-card-evt-1')), findsOneWidget);
    });

    testWidgets('titre trop court : refus local, aucun appel serveur', (
      tester,
    ) async {
      await pumpApp(tester);
      await openEventsTab(tester);
      await tester.tap(find.byKey(const Key('events-new')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('event-title')), 'A');
      await tapVisible(tester, find.byKey(const Key('event-submit')));
      expect(
        find.text('Saisissez un titre de 2 à 160 caractères.'),
        findsOneWidget,
      );
      expect(events.createCalls, isEmpty);
    });

    testWidgets('refus serveur affiché dans le formulaire', (tester) async {
      events.nextWriteFailure = EventFailure.timezoneInvalid;
      await pumpApp(tester);
      await openEventsTab(tester);
      await tester.tap(find.byKey(const Key('events-new')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('event-title')), 'Gala');
      await tapVisible(tester, find.byKey(const Key('event-submit')));
      expect(find.byKey(const Key('event-error')), findsOneWidget);
      expect(find.text('Fuseau horaire inconnu.'), findsOneWidget);
      expect(find.byType(EventFormPage), findsOneWidget);
    });
  });

  group('fiche et cycle de vie (S09, EVT-01)', () {
    Future<void> openEvent(WidgetTester tester, String id) async {
      await openEventsTab(tester);
      await tester.tap(find.byKey(Key('event-card-$id')));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailPage), findsOneWidget);
    }

    testWidgets('publier après confirmation', (tester) async {
      events.events.add(testEvent(id: 'e1'));
      await pumpApp(tester);
      await openEvent(tester, 'e1');

      await tapVisible(tester, find.byKey(const Key('event-action-published')));
      expect(
        find.text('Les billets pourront être émis et contrôlés aux portes.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('event-confirm')));
      await tester.pumpAndSettle();

      expect(events.statusCalls, [('e1', EventStatus.published)]);
      expect(find.text('Statut : Publié'), findsOneWidget);
      expect(find.byKey(const Key('event-action-in_progress')), findsOneWidget);
      expect(find.byKey(const Key('event-action-published')), findsNothing);
    });

    testWidgets('« Retour » dans la confirmation : rien n’est envoyé', (
      tester,
    ) async {
      events.events.add(testEvent(id: 'e1'));
      await pumpApp(tester);
      await openEvent(tester, 'e1');
      await tapVisible(tester, find.byKey(const Key('event-action-cancelled')));
      await tester.tap(find.text('Retour'));
      await tester.pumpAndSettle();
      expect(events.statusCalls, isEmpty);
    });

    testWidgets('refus serveur : message explicite, statut inchangé', (
      tester,
    ) async {
      events.events.add(testEvent(id: 'e1', status: EventStatus.published));
      events.nextWriteFailure = EventFailure.hasTickets;
      await pumpApp(tester);
      await openEvent(tester, 'e1');
      await tapVisible(tester, find.byKey(const Key('event-action-draft')));
      await tester.tap(find.byKey(const Key('event-confirm')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Des billets ont été émis : impossible de repasser en brouillon.',
        ),
        findsOneWidget,
      );
      expect(find.text('Publié'), findsWidgets);
    });

    testWidgets('modifier un brouillon', (tester) async {
      events.events.add(testEvent(id: 'e1', title: 'Ancien titre'));
      await pumpApp(tester);
      await openEvent(tester, 'e1');
      await tester.tap(find.byKey(const Key('event-edit')));
      await tester.pumpAndSettle();
      expect(find.text("Modifier l'événement"), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('event-title')),
        'Nouveau titre',
      );
      await tapVisible(tester, find.byKey(const Key('event-submit')));
      expect(events.updateCalls.single.$1, 'e1');
      expect(find.byType(EventDetailPage), findsOneWidget);
      expect(find.text('Nouveau titre'), findsWidgets);
    });

    testWidgets('événement clôturé : ni modification, seulement « Archiver »', (
      tester,
    ) async {
      events.events.add(testEvent(id: 'e1', status: EventStatus.closed));
      await pumpApp(tester);
      await openEventsTab(tester);
      await tester.tap(find.byKey(const Key('events-filter-done')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-card-e1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event-edit')), findsNothing);
      expect(find.byKey(const Key('event-action-archived')), findsOneWidget);
    });

    testWidgets('Retour : fiche → liste → Accueil', (tester) async {
      events.events.add(testEvent(id: 'e1'));
      await pumpApp(tester);
      await openEvent(tester, 'e1');
      await pressBack(tester);
      expect(find.byType(EventsTabPage).hitTestable(), findsOneWidget);
      await pressBack(tester);
      expect(find.byType(HomePage).hitTestable(), findsOneWidget);
    });
  });

  group('Accueil', () {
    testWidgets('prochain événement affiché ; un toucher ouvre sa fiche', (
      tester,
    ) async {
      events.events.add(testEvent(id: 'e1', title: 'Le prochain'));
      await pumpApp(tester);
      expect(find.byKey(const Key('home-next-event')), findsOneWidget);
      await tester.tap(find.text('Le prochain'));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailPage), findsOneWidget);
    });

    testWidgets('aucun événement : raccourci de création', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(const Key('home-no-event')), findsOneWidget);
      await tester.tap(find.byKey(const Key('home-event-action')));
      await tester.pumpAndSettle();
      expect(find.byType(EventFormPage), findsOneWidget);
    });
  });
}
