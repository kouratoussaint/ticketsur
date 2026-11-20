import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, NotifierProviderFamily;
import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/dashboard/domain/event_summary.dart';

/// Dépôt du tableau de bord (Supabase au démarrage, faux en test).
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => throw UnimplementedError(
    'dashboardRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Intervalle d'actualisation automatique pendant que l'écran est visible.
final dashboardRefreshIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 15),
);

/// État du tableau de bord : les derniers chiffres reçus et l'issue de la
/// dernière actualisation. Un échec ne remplace jamais les chiffres : ils
/// restent affichés, signalés comme non actualisés (DASH-03).
@immutable
final class DashboardState {
  const new({this.data, this.failure, this.loading = false});

  /// Derniers chiffres reçus du serveur.
  final EventDashboard? data;

  /// Échec de la dernière actualisation ; `null` si elle a réussi.
  final DashboardFailure? failure;

  /// Actualisation en cours.
  final bool loading;

  /// Chiffres affichés mais pas à jour.
  bool get stale => data != null && failure != null;
}

/// Tableau de bord d'un événement, actualisé à la demande.
class DashboardController extends Notifier<DashboardState> {
  new(this.eventId);

  final String eventId;

  bool _inFlight = false;

  @override
  DashboardState build() {
    unawaited(Future.microtask(refresh));
    return const DashboardState(loading: true);
  }

  /// Relit les chiffres. Sans effet si une lecture est déjà en cours.
  Future<void> refresh() async {
    if (_inFlight || !ref.mounted) return;
    _inFlight = true;
    final previous = state.data;
    state = DashboardState(
      data: previous,
      failure: state.failure,
      loading: true,
    );
    try {
      final data = await ref.read(dashboardRepositoryProvider).load(eventId);
      if (!ref.mounted) return;
      state = DashboardState(data: data);
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = DashboardState(
        data: previous,
        failure: error is DashboardFailure ? error : DashboardFailure.unknown,
      );
    } finally {
      _inFlight = false;
    }
  }
}

/// Tableau de bord d'un événement (organisateurs).
final NotifierProviderFamily<DashboardController, DashboardState, String>
dashboardProvider = NotifierProvider.autoDispose
    .family<DashboardController, DashboardState, String>(
      DashboardController.new,
    );

/// Bilan d'un événement : servi par le même dépôt que le tableau de bord.
final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  if (repository is SummaryRepository) return repository as SummaryRepository;
  throw UnimplementedError(
    'Le dépôt du tableau de bord ne fournit pas le bilan.',
  );
});

/// Bilan d'après-événement (propriétaires et gestionnaires).
final FutureProviderFamily<EventSummary, String> eventSummaryProvider =
    FutureProvider.autoDispose.family<EventSummary, String>(
      (ref, eventId) => ref.watch(summaryRepositoryProvider).summary(eventId),
      retry: (retryCount, error) => null,
    );
