import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/features/scanner/domain/ticket_qr_payload.dart';

/// Accès serveur du contrôle (Supabase au démarrage, faux en test).
final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => throw UnimplementedError(
    'scanRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Identifiant de requête : UUID v4 tiré d'un générateur cryptographique.
String newRequestId([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10).join()}';
}

/// Fabrique d'identifiants de requête (remplacée en test).
final requestIdProvider = Provider<String Function()>((ref) => newRequestId);

/// Attentes entre deux essais d'une même requête (remplacées en test).
final scanRetryDelaysProvider = Provider<List<Duration>>(
  (ref) => const [Duration(milliseconds: 600), Duration(milliseconds: 1500)],
);

/// Retour sonore et haptique selon le verdict (remplacé en test).
final scanFeedbackProvider = Provider<void Function(VerdictKind kind)>(
  (ref) => ref.read(feedbackProvider).verdict,
);

/// Postes de contrôle de l'utilisateur.
final FutureProvider<List<ScanPost>> scanPostsProvider =
    FutureProvider.autoDispose<List<ScanPost>>((ref) {
      // Changer d'organisation active peut changer les droits affichés.
      ref.watch(activeOrganizationProvider.select((o) => o?.id));
      return ref.read(scanRepositoryProvider).myPosts();
    }, retry: (retryCount, error) => null);

/// Scans récents de l'utilisateur.
final FutureProvider<List<RecentScan>> recentScansProvider =
    FutureProvider.autoDispose<List<RecentScan>>(
      (ref) => ref.read(scanRepositoryProvider).recentScans(),
      retry: (retryCount, error) => null,
    );

/// Étape du poste de scan.
enum ScanPhase {
  /// Prêt à recevoir un code.
  ready,

  /// Requête envoyée, verdict attendu.
  verifying,

  /// Verdict affiché ; « Suivant » réarme le poste.
  verdict,
}

/// État du poste de scan.
@immutable
final class ScanSessionState {
  const new({required this.phase, this.verdict, this.scanned = 0});

  final ScanPhase phase;
  final ScanVerdict? verdict;

  /// Nombre de verdicts rendus depuis l'ouverture du poste.
  final int scanned;
}

/// Requête en cours ou à rejouer (même identifiant).
typedef _ScanRequest = ({String requestId, String? token, String? ticketId});

/// Clé d'un poste : événement et porte.
typedef ScanPostKey = ({String eventId, String checkpointId});

/// Poste de scan : un code à la fois, réarmement explicite, rejeu
/// idempotent.
///
/// Règles de sûreté (§ 8, 12) :
/// - un code reçu pendant une vérification ou un verdict est ignoré ;
/// - sans réponse, la MÊME requête (même `request_id`) est rejouée ; le
///   serveur renvoie alors le résultat déjà enregistré, sans nouvelle entrée ;
/// - un résultat inconnu reste « vérification impossible », jamais vert ;
/// - un code au mauvais format n'est pas envoyé.
class ScanSessionController extends Notifier<ScanSessionState> {
  new(this.post);

  final ScanPostKey post;
  _ScanRequest? _pending;

  @override
  ScanSessionState build() => const ScanSessionState(phase: ScanPhase.ready);

  /// Code lu ou saisi. Ignoré si le poste n'est pas prêt.
  Future<void> submit(String rawCode) async {
    if (state.phase != ScanPhase.ready) return;
    final requestId = ref.read(requestIdProvider)();
    final payload = TicketQrPayload.tryParse(rawCode);
    if (payload == null) {
      _show(ScanVerdict(requestId: requestId, result: ScanResult.notFound));
      return;
    }
    _pending = (requestId: requestId, token: payload.token, ticketId: null);
    await _send();
  }

  /// Ticket choisi après une recherche à la porte (QR perdu) : validé par
  /// le serveur avec les mêmes règles que le scan.
  Future<void> submitTicket(String ticketId) async {
    if (state.phase != ScanPhase.ready) return;
    _pending = (
      requestId: ref.read(requestIdProvider)(),
      token: null,
      ticketId: ticketId,
    );
    await _send();
  }

  /// Rejoue la requête restée sans verdict certain (même identifiant).
  Future<void> retry() async {
    if (_pending == null || state.phase == ScanPhase.verifying) return;
    await _send();
  }

  /// Réarme le poste pour le ticket suivant.
  void next() {
    if (state.phase == ScanPhase.verifying) return;
    _pending = null;
    state = ScanSessionState(phase: ScanPhase.ready, scanned: state.scanned);
  }

  Future<void> _send() async {
    final request = _pending!;
    state = ScanSessionState(
      phase: ScanPhase.verifying,
      scanned: state.scanned,
    );
    final repository = ref.read(scanRepositoryProvider);
    final delays = ref.read(scanRetryDelaysProvider);
    var verdict = ScanVerdict.unavailable(request.requestId);
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      if (attempt > 0) await Future<void>.delayed(delays[attempt - 1]);
      try {
        final json = switch (request) {
          (:final ticketId?, token: _, requestId: _) =>
            await repository.validateTicket(
              requestId: request.requestId,
              eventId: post.eventId,
              checkpointId: post.checkpointId,
              ticketId: ticketId,
            ),
          _ => await repository.validate(
            requestId: request.requestId,
            eventId: post.eventId,
            checkpointId: post.checkpointId,
            token: request.token!,
          ),
        };
        verdict = ScanVerdict.fromServer(
          json,
          expectedRequestId: request.requestId,
        );
      } on ScanTransportException {
        verdict = ScanVerdict.unavailable(request.requestId);
      }
      if (!ref.mounted) return;
      // Seuls « en attente » et « injoignable » justifient un nouvel essai.
      if (verdict.result != ScanResult.pending &&
          verdict.result != ScanResult.unavailable) {
        break;
      }
    }
    if (verdict.kind != VerdictKind.indeterminate) _pending = null;
    _show(verdict);
  }

  void _show(ScanVerdict verdict) {
    ref.read(scanFeedbackProvider)(verdict.kind);
    state = ScanSessionState(
      phase: ScanPhase.verdict,
      verdict: verdict,
      scanned: state.scanned + 1,
    );
  }
}

/// Poste de scan pour un événement et une porte.
final NotifierProviderFamily<
  ScanSessionController,
  ScanSessionState,
  ScanPostKey
>
scanSessionProvider = NotifierProvider.autoDispose
    .family<ScanSessionController, ScanSessionState, ScanPostKey>(
      ScanSessionController.new,
    );
