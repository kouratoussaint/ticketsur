import 'package:flutter_test/flutter_test.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';

void main() {
  const requestId = '6dd6ae2c-8045-419b-81b9-de38b80f5417';

  /// Réponse réelle de `validate_scan` (capturée sur PostgreSQL 16).
  Map<String, Object?> accepted() => {
    'version': 1,
    'request_id': requestId,
    'result': 'accepted',
    'validation_id': 'd9918b77-e41c-4350-ab59-a9190592fe83',
    'ticket': {'public_reference': 'TS-UZEY-Q2HM', 'category': 'Standard'},
    'first_validated_at': '2026-11-18T13:16:52.472496+00:00',
    'checkpoint_label': 'Entrée principale',
    'server_time': '2026-11-18T13:16:52.472496+00:00',
  };

  group('ScanVerdict.fromServer', () {
    test('lit une acceptation complète', () {
      final verdict = ScanVerdict.fromServer(
        accepted(),
        expectedRequestId: requestId,
      );
      expect(verdict.result, ScanResult.accepted);
      expect(verdict.kind, VerdictKind.admitted);
      expect(verdict.publicReference, 'TS-UZEY-Q2HM');
      expect(verdict.category, 'Standard');
      expect(verdict.checkpointLabel, 'Entrée principale');
      expect(
        verdict.firstValidatedAt,
        DateTime.utc(2026, 11, 18, 13, 16, 52, 472, 496),
      );
      expect(verdict.firstValidatedAt!.isUtc, isTrue);
    });

    test('lit « déjà utilisé » avec l’heure du premier passage', () {
      final json = accepted()
        ..['result'] = 'already_used'
        ..remove('validation_id');
      final verdict = ScanVerdict.fromServer(
        json,
        expectedRequestId: requestId,
      );
      expect(verdict.result, ScanResult.alreadyUsed);
      expect(verdict.kind, VerdictKind.refused);
      expect(verdict.firstValidatedAt, isNotNull);
    });

    test('lit le compteur d’un pass (champ entries)', () {
      final verdict = ScanVerdict.fromServer(
        accepted()..['entries'] = {'policy': 'limited', 'used': 3, 'max': 3},
        expectedRequestId: requestId,
      );
      expect(verdict.kind, VerdictKind.admitted);
      expect(verdict.entries?.policy, EntryPolicy.limited);
      expect(verdict.entries?.used, 3);
      expect(verdict.entries?.exhausted, isTrue);
      final daily = ScanVerdict.fromServer(
        accepted()..['entries'] = {'policy': 'per_day', 'used': 2},
        expectedRequestId: requestId,
      );
      expect(daily.entries?.policy, EntryPolicy.perDay);
      expect(daily.entries?.max, isNull);
      expect(daily.entries?.exhausted, isFalse);
      // Entrée unique ou forme inattendue : pas de compteur, verdict intact.
      for (final odd in [
        null,
        'x',
        {'policy': 'single', 'used': 1},
        {'policy': 'per_day'},
      ]) {
        final plain = ScanVerdict.fromServer(
          accepted()..['entries'] = odd,
          expectedRequestId: requestId,
        );
        expect(plain.entries, isNull, reason: '$odd');
        expect(plain.kind, VerdictKind.admitted);
      }
    });

    test('connaît les 11 codes du contrat', () {
      expect(ScanResult.values.map((r) => r.wireName), [
        'accepted',
        'already_used',
        'revoked',
        'expired',
        'not_found',
        'wrong_event',
        'unauthorized',
        'event_inactive',
        'rate_limited',
        'pending',
        'unavailable',
      ]);
    });

    test('un seul code peut ouvrir la porte', () {
      final admitting = ScanResult.values.where(
        (r) => r.kind == VerdictKind.admitted,
      );
      expect(admitting, [ScanResult.accepted]);
    });

    test('rate_limited, pending et unavailable restent indéterminés', () {
      for (final r in [
        ScanResult.rateLimited,
        ScanResult.pending,
        ScanResult.unavailable,
      ]) {
        expect(r.kind, VerdictKind.indeterminate, reason: r.wireName);
      }
    });
  });

  group(
    'sûreté : toute réponse douteuse devient indéterminée, jamais verte',
    () {
      final cases = <String, Object?>{
        'réponse nulle': null,
        'réponse non JSON objet': 'accepted',
        'liste': [accepted()],
        'code inconnu': accepted()..['result'] = 'ok',
        'code absent': accepted()..remove('result'),
        'autre request_id': accepted()..['request_id'] = 'autre',
        'version future': accepted()..['version'] = 2,
        'version absente': accepted()..remove('version'),
        'accepted sans validation_id': accepted()..remove('validation_id'),
        'accepted avec validation_id vide': accepted()..['validation_id'] = '',
      };
      for (final MapEntry(key: label, value: json) in cases.entries) {
        test(label, () {
          final verdict = ScanVerdict.fromServer(
            json,
            expectedRequestId: requestId,
          );
          expect(verdict.result, ScanResult.unavailable);
          expect(verdict.kind, VerdictKind.indeterminate);
          expect(verdict.requestId, requestId);
        });
      }
    },
  );

  test('unauthorized sans session (réponse sans version) reste un refus', () {
    final verdict = ScanVerdict.fromServer({
      'request_id': requestId,
      'result': 'unauthorized',
    }, expectedRequestId: requestId);
    expect(verdict.result, ScanResult.unauthorized);
    expect(verdict.kind, VerdictKind.refused);
  });

  test('ScanVerdict.unavailable est indéterminé', () {
    const verdict = ScanVerdict.unavailable(requestId);
    expect(verdict.kind, VerdictKind.indeterminate);
    expect(verdict.validationId, isNull);
  });
}
