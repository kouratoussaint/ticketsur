import 'package:flutter_test/flutter_test.dart';
import 'package:ticketsur/features/scanner/domain/ticket_qr_payload.dart';

void main() {
  const valid = 'TS1.Ab3_-xYz0123456789abcdefghijklmnopqrstuvwxy';

  group('TicketQrPayload.tryParse', () {
    test('accepte le format TS1 + 43 caractères base64url', () {
      expect(valid.length, 47);
      expect(TicketQrPayload.tryParse(valid)?.token, valid);
    });

    test('tolère les espaces autour du contenu', () {
      expect(TicketQrPayload.tryParse('  $valid\n')?.token, valid);
    });

    for (final (label, raw) in [
      ('null', null),
      ('vide', ''),
      ('URL', 'https://exemple.com/ticket/123'),
      ('mauvais préfixe', valid.replaceFirst('TS1.', 'TS2.')),
      ('trop court', valid.substring(0, 46)),
      ('trop long', '${valid}A'),
      ('caractère hors base64url', valid.replaceFirst('A', '+')),
      ('remplissage =', '${valid.substring(0, 46)}='),
    ]) {
      test('rejette : $label', () {
        expect(TicketQrPayload.tryParse(raw), isNull);
      });
    }
  });

  test('toString ne révèle jamais le jeton (journaux, crashs)', () {
    final payload = TicketQrPayload.tryParse(valid)!;
    expect(payload.toString(), isNot(contains(valid.substring(4))));
    expect('$payload', 'TicketQrPayload(TS1.***)');
  });

  test('égalité par valeur', () {
    expect(TicketQrPayload.tryParse(valid), TicketQrPayload.tryParse(valid));
  });
}
