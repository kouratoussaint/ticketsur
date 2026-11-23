import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/notifications/domain/push.dart';

/// [PushRepository] adossé aux fonctions de la migration 2800.
class SupabasePushRepository implements PushRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<void> register(String token) async {
    await _client
        .rpc<Object?>('register_push_device', params: {'p_token': token})
        .timeout(const Duration(seconds: 20));
  }

  @override
  Future<void> unregister(String token) async {
    await _client
        .rpc<Object?>('unregister_push_device', params: {'p_token': token})
        .timeout(const Duration(seconds: 20));
  }

  @override
  Future<void> sendTest() async {
    try {
      await _client
          .rpc<Object?>('send_test_push')
          .timeout(const Duration(seconds: 20));
    } on supabase.PostgrestException catch (error) {
      throw PushTestException(switch (error.message) {
        'push_no_device' => PushTestFailure.noDevice,
        'push_test_rate_limited' => PushTestFailure.rateLimited,
        _ => PushTestFailure.network,
      });
    } on Object {
      throw const PushTestException(PushTestFailure.network);
    }
  }

  @override
  Future<int> acknowledge(List<int> ids, String token) async {
    final count = await _client
        .rpc<int>('push_ack', params: {'p_ids': ids, 'p_token': token})
        .timeout(const Duration(seconds: 20));
    return count;
  }

  @override
  Future<void> flush({Duration delay = Duration.zero}) =>
      flushPushOutbox(_client, delay: delay);
}

/// Demande l'envoi des notifications en attente (fonction Edge
/// `push-dispatch`). Sans effet si rien n'attend ; ne lève jamais.
Future<void> flushPushOutbox(
  supabase.SupabaseClient client, {
  Duration delay = Duration.zero,
}) async {
  try {
    await client.functions
        .invoke(
          'push-dispatch',
          body: {if (delay > Duration.zero) 'delay_seconds': delay.inSeconds},
        )
        .timeout(const Duration(seconds: 30));
  } on Object {
    // Les messages restent en file : envoyés au prochain appel.
  }
}
