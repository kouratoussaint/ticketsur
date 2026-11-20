import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';

import '../../helpers/fake_scan_repository.dart';

const _token = 'TS1.abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ';
const ScanPostKey _post = (eventId: 'e1', checkpointId: 'p1');

void main() {
  late FakeScanRepository server;
  late ProviderContainer container;
  late List<VerdictKind> feedback;
  var ids = 0;

  ScanSessionController session() =>
      container.read(scanSessionProvider(_post).notifier);
  ScanSessionState state() => container.read(scanSessionProvider(_post));

  setUp(() {
    server = FakeScanRepository();
    feedback = [];
    ids = 0;
    container =
        ProviderContainer(
            overrides: [
              scanRepositoryProvider.overrideWithValue(server),
              requestIdProvider.overrideWithValue(() => 'req-${++ids}'),
              scanRetryDelaysProvider.overrideWithValue(const [
                Duration.zero,
                Duration.zero,
              ]),
              scanFeedbackProvider.overrideWithValue(feedback.add),
            ],
          )
          // Garde le poste en vie pendant le test (fournisseur autoDispose).
          ..listen(scanSessionProvider(_post), (_, _) {});
  });

  tearDown(() => container.dispose());

  test('identifiant de requête : UUID v4', () {
    final id = newRequestId(Random(42));
    final uuidV4 = RegExp(
      '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
      r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(uuidV4.hasMatch(id), isTrue, reason: id);
    expect(newRequestId(), isNot(newRequestId()));
  });

  test('accepté : verdict vert, retour haptique, poste à réarmer', () async {
    server.script.add((id) => scanResponse(id, 'accepted', validationId: 'v1'));
    await session().submit(' $_token ');
    expect(server.tokens, [_token]);
    expect(state().phase, ScanPhase.verdict);
    expect(state().verdict!.kind, VerdictKind.admitted);
    expect(feedback, [VerdictKind.admitted]);
  });

  test('perte de réponse puis succès : MÊME request_id rejoué', () async {
    server.script
      ..add((_) => throw const ScanTransportException())
      ..add((id) => scanResponse(id, 'accepted', validationId: 'v1'));
    await session().submit(_token);
    expect(server.requestIds, ['req-1', 'req-1']);
    expect(state().verdict!.kind, VerdictKind.admitted);
  });

  test('serveur muet : « état à confirmer », jamais vert ; Réessayer '
      'rejoue la même requête', () async {
    await session().submit(_token);
    expect(server.requestIds, ['req-1', 'req-1', 'req-1']);
    expect(state().verdict!.result, ScanResult.unavailable);
    expect(state().verdict!.kind, VerdictKind.indeterminate);

    // Le serveur avait en fait enregistré l'entrée : il renvoie le même
    // résultat pour la même requête.
    server.script.add((id) => scanResponse(id, 'accepted', validationId: 'v1'));
    await session().retry();
    expect(server.requestIds.last, 'req-1');
    expect(state().verdict!.kind, VerdictKind.admitted);
  });

  test('« pending » : nouvel essai avec le même identifiant', () async {
    server.script
      ..add((id) => scanResponse(id, 'pending'))
      ..add(
        (id) => scanResponse(
          id,
          'already_used',
          firstValidatedAt: '2030-01-01T19:30:00Z',
        ),
      );
    await session().submit(_token);
    expect(server.requestIds, ['req-1', 'req-1']);
    expect(state().verdict!.result, ScanResult.alreadyUsed);
    expect(state().verdict!.kind, VerdictKind.refused);
  });

  test('réponse à une autre requête : jamais acceptée', () async {
    server.script.addAll([
      for (var i = 0; i < 3; i++)
        (_) => scanResponse('autre', 'accepted', validationId: 'v1'),
    ]);
    await session().submit(_token);
    expect(state().verdict!.kind, VerdictKind.indeterminate);
  });

  test('« accepted » sans validation_id : jamais vert', () async {
    server.script.addAll([
      for (var i = 0; i < 3; i++) (id) => scanResponse(id, 'accepted'),
    ]);
    await session().submit(_token);
    expect(state().verdict!.kind, VerdictKind.indeterminate);
  });

  test('code au mauvais format : refusé sans appel serveur', () async {
    await session().submit('https://exemple.com/faux-ticket');
    expect(server.requestIds, isEmpty);
    expect(state().verdict!.result, ScanResult.notFound);
    expect(state().verdict!.kind, VerdictKind.refused);
  });

  test('double lecture : code ignoré tant que le poste n’est pas réarmé, '
      'puis nouvelle requête', () async {
    server.script
      ..add((id) => scanResponse(id, 'accepted', validationId: 'v1'))
      ..add((id) => scanResponse(id, 'already_used'));
    await session().submit(_token);
    await session().submit(_token); // verdict affiché : ignoré
    expect(server.requestIds, ['req-1']);

    session().next();
    expect(state().phase, ScanPhase.ready);
    expect(state().scanned, 1);
    await session().submit(_token);
    expect(server.requestIds, ['req-1', 'req-2']);
    expect(state().verdict!.result, ScanResult.alreadyUsed);
    expect(state().scanned, 2);
    // Compteurs du poste : une entrée, un refus.
    expect(state().admitted, 1);
    expect(state().refused, 1);
  });

  test('refus serveur : pas de nouvel essai', () async {
    server.script.add((id) => scanResponse(id, 'revoked'));
    await session().submit(_token);
    expect(server.requestIds, ['req-1']);
    expect(state().verdict!.result, ScanResult.revoked);
    // Rien à rejouer après un verdict certain.
    await session().retry();
    expect(server.requestIds, ['req-1']);
  });
}
