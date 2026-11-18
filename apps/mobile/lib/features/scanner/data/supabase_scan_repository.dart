import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/scanner/domain/scan_post.dart';

/// [ScanRepository] adossé à `my_scan_posts`, `my_recent_scans` et
/// `validate_scan`.
class SupabaseScanRepository implements ScanRepository {
  new(this._client, {this.timeout = const Duration(seconds: 8)});

  final supabase.SupabaseClient _client;

  /// Délai au-delà duquel la réponse est considérée perdue (la requête est
  /// alors rejouée avec le même identifiant).
  final Duration timeout;

  Future<List<Map<String, Object?>>> _rows(
    String function, [
    Map<String, Object?>? params,
  ]) async {
    final rows = await _client.rpc<List<dynamic>>(function, params: params);
    return [for (final row in rows) Map<String, Object?>.from(row as Map)];
  }

  @override
  Future<List<ScanPost>> myPosts() async => [
    for (final row in await _rows('my_scan_posts')) ScanPost.fromJson(row),
  ];

  @override
  Future<List<RecentScan>> recentScans() async => [
    for (final row in await _rows('my_recent_scans', {'p_limit': 50}))
      RecentScan.fromJson(row),
  ];

  @override
  Future<Object?> validate({
    required String requestId,
    required String eventId,
    required String checkpointId,
    required String token,
  }) async {
    try {
      final response = await _client
          .rpc<Object?>(
            'validate_scan',
            params: {
              'p_request_id': requestId,
              'p_event_id': eventId,
              'p_checkpoint_id': checkpointId,
              'p_qr_token': token,
            },
          )
          .timeout(timeout);
      return response is Map ? Map<String, Object?>.from(response) : response;
    } on SocketException catch (error) {
      throw ScanTransportException(error);
    } on TimeoutException catch (error) {
      throw ScanTransportException(error);
    } on supabase.AuthRetryableFetchException catch (error) {
      throw ScanTransportException(error);
    } on supabase.PostgrestException catch (error) {
      // Erreur HTTP sans corps exploitable (passerelle, 5xx…) : issue
      // inconnue, donc à rejouer, jamais un verdict.
      throw ScanTransportException(error);
    }
  }
}
