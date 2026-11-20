import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// [TicketRepository] adossé à `event_tickets`, `issue_tickets`,
/// `issue_named_tickets`, `set_ticket_holder`, `export_tickets` et
/// `revoke_ticket`.
class SupabaseTicketRepository implements TicketRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<TicketPage> list(
    String eventId, {
    TicketStatus? status,
    String? search,
    int limit = 50,
    int offset = 0,
    bool undelivered = false,
    String? categoryId,
  }) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'event_tickets',
      params: {
        'p_event_id': eventId,
        'p_status': status?.wireName,
        'p_search': (search?.trim().isEmpty ?? true) ? null : search!.trim(),
        'p_limit': limit,
        'p_offset': offset,
        // Paramètre omis par défaut : compatible avec un serveur sans 1500.
        if (undelivered) 'p_undelivered': true,
        // Idem : compatible avec un serveur sans 2100.
        'p_category_id': ?categoryId,
      },
    );
    final items = [
      for (final row in rows) Map<String, Object?>.from(row as Map),
    ];
    return TicketPage(
      items: [for (final row in items) TicketSummary.fromJson(row)],
      total: items.isEmpty
          ? (offset == 0 ? 0 : offset)
          : (items.first['total_count']! as num).toInt(),
    );
  });

  @override
  Future<List<TicketSecret>> issue(
    String eventId,
    String categoryId,
    int quantity, {
    required String categoryName,
    bool isInvitation = false,
  }) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'issue_tickets',
      params: {
        'p_event_id': eventId,
        'p_category_id': categoryId,
        'p_quantity': quantity,
      },
    );
    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        TicketSecret(
          ticketId: row['ticket_id']! as String,
          reference: row['public_reference']! as String,
          token: row['qr_token']! as String,
          categoryName: categoryName,
          isInvitation: isInvitation,
        ),
    ];
  });

  @override
  Future<List<TicketSecret>> issueNamed(String eventId, List<TicketRow> rows) =>
      _guard(() async {
        final result = await _client.rpc<List<dynamic>>(
          'issue_named_tickets',
          params: {
            'p_event_id': eventId,
            'p_rows': [
              for (final row in rows)
                {
                  'category_id': row.categoryId,
                  'name': row.holder.name,
                  'phone': row.holder.phone,
                  'email': row.holder.email,
                },
            ],
          },
        );
        return [
          for (final row in result.cast<Map<String, dynamic>>())
            TicketSecret(
              ticketId: row['ticket_id']! as String,
              reference: row['public_reference']! as String,
              token: row['qr_token']! as String,
              categoryName: row['category_name']! as String,
              holderName: row['holder_name'] as String?,
              isInvitation: row['category_is_invitation'] == true,
            ),
        ];
      });

  @override
  Future<TicketHolder> setHolder(String ticketId, TicketHolder holder) =>
      _guard(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'set_ticket_holder',
          params: {
            'p_ticket_id': ticketId,
            'p_name': holder.name,
            'p_phone': holder.phone,
            'p_email': holder.email,
          },
        );
        return TicketHolder.fromJson(
          Map<String, Object?>.from(rows.single as Map),
        );
      });

  @override
  Future<DateTime> recordDelivery(String ticketId, DeliveryChannel channel) =>
      _guard(() async {
        final at = await _client.rpc<String>(
          'record_ticket_delivery',
          params: {'p_ticket_id': ticketId, 'p_channel': channel.wireName},
        );
        return DateTime.parse(at).toUtc();
      });

  @override
  Future<List<TicketSecret>> export(List<String> ticketIds) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'export_tickets',
      params: {'p_ticket_ids': ticketIds},
    );
    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        TicketSecret(
          ticketId: row['ticket_id']! as String,
          reference: row['public_reference']! as String,
          token: row['qr_token']! as String,
          categoryName: row['category_name']! as String,
          status: TicketStatus.fromWire(row['status']),
          holderName: row['holder_name'] as String?,
          isInvitation: row['category_is_invitation'] == true,
        ),
    ];
  });

  @override
  Future<TicketStatus> revoke(String ticketId, {String? reason}) =>
      _guard(() async {
        final status = await _client.rpc<String>(
          'revoke_ticket',
          params: {'p_ticket_id': ticketId, 'p_reason': reason},
        );
        return TicketStatus.fromWire(status);
      });

  @override
  Future<int> revokeMany(List<String> ticketIds, {String? reason}) => _guard(
    () => _client.rpc<int>(
      'revoke_tickets',
      params: {'p_ticket_ids': ticketIds, 'p_reason': reason},
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapTicketError(error);
    }
  }
}

/// Traduit une erreur PostgREST ou réseau en [TicketFailure].
TicketFailure mapTicketError(Object error) {
  if (error is TicketFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return TicketFailure.network;
  }
  if (error is supabase.PostgrestException) {
    final failure = TicketFailure.fromServerCode(error.message);
    if (failure != TicketFailure.unknown) return failure;
    return switch (error.code) {
      '42501' => TicketFailure.notFound,
      '22023' => TicketFailure.invalid,
      _ => TicketFailure.unknown,
    };
  }
  return TicketFailure.unknown;
}
