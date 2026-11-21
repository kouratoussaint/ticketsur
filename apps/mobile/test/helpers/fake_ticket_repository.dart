import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Jeton factice au format Tikéo (43 caractères après « TS1. »).
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

  /// Types demandés à [list] (`null` : tous).
  final List<String?> categoryQueries = [];

  /// Lots demandés à [list] (`null` : tous).
  final List<String?> batchQueries = [];

  /// Lots de l'événement ; un lot est ajouté à chaque émission. Les
  /// compteurs sont recalculés à partir de [tickets].
  final List<TicketBatch> batchList = [];

  /// Lot courant pendant une émission.
  int? _currentBatch;

  @override
  Future<List<TicketBatch>> batches(String eventId) async {
    calls.add('batches');
    _maybeFail();
    return [
      for (final b in batchList.reversed)
        TicketBatch(
          id: b.id,
          number: b.number,
          createdAt: b.createdAt,
          createdBy: b.createdBy,
          total: tickets.where((t) => t.batchNumber == b.number).length,
          issued: tickets
              .where(
                (t) =>
                    t.batchNumber == b.number &&
                    t.status == TicketStatus.issued,
              )
              .length,
          redeemed: tickets
              .where(
                (t) =>
                    t.batchNumber == b.number &&
                    t.status == TicketStatus.redeemed,
              )
              .length,
          revoked: tickets
              .where(
                (t) =>
                    t.batchNumber == b.number &&
                    t.status == TicketStatus.revoked,
              )
              .length,
          categories: {
            for (final t in tickets)
              if (t.batchNumber == b.number) t.categoryName,
          }.toList(),
        ),
    ];
  }

  @override
  Future<List<(String id, TicketStatus status)>> batchTickets(
    String batchId,
  ) async {
    calls.add('batchTickets $batchId');
    _maybeFail();
    final number = batchList.firstWhere((b) => b.id == batchId).number;
    return [
      for (final t in tickets.reversed)
        if (t.batchNumber == number) (t.id, t.status),
    ];
  }

  /// Ouvre un lot (appelé au début d'une émission).
  void _openBatch() {
    final number = batchList.length + 1;
    batchList.add(
      TicketBatch(
        id: 'batch-$number',
        number: number,
        createdAt: DateTime.utc(2030, 1, 1, 12, number),
        createdBy: 'Awa',
        total: 0,
      ),
    );
    _currentBatch = number;
  }

  @override
  Future<TicketPage> list(
    String eventId, {
    TicketStatus? status,
    String? search,
    int limit = 50,
    int offset = 0,
    bool undelivered = false,
    String? categoryId,
    String? batchId,
  }) async {
    categoryQueries.add(categoryId);
    batchQueries.add(batchId);
    final batchNumber = batchId == null
        ? null
        : batchList.where((b) => b.id == batchId).firstOrNull?.number;
    final filtered = [
      for (final t in tickets)
        if ((status == null || t.status == status) &&
            (batchId == null || t.batchNumber == batchNumber) &&
            (categoryId == null || t.categoryId == categoryId) &&
            (!undelivered || t.lastDelivery == null) &&
            (search == null ||
                search.isEmpty ||
                t.reference.contains(search.toUpperCase()) ||
                (t.holder.name?.toUpperCase().contains(search.toUpperCase()) ??
                    false)))
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
    bool isInvitation = false,
  }) async {
    calls.add('issue $categoryId $quantity');
    _maybeFail();
    _openBatch();
    return [
      for (var i = 0; i < quantity; i++)
        _create(categoryName, isInvitation: isInvitation),
    ];
  }

  /// Lignes reçues par [issueNamed], dans l'ordre.
  final List<TicketRow> namedRows = [];

  /// Nom des catégories, pour l'émission nominative.
  Map<String, String> categoryNames = const {};

  /// Catégories d'invitations, pour l'émission nominative.
  Set<String> invitationCategories = const {};

  @override
  Future<List<TicketSecret>> issueNamed(
    String eventId,
    List<TicketRow> rows,
  ) async {
    calls.add('issueNamed ${rows.length}');
    _maybeFail();
    _openBatch();
    namedRows.addAll(rows);
    return [
      for (final row in rows)
        _create(
          categoryNames[row.categoryId] ?? row.categoryId,
          holder: row.holder,
          isInvitation: invitationCategories.contains(row.categoryId),
        ),
    ];
  }

  /// Envois enregistrés, dans l'ordre.
  final List<(String, DeliveryChannel)> deliveries = [];

  @override
  Future<DateTime> recordDelivery(
    String ticketId,
    DeliveryChannel channel,
  ) async {
    calls.add('recordDelivery $ticketId ${channel.wireName}');
    _maybeFail();
    deliveries.add((ticketId, channel));
    final at = DateTime.utc(2030, 1, 2, 9, 30);
    final index = tickets.indexWhere((t) => t.id == ticketId);
    tickets[index] = tickets[index].withDelivery((channel: channel, at: at));
    return at;
  }

  @override
  Future<TicketHolder> setHolder(String ticketId, TicketHolder holder) async {
    calls.add('setHolder $ticketId ${holder.name ?? '-'}');
    _maybeFail();
    final index = tickets.indexWhere((t) => t.id == ticketId);
    tickets[index] = tickets[index].withHolder(holder);
    return holder;
  }

  TicketSecret _create(
    String categoryName, {
    TicketHolder holder = TicketHolder.none,
    bool isInvitation = false,
  }) {
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
        holder: holder,
        isInvitation: isInvitation,
        batchNumber: _currentBatch,
      ),
    );
    tokens[id] = fakeToken(n);
    return TicketSecret(
      ticketId: id,
      reference: reference,
      token: tokens[id]!,
      categoryName: categoryName,
      holderName: holder.name,
      isInvitation: isInvitation,
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
            holderName: t.holder.name,
            isInvitation: t.isInvitation,
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

  @override
  Future<int> revokeMany(List<String> ticketIds, {String? reason}) async {
    calls.add('revokeMany ${ticketIds.join(',')} ${reason ?? '-'}');
    _maybeFail();
    var count = 0;
    for (final id in ticketIds) {
      final index = tickets.indexWhere((t) => t.id == id);
      if (index < 0 || tickets[index].status != TicketStatus.issued) continue;
      tickets[index] = tickets[index].withStatus(TicketStatus.revoked);
      count++;
    }
    return count;
  }
}
