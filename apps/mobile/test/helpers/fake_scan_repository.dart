import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';

/// Poste de test : « Gala », porte « Entrée Nord », fenêtre ouverte.
ScanPost testPost({
  String eventId = 'e1',
  String checkpointId = 'p1',
  String eventTitle = 'Gala',
  String checkpointName = 'Entrée Nord',
}) {
  final now = DateTime.now().toUtc();
  return ScanPost(
    eventId: eventId,
    eventTitle: eventTitle,
    eventStatus: EventStatus.inProgress,
    timezone: 'Africa/Ouagadougou',
    startsAt: now.subtract(const Duration(hours: 1)),
    endsAt: now.add(const Duration(hours: 3)),
    scanOpensAt: now.subtract(const Duration(hours: 4)),
    scanClosesAt: now.add(const Duration(hours: 9)),
    organizationName: 'Nuits Sacrées',
    checkpointId: checkpointId,
    checkpointName: checkpointName,
  );
}

/// Réponse serveur `validate_scan` (version 1).
Map<String, Object?> scanResponse(
  String requestId,
  String result, {
  String? validationId,
  String? firstValidatedAt,
}) => {
  'version': 1,
  'request_id': requestId,
  'result': result,
  'validation_id': ?validationId,
  'ticket': {'public_reference': 'TS-AAAA-0001', 'category': 'VIP'},
  'first_validated_at': ?firstValidatedAt,
  'checkpoint_label': 'Entrée Nord',
  'server_time': DateTime.now().toUtc().toIso8601String(),
};

/// Faux serveur de contrôle. Chaque appel à [validate] consomme la réponse
/// suivante de [script] : une fonction qui reçoit l'identifiant de requête
/// et renvoie le JSON, ou lève (par exemple [ScanTransportException]).
class FakeScanRepository implements ScanRepository {
  new({List<ScanPost>? posts, List<RecentScan>? recent})
    : posts = [...?posts],
      recent = [...?recent];

  final List<ScanPost> posts;
  final List<RecentScan> recent;
  final List<Object? Function(String requestId)> script = [];

  /// Identifiants de requête reçus, dans l'ordre.
  final List<String> requestIds = [];

  /// Jetons reçus (pour vérifier ce qui part réellement au serveur).
  final List<String> tokens = [];

  @override
  Future<List<ScanPost>> myPosts() async => List.of(posts);

  @override
  Future<List<RecentScan>> recentScans() async => List.of(recent);

  @override
  Future<Object?> validate({
    required String requestId,
    required String eventId,
    required String checkpointId,
    required String token,
  }) async {
    requestIds.add(requestId);
    tokens.add(token);
    if (script.isEmpty) throw const ScanTransportException();
    return script.removeAt(0)(requestId);
  }
}
