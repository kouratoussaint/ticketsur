import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';

/// Identifiants publics de l'application Firebase, passés par la CI
/// (`--dart-define-from-file`, tirés de google-services.json).
abstract final class FirebaseConfig {
  static const apiKey = String.fromEnvironment('TIKEO_FB_API_KEY');
  static const appId = String.fromEnvironment('TIKEO_FB_APP_ID');
  static const senderId = String.fromEnvironment('TIKEO_FB_SENDER_ID');
  static const projectId = String.fromEnvironment('TIKEO_FB_PROJECT_ID');

  static bool get configured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      senderId.isNotEmpty &&
      projectId.isNotEmpty;
}

/// [PushService] par Firebase Cloud Messaging.
class FirebasePushService implements PushService {
  new();

  FirebaseMessaging? _messaging;

  @override
  Future<bool> start() async {
    if (!FirebaseConfig.configured) return false;
    try {
      if (Firebase.apps.isEmpty) {
        try {
          // Application déjà démarrée par Android (ressources de l'APK).
          await Firebase.initializeApp();
        } on Object {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: FirebaseConfig.apiKey,
              appId: FirebaseConfig.appId,
              messagingSenderId: FirebaseConfig.senderId,
              projectId: FirebaseConfig.projectId,
            ),
          );
        }
      }
      final messaging = _messaging ??= FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } on Object {
      return false;
    }
  }

  // Jeton d'enregistrement FCM : la cible `token` de l'API HTTP v1 utilisée
  // par la fonction Edge. Les API « FID » (register/onRegistered) visent un
  // autre mode d'envoi ; on garde celui-ci, toujours pris en charge.
  @override
  Future<String?> token() async {
    try {
      // Jeton FCM voulu (voir plus haut), malgré la dépréciation.
      // ignore: deprecated_member_use
      return await _messaging?.getToken();
    } on Object {
      return null;
    }
  }

  @override
  Stream<String> get tokenRefresh =>
      // Rotation du jeton FCM (voir plus haut), malgré la dépréciation.
      // ignore: deprecated_member_use
      _messaging?.onTokenRefresh ?? const Stream.empty();

  @override
  Future<void> subscribe(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
    } on Object {
      // Réessayé au prochain démarrage.
    }
  }

  @override
  Future<void> unsubscribe(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
    } on Object {
      // Réessayé au prochain démarrage.
    }
  }

  static PushMessage _read(RemoteMessage message) => PushMessage(
    title: message.notification?.title ?? 'Tikéo',
    body: message.notification?.body ?? '',
    route: message.data['route'] as String?,
  );

  @override
  Stream<PushMessage> get foreground => _messaging == null
      ? const Stream.empty()
      : FirebaseMessaging.onMessage.map(_read);

  @override
  Stream<String> get opened => _messaging == null
      ? const Stream.empty()
      : FirebaseMessaging.onMessageOpenedApp
            .map((m) => m.data['route'] as String?)
            .where(isSafePushRoute)
            .cast<String>();

  @override
  Future<String?> initialRoute() async {
    try {
      final message = await _messaging?.getInitialMessage();
      final route = message?.data['route'] as String?;
      return isSafePushRoute(route) ? route : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      // Oubli du jeton FCM (voir plus haut), malgré la dépréciation.
      // ignore: deprecated_member_use
      await _messaging?.deleteToken();
    } on Object {
      // Sans réseau : le jeton sera oublié côté serveur au prochain envoi.
    }
  }
}
