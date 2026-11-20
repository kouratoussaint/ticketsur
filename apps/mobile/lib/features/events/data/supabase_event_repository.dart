import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:math' show Random;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/core/image_upload.dart';
import 'package:ticketsur/design_system/image_rules.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/notifications/data/supabase_push_repository.dart';

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
      'kind, cover_path, is_public, public_blocked_at, public_blocked_reason, '
      'tagline';

  String _coverUrl(String path) =>
      _client.storage.from(coverBucket).getPublicUrl(path);

  TicketEvent _read(Map<String, dynamic> json) =>
      TicketEvent.fromJson(json, coverUrlOf: _coverUrl);

  /// Accroche enregistrée à part (`set_event_tagline`), si elle change.
  Future<TicketEvent> _withTagline(TicketEvent event, EventDraft draft) async {
    final tagline = draft.cleanTagline;
    if (tagline == event.tagline) return event;
    final json = await _client.rpc<Map<String, dynamic>>(
      'set_event_tagline',
      params: {'p_event_id': event.id, 'p_tagline': tagline},
    );
    return _read(json);
  }

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
        return await _withTagline(_read(json), draft);
      });

  @override
  Future<TicketEvent> update(String eventId, EventDraft draft) =>
      _guard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'update_event',
          params: {'p_event_id': eventId, ...draft.toParams()},
        );
        return await _withTagline(_read(json), draft);
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
        // Contrôle démarré : les contrôleurs sont prévenus tout de suite.
        if (status == EventStatus.inProgress) {
          unawaited(flushPushOutbox(_client));
        }
        return _read(json);
      });

  @override
  Future<TicketEvent> setCover(TicketEvent event, CoverImage image) =>
      _guard(() async {
        // Réduite (1600 × 900 au plus), compressée (≤ 400 Ko) et vignette
        // 480 × 270 pour les listes (ADR 0026).
        final prepared = await prepareImage(
          image.bytes,
          image.mimeType,
          ImageRules.cover,
        );
        if (prepared.bytes.length > CoverImage.maxBytes) {
          throw EventFailure.coverInvalid;
        }
        final name = List.generate(
          16,
          (_) => _random.nextInt(16).toRadixString(16),
        ).join();
        final path =
            '${event.organizationId}/${event.id}/$name.${prepared.extension}';
        await uploadWithThumbnail(
          _client.storage.from(coverBucket),
          path,
          prepared,
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

  @override
  Future<String> duplicate(
    TicketEvent source, {
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
  }) => _guard(() async {
    final id = await _client.rpc<String>(
      'duplicate_event',
      params: {
        'p_event_id': source.id,
        'p_title': title.trim(),
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_ends_at': endsAt.toUtc().toIso8601String(),
      },
    );
    // Photo : copie dans un fichier propre à la copie. Un échec laisse la
    // copie sans photo, sans annuler la duplication.
    if (source.coverPath case final from?) {
      final extension = from.contains('.') ? from.split('.').last : 'jpg';
      final name = List.generate(
        16,
        (_) => _random.nextInt(16).toRadixString(16),
      ).join();
      final to = '${source.organizationId}/$id/$name.$extension';
      try {
        final bucket = _client.storage.from(coverBucket);
        await bucket.copy(from, to);
        await copyThumbnail(bucket, from, to);
        await _client.rpc<Map<String, dynamic>>(
          'set_event_cover',
          params: {'p_event_id': id, 'p_path': to},
        );
      } on Object {
        await _removeQuietly(to);
      }
    }
    await _copyCustomTemplates(source, id);
    return id;
  });

  /// Designs importés : image recopiée dans le dossier de la copie, modèle
  /// posé sur la catégorie de même nom (les thèmes intégrés sont recopiés
  /// par le serveur). Au mieux : un échec laisse le modèle proposé.
  Future<void> _copyCustomTemplates(TicketEvent source, String id) async {
    try {
      final templates = await _client.rpc<List<dynamic>>(
        'event_ticket_templates',
        params: {'p_event_id': source.id},
      );
      final custom = [
        for (final row in templates.cast<Map<String, dynamic>>())
          if ((row['template'] as Map?)?['kind'] == 'custom') row,
      ];
      if (custom.isEmpty) return;
      Future<Map<String, String>> names(String eventId) async {
        final rows = await _client.rpc<List<dynamic>>(
          'event_categories',
          params: {'p_event_id': eventId},
        );
        return {
          for (final row in rows.cast<Map<String, dynamic>>())
            row['id']! as String: row['name']! as String,
        };
      }

      final sourceNames = await names(source.id);
      final copyIds = {
        for (final MapEntry(:key, :value) in (await names(id)).entries)
          value: key,
      };
      for (final row in custom) {
        final template = Map<String, Object?>.from(row['template']! as Map);
        final target = copyIds[sourceNames[row['category_id']]];
        final from = template['image_path'] as String?;
        if (target == null || from == null) continue;
        final extension = from.contains('.') ? from.split('.').last : 'jpg';
        final name = List.generate(
          12,
          (_) => _random.nextInt(16).toRadixString(16),
        ).join();
        final to = '${source.organizationId}/$id/Modele_$name.$extension';
        try {
          await _client.storage.from(coverBucket).copy(from, to);
          await _client.rpc<Object?>(
            'set_ticket_template',
            params: {
              'p_category_id': target,
              'p_template': {...template, 'image_path': to},
            },
          );
        } on Object {
          await _removeQuietly(to);
        }
      }
    } on Object {
      // La copie garde le modèle proposé pour ces catégories.
    }
  }

  /// Suppression sans échec (avec la vignette) : un fichier orphelin ne
  /// gêne personne.
  Future<void> _removeQuietly(String path) =>
      removeWithThumbnail(_client.storage.from(coverBucket), path);

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
