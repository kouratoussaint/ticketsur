import 'dart:async';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/billing/domain/billing_block.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';

/// [TicketTemplateRepository] adossé aux fonctions de la migration 3100 et
/// au bucket `event-covers` (dossier de l'événement, mêmes droits que la
/// photo de couverture).
class SupabaseTicketTemplateRepository implements TicketTemplateRepository {
  new(this._client, {Random? random}) : _random = random ?? Random.secure();

  final supabase.SupabaseClient _client;
  final Random _random;

  static const _bucket = 'event-covers';

  /// Limite du bucket (2 Mo).
  static const int maxBytes = 2 * 1024 * 1024;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(const Duration(seconds: 30));
    } on TemplateFailure {
      rethrow;
    } on supabase.PostgrestException catch (error) {
      captureBillingBlock(error);
      throw TemplateFailure.fromCode(error.message);
    } on supabase.StorageException {
      throw TemplateFailure.imageInvalid;
    } on Object {
      throw TemplateFailure.network;
    }
  }

  @override
  String imageUrl(String path) =>
      _client.storage.from(_bucket).getPublicUrl(path);

  @override
  Future<Map<String, TicketTemplate>> forEvent(String eventId) =>
      _guard(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'event_ticket_templates',
          params: {'p_event_id': eventId},
        );
        return {
          for (final row in rows.cast<Map<String, dynamic>>())
            row['category_id']! as String: ?templateFromJson(
              row['template'],
              imageUrlOf: imageUrl,
            ),
        };
      });

  @override
  Future<void> save(String categoryId, TicketTemplate? template) =>
      _guard(() async {
        await _client.rpc<Object?>(
          'set_ticket_template',
          params: {
            'p_category_id': categoryId,
            'p_template': template == null ? null : templateToJson(template),
          },
        );
      });

  @override
  Future<String> uploadImage(
    TicketEvent event,
    Uint8List bytes,
    String mimeType,
  ) => _guard(() async {
    if (bytes.length > maxBytes) throw TemplateFailure.imageTooLarge;
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final name = List.generate(
      12,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    final path = '${event.organizationId}/${event.id}/Modele_$name.$extension';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: supabase.FileOptions(
            contentType: mimeType,
            cacheControl: '31536000',
          ),
        );
    return path;
  });

  @override
  Future<Map<String, TicketArtInfo>> artInfo(List<String> ticketIds) =>
      _guard(() async {
        final result = <String, TicketArtInfo>{};
        // 500 identifiants au plus par appel.
        for (var start = 0; start < ticketIds.length; start += 500) {
          final rows = await _client.rpc<List<dynamic>>(
            'ticket_art_info',
            params: {
              'p_ticket_ids': ticketIds.sublist(
                start,
                (start + 500).clamp(0, ticketIds.length),
              ),
            },
          );
          for (final row in rows.cast<Map<String, dynamic>>()) {
            result[row['ticket_id']! as String] = (
              categoryId: row['category_id']! as String,
              number: (row['event_number']! as num).toInt(),
            );
          }
        }
        return result;
      });
}
