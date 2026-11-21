import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/core/bulk.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/navigation.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'chef@exemple.bf');
  late FakeEventRepository events;

  setUp(() {
    events = FakeEventRepository([
      testEvent(id: 'e1', title: 'Concert A', status: EventStatus.published),
      testEvent(
        id: 'e2',
        title: 'Concert B',
        status: EventStatus.published,
        isPublic: true,
      ),
      testEvent(
        id: 'e3',
        title: 'Gala clôturé',
        status: EventStatus.closed,
        startsAt: DateTime.utc(2020, 1, 10, 20),
      ),
    ]);
  });

  Future<void> pumpEvents(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(user: user),
          organizations: FakeOrganizationRepository([
            testOrganization.withRole(MemberRole.owner),
          ]),
          events: events,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
    await openEventsList(tester);
  }

  Future<void> longPress(WidgetTester tester, String id) async {
    final card = find.byKey(Key('event-card-$id'));
    await tester.ensureVisible(card);
    await tester.longPress(card);
    await tester.pumpAndSettle();
  }

  Future<void> tapAction(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  test('runBulk : continue après un échec, s’arrête si demandé', () async {
    final seen = <int>[];
    final outcome = await runBulk([1, 2, 3], (n) async {
      seen.add(n);
      if (n == 2) throw StateError('non');
    }, skipped: 1);
    expect(seen, [1, 2, 3]);
    expect((outcome.done, outcome.failed, outcome.total), (2, 1, 4));
    final stopped = await runBulk(
      [1, 2, 3],
      (n) async => throw StateError('réseau'),
      stopOn: (_) => true,
    );
    expect((stopped.done, stopped.failed), (0, 3));
  });

  test('éligibilité : public, privé, archivage', () {
    final draft = testEvent();
    final cancelled = testEvent(status: EventStatus.cancelled);
    final closed = testEvent(status: EventStatus.closed);
    expect(canBulkSetPublic(draft, public: true), isTrue);
    expect(canBulkSetPublic(draft, public: false), isFalse);
    expect(canBulkSetPublic(cancelled, public: true), isFalse);
    expect(canBulkArchive(closed), isTrue);
    expect(canBulkArchive(draft), isFalse);
  });

  testWidgets('rendre publics : seuls les privés sont envoyés', (tester) async {
    await pumpEvents(tester);
    await longPress(tester, 'e1');
    expect(find.byKey(const Key('events-selection-bar')), findsOneWidget);
    expect(find.byKey(const Key('events-new')), findsNothing);
    // En sélection, un appui coche.
    await tester.tap(find.byKey(const Key('event-card-e2')));
    await tester.pumpAndSettle();
    expect(find.text('2 sélectionnés'), findsOneWidget);

    await tapAction(tester, 'events-bulk-public');
    expect(find.text('Rendre 1 événement public ?'), findsOneWidget);
    expect(
      find.textContaining('1 événement choisi sera laissé de côté.'),
      findsOneWidget,
    );
    await tapAction(tester, 'bulk-confirm');
    expect(events.publicCalls, [('e1', true)]);
    expect(find.text('1 événement rendu public'), findsOneWidget);
    expect(find.byKey(const Key('events-selection-bar')), findsNothing);
  });

  testWidgets('archiver : rien d’archivable, puis un événement clôturé', (
    tester,
  ) async {
    await pumpEvents(tester);
    await longPress(tester, 'e1');
    await tapAction(tester, 'events-bulk-archive');
    expect(
      find.text(
        'Seuls les événements clôturés ou annulés peuvent être archivés.',
      ),
      findsOneWidget,
    );
    expect(events.statusCalls, isEmpty);
    // Le message disparaît (il couvre la barre d'actions).
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('selection-all')));
    await tester.pumpAndSettle();
    expect(find.text('3 sélectionnés'), findsOneWidget);
    await tapAction(tester, 'events-bulk-archive');
    expect(find.text('Archiver 1 événement ?'), findsOneWidget);
    // Annuler ne fait rien.
    await tapAction(tester, 'bulk-cancel');
    expect(events.statusCalls, isEmpty);
    await tapAction(tester, 'events-bulk-archive');
    await tapAction(tester, 'bulk-confirm');
    expect(events.statusCalls, [('e3', EventStatus.archived)]);
    expect(find.text('1 événement archivé'), findsOneWidget);
  });

  testWidgets('dupliquer : une copie par événement, une semaine après', (
    tester,
  ) async {
    await pumpEvents(tester);
    await longPress(tester, 'e1');
    await tester.tap(find.byKey(const Key('event-card-e2')));
    await tester.pumpAndSettle();
    await tapAction(tester, 'events-bulk-duplicate');
    expect(find.text('Dupliquer 2 événements ?'), findsOneWidget);
    await tapAction(tester, 'bulk-confirm');
    expect(events.duplicateCalls, hasLength(2));
    final (source, title, start, end) = events.duplicateCalls.first;
    expect(source, 'e1');
    expect(title, 'Concert A (copie)');
    expect(start, DateTime.utc(2030, 6, 27, 20));
    expect(end.difference(start), const Duration(hours: 4));
    expect(find.text('2 copies créées en brouillon'), findsOneWidget);
  });

  testWidgets('échec partiel : le message le dit', (tester) async {
    await pumpEvents(tester);
    await longPress(tester, 'e1');
    await tester.tap(find.byKey(const Key('event-card-e2')));
    await tester.pumpAndSettle();
    events.nextWriteFailure = EventFailure.locked;
    await tapAction(tester, 'events-bulk-private');
    await tapAction(tester, 'bulk-confirm');
    expect(events.publicCalls, [('e2', false)]);
    // Le seul envoi a échoué.
    expect(find.textContaining('Fait pour 0 sur 1'), findsOneWidget);
  });

  testWidgets('Retour quitte la sélection', (tester) async {
    await pumpEvents(tester);
    await longPress(tester, 'e1');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('events-selection-bar')), findsNothing);
    expect(find.byKey(const Key('event-card-e1')), findsOneWidget);
  });
}
