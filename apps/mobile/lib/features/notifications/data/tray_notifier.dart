import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';

/// Notification dans la barre du téléphone quand l'app est ouverte
/// (Android ne l'affiche pas de lui-même au premier plan), ADR 0054.
abstract interface class TrayNotifier {
  /// Affiche [message] dans la barre ; faux si impossible (autorisation
  /// refusée, plateforme sans canal) : l'app montre alors son bandeau.
  Future<bool> show(PushMessage message);

  /// Pages des notifications touchées pendant que l'app tourne.
  Stream<String> get opened;

  /// Page d'une notification touchée qui a lancé l'app, une seule fois.
  Future<String?> launchRoute();
}

/// Canal natif `tikeo/notifications` (`MainActivity`).
class AndroidTrayNotifier implements TrayNotifier {
  new() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openRoute' && call.arguments is String) {
        _opened.add(call.arguments as String);
      }
      return null;
    });
  }

  static const _channel = MethodChannel('tikeo/notifications');
  final _opened = StreamController<String>.broadcast();

  @override
  Future<bool> show(PushMessage message) async {
    try {
      return await _channel.invokeMethod<bool>('notify', {
            'title': message.title,
            'body': message.body,
            'route': message.route,
            'tag': message.tag,
          }) ??
          false;
    } on Object {
      return false;
    }
  }

  @override
  Stream<String> get opened => _opened.stream.where(isSafePushRoute);

  @override
  Future<String?> launchRoute() async {
    try {
      final route = await _channel.invokeMethod<String>('launchRoute');
      return isSafePushRoute(route) ? route : null;
    } on Object {
      return null;
    }
  }
}

/// Sans barre de notification (tests, plateformes non Android).
class NoTrayNotifier implements TrayNotifier {
  const new();

  @override
  Future<bool> show(PushMessage message) async => false;

  @override
  Stream<String> get opened => const Stream.empty();

  @override
  Future<String?> launchRoute() async => null;
}
