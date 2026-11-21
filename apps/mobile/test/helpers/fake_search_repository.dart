import 'package:ticketsur/features/search/domain/search.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

SearchTicketHit searchTicket({
  String id = 't1',
  String eventId = 'e1',
  String? holder = 'Aïcha Ouédraogo',
  TicketStatus status = TicketStatus.issued,
}) => SearchTicketHit(
  id: id,
  eventId: eventId,
  eventTitle: 'Nuit du Djembé',
  reference: 'TS-AB12-CD34',
  category: 'Standard',
  status: status,
  holderName: holder,
  holderPhone: '+22670112233',
);

/// Recherche en mémoire : renvoie [result] pour toute requête.
class FakeSearchRepository implements SearchRepository {
  new({this.result = const PromoterSearchResult()});

  PromoterSearchResult result;
  final List<(String, String)> queries = [];
  SearchFailure? failure;

  @override
  Future<PromoterSearchResult> search(
    String organizationId,
    String query,
  ) async {
    queries.add((organizationId, query));
    if (failure case final f?) throw f;
    return result;
  }
}
