import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

/// Service de notifications ; Firebase dans `main.dart` quand l'APK est
/// configurée, rien sinon (et dans les tests).
final pushServiceProvider = Provider<PushService>(
  (ref) => const NoPushService(),
);

/// Enregistrement des appareils ; surchargé dans `main.dart` et les tests.
final pushRepositoryProvider = Provider<PushRepository>(
  (ref) => throw UnimplementedError(
    'pushRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

const pushEnabledKey = 'notifications.enabled';
const _tokenKey = 'notifications.token';
const _topicsKey = 'notifications.topics';

/// Réglage « Recevoir les notifications » (oui par défaut).
class PushEnabled extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(pushEnabledKey) ?? true;

  Future<void> set({required bool enabled}) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(pushEnabledKey, enabled);
  }
}

final NotifierProvider<PushEnabled, bool> pushEnabledProvider =
    NotifierProvider<PushEnabled, bool>(PushEnabled.new);

/// Sujets d'annonces de l'appareil, comme `private.my_audiences()` :
/// visiteur sans compte ; sinon promoteur et/ou contrôleur selon les rôles ;
/// compte classique à défaut.
Set<PushTopic> pushTopicsFor({
  required bool signedIn,
  required List<Organization> organizations,
}) {
  if (!signedIn) return {PushTopic.visitors};
  final topics = <PushTopic>{
    for (final o in organizations)
      if (o.role == MemberRole.controller)
        PushTopic.controllers
      else
        PushTopic.promoters,
  };
  return topics.isEmpty ? {PushTopic.users} : topics;
}

/// État des notifications de l'appareil.
enum PushStatus {
  /// APK sans notifications (développement, configuration absente).
  unavailable,

  /// Coupées dans les Paramètres.
  disabled,

  /// Refusées dans les réglages du téléphone.
  denied,

  /// Actives.
  active,
}

/// Abonne l'appareil aux seuls sujets [wanted] (diff mémorisé sur
/// l'appareil, pour ne pas rappeler Firebase à chaque reconstruction).
Future<void> applyPushTopics(Ref ref, Set<PushTopic> wanted) async {
  final service = ref.read(pushServiceProvider);
  final preferences = ref.read(sharedPreferencesProvider);
  final previous = {...?preferences.getStringList(_topicsKey)};
  for (final topic in PushTopic.values) {
    final want = wanted.contains(topic);
    final had = previous.contains(topic.topic);
    if (want && !had) await service.subscribe(topic.topic);
    if (!want && had) await service.unsubscribe(topic.topic);
  }
  await preferences.setStringList(_topicsKey, [
    for (final t in wanted) t.topic,
  ]);
}

/// Synchronise l'appareil : autorisation, jeton enregistré pour le compte,
/// sujet des visiteurs sans compte. Les sujets d'un compte connecté
/// dépendent de ses structures : voir [pushTopicsProvider], tenu par la
/// coque connectée (la liste des structures ne doit pas survivre à la
/// déconnexion).
class PushSync extends AsyncNotifier<PushStatus> {
  StreamSubscription<String>? _refresh;

  @override
  Future<PushStatus> build() async {
    ref.onDispose(() => unawaited(_refresh?.cancel()));
    final service = ref.read(pushServiceProvider);
    final enabled = ref.watch(pushEnabledProvider);
    final user = ref.watch(currentUserProvider).value;

    final available = await service.start();
    if (!available) {
      return service is NoPushService
          ? PushStatus.unavailable
          : enabled
          ? PushStatus.denied
          : PushStatus.disabled;
    }
    if (!enabled) {
      await applyPushTopics(ref, const {});
      await _forget();
      await service.deleteToken();
      return PushStatus.disabled;
    }
    if (user == null) {
      await applyPushTopics(ref, const {PushTopic.visitors});
      return PushStatus.active;
    }
    if (await service.token() case final token?) await _register(token);
    await _refresh?.cancel();
    _refresh = service.tokenRefresh.listen((t) => unawaited(_register(t)));
    return PushStatus.active;
  }

  Future<void> _register(String token) async {
    try {
      await ref.read(pushRepositoryProvider).register(token);
      await ref.read(sharedPreferencesProvider).setString(_tokenKey, token);
    } on Object {
      // Réessayé au prochain démarrage.
    }
  }

  Future<void> _forget() async {
    final preferences = ref.read(sharedPreferencesProvider);
    final token = preferences.getString(_tokenKey);
    if (token == null) return;
    try {
      await ref.read(pushRepositoryProvider).unregister(token);
    } on Object {
      // Le serveur oubliera le jeton au premier envoi refusé.
    }
    await preferences.remove(_tokenKey);
  }

  /// Avant la déconnexion : l'appareil ne reçoit plus les messages du compte.
  Future<void> beforeSignOut() => _forget();
}

final AsyncNotifierProvider<PushSync, PushStatus> pushSyncProvider =
    AsyncNotifierProvider<PushSync, PushStatus>(PushSync.new);

/// Sujets d'annonces d'un compte connecté, selon ses structures. Tenu par
/// la coque connectée (`AppShell`), libéré avec elle à la déconnexion.
final FutureProvider<void> pushTopicsProvider =
    FutureProvider.autoDispose<void>((ref) async {
      final status = await ref.watch(pushSyncProvider.future);
      if (status != PushStatus.active) return;
      if (ref.watch(currentUserProvider).value == null) return;
      final organizations = ref.watch(organizationsProvider).value;
      if (organizations == null) return;
      await applyPushTopics(
        ref,
        pushTopicsFor(signedIn: true, organizations: organizations.all),
      );
    });
