import 'dart:async';

import 'package:ticketsur/features/notifications/domain/push.dart';

/// Service de notifications piloté par les tests.
class FakePushService implements PushService {
  new({this.granted = true, this.deviceToken = 'jeton-appareil-de-test-0001'});

  bool granted;
  String deviceToken;
  final Set<String> topics = {};
  final List<String> calls = [];
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<String>.broadcast();
  String? launchRoute;

  /// Simule un message reçu application ouverte.
  void receive(PushMessage message) => _foreground.add(message);

  /// Simule une notification touchée.
  void tap(String route) => _opened.add(route);

  @override
  Future<bool> start() async {
    calls.add('start');
    return granted;
  }

  @override
  Future<String?> token() async => deviceToken;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Future<void> subscribe(String topic) async {
    calls.add('subscribe $topic');
    topics.add(topic);
  }

  @override
  Future<void> unsubscribe(String topic) async {
    calls.add('unsubscribe $topic');
    topics.remove(topic);
  }

  @override
  Stream<PushMessage> get foreground => _foreground.stream;

  @override
  Stream<String> get opened => _opened.stream;

  @override
  Future<String?> initialRoute() async => launchRoute;

  @override
  Future<void> deleteToken() async => calls.add('deleteToken');
}

/// Enregistrement des appareils en mémoire.
class FakePushRepository implements PushRepository {
  final Set<String> registered = {};
  final List<String> calls = [];

  @override
  Future<void> register(String token) async {
    calls.add('register');
    registered.add(token);
  }

  @override
  Future<void> unregister(String token) async {
    calls.add('unregister');
    registered.remove(token);
  }
}
