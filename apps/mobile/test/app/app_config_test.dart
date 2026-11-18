import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticketsur/app/app_config.dart';

AppConfig _config(String url, String key) => AppConfig(
  environment: AppEnvironment.staging,
  supabaseUrl: url,
  supabasePublishableKey: key,
);

String _fakeJwt(String role) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'role': role})}.signature';
}

void main() {
  const url = 'https://exemple.supabase.co';

  test('accepte une clé publishable sur une URL HTTPS', () {
    expect(_config(url, 'sb_publishable_abc123').problem, isNull);
  });

  test('accepte une ancienne clé anon (JWT)', () {
    expect(_config(url, _fakeJwt('anon')).isUsable, isTrue);
  });

  for (final (label, config, problem) in [
    ('configuration vide', _config('', ''), 'Configuration Supabase absente'),
    (
      'URL non HTTPS',
      _config('http://exemple.supabase.co', 'sb_publishable_x'),
      "L'URL Supabase doit être en HTTPS",
    ),
    (
      'clé secrète moderne',
      _config(url, 'sb_secret_abc123'),
      "Clé secrète interdite dans l'application",
    ),
    (
      'ancienne clé service_role',
      _config(url, _fakeJwt('service_role')),
      "Clé secrète interdite dans l'application",
    ),
    (
      'clé fantaisiste',
      _config(url, 'motdepasse'),
      'Clé publishable Supabase invalide',
    ),
  ]) {
    test('refuse : $label', () {
      expect(config.problem, problem);
      expect(config.isUsable, isFalse);
    });
  }

  test(
    'les fichiers config/*.json ne contiennent que des valeurs publiques',
    () {
      final files = Directory('config')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'));
      expect(files, isNotEmpty);
      for (final file in files) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final config = AppConfig(
          environment: AppEnvironment.values.byName(
            json['TICKETSUR_ENV'] as String,
          ),
          supabaseUrl: json['SUPABASE_URL'] as String,
          supabasePublishableKey: json['SUPABASE_PUBLISHABLE_KEY'] as String,
        );
        expect(config.problem, isNull, reason: file.path);
        expect(
          json.keys,
          unorderedEquals([
            'TICKETSUR_ENV',
            'SUPABASE_URL',
            'SUPABASE_PUBLISHABLE_KEY',
          ]),
          reason: '${file.path} : aucune autre clé autorisée',
        );
      }
    },
  );
}
