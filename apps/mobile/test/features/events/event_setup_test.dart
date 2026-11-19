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
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Événements'),
        ),
      );
      await tester.pumpAndSettle();
      if (!status.isActive) {
        await tester.tap(find.byKey(const Key('events-filter-done')));
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
