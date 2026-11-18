import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Titre plein écran d'un verdict.
String verdictTitle(AppLocalizations l10n, VerdictKind kind) => switch (kind) {
  VerdictKind.admitted => l10n.verdictTitleAdmitted,
  VerdictKind.refused => l10n.verdictTitleRefused,
  VerdictKind.indeterminate => l10n.verdictTitleIndeterminate,
  VerdictKind.verifying => l10n.verdictVerifying,
};

/// Raison détaillée d'un verdict (libellés du cahier des charges, §7.5).
String verdictReason(AppLocalizations l10n, ScanResult result) =>
    switch (result) {
      ScanResult.accepted => l10n.verdictReasonAccepted,
      ScanResult.alreadyUsed => l10n.verdictReasonAlreadyUsed,
      ScanResult.revoked => l10n.verdictReasonRevoked,
      ScanResult.expired => l10n.verdictReasonExpired,
      ScanResult.notFound => l10n.verdictReasonNotFound,
      ScanResult.wrongEvent => l10n.verdictReasonWrongEvent,
      ScanResult.unauthorized => l10n.verdictReasonUnauthorized,
      ScanResult.eventInactive => l10n.verdictReasonEventInactive,
      ScanResult.rateLimited => l10n.verdictReasonRateLimited,
      ScanResult.pending => l10n.verdictReasonPending,
      ScanResult.unavailable => l10n.verdictReasonUnavailable,
    };

/// Heure `HH:mm` d'un instant UTC dans le fuseau de l'événement.
///
/// [eventUtcOffset] est le décalage du fuseau de l'événement à cet instant
/// (Africa/Ouagadougou : UTC+0, sans heure d'été). L'heure du téléphone n'est
/// jamais utilisée.
String formatEventTime(
  DateTime instant, {
  Duration eventUtcOffset = Duration.zero,
}) {
  final local = instant.toUtc().add(eventUtcOffset);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}
