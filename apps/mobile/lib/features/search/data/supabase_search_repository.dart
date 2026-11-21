import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/search/domain/search.dart';

/// [SearchRepository] adossé à `promoter_search` (migration 4400).
class SupabaseSearchRepository implements SearchRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<PromoterSearchResult> search(
    String organizationId,
    String query,
  ) async {
    try {
      final json = await _client
          .rpc<Map<String, dynamic>>(
            'promoter_search',
            params: {
              'p_organization_id': organizationId,
              'p_query': query.trim(),
            },
          )
          .timeout(const Duration(seconds: 20));
      return PromoterSearchResult.fromJson(json);
    } on Object catch (error) {
      throw mapSearchError(error);
    }
  }
}

SearchFailure mapSearchError(Object error) {
  if (error is SearchFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return SearchFailure.network;
  }
  if (error is supabase.PostgrestException && error.message == 'forbidden') {
    return SearchFailure.forbidden;
  }
  return SearchFailure.unknown;
}
