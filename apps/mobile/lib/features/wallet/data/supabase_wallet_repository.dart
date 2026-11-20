import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/wallet/domain/wallet.dart';

/// [WalletRepository] adossé aux fonctions de la migration 2700.
class SupabaseWalletRepository implements WalletRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  String _coverUrl(String path) =>
      _client.storage.from('event-covers').getPublicUrl(path);

  @override
  Future<List<WalletTicket>> mine() => _guard(() async {
    final rows = await _client
        .rpc<List<dynamic>>('my_tickets')
        .timeout(_timeout);
    return [
      for (final row in rows)
        WalletTicket.fromJson(
          Map<String, Object?>.from(row as Map),
          coverUrlOf: _coverUrl,
        ),
    ];
  });

  @override
  Future<String> claim(String token) => _guard(
    () => _client
        .rpc<String>('claim_ticket', params: {'p_qr_token': token.trim()})
        .timeout(_timeout),
  );

  @override
  Future<void> release(String ticketId) => _guard(() async {
    await _client
        .rpc<Object?>('release_ticket', params: {'p_ticket_id': ticketId})
        .timeout(_timeout);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapWalletError(error);
    }
  }
}

/// Traduit une erreur réseau ou PostgREST en [WalletFailure].
WalletFailure mapWalletError(Object error) {
  if (error is WalletFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return WalletFailure.network;
  }
  if (error is supabase.PostgrestException) {
    return switch (error.message) {
      'qr_invalid' => WalletFailure.invalidCode,
      'ticket_unknown' || 'ticket_not_found' => WalletFailure.unknown,
      'ticket_revoked' => WalletFailure.revoked,
      'ticket_claimed' => WalletFailure.claimed,
      _ => WalletFailure.other,
    };
  }
  return WalletFailure.other;
}
