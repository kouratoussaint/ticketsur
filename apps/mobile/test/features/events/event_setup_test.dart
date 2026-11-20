import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/data/supabase_event_setup_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_event_setup_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/navigation.dart';

void main() {
  group('domaine', () {
    test('codes serveur des catégories et portes', () {
      for (final (code, failure) in [
        ('category_not_found', SetupFailure.notFound),
        ('checkpoint_not_found', SetupFailure.notFound),
        ('category_name_invalid', SetupFailure.nameInvalid),
        ('checkpoint_name_taken', SetupFailure.nameTaken),
        ('category_name_taken', SetupFailure.nameTaken),
        ('category_capacity_invalid', SetupFailure.capacityInvalid),
        ('category_capacity_below_issued', SetupFailure.capacityBelowIssued),
        ('category_has_tickets', SetupFailure.hasTickets),
        ('event_locked', SetupFailure.locked),
        ('category_entries_invalid', SetupFailure.entriesInvalid),
        ('category_has_entries', SetupFailure.entriesLocked),
      ]) {
        expect(
          mapSetupError(PostgrestException(message: code, code: '22023')),
          failure,
          reason: code,
        );
      }
      expect(
        mapSetupError(const PostgrestException(message: 'x', code: '42501')),
        SetupFailure.notFound,
      );
    });

    test('règle d’entrée lue depuis le serveur', () {
      final pass = TicketCategory.fromJson(const {
        'id': 'p',
        'event_id': 'e',
        'name': 'Pass',
        'entry_policy': 'limited',
        'max_entries': 3,
      });
      expect(pass.entryPolicy, EntryPolicy.limited);
      expect(pass.maxEntries, 3);
      expect(pass.isPass, isTrue);
      for (final wire in [null, 'single', 'weekly']) {
        final plain = TicketCategory.fromJson({
          'id': 's',
          'event_id': 'e',
          'name': 'S',
          'entry_policy': wire,
        });
        expect(plain.entryPolicy, EntryPolicy.single, reason: '$wire');
        expect(plain.isPass, isFalse);
      }
      expect(
        TicketCategory.fromJson(const {
          'id': 'd',
          'event_id': 'e',
          'name': 'D',
          'entry_policy': 'per_day',
        }).entryPolicy,
        EntryPolicy.perDay,
      );
    });

    test('remplissage du quota', () {
      const unlimited = TicketCategory(id: 'a', eventId: 'e', name: 'A');
      const half = TicketCategory(
        id: 'b',
        eventId: 'e',
        name: 'B',
        capacity: 10,
        issued: 5,
      );
      expect(unlimited.fill, isNull);
      expect(half.fill, 0.5);
      expect(
        TicketCategory.fromJson(const {
          'id': 'c',
          'event_id': 'e',
          'name': 'C',
          'capacity': null,
        }).issued,
        0,
      );
    });
  });

  group('fiche événement : catégories et portes', () {
    const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
    late FakeEventRepository events;
    late FakeEventSetupRepository setup;

    Future<void> openEvent(
      WidgetTester tester, {
      MemberRole role = MemberRole.owner,
      EventStatus status = EventStatus.published,
    }) async {
      events.events.add(testEvent(id: 'e1', status: status));
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: user),
            organizations: FakeOrganizationRepository([
              Organization(
                id: testOrganization.id,
                name: testOrganization.name,
                slug: testOrganization.slug,
                role: role,
              ),
            ]),
            events: events,
            setup: setup,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await openEventsList(tester);
      await tester.pumpAndSettle();
      if (!status.isActive) {
        await tester.ensureVisible(find.byKey(const Key('events-filter-past')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('events-filter-past')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('event-card-e1')));
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
      events = FakeEventRepository();
      setup = FakeEventSetupRepository();
    });

    testWidgets('vide : invitations à ajouter catégories et portes', (
      tester,
    ) async {
      await openEvent(tester);
      expect(find.byKey(const Key('categories-empty')), findsOneWidget);
      expect(find.byKey(const Key('checkpoints-empty')), findsOneWidget);
    });

    testWidgets('ajouter une catégorie avec quota', (tester) async {
      await openEvent(tester);
      await tapVisible(tester, find.byKey(const Key('category-add')));
      await tester.enterText(find.byKey(const Key('setup-name')), ' VIP ');
      await tester.enterText(find.byKey(const Key('setup-capacity')), '50');
      await tapVisible(tester, find.byKey(const Key('setup-submit')));

      expect(setup.calls, ['createCategory  VIP  50']);
      expect(find.text('VIP'), findsOneWidget);
      expect(find.text('Quota : 50'), findsOneWidget);
      expect(find.text('Catégorie enregistrée'), findsOneWidget);
      expect(find.text('0 tickets émis, capacité non limitée'), findsOneWidget);
    });

    testWidgets("catégorie d'invitations : marque envoyée et affichée", (
      tester,
    ) async {
      await openEvent(tester);
      await tapVisible(tester, find.byKey(const Key('category-add')));
      await tester.enterText(find.byKey(const Key('setup-name')), 'Invités');
      await tapVisible(tester, find.byKey(const Key('setup-invitation')));
      await tapVisible(tester, find.byKey(const Key('setup-submit')));

      expect(setup.calls, ['createCategory Invités null invitation']);
      expect(
        find.byKey(const Key('category-invitation-cat-1')),
        findsOneWidget,
      );

      // Modification : la marque est préremplie et renvoyée telle quelle.
      await tapVisible(tester, find.byKey(const Key('category-cat-1')));
      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('setup-invitation')),
      );
      expect(toggle.value, isTrue);
      await tapVisible(tester, find.byKey(const Key('setup-submit')));
      expect(setup.calls.last, 'updateCategory cat-1 Invités null invitation');
    });

    testWidgets('pass de 3 entrées, puis pass journalier', (tester) async {
      await openEvent(tester);
      await tapVisible(tester, find.byKey(const Key('category-add')));
      await tester.enterText(find.byKey(const Key('setup-name')), 'Festival');
      expect(
        find.text('Le ticket est utilisé dès la première entrée.'),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('setup-entries-limited')));
      // Bornes vérifiées avant l'envoi.
      await tester.enterText(find.byKey(const Key('setup-max-entries')), '1');
      await tapVisible(tester, find.byKey(const Key('setup-submit')));
      expect(find.text('De 2 à 100 entrées.'), findsOneWidget);
      expect(setup.calls, isEmpty);

      await tester.enterText(find.byKey(const Key('setup-max-entries')), '3');
      await tapVisible(tester, find.byKey(const Key('setup-submit')));
      expect(setup.calls, [
        'createCategory Festival null',
        'entries cat-1 limited 3',
      ]);
      expect(find.text('Pass 3 entrées'), findsOneWidget);

      // Modification : règle préremplie, envoyée seulement si elle change.
      await tapVisible(tester, find.byKey(const Key('category-cat-1')));
      expect(
        tester
            .widget<SegmentedButton<EntryPolicy>>(
              find.byKey(const Key('setup-entries')),
            )
            .selected,
        {EntryPolicy.limited},
      );
      await tapVisible(tester, find.byKey(const Key('setup-entries-per-day')));
      expect(find.byKey(const Key('setup-max-entries')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('setup-submit')));
      expect(setup.calls.skip(2), [
        'updateCategory cat-1 Festival null',
        'entries cat-1 per_day null',
      ]);
      expect(find.byKey(const Key('category-pass-cat-1')), findsOneWidget);
      expect(find.text('Pass journalier'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('category-cat-1')));
      await tapVisible(tester, find.byKey(const Key('setup-submit')));
      expect(setup.calls.last, 'updateCategory cat-1 Festival null');
    });

    testWidgets('pass déjà utilisé : règle figée, refus serveur expliqué', (
      tester,
    ) async {
      setup.categoryRows.add(
        const TicketCategory(
          id: 'c1',
          eventId: 'e1',
          name: 'Pass',
          issued: 10,
          redeemed: 4,
          entryPolicy: EntryPolicy.perDay,
        ),
      );
      await openEvent(tester);
      await tapVisible(tester, find.byKey(const Key('category-c1')));
      expect(
        find.text(
          'Règle figée : des tickets de cette catégorie sont déjà entrés.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SegmentedButton<EntryPolicy>>(
              find.byKey(const Key('setup-entries')),
            )
            .onSelectionChanged,
        isNull,
      );
      await tapVisible(tester, find.byKey(const Key('setup-submit')));
      expect(setup.calls, ['updateCategory c1 Pass null']);
    });

    testWidgets('règle refusée par le serveur : message dans la feuille', (
      tester,
    ) async {
      setup.categoryRows.add(
        const TicketCategory(id: 'c1', eventId: 'e1', name: 'Pass'),
      );
      await openEvent(tester);
      await tapVisible(tester, find.byKey(const Key('category-c1')));
      await tapVisible(tester, find.byKey(const Key('setup-entries-per-day')));
      setup.nextEntriesFailure = SetupFailure.entriesLocked;
      await tapVisible(tester, find.byKey(const Key('setup-submit')));
      expect(
        find.text(
          'Des tickets de cette catégorie sont déjà entrés : '
          "la règle d'entrée ne peut plus changer.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('setup-name')), findsOneWidget);
    });

    testWidgets('refus serveur : la feuille reste ouverte avec le message', (
      tester,
    ) async {
      setup.categoryRows.add(
        const TicketCategory(
          id: 'c1',
          eventId: 'e1',
          name: 'Standard',
          capacity: 100,
          issued: 40,
          redeemed: 12,
        ),
      );
      await openEvent(tester);
      expect(find.text('40 émis · 12 entrés'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('category-c1')));
      setup.nextWriteFailure = SetupFailure.capacityBelowIssued;
      await tester.enterText(find.byKey(const Key('setup-capacity')), '10');
      await tapVisible(tester, find.byKey(const Key('setup-submit')));
      expect(
        find.text('Le quota ne peut pas être inférieur aux tickets déjà émis.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('setup-name')), findsOneWidget);
    });

    testWidgets('supprimer une catégorie après confirmation', (tester) async {
      setup.categoryRows.add(
        const TicketCategory(id: 'c1', eventId: 'e1', name: 'Invitation'),
      );
      await openEvent(tester);
      await tapVisible(tester, find.byKey(const Key('category-c1')));
      await tapVisible(tester, find.byKey(const Key('setup-delete')));
      await tester.tap(find.byKey(const Key('setup-delete-confirm')));
      await tester.pumpAndSettle();
      expect(setup.calls, ['deleteCategory c1']);
      expect(find.byKey(const Key('categories-empty')), findsOneWidget);
      expect(find.text('Catégorie supprimée'), findsOneWidget);
    });

    testWidgets('portes : ajout puis désactivation confirmée', (tester) async {
      await openEvent(tester);
      await tapVisible(tester, find.byKey(const Key('checkpoint-add')));
      await tester.enterText(
        find.byKey(const Key('setup-name')),
        'Entrée principale',
      );
      await tapVisible(tester, find.byKey(const Key('setup-submit')));
      expect(find.text('Entrée principale'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      final toggle = find.byKey(const Key('checkpoint-active-cp-1'));
      await tapVisible(tester, toggle);
      expect(
        find.textContaining('seront refusés immédiatement'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('checkpoint-deactivate-confirm')));
      await tester.pumpAndSettle();
      expect(setup.calls.last, 'updateCheckpoint cp-1 Entrée principale false');
      expect(find.text('Désactivée : scans refusés'), findsOneWidget);

      // Réactivation : sans confirmation.
      await tapVisible(tester, toggle);
      expect(setup.calls.last, 'updateCheckpoint cp-1 Entrée principale true');
    });

    testWidgets('événement clôturé : configuration figée', (tester) async {
      setup.categoryRows.add(
        const TicketCategory(id: 'c1', eventId: 'e1', name: 'Standard'),
      );
      await openEvent(tester, status: EventStatus.closed);
      expect(find.byKey(const Key('category-add')), findsNothing);
      expect(find.byKey(const Key('checkpoint-add')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('category-c1')));
      expect(find.byKey(const Key('setup-name')), findsNothing);
    });

    testWidgets('erreur de chargement des catégories : « Réessayer »', (
      tester,
    ) async {
      setup
        ..nextLoadFailure = SetupFailure.network
        ..categoryRows.add(
          const TicketCategory(id: 'c1', eventId: 'e1', name: 'Revenue'),
        );
      await openEvent(tester);
      expect(find.text('Chargement impossible.'), findsOneWidget);
      await tapVisible(tester, find.text('Réessayer'));
      expect(find.text('Revenue'), findsOneWidget);
    });
  });
}
