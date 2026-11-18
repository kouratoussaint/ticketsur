import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Jeton factice au format TicketSûr (43 caractères après « TS1. »).
String fakeToken(int n) => 'TS1.${n.toString().padLeft(43, 'A')}';

/// Faux dépôt de tickets, piloté par les tests.
class FakeTicketRepository implements TicketRepository {
  new([List<TicketSummary>? tickets]) : tickets = [...?tickets];

  final List<TicketSummary> tickets;
  final Map<String, String> tokens = {};
  final List<String> calls = [];
  TicketFailure? nextFailure;
  int _n = 0;

  void _maybeFail() {
    if (nextFailure case final failure?) {
      nextFailure = null;
      throw failure;
    }
  }

  @override
  Future<TicketPage> list(
    String eventId, {
    TicketStatus? status,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final filtered = [
      for (final t in tickets)
        if ((status == null || t.status == status) &&
            (search == null ||
                search.isEmpty ||
                t.reference.contains(search.toUpperCase())))
          t,
    ];
    return TicketPage(
      items: filtered.skip(offset).take(limit).toList(),
      total: filtered.length,
    );
  }

  @override
  Future<List<TicketSecret>> issue(
    String eventId,
    String categoryId,
    int quantity, {
    required String categoryName,
  }) async {
    calls.add('issue $categoryId $quantity');
    _maybeFail();
    return [for (var i = 0; i < quantity; i++) _create(categoryName)];
  }

  TicketSecret _create(String categoryName) {
    final n = ++_n;
    final id = 'tk-$n';
    final reference = 'TS-AAAA-${n.toString().padLeft(4, '0')}';
    tickets.insert(
      0,
      TicketSummary(
        id: id,
        reference: reference,
        categoryName: categoryName,
        status: TicketStatus.issued,
        issuedAt: DateTime.utc(2030, 1, 1, 12),
      ),
    );
    tokens[id] = fakeToken(n);
    return TicketSecret(
      ticketId: id,
      reference: reference,
      token: tokens[id]!,
      categoryName: categoryName,
    );
  }

  @override
  Future<List<TicketSecret>> export(List<String> ticketIds) async {
    calls.add('export ${ticketIds.join(',')}');
    _maybeFail();
    return [
      for (final t in tickets)
        if (ticketIds.contains(t.id) && t.status != TicketStatus.revoked)
          TicketSecret(
            ticketId: t.id,
            reference: t.reference,
            token: tokens[t.id] ?? fakeToken(999),
            categoryName: t.categoryName,
            status: t.status,
          ),
    ];
  }

  @override
  Future<TicketStatus> revoke(String ticketId, {String? reason}) async {
    calls.add('revoke $ticketId ${reason ?? '-'}');
    _maybeFail();
    final index = tickets.indexWhere((t) => t.id == ticketId);
    final current = tickets[index];
    if (current.status != TicketStatus.issued) return current.status;
    tickets[index] = current.withStatus(TicketStatus.revoked);
    return TicketStatus.revoked;
  }
}
