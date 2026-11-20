import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ticketsur/features/updates/domain/update_checker.dart';

/// Dernière version pilote publiée sur GitHub (dépôt public, sans jeton).
class GitHubUpdateChecker implements UpdateChecker {
  const new();

  static final Uri _latest = Uri.https(
    'api.github.com',
    '/repos/kouratoussaint/ticketsur/releases/latest',
  );

  @override
  Future<int?> latestBuild() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(_latest);
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      return json is Map ? buildFromTag(json['tag_name']) : null;
    } on Object {
      return null;
    } finally {
      client.close();
    }
  }
}
