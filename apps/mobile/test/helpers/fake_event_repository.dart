import 'package:ticketsur/features/events/domain/event.dart';

/// Événement de test : brouillon dans l'organisation de test.
TicketEvent testEvent({
  String id = 'evt-test',
  String title = 'Concert de test',
  EventStatus status = EventStatus.draft,
  DateTime? startsAt,
  String? venue = 'Palais des sports',
  String organizationId = 'org-test',
}) {
  final start = startsAt ?? DateTime.utc(2030, 6, 20, 20);
  return TicketEvent(
    id: id,
    organizationId: organizationId,
    title: title,
    venue: venue,
    timezone: 'Africa/Ouagadougou',
    startsAt: start,
    endsAt: start.add(const Duration(hours: 4)),
    status: status,
  );
}

/// Faux dépôt d'événements, piloté par les tests.
class FakeEventRepository implements EventRepository {
  new([List<TicketEvent>? events]) : events = [...?events];

  final List<TicketEvent> events;

  EventFailure? nextLoadFailure;
  EventFailure? nextWriteFailure;

  final List<EventDraft> createCalls = [];
  final List<(String, EventDraft)> updateCalls = [];
  final List<(String, EventStatus)> statusCalls = [];

  EventFailure? _takeWriteFailure() {
    final failure = nextWriteFailure;
    nextWriteFailure = null;
    return failure;
  }

  @override
  Future<List<TicketEvent>> list(String organizationId) async {
    if (nextLoadFailure case final failure?) {
      nextLoadFailure = null;
      throw failure;
    }
    return [
      for (final e in events)
        if (e.organizationId == organizationId) e,
    ];
  }

  @override
  Future<TicketEvent> create(String organizationId, EventDraft draft) async {
    createCalls.add(draft);
    if (_takeWriteFailure() case final failure?) throw failure;
    final created = TicketEvent(
      id: 'evt-${events.length + 1}',
      organizationId: organizationId,
      title: draft.title.trim().replaceAll(RegExp(r'\s+'), ' '),
      venue: (draft.venue?.trim().isEmpty ?? true) ? null : draft.venue!.trim(),
      timezone: draft.timezone,
      startsAt: draft.startsAt,
      endsAt: draft.endsAt,
      capacity: draft.capacity,
      status: EventStatus.draft,
    );
    events.add(created);
    return created;
  }

  @override
  Future<TicketEvent> update(String eventId, EventDraft draft) async {
    updateCalls.add((eventId, draft));
    if (_takeWriteFailure() case final failure?) throw failure;
    final index = events.indexWhere((e) => e.id == eventId);
    final current = events[index];
    final updated = TicketEvent(
      id: current.id,
      organizationId: current.organizationId,
      title: draft.title.trim().replaceAll(RegExp(r'\s+'), ' '),
      venue: (draft.venue?.trim().isEmpty ?? true) ? null : draft.venue!.trim(),
      timezone: draft.timezone,
      startsAt: draft.startsAt,
      endsAt: draft.endsAt,
      capacity: draft.capacity,
      status: current.status,
    );
    events[index] = updated;
    return updated;
  }

  @override
  Future<TicketEvent> setStatus(String eventId, EventStatus status) async {
    statusCalls.add((eventId, status));
    if (_takeWriteFailure() case final failure?) throw failure;
    final index = events.indexWhere((e) => e.id == eventId);
    final updated = events[index].withStatus(status);
    events[index] = updated;
    return updated;
  }
}
