import 'dart:async';

import 'package:ticketsur/features/notifications/data/tray_notifier.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';

/// Service de notifications piloté par les tests.
class FakePushService implements PushService {
  new({this.granted = true, this.deviceToken = 'appareil-de-test'});

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

  /// Échec simulé de la notification de test.
  PushTestFailure? testFailure;

  @override
  Future<void> sendTest() async {
    if (testFailure case final failure?) throw PushTestException(failure);
    calls.add('sendTest');
  }

  /// Accusés de réception envoyés : (numéros, jeton).
  final List<(List<int>, String)> acks = [];

  @override
  Future<int> acknowledge(List<int> ids, String token) async {
    acks.add((ids, token));
    return ids.length;
  }

  @override
  Future<void> flush({Duration delay = Duration.zero}) async =>
      calls.add(delay == Duration.zero ? 'flush' : 'flush ${delay.inSeconds}s');
}

/// Barre de notification simulée : [shown] note les messages ; [tap]
/// simule une notification touchée.
class FakeTrayNotifier implements TrayNotifier {
  final List<PushMessage> shown = [];
  final _opened = StreamController<String>.broadcast();

  void tap(String route) => _opened.add(route);

  @override
  Future<bool> show(PushMessage message) async {
    shown.add(message);
    return true;
  }

  @override
  Stream<String> get opened => _opened.stream;

  @override
  Future<String?> launchRoute() async => null;
}
