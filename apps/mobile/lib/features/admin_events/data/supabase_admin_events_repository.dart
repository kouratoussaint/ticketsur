import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/admin_accounts/data/supabase_admin_accounts_repository.dart'
    show mapAdminAccountsError;
import 'package:ticketsur/features/admin_events/domain/admin_events.dart';
import 'package:ticketsur/features/events/domain/event.dart' show EventStatus;
import 'package:ticketsur/features/notifications/data/supabase_push_repository.dart'
    show flushPushOutbox;

/// [AdminEventsRepository] : fonctions SQL de la migration 5100.
class SupabaseAdminEventsRepository implements AdminEventsRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 30);

  Future<T> _rpc<T>(String name, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc<T>(name, params: params).timeout(_timeout);
    } on Object catch (error) {
      throw mapAdminAccountsError(error);
    }
  }

  /// Notifications éventuelles : la file part tout de suite.
  void _flush() => unawaited(flushPushOutbox(_client));

  List<Map<String, dynamic>> _rows(List<dynamic> rows) => [
    for (final row in rows) (row as Map).cast<String, dynamic>(),
  ];

  @override
  Future<List<AdminEventRow>> events({
    String search = '',
    EventStatus? status,
    String? organizationId,
    int offset = 0,
    int limit = 30,
  }) async {
    final rows = await _rpc<List<dynamic>>('admin_events', {
      'p_search': search.trim().isEmpty ? null : search.trim(),
      'p_status': status?.wireName,
      'p_organization_id': organizationId,
      'p_limit': limit,
      'p_offset': offset,
    });
    return [for (final row in _rows(rows)) AdminEventRow.fromJson(row)];
  }

  @override
  Future<AdminEventDetail> eventDetail(String eventId) async =>
      AdminEventDetail.fromJson(
        await _rpc<Map<String, dynamic>>('admin_event_detail', {
          'p_event_id': eventId,
        }),
      );

  @override
  Future<void> updateEvent(
    String eventId,
    AdminEventEdit edit, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_update_event', {
      'p_event_id': eventId,
      'p_title': edit.title,
      'p_starts_at': edit.startsAt.toUtc().toIso8601String(),
      'p_ends_at': edit.endsAt.toUtc().toIso8601String(),
      'p_timezone': edit.timezone,
      'p_venue': edit.venue,
      'p_city': edit.city,
      'p_venue_address': edit.venueAddress,
      'p_description': edit.description,
      'p_tagline': edit.tagline,
      'p_capacity': edit.capacity,
      'p_is_public': edit.isPublic,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<EventStatusOutcome> setStatus(
    String eventId,
    EventStatus status, {
    required String reason,
    bool? notify,
  }) async {
    final result = await _rpc<Map<String, dynamic>>('admin_set_event_status', {
      'p_event_id': eventId,
      'p_status': status.wireName,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
    return (
      ticketsCancelled: (result['tickets_cancelled'] as num?)?.toInt() ?? 0,
      holdersNotified: (result['holders_notified'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> move(
    String eventId,
    String organizationId, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_move_event', {
      'p_event_id': eventId,
      'p_organization_id': organizationId,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<void> trash(
    String eventId, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_trash_event', {
      'p_event_id': eventId,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<void> restore(
    String eventId, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_restore_event', {
      'p_event_id': eventId,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<int> issueTickets(
    String eventId, {
    required String categoryId,
    required int quantity,
    required String reason,
  }) async {
    final result = await _rpc<Map<String, dynamic>>('admin_issue_tickets', {
      'p_event_id': eventId,
      'p_category_id': categoryId,
      'p_quantity': quantity,
      'p_reason': reason,
    });
    return (result['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<List<AdminTicketRow>> findTickets(String query) async {
    final rows = await _rpc<List<dynamic>>('admin_find_tickets', {
      'p_query': query.trim(),
    });
    return [for (final row in _rows(rows)) AdminTicketRow.fromJson(row)];
  }

  @override
  Future<AdminTicketDetail> ticketDetail(String ticketId) async =>
      AdminTicketDetail.fromJson(
        await _rpc<Map<String, dynamic>>('admin_ticket_detail', {
          'p_ticket_id': ticketId,
        }),
      );

  @override
  Future<void> revokeTicket(
    String ticketId, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_revoke_ticket', {
      'p_ticket_id': ticketId,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<void> setTicketHolder(
    String ticketId, {
    required String reason,
    String? name,
    String? phone,
    String? email,
  }) => _rpc<Object?>('admin_set_ticket_holder', {
    'p_ticket_id': ticketId,
    'p_name': name,
    'p_phone': phone,
    'p_email': email,
    'p_reason': reason,
  });
}
