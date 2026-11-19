import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:math' show Random;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/events/domain/event.dart';

/// [EventRepository] adossé à la table `events` (lecture, RLS), aux
/// fonctions `create_event`, `update_event`, `set_event_status`,
/// `set_event_cover` (migrations 0600 et 1100) et au bucket Storage
/// `event-covers`.
class SupabaseEventRepository implements EventRepository {
  new(this._client, {Random? random}) : _random = random ?? Random.secure();

  final supabase.SupabaseClient _client;
  final Random _random;

  /// Bucket des photos de couverture.
  static const coverBucket = 'event-covers';

  /// Colonnes lues pour un événement.
  static const columns =
      'id, organization_id, title, venue, timezone, starts_at, ends_at, '
      'capacity, status, city, country_code, venue_address, description, '
      'kind, cover_path, is_public';

  String _coverUrl(String path) =>
      _client.storage.from(coverBucket).getPublicUrl(path);

  TicketEvent _read(Map<String, dynamic> json) =>
      TicketEvent.fromJson(json, coverUrlOf: _coverUrl);

  @override
  Future<List<TicketEvent>> list(String organizationId) => _guard(() async {
    final rows = await _client
        .from('events')
        .select(columns)
        .eq('organization_id', organizationId)
        .order('starts_at');
    return [for (final row in rows) _read(row)];
  });

  @override
  Future<TicketEvent> create(String organizationId, EventDraft draft) =>
      _guard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'create_event',
          params: {'p_organization_id': organizationId, ...draft.toParams()},
        );
        return _read(json);
      });

  @override
  Future<TicketEvent> update(String eventId, EventDraft draft) =>
      _guard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'update_event',
          params: {'p_event_id': eventId, ...draft.toParams()},
        );
        return _read(json);
      });

  @override
  Future<TicketEvent> setPublic(String eventId, {required bool public}) =>
      _guard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'set_event_public',
          params: {'p_event_id': eventId, 'p_public': public},
        );
        return _read(json);
      });

  @override
  Future<TicketEvent> setStatus(String eventId, EventStatus status) =>
      _guard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'set_event_status',
          params: {'p_event_id': eventId, 'p_status': status.wireName},
        );
        return _read(json);
      });

  @override
  Future<TicketEvent> setCover(TicketEvent event, CoverImage image) =>
      _guard(() async {
        if (image.bytes.length > CoverImage.maxBytes) {
          throw EventFailure.coverInvalid;
        }
        final name = List.generate(
          16,
          (_) => _random.nextInt(16).toRadixString(16),
        ).join();
        final path =
            '${event.organizationId}/${event.id}/$name.${image.extension}';
        final bucket = _client.storage.from(coverBucket);
        await bucket.uploadBinary(
          path,
          image.bytes,
          fileOptions: supabase.FileOptions(
            contentType: image.mimeType,
            cacheControl: '31536000',
          ),
        );
        final TicketEvent updated;
        try {
          updated = _read(
            await _client.rpc<Map<String, dynamic>>(
              'set_event_cover',
              params: {'p_event_id': event.id, 'p_path': path},
            ),
          );
        } on Object {
          await _removeQuietly(path);
          rethrow;
        }
        if (event.coverPath case final old? when old != path) {
          await _removeQuietly(old);
        }
        return updated;
      });

  /// Suppression sans échec : un fichier orphelin ne gêne personne.
  Future<void> _removeQuietly(String path) async {
    try {
      await _client.storage.from(coverBucket).remove([path]);
    } on Object {
      // Ignoré volontairement.
    }
  }

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
  if (error is supabase.StorageException) {
    // Refus du bucket : taille, format ou dossier non autorisé.
    return EventFailure.coverInvalid;
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
