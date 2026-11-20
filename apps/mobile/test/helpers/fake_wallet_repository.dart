import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/wallet/domain/wallet.dart';

import 'fake_ticket_repository.dart';

/// Ligne `my_tickets` type.
Map<String, Object?> walletRow({
  String id = 'w1',
  String token = '',
  TicketStatus status = TicketStatus.issued,
  String title = 'Soirée Afro-Jazz',
  DateTime? startsAt,
  int? number = 12,
  Map<String, Object?>? template,
}) {
  final start = startsAt ?? DateTime.utc(2030, 6, 20, 20);
  return {
    'ticket_id': id,
    'public_reference': 'TS-AB12-${id.toUpperCase().padLeft(4, '0')}',
    'status': status.wireName,
    'category_name': 'Fosse',
    'is_invitation': false,
    'holder_name': 'Awa Ouédraogo',
    'qr_token': status == TicketStatus.issued
        ? (token.isEmpty ? fakeToken(7) : token)
        : null,
    'redeemed_at': status == TicketStatus.redeemed
        ? '2030-06-20T21:00:00Z'
        : null,
    'organization_name': 'Kwabo Événements',
    'event_id': 'ev-$id',
    'event_title': title,
    'venue': 'Jardin de la musique',
    'timezone': 'Africa/Ouagadougou',
    'starts_at': start.toIso8601String(),
    'ends_at': start.add(const Duration(hours: 4)).toIso8601String(),
    'event_status': 'published',
    'city': 'Ouagadougou',
    'kind': 'concert',
    'event_number': number,
    'template': template,
    'cover_path': null,
  };
}

/// « Mes tickets » en mémoire : un QR connu correspond à un ticket.
class FakeWalletRepository implements WalletRepository {
  new({
    List<Map<String, Object?>>? mine,
    Map<String, Map<String, Object?>>? known,
  }) : _mine = [...?mine],
       known = {...?known};

  final List<Map<String, Object?>> _mine;

  /// Tickets ajoutables, par QR.
  final Map<String, Map<String, Object?>> known;

  /// QR déjà dans un autre compte.
  final Set<String> claimedElsewhere = {};

  WalletFailure? failure;
  final List<String> calls = [];

  @override
  Future<List<WalletTicket>> mine() async {
    calls.add('mine');
    if (failure case final f?) throw f;
    return [for (final row in _mine) WalletTicket.fromJson(row)];
  }

  @override
  Future<String> claim(String token) async {
    calls.add('claim');
    if (failure case final f?) throw f;
    if (claimedElsewhere.contains(token)) throw WalletFailure.claimed;
    final row = known[token];
    if (row == null) throw WalletFailure.unknown;
    if (!_mine.any((r) => r['ticket_id'] == row['ticket_id'])) _mine.add(row);
    return row['ticket_id']! as String;
  }

  @override
  Future<void> release(String ticketId) async {
    calls.add('release $ticketId');
    if (failure case final f?) throw f;
    _mine.removeWhere((r) => r['ticket_id'] == ticketId);
  }
}
