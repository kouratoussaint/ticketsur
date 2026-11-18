import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/data/supabase_event_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';

import '../../helpers/fake_event_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('TicketEvent.fromJson', () {
    test('lit une ligne de la table events', () {
      final event = TicketEvent.fromJson(const {
        'id': 'e1',
        'organization_id': 'o1',
        'title': 'Gala',
        'venue': null,
        'timezone': 'Africa/Lagos',
        'starts_at': '2030-06-20T19:00:00+00:00',
        'ends_at': '2030-06-20T23:00:00+00:00',
        'capacity': 300,
        'status': 'in_progress',
      });
      expect(event.status, EventStatus.inProgress);
      expect(event.startsAt, DateTime.utc(2030, 6, 20, 19));
      expect(event.startsAt.isUtc, isTrue);
      expect(event.capacity, 300);
      expect(event.venue, isNull);
    });

    test('statut inconnu : lecture seule (archivé)', () {
      expect(EventStatus.fromWire('futur'), EventStatus.archived);
      expect(EventStatus.archived.nextStatuses, isEmpty);
    });
  });

  test('transitions proposées = celles autorisées par le serveur', () {
    // Miroir de private.event_transition_allowed (migration 0600).
    const server = {
      EventStatus.draft: {EventStatus.published, EventStatus.cancelled},
      EventStatus.published: {
        EventStatus.draft,
        EventStatus.inProgress,
        EventStatus.closed,
        EventStatus.cancelled,
      },
      EventStatus.inProgress: {EventStatus.closed},
      EventStatus.closed: {EventStatus.archived},
      EventStatus.cancelled: {EventStatus.archived},
      EventStatus.archived: <EventStatus>{},
    };
    for (final status in EventStatus.values) {
      expect(status.nextStatuses.toSet(), server[status], reason: '$status');
    }
    expect(EventStatus.values.where((s) => s.isEditable), [
      EventStatus.draft,
      EventStatus.published,
    ]);
  });

  test('EventDraft.toParams : texte nettoyé, lieu vide → null, UTC', () {
    final params = EventDraft(
      title: '  Gala  ',
      venue: '   ',
      timezone: 'Africa/Ouagadougou',
      startsAt: DateTime.utc(2030, 1, 1, 20),
      endsAt: DateTime.utc(2030, 1, 1, 23),
    ).toParams();
    expect(params['p_title'], 'Gala');
    expect(params['p_venue'], isNull);
    expect(params['p_starts_at'], '2030-01-01T20:00:00.000Z');
    expect(params['p_capacity'], isNull);
  });

  group('erreurs serveur', () {
    test('chaque code stable a son échec', () {
      for (final (code, failure) in [
        ('event_not_found', EventFailure.notFound),
        ('event_title_invalid', EventFailure.titleInvalid),
        ('event_venue_invalid', EventFailure.venueInvalid),
        ('event_dates_invalid', EventFailure.datesInvalid),
        ('event_timezone_invalid', EventFailure.timezoneInvalid),
        ('event_capacity_invalid', EventFailure.capacityInvalid),
        ('event_capacity_below_issued', EventFailure.capacityBelowIssued),
        ('event_locked', EventFailure.locked),
        ('event_invalid_transition', EventFailure.invalidTransition),
        ('event_has_tickets', EventFailure.hasTickets),
        ('event_already_ended', EventFailure.alreadyEnded),
      ]) {
        expect(
          mapEventError(PostgrestException(message: code, code: '55000')),
          failure,
          reason: code,
        );
      }
    });

    test('droits sans code métier, réseau, inconnu', () {
      expect(
        mapEventError(
          const PostgrestException(message: 'permission denied', code: '42501'),
        ),
        EventFailure.notFound,
      );
      expect(
        mapEventError(const SocketException('hors ligne')),
        EventFailure.network,
      );
      expect(mapEventError(StateError('x')), EventFailure.unknown);
    });
  });

  group('fuseaux (EVT-02)', () {
    test('tous les fuseaux proposés existent', () {
      for (final zone in eventTimeZones) {
        expect(
          () => utcOffsetLabel(zone.id, DateTime.utc(2030)),
          returnsNormally,
          reason: zone.id,
        );
      }
    });

    test('heure murale → UTC, et retour', () {
      final wall = DateTime(2030, 6, 20, 20);
      expect(
        instantFromWallTime('Africa/Ouagadougou', wall),
        DateTime.utc(2030, 6, 20, 20),
      );
      expect(
        instantFromWallTime('Africa/Lagos', wall),
        DateTime.utc(2030, 6, 20, 19),
      );
      expect(wallTimeIn('Africa/Lagos', DateTime.utc(2030, 6, 20, 19)), wall);
    });

    test('heure d’été prise en compte (Paris)', () {
      expect(
        instantFromWallTime('Europe/Paris', DateTime(2030, 7, 1, 20)),
        DateTime.utc(2030, 7, 1, 18),
      );
      expect(
        instantFromWallTime('Europe/Paris', DateTime(2030, 1, 15, 20)),
        DateTime.utc(2030, 1, 15, 19),
      );
      expect(utcOffsetLabel('Europe/Paris', DateTime.utc(2030, 7)), 'UTC+2');
      expect(utcOffsetLabel('Africa/Lagos', DateTime.utc(2030)), 'UTC+1');
      expect(utcOffsetLabel('Africa/Ouagadougou', DateTime.utc(2030)), 'UTC');
    });

    test('libellé des fuseaux', () {
      expect(timeZoneLabel('Africa/Ouagadougou'), 'Burkina Faso — Ouagadougou');
      expect(timeZoneLabel('Asia/Tokyo'), 'Asia/Tokyo');
    });
  });

  test('ordre : actifs du plus proche, puis terminés du plus récent', () {
    final sorted = sortEvents([
      testEvent(
        id: 'vieux',
        status: EventStatus.closed,
        startsAt: DateTime.utc(2025),
      ),
      testEvent(id: 'loin', startsAt: DateTime.utc(2031)),
      testEvent(
        id: 'récent',
        status: EventStatus.archived,
        startsAt: DateTime.utc(2026),
      ),
      testEvent(
        id: 'proche',
        status: EventStatus.published,
        startsAt: DateTime.utc(2030),
      ),
    ]);
    expect(sorted.map((e) => e.id), ['proche', 'loin', 'récent', 'vieux']);
  });

  test('plage horaire affichée dans le fuseau de l’événement', () {
    // 20:00 → 00:00 le lendemain : affichage sur deux jours.
    final overnight = testEvent(startsAt: DateTime.utc(2030, 6, 20, 20));
    expect(formatEventRange(overnight), contains('20:00 →'));
    expect(formatEventRange(overnight), endsWith('· 00:00'));
    final lagos = TicketEvent(
      id: 'l',
      organizationId: 'o',
      title: 'Lagos',
      timezone: 'Africa/Lagos',
      startsAt: DateTime.utc(2030, 6, 20, 17),
      endsAt: DateTime.utc(2030, 6, 20, 21),
      status: EventStatus.draft,
    );
    expect(formatEventRange(lagos), endsWith('18:00 – 22:00'));
  });
}
