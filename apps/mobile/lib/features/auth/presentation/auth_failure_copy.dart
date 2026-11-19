import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Message affiché pour une [AuthFailure].
String authFailureMessage(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure) {
      AuthFailure.invalidCredentials => l10n.authErrorInvalidCredentials,
      AuthFailure.emailNotConfirmed => l10n.authErrorEmailNotConfirmed,
      AuthFailure.rateLimited => l10n.authErrorRateLimited,
      AuthFailure.network => l10n.authErrorNetwork,
      AuthFailure.weakPassword => l10n.authErrorWeakPassword,
      AuthFailure.samePassword => l10n.authErrorSamePassword,
      AuthFailure.emailTaken => l10n.authErrorEmailTaken,
      AuthFailure.unknown => l10n.authErrorUnknown,
    };

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Validation locale d'une adresse e-mail (le serveur reste l'autorité).
String? validateEmail(AppLocalizations l10n, String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.validationEmailRequired;
  if (!_emailPattern.hasMatch(email)) return l10n.validationEmailInvalid;
  return null;
}
