import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/billing/domain/billing_block.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';

/// [EventSetupRepository] adossé aux fonctions de la migration 0700 et à la
/// table `checkpoints` (lecture, RLS).
class SupabaseEventSetupRepository implements EventSetupRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<List<TicketCategory>> categories(String eventId) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'event_categories',
      params: {'p_event_id': eventId},
    );
    return [
      for (final row in rows)
        TicketCategory.fromJson(Map<String, Object?>.from(row as Map)),
    ];
  });

  @override
  Future<TicketCategory> createCategory(
    String eventId,
    String name,
    int? capacity, {
    bool isInvitation = false,
  }) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'create_ticket_category',
      params: {
        'p_event_id': eventId,
        'p_name': name.trim(),
        'p_capacity': capacity,
        'p_is_invitation': isInvitation,
      },
    );
    return TicketCategory.fromJson(json);
  });

  @override
  Future<TicketCategory> updateCategory(
    String categoryId,
    String name,
    int? capacity, {
    required bool isInvitation,
  }) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'update_ticket_category',
      params: {
        'p_category_id': categoryId,
        'p_name': name.trim(),
        'p_capacity': capacity,
        'p_is_invitation': isInvitation,
      },
    );
    return TicketCategory.fromJson(json);
  });

  @override
  Future<void> deleteCategory(String categoryId) => _guard(
    () => _client.rpc<void>(
      'delete_ticket_category',
      params: {'p_category_id': categoryId},
    ),
  );

  @override
  Future<List<Checkpoint>> checkpoints(String eventId) => _guard(() async {
    final rows = await _client
        .from('checkpoints')
        .select('id, event_id, name, active')
        .eq('event_id', eventId)
        .order('created_at');
    return [for (final row in rows) Checkpoint.fromJson(row)];
  });

  @override
  Future<Checkpoint> createCheckpoint(String eventId, String name) =>
      _guard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'create_checkpoint',
          params: {'p_event_id': eventId, 'p_name': name.trim()},
        );
        return Checkpoint.fromJson(json);
      });

  @override
  Future<Checkpoint> updateCheckpoint(
    String checkpointId,
    String name, {
    required bool active,
  }) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'update_checkpoint',
      params: {
        'p_checkpoint_id': checkpointId,
        'p_name': name.trim(),
        'p_active': active,
      },
    );
    return Checkpoint.fromJson(json);
  });

  @override
  Future<void> setCategoryPrice(String categoryId, int? price) => _guard(
    () => _client.rpc<Map<String, dynamic>>(
      'set_category_price',
      params: {'p_category_id': categoryId, 'p_price': price},
    ),
  );

  @override
  Future<void> setCategoryEntries(
    String categoryId,
    EntryPolicy policy,
    int? maxEntries,
  ) => _guard(
    () => _client.rpc<Map<String, dynamic>>(
      'set_category_entry_policy',
      params: {
        'p_category_id': categoryId,
        'p_policy': policy.wireName,
        'p_max_entries': policy == EntryPolicy.limited ? maxEntries : null,
      },
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapSetupError(error);
    }
  }
}

/// Traduit une erreur PostgREST ou réseau en [SetupFailure].
SetupFailure mapSetupError(Object error) {
  // Limite du pack : la feuille « Limite atteinte » s'ouvre (P8).
  captureBillingBlock(error);
  if (error is SetupFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return SetupFailure.network;
  }
  if (error is supabase.PostgrestException) {
    final failure = SetupFailure.fromServerCode(error.message);
    if (failure != SetupFailure.unknown) return failure;
    if (error.code == '42501') return SetupFailure.notFound;
  }
  return SetupFailure.unknown;
}
