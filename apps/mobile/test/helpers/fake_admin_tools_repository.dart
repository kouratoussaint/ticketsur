import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/platform/domain/platform_status.dart';
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

  /// Dernier état enregistré (maintenance, inscriptions).
  PlatformStatus? saved;

  /// Export renvoyé (lignes d'exemple sinon).
  ConsoleExport? exportResult;

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

  @override
  Future<PlatformStatus> savePlatformStatus({
    required bool maintenance,
    required String message,
    required bool blockWrites,
    required bool signupsOpen,
  }) async {
    calls.add(
      'platform $maintenance $blockWrites $signupsOpen ${message.trim()}',
    );
    _check();
    return saved = PlatformStatus(
      maintenance: maintenance,
      message: message.trim().isEmpty ? null : message.trim(),
      writesBlocked: blockWrites,
      signupsOpen: signupsOpen,
    );
  }

  @override
  Future<ConsoleExport> export(ExportKind kind) async {
    calls.add('export ${kind.name}');
    _check();
    return exportResult ??
        ConsoleExport(
          kind: kind,
          columns: const ['id', 'name', 'email', 'deleted'],
          rows: const [
            ['u1', 'Awa Ouédraogo', 'awa@exemple.bf', false],
            ['u2', '=HYPERLINK("x")', null, true],
          ],
        );
  }
}
