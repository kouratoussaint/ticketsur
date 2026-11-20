import 'package:ticketsur/features/events/domain/event.dart';

/// Événement de test : brouillon dans l'organisation de test.
TicketEvent testEvent({
  String id = 'evt-test',
  String title = 'Concert de test',
  EventStatus status = EventStatus.draft,
  DateTime? startsAt,
  String? venue = 'Palais des sports',
  String organizationId = 'org-test',
  String? city,
  String? coverPath,
  EventKind kind = EventKind.other,
  bool isPublic = false,
  String? blockedReason,
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
    city: city,
    kind: kind,
    coverPath: coverPath,
    coverUrl: coverPath == null ? null : 'https://covers.test/$coverPath',
    isPublic: isPublic,
    publicBlocked: blockedReason != null,
    publicBlockedReason: blockedReason,
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
  final List<(String, CoverImage)> coverCalls = [];

  /// Échec du prochain envoi de photo uniquement.
  EventFailure? nextCoverFailure;

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
      city: _clean(draft.city),
      countryCode: draft.countryCode,
      venueAddress: _clean(draft.venueAddress),
      description: _clean(draft.description),
      kind: draft.kind,
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
      city: _clean(draft.city),
      countryCode: draft.countryCode,
      venueAddress: _clean(draft.venueAddress),
      description: _clean(draft.description),
      kind: draft.kind,
      coverPath: current.coverPath,
      coverUrl: current.coverUrl,
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

  /// Appels à [duplicate] : (source, titre, début, fin).
  final List<(String, String, DateTime, DateTime)> duplicateCalls = [];

  @override
  Future<String> duplicate(
    TicketEvent source, {
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    duplicateCalls.add((source.id, title, startsAt, endsAt));
    if (_takeWriteFailure() case final failure?) throw failure;
    final id = 'evt-${events.length + 1}';
    events.add(
      TicketEvent(
        id: id,
        organizationId: source.organizationId,
        title: title.trim(),
        venue: source.venue,
        timezone: source.timezone,
        startsAt: startsAt,
        endsAt: endsAt,
        capacity: source.capacity,
        status: EventStatus.draft,
        city: source.city,
        countryCode: source.countryCode,
        venueAddress: source.venueAddress,
        description: source.description,
        kind: source.kind,
      ),
    );
    return id;
  }

  /// Appels à [setPublic] : (événement, visible).
  final List<(String, bool)> publicCalls = [];

  @override
  Future<TicketEvent> setPublic(String eventId, {required bool public}) async {
    publicCalls.add((eventId, public));
    if (_takeWriteFailure() case final failure?) throw failure;
    final index = events.indexWhere((e) => e.id == eventId);
    if (public && events[index].publicBlocked) throw EventFailure.blocked;
    final updated = events[index].withPublic(public);
    events[index] = updated;
    return updated;
  }

  @override
  Future<TicketEvent> setCover(TicketEvent event, CoverImage image) async {
    coverCalls.add((event.id, image));
    if (nextCoverFailure case final failure?) {
      nextCoverFailure = null;
      throw failure;
    }
    final index = events.indexWhere((e) => e.id == event.id);
    final path =
        '${event.organizationId}/${event.id}/cover-${coverCalls.length}.${image.extension}';
    final updated = events[index].withCover(path, 'https://covers.test/$path');
    events[index] = updated;
    return updated;
  }

  static String? _clean(String? text) {
    final value = text?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }
}
