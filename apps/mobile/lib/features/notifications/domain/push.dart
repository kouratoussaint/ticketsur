import 'package:flutter/foundation.dart';

/// Un message reçu pendant que l'application est ouverte.
@immutable
final class PushMessage {
  const new({
    required this.title,
    required this.body,
    this.route,
    this.id,
    this.tag,
  });

  final String title;
  final String body;

  /// Page à ouvrir (« /support/… », « /postes?… »).
  final String? route;

  /// Numéro du message dans la file du serveur (`outbox_id`), pour
  /// l'accusé de réception (ADR 0053).
  final String? id;

  /// Étiquette : les notifications d'un même événement se remplacent dans
  /// la barre du téléphone (ADR 0054).
  final String? tag;
}

/// Notifications du téléphone (Firebase Cloud Messaging), derrière une
/// interface : les tests et les APK sans configuration n'en ont pas.
abstract interface class PushService {
  /// Prépare le service et demande l'autorisation ; `false` si les
  /// notifications sont indisponibles ou refusées.
  Future<bool> start();

  /// Jeton de l'appareil (`null` sans service).
  Future<String?> token();

  /// Nouveaux jetons (rotation par Firebase).
  Stream<String> get tokenRefresh;

  Future<void> subscribe(String topic);

  Future<void> unsubscribe(String topic);

  /// Messages reçus application ouverte.
  Stream<PushMessage> get foreground;

  /// Pages des notifications touchées (application en arrière-plan).
  Stream<String> get opened;

  /// Page de la notification qui a lancé l'application, s'il y en a une.
  Future<String?> initialRoute();

  /// Coupe : oublie le jeton de l'appareil.
  Future<void> deleteToken();
}

/// Pas de notifications (tests, APK sans configuration Firebase).
class NoPushService implements PushService {
  const new();

  @override
  Future<bool> start() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Future<void> subscribe(String topic) async {}

  @override
  Future<void> unsubscribe(String topic) async {}

  @override
  Stream<PushMessage> get foreground => const Stream.empty();

  @override
  Stream<String> get opened => const Stream.empty();

  @override
  Future<String?> initialRoute() async => null;

  @override
  Future<void> deleteToken() async {}
}

/// Sujets Firebase par destinataire d'annonce (voir migration 2800).
enum PushTopic {
  visitors('tikeo_visitors'),
  users('tikeo_users'),
  promoters('tikeo_promoters'),
  controllers('tikeo_controllers');

  new(this.topic);

  final String topic;
}

/// Seules les pages internes connues peuvent être ouvertes depuis une
/// notification.
bool isSafePushRoute(String? route) =>
    route != null &&
    RegExp(
      r'^/(support/[0-9a-f-]{36}|postes(\?evenement=[0-9a-f-]{36})?|parametres|profil'
      '|portefeuille|mon-ticket/[0-9a-f-]{36}'
      '|evenement/[0-9a-f-]{36}|organisateur/[0-9a-f-]{36}'
      r'|facturation(/demande/[0-9a-f-]{36}|/factures/[0-9a-f-]{36})?)?$',
    ).hasMatch(route);

/// Pourquoi la notification de test n'a pas pu partir.
enum PushTestFailure { noDevice, rateLimited, network }

final class PushTestException implements Exception {
  const new(this.failure);

  final PushTestFailure failure;
}

/// Enregistrement des appareils (migration 2800) et notification de test
/// (migration 3000).
abstract interface class PushRepository {
  Future<void> register(String token);

  Future<void> unregister(String token);

  /// Met une notification de test en file pour les appareils du compte.
  /// Lève [PushTestException].
  Future<void> sendTest();

  /// Demande l'envoi des messages en attente, après [delay] côté serveur
  /// (le téléphone suspend l'application en arrière-plan) ; ne lève jamais.
  Future<void> flush({Duration delay = Duration.zero});

  /// Confirme la réception de messages sur l'appareil au jeton [token] ;
  /// renvoie le nombre d'accusés nouveaux.
  Future<int> acknowledge(List<int> ids, String token);
}
