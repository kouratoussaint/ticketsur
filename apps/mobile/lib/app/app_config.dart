import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;

/// Environnement d'exécution de l'application.
enum AppEnvironment {
  /// Développement local.
  development,

  /// Projet Supabase de staging (données factices).
  staging,

  /// Production.
  production,
}

/// Configuration publique de l'application, fournie à la compilation :
/// `flutter run --dart-define-from-file=config/staging.json`.
///
/// Ne contient que des valeurs publiques par nature (URL du projet et clé
/// publishable). Une clé secrète (`sb_secret_…`, `service_role`) est refusée :
/// elle donnerait à quiconque décompile l'APK un accès sans RLS.
@immutable
final class AppConfig {
  /// Crée une configuration (préférer [AppConfig.fromEnvironment]).
  const new({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  /// Lit les valeurs passées par `--dart-define(-from-file)`.
  factory fromEnvironment() => AppConfig(
    environment: AppEnvironment.values.firstWhere(
      (e) => e.name == const String.fromEnvironment('TICKETSUR_ENV'),
      orElse: () => AppEnvironment.development,
    ),
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
  );

  /// Environnement ciblé.
  final AppEnvironment environment;

  /// URL HTTPS du projet Supabase.
  final String supabaseUrl;

  /// Clé publishable du projet.
  final String supabasePublishableKey;

  /// Problème bloquant de configuration, ou `null` si elle est utilisable.
  String? get problem {
    final key = supabasePublishableKey;
    if (supabaseUrl.isEmpty || key.isEmpty) {
      return 'Configuration Supabase absente';
    }
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return "L'URL Supabase doit être en HTTPS";
    }
    if (key.startsWith('sb_secret_') || _isServiceRoleJwt(key)) {
      return "Clé secrète interdite dans l'application";
    }
    if (!key.startsWith('sb_publishable_') && !key.startsWith('eyJ')) {
      return 'Clé publishable Supabase invalide';
    }
    return null;
  }

  /// Vrai si la configuration permet de joindre Supabase.
  bool get isUsable => problem == null;

  /// Détecte une ancienne clé JWT `service_role` (sans vérifier la signature).
  static bool _isServiceRoleJwt(String key) {
    final parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      return claims is Map && claims['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}
