import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/legal/domain/legal_document.dart';

class SupabaseLegalRepository implements LegalRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  @override
  Future<LegalDocument> fetch(LegalSlug slug, {String locale = 'fr'}) =>
      _guard(() async {
        final rows = await _client
            .rpc<List<dynamic>>(
              'legal_document',
              params: {'p_slug': slug.wireName, 'p_locale': locale},
            )
            .timeout(_timeout);
        if (rows.isEmpty) throw LegalFailure.notFound;
        return LegalDocument.fromJson(
          Map<String, Object?>.from(rows.first as Map),
        );
      });

  @override
  Future<int> save(
    LegalSlug slug, {
    required String title,
    required String body,
    String locale = 'fr',
  }) => _guard(
    () => _client
        .rpc<int>(
          'admin_save_legal_document',
          params: {
            'p_slug': slug.wireName,
            'p_title': title.trim(),
            'p_body': body.trim(),
            'p_locale': locale,
          },
        )
        .timeout(_timeout),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on LegalFailure {
      rethrow;
    } on Object catch (error) {
      if (error is SocketException ||
          error is TimeoutException ||
          error is supabase.AuthRetryableFetchException) {
        throw LegalFailure.network;
      }
      if (error is supabase.PostgrestException) {
        throw switch (error.code) {
          '22023' => LegalFailure.invalid,
          'P0002' => LegalFailure.notFound,
          _ => LegalFailure.unknown,
        };
      }
      throw LegalFailure.unknown;
    }
  }
}
