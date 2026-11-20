import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/billing/domain/billing_block.dart';
import 'package:ticketsur/features/reports/domain/report.dart';

/// [ReportRepository] adossé à `event_report_rows` (migration 1600).
class SupabaseReportRepository implements ReportRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<List<ReportRow>> rows(String eventId) async {
    try {
      final rows = await _client
          .rpc<List<dynamic>>(
            'event_report_rows',
            params: {'p_event_id': eventId},
          )
          .timeout(const Duration(seconds: 60));
      return [
        for (final row in rows)
          ReportRow.fromJson(Map<String, Object?>.from(row as Map)),
      ];
    } on Object catch (error) {
      throw mapReportError(error);
    }
  }
}

/// Traduit une erreur PostgREST ou réseau en [ReportFailure].
ReportFailure mapReportError(Object error) {
  // Limite du pack : la feuille « Limite atteinte » s'ouvre (P8).
  captureBillingBlock(error);
  if (error is ReportFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return ReportFailure.network;
  }
  if (error is supabase.PostgrestException &&
      (error.message == 'event_not_found' || error.code == '42501')) {
    return ReportFailure.notFound;
  }
  return ReportFailure.unknown;
}
