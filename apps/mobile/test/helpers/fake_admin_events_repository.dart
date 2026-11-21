import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_events/domain/admin_events.dart';
import 'package:ticketsur/features/events/domain/event.dart' show EventStatus;
import 'package:ticketsur/features/tickets/domain/ticket.dart'
    show TicketStatus;

/// Fiche de test : concert publié de Kwabo, 120 tickets dont 20 entrés.
AdminEventDetail adminEventDetail({
  String id = 'e1',
  String title = 'Concert de Noël',
  EventStatus status = EventStatus.published,
  int ticketsTotal = 120,
  DateTime? trashedAt,
}) => AdminEventDetail(
  id: id,
  title: title,
  status: status,
  startsAt: DateTime.utc(2026, 12, 24, 20),
  endsAt: DateTime.utc(2026, 12, 25),
  organizationId: 'o1',
  organizationName: 'Kwabo Événements',
  venue: 'Maison du peuple',
  city: 'Ouagadougou',
  isPublic: true,
  trashedAt: trashedAt,
  purgeDueAt: trashedAt?.add(const Duration(days: 30)),
  categories: const [
    AdminEventCategory(id: 'c1', name: 'Standard', issued: 100, admitted: 20),
    AdminEventCategory(id: 'c2', name: 'VIP', issued: 20),
  ],
  checkpoints: const ['Entrée principale'],
  ticketsTotal: ticketsTotal,
  ticketsValid: ticketsTotal == 0 ? 0 : 100,
  ticketsAdmitted: ticketsTotal == 0 ? 0 : 20,
  ticketsToCancel: ticketsTotal == 0 ? 0 : 100,
  holdersToNotify: ticketsTotal == 0 ? 0 : 12,
);

/// Fiche de test d'un ticket valable, dans « Mes tickets ».
AdminTicketDetail adminTicketDetail({
  String id = 't1',
  TicketStatus status = TicketStatus.issued,
}) => AdminTicketDetail(
  id: id,
  reference: 'TS-AB12-CD34',
  status: status,
  issuedAt: DateTime.utc(2026, 11, 20, 9),
  eventId: 'e1',
  eventTitle: 'Concert de Noël',
  eventStartsAt: DateTime.utc(2026, 12, 24, 20),
  organizationId: 'o1',
  organizationName: 'Kwabo Événements',
  categoryName: 'Standard',
  holderName: 'Aïcha Sawadogo',
  holderPhone: '+22670123456',
  walletOwner: 'Aïcha S.',
  deliveries: [(channel: 'whatsapp', sentAt: DateTime.utc(2026, 11, 20, 10))],
);

/// Événements et tickets de la console en mémoire.
class FakeAdminEventsRepository implements AdminEventsRepository {
  new({
    Map<String, AdminEventDetail>? events,
    Map<String, AdminTicketDetail>? tickets,
  }) : eventDetails = events ?? {'e1': adminEventDetail()},
       ticketDetails = tickets ?? {'t1': adminTicketDetail()};

  final Map<String, AdminEventDetail> eventDetails;
  final Map<String, AdminTicketDetail> ticketDetails;
  final List<String> calls = [];
  final List<AdminEventEdit> edits = [];

  /// Échec de la prochaine action.
  AdminAccountsFailure? failure;

  void _fail() {
    if (failure case final f?) {
      failure = null;
      throw f;
    }
  }

  @override
  Future<List<AdminEventRow>> events({
    String search = '',
    EventStatus? status,
    String? organizationId,
    int offset = 0,
    int limit = 30,
  }) async {
    calls.add('events $search ${status?.wireName ?? '-'}');
    if (offset > 0) return const [];
    return [
      for (final event in eventDetails.values)
        if (!event.trashed &&
            (status == null || event.status == status) &&
            event.title.toLowerCase().contains(search.toLowerCase()))
          AdminEventRow(
            id: event.id,
            title: event.title,
            status: event.status,
            startsAt: event.startsAt,
            city: event.city,
            organizationId: event.organizationId,
            organizationName: event.organizationName,
            tickets: event.ticketsTotal,
            admitted: event.ticketsAdmitted,
          ),
    ];
  }

  @override
  Future<AdminEventDetail> eventDetail(String eventId) async {
    final event = eventDetails[eventId];
    if (event == null) throw AdminAccountsFailure.orgNotFound;
    return event;
  }

  @override
  Future<void> updateEvent(
    String eventId,
    AdminEventEdit edit, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('update $eventId ${edit.title} $reason $notify');
    edits.add(edit);
    _fail();
    eventDetails[eventId] = adminEventDetail(id: eventId, title: edit.title);
  }

  @override
  Future<EventStatusOutcome> setStatus(
    String eventId,
    EventStatus status, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('status $eventId ${status.wireName} $reason');
    _fail();
    final event = eventDetails[eventId]!;
    eventDetails[eventId] = adminEventDetail(
      id: eventId,
      title: event.title,
      status: status,
      ticketsTotal: event.ticketsTotal,
    );
    return status == EventStatus.cancelled
        ? (ticketsCancelled: event.ticketsToCancel, holdersNotified: 12)
        : (ticketsCancelled: 0, holdersNotified: 0);
  }

  @override
  Future<void> move(
    String eventId,
    String organizationId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('move $eventId $organizationId $reason');
    _fail();
  }

  @override
  Future<void> trash(
    String eventId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('trash $eventId $reason');
    _fail();
    final event = eventDetails[eventId]!;
    eventDetails[eventId] = adminEventDetail(
      id: eventId,
      title: event.title,
      status: event.status,
      ticketsTotal: event.ticketsTotal,
      trashedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> restore(
    String eventId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('restore $eventId $reason');
    _fail();
  }

  @override
  Future<int> issueTickets(
    String eventId, {
    required String categoryId,
    required int quantity,
    required String reason,
  }) async {
    calls.add('issue $eventId $categoryId $quantity $reason');
    _fail();
    return quantity;
  }

  @override
  Future<List<AdminTicketRow>> findTickets(String query) async {
    calls.add('find $query');
    _fail();
    return [
      for (final ticket in ticketDetails.values)
        if ((ticket.holderName ?? '').toLowerCase().contains(
              query.toLowerCase(),
            ) ||
            ticket.reference.contains(query.toUpperCase()))
          AdminTicketRow(
            id: ticket.id,
            reference: ticket.reference,
            status: ticket.status,
            holderName: ticket.holderName,
            eventId: ticket.eventId,
            eventTitle: ticket.eventTitle,
            startsAt: ticket.eventStartsAt,
            organizationName: ticket.organizationName,
            categoryName: ticket.categoryName,
          ),
    ];
  }

  @override
  Future<AdminTicketDetail> ticketDetail(String ticketId) async {
    final ticket = ticketDetails[ticketId];
    if (ticket == null) throw AdminAccountsFailure.orgNotFound;
    return ticket;
  }

  @override
  Future<void> revokeTicket(
    String ticketId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('revoke $ticketId $reason $notify');
    _fail();
    ticketDetails[ticketId] = adminTicketDetail(
      id: ticketId,
      status: TicketStatus.revoked,
    );
  }

  @override
  Future<void> setTicketHolder(
    String ticketId, {
    required String reason,
    String? name,
    String? phone,
    String? email,
  }) async {
    calls.add('holder $ticketId ${name ?? '-'} ${phone ?? '-'} $reason');
    _fail();
  }
}
