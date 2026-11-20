import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/team/domain/team.dart';
import 'package:ticketsur/l10n/gen/app_localizations.dart';

/// Message d'un échec de gestion d'équipe.
String teamFailureMessage(AppLocalizations l10n, TeamFailure failure) =>
    switch (failure) {
      TeamFailure.forbidden => l10n.teamErrorForbidden,
      TeamFailure.invalid => l10n.teamErrorInvalid,
      TeamFailure.memberNotFound => l10n.teamErrorMemberNotFound,
      TeamFailure.isOwner => l10n.teamErrorIsOwner,
      TeamFailure.isSelf => l10n.teamErrorIsSelf,
      TeamFailure.checkpointNotFound => l10n.teamErrorCheckpoint,
      TeamFailure.locked => l10n.setupErrorLocked,
      TeamFailure.network => l10n.eventErrorNetwork,
      TeamFailure.unknown => l10n.eventErrorUnknown,
    };

/// Message d'une saisie de code refusée.
String joinResultMessage(AppLocalizations l10n, JoinResult result) =>
    switch (result) {
      JoinResult.joined => '',
      JoinResult.invalid => l10n.joinInvalid,
      JoinResult.expired => l10n.joinExpired,
      JoinResult.alreadyMember => l10n.joinAlreadyMember,
      JoinResult.rateLimited => l10n.joinRateLimited,
      JoinResult.unauthorized => l10n.joinUnauthorized,
    };

/// Date et heure locales : « 25 nov. 2026 à 19:30 ».
String formatLocalDateTime(DateTime instant) =>
    formatDateAtTime(instant.toLocal());

/// Initiale affichée dans l'avatar.
String initialOf(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty
      ? '?'
      : String.fromCharCode(trimmed.runes.first).toUpperCase();
}
