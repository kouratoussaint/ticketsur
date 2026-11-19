import 'dart:async';

import 'package:ticketsur/features/dashboard/domain/event_dashboard.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';

/// Faux tableau de bord : renvoie [next] (ou lève [failure]) et compte les
/// appels. [gate] permet de retenir une réponse pour observer l'état
/// « actualisation en cours ».
class FakeDashboardRepository implements DashboardRepository {
  new({this.next, this.failure});

  EventDashboard? next;
  DashboardFailure? failure;
  Completer<void>? gate;
  final List<String> calls = [];

  @override
  Future<EventDashboard> load(String eventId) async {
    calls.add(eventId);
    if (gate case final gate?) await gate.future;
    if (failure case final failure?) throw failure;
    return next ?? sampleDashboard(eventId: eventId);
  }
}

/// Tableau de bord type : 2 catégories, 2 portes, 1 contrôleur, 3 tranches.
EventDashboard sampleDashboard({
  String eventId = 'evt-1',
  int admitted = 42,
  int issued = 120,
  bool windowOpen = true,
  DateTime? serverTime,
}) {
  final now = serverTime ?? DateTime.utc(2026, 11, 20, 20, 15, 7);
  return EventDashboard(
    eventId: eventId,
    serverTime: now,
    capacity: 150,
    scanOpensAt: windowOpen
        ? now.subtract(const Duration(hours: 2))
        : now.add(const Duration(hours: 2)),
    scanClosesAt: now.add(const Duration(hours: 6)),
    tickets: TicketCounts(
      issued: issued,
      admitted: admitted,
      remaining: issued - admitted,
      revoked: 3,
    ),
    scans: const ScanCounts(
      total: 50,
      accepted: 42,
      refused: 8,
      recentAccepted: 12,
      byOutcome: {ScanResult.alreadyUsed: 5, ScanResult.notFound: 3},
    ),
    categories: const [
      CategoryStats(
        id: 'cat-vip',
        name: 'VIP',
        capacity: 20,
        issued: 20,
        admitted: 15,
      ),
      CategoryStats(id: 'cat-std', name: 'Standard', issued: 100, admitted: 27),
    ],
    checkpoints: [
      CheckpointStats(
        id: 'cp-a',
        name: 'Porte A',
        admitted: 30,
        refused: 6,
        lastAt: now.subtract(const Duration(minutes: 1)),
      ),
      const CheckpointStats(
        id: 'cp-b',
        name: 'Porte B',
        active: false,
        admitted: 12,
        refused: 2,
      ),
    ],
    controllers: [
      ControllerStats(
        userId: 'user-ctrl',
        displayName: 'Awa',
        accepted: 42,
        refused: 8,
        lastAt: now.subtract(const Duration(minutes: 1)),
      ),
    ],
    stepMinutes: 15,
    timeline: [
      TimelineBucket(
        at: DateTime.utc(2026, 11, 20, 19, 45),
        accepted: 10,
        refused: 2,
      ),
      TimelineBucket(
        at: DateTime.utc(2026, 11, 20, 20),
        accepted: 20,
        refused: 4,
      ),
      TimelineBucket(
        at: DateTime.utc(2026, 11, 20, 20, 15),
        accepted: 12,
        refused: 2,
      ),
    ],
  );
}
