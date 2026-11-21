import 'package:flutter/foundation.dart' show immutable;

/// Appareil qui s'inscrit (modèle, système, version de l'app).
@immutable
final class DeviceIdentity {
  const new({required this.label, required this.platform, this.appBuild});

  /// « Tecno Spark 10 » ; jamais de numéro de série ni d'identifiant.
  final String label;

  /// `android`, `ios` ou `other`.
  final String platform;
  final int? appBuild;
}

/// Appareil connecté au compte (une session Supabase Auth, migration 4300).
@immutable
final class ConnectedDevice {
  const new({
    required this.sessionId,
    required this.signedInAt,
    required this.lastSeenAt,
    this.label,
    this.platform,
    this.appBuild,
    this.current = false,
  });

  factory fromJson(Map<String, Object?> json) => ConnectedDevice(
    sessionId: json['session_id']! as String,
    label: json['label'] as String?,
    platform: json['platform'] as String?,
    appBuild: (json['app_build'] as num?)?.toInt(),
    signedInAt: DateTime.parse(json['signed_in_at']! as String).toUtc(),
    lastSeenAt: DateTime.parse(json['last_seen_at']! as String).toUtc(),
    current: json['current'] == true,
  );

  final String sessionId;

  /// Null : appareil qui ne s'est pas encore inscrit (ancienne version de
  /// l'app, navigateur…).
  final String? label;
  final String? platform;
  final int? appBuild;
  final DateTime signedInAt;
  final DateTime lastSeenAt;

  /// Appareil en cours d'utilisation.
  final bool current;
}

enum DeviceFailure implements Exception {
  /// Cet appareil a été déconnecté depuis un autre.
  sessionRevoked,

  /// Action impossible sur l'appareil en cours (utiliser « Se déconnecter »).
  current,

  /// Appareil introuvable ou déjà déconnecté.
  notFound,
  network,
  unknown,
}

/// Appareils connectés et déconnexion à distance (lot 4-6a, ADR 0031).
abstract interface class DeviceSecurityRepository {
  /// Inscrit ou rafraîchit l'appareil en cours ;
  /// [DeviceFailure.sessionRevoked] s'il a été déconnecté à distance.
  Future<void> register(DeviceIdentity device);

  /// Appareils connectés, celui en cours d'abord.
  Future<List<ConnectedDevice>> devices();

  /// Déconnecte un autre appareil.
  Future<void> revoke(String sessionId);

  /// Déconnecte tous les autres appareils ; renvoie leur nombre.
  Future<int> revokeOthers();
}

/// Verrouillage de l'app par l'empreinte ou le code du téléphone.
abstract interface class BiometricService {
  /// Le téléphone a une empreinte, un visage ou un code configuré.
  Future<bool> isAvailable();

  /// Demande l'empreinte (ou le code du téléphone) ; vrai si réussi.
  Future<bool> authenticate(String reason);
}
