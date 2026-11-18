import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/auth/data/supabase_auth_repository.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';

void main() {
  group('mapAuthError', () {
    final cases = <String, (Object, AuthFailure)>{
      'mauvais identifiants (code)': (
        const supabase.AuthApiException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
        AuthFailure.invalidCredentials,
      ),
      'mauvais identifiants (ancien serveur, 400 sans code)': (
        const supabase.AuthException(
          'Invalid login credentials',
          statusCode: '400',
        ),
        AuthFailure.invalidCredentials,
      ),
      'e-mail non confirmé': (
        const supabase.AuthApiException(
          'Email not confirmed',
          statusCode: '400',
          code: 'email_not_confirmed',
        ),
        AuthFailure.emailNotConfirmed,
      ),
      'trop de requêtes (code)': (
        const supabase.AuthApiException(
          'Rate limit',
          statusCode: '429',
          code: 'over_request_rate_limit',
        ),
        AuthFailure.rateLimited,
      ),
      'trop d’e-mails envoyés': (
        const supabase.AuthApiException(
          'Rate limit',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
        AuthFailure.rateLimited,
      ),
      'HTTP 429 sans code': (
        const supabase.AuthException('Too many', statusCode: '429'),
        AuthFailure.rateLimited,
      ),
      'réseau (Supabase)': (
        supabase.AuthRetryableFetchException(message: 'offline'),
        AuthFailure.network,
      ),
      'réseau (socket)': (
        const SocketException('Failed host lookup'),
        AuthFailure.network,
      ),
      'délai dépassé': (TimeoutException('10 s'), AuthFailure.network),
      'erreur serveur 500': (
        const supabase.AuthException('Boom', statusCode: '500'),
        AuthFailure.unknown,
      ),
      'erreur quelconque': (StateError('?'), AuthFailure.unknown),
      'AuthFailure déjà traduite': (
        AuthFailure.rateLimited,
        AuthFailure.rateLimited,
      ),
    };
    for (final MapEntry(key: label, value: (error, expected))
        in cases.entries) {
      test(label, () => expect(mapAuthError(error), expected));
    }
  });

  test('le lien de réinitialisation utilise l’identifiant Android', () {
    expect(kPasswordResetRedirect, startsWith('com.ticketsur.fasosoft://'));
  });
}
