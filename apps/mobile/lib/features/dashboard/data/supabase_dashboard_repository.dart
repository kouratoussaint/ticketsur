import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/dashboard/domain/event_summary.dart';

/// [DashboardRepository] adossé à `event_dashboard` (migration 1300), et
/// bilan d'après-événement (`event_summary`, migration 3500).
class SupabaseDashboardRepository
    implements DashboardRepository, SummaryRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  /// Au-delà, l'actualisation est abandonnée : les chiffres affichés restent
  /// ceux du dernier appel réussi, signalés comme non actualisés.
  static const Duration timeout = Duration(seconds: 12);

  @override
  Future<EventDashboard> load(String eventId) async {
    try {
      final json = await _client
          .rpc<Object?>('event_dashboard', params: {'p_event_id': eventId})
          .timeout(timeout);
      return EventDashboard.fromJson(json);
    } on Object catch (error) {
      throw mapDashboardError(error);
    }
  }

  @override
  Future<EventSummary> summary(String eventId) async {
    try {
      final json = await _client
          .rpc<Object?>('event_summary', params: {'p_event_id': eventId})
          .timeout(timeout);
      return EventSummary.fromJson(json);
    } on Object catch (error) {
      throw mapDashboardError(error);
    }
  }
}

/// Traduit une erreur PostgREST ou réseau en [DashboardFailure].
DashboardFailure mapDashboardError(Object error) {
  if (error is DashboardFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return DashboardFailure.network;
  }
  if (error is supabase.PostgrestException &&
      (error.message == 'event_not_found' || error.code == '42501')) {
    return DashboardFailure.notFound;
  }
  // Pas de feuille ici : le tableau de bord s'actualise toutes les 15 s.
  if (error is supabase.PostgrestException &&
      error.message == 'billing_option_live_dashboard') {
    return DashboardFailure.notInPack;
  }
  return DashboardFailure.unknown;
}
