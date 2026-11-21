import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Résultat de recherche d'exemple : un élément de chaque sorte.
GlobalSearchResult sampleSearchResult() => GlobalSearchResult(
  accounts: const [
    SearchAccount(id: 'u2', name: 'Awa Ouédraogo', email: 'awa@exemple.bf'),
  ],
  organizations: const [
    SearchOrganization(id: 'o1', name: 'Kwabo Événements', ownerName: 'Awa'),
  ],
  events: [
    SearchEvent(
      id: 'e1',
      title: 'Concert de Noël',
      status: EventStatus.published,
      startsAt: DateTime.utc(2026, 12, 24, 20),
      organizationName: 'Kwabo Événements',
    ),
  ],
  tickets: const [
    SearchTicket(
      id: 't1',
      reference: 'TS-AB12-CD34',
      status: TicketStatus.issued,
      holderName: 'Aïcha Sawadogo',
      eventTitle: 'Concert de Noël',
    ),
  ],
);

/// Faux outils de la console : recherches et messages enregistrés.
class FakeAdminToolsRepository implements AdminToolsRepository {
  new({GlobalSearchResult? result}) : result = result ?? sampleSearchResult();

  GlobalSearchResult result;
  final List<String> calls = [];

  /// Échec de la prochaine action (consommé).
  AdminAccountsFailure? failure;

  /// Destinataires renvoyés par un envoi.
  int recipients = 12;

  void _check() {
    if (failure case final f?) {
      failure = null;
      throw f;
    }
  }

  @override
  Future<GlobalSearchResult> search(String query) async {
    calls.add('search $query');
    _check();
    return result;
  }

  @override
  Future<int> sendMessage(
    MessageTarget target, {
    required String title,
    required String body,
    int days = 7,
  }) async {
    calls.add('message ${target.kind.name} ${target.id} $title $days');
    _check();
    return target.kind == MessageTargetKind.account ? 1 : recipients;
  }
}
