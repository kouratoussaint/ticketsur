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
}

/// Demande l'envoi des notifications en attente (fonction Edge
/// `push-dispatch`). Sans effet si rien n'attend ; ne lève jamais.
Future<void> flushPushOutbox(supabase.SupabaseClient client) async {
  try {
    await client.functions
        .invoke('push-dispatch')
        .timeout(const Duration(seconds: 20));
  } on Object {
    // Les messages restent en file : envoyés au prochain appel.
  }
}
