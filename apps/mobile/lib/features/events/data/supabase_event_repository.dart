import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/events/domain/event.dart';

/// [EventRepository] adossé à la table `events` (lecture, RLS) et aux
/// fonctions `create_event`, `update_event`, `set_event_status`
/// (migration 0600).
class SupabaseEventRepository implements EventRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<List<TicketEvent>> list(String organizationId) => _guard(() async {
    final rows = await _client
        .from('events')
        .select(
          'id, organization_id, title, venue, timezone, starts_at, ends_at, '
          'capacity, status',
        )
        .eq('organization_id', organizationId)
        .order('starts_at');
    return [for (final row in rows) TicketEvent.fromJson(row)];
  });

  @override
  Future<TicketEvent> create(String organizationId, EventDraft draft) =>
      _guard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'create_event',
          params: {'p_organization_id': organizationId, ...draft.toParams()},
        );
        return TicketEvent.fromJson(json);
      });

  @override
  Future<TicketEvent> update(String eventId, EventDraft draft) =>
      _guard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'update_event',
          params: {'p_event_id': eventId, ...draft.toParams()},
        );
        return TicketEvent.fromJson(json);
      });

  @override
  Future<TicketEvent> setStatus(String eventId, EventStatus status) =>
      _guard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'set_event_status',
          params: {'p_event_id': eventId, 'p_status': status.wireName},
        );
        return TicketEvent.fromJson(json);
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapEventError(error);
    }
  }
}

/// Traduit une erreur PostgREST ou réseau en [EventFailure].
EventFailure mapEventError(Object error) {
  if (error is EventFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return EventFailure.network;
  }
  if (error is supabase.PostgrestException) {
    // Le message porte le code stable (« event_dates_invalid »…).
    final failure = EventFailure.fromServerCode(error.message);
    if (failure != EventFailure.unknown) return failure;
    // insufficient_privilege sans code métier (session expirée, RLS…).
    if (error.code == '42501') return EventFailure.notFound;
  }
  return EventFailure.unknown;
}
