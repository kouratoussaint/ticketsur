import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/l10n/gen/app_localizations.dart';

/// Libellé d'un statut de ticket.
String ticketStatusLabel(AppLocalizations l10n, TicketStatus status) =>
    switch (status) {
      TicketStatus.issued => l10n.ticketStatusIssued,
      TicketStatus.redeemed => l10n.ticketStatusRedeemed,
      TicketStatus.revoked => l10n.ticketStatusRevoked,
      TicketStatus.expired => l10n.ticketStatusExpired,
    };

/// Icône et couleur d'un statut, lisibles sur les surfaces du thème
/// (clair ou sombre).
({IconData icon, Color color}) ticketStatusStyle(
  TicketStatus status,
  TicketSurPalette palette,
) => switch (status) {
  TicketStatus.issued => (
    icon: Icons.confirmation_number_outlined,
    color: palette.accentText,
  ),
  TicketStatus.redeemed => (
    icon: Icons.how_to_reg_rounded,
    color: palette.successText,
  ),
  TicketStatus.revoked => (
    icon: Icons.block_rounded,
    color: palette.dangerText,
  ),
  TicketStatus.expired => (
    icon: Icons.timer_off_outlined,
    color: palette.mutedText,
  ),
};

/// Message d'un échec.
String ticketFailureMessage(AppLocalizations l10n, TicketFailure failure) =>
    switch (failure) {
      TicketFailure.notFound => l10n.ticketErrorNotFound,
      TicketFailure.eventNotPublished => l10n.ticketErrorNotPublished,
      TicketFailure.categoryCapacityExceeded =>
        l10n.ticketErrorCategoryCapacity,
      TicketFailure.eventCapacityExceeded => l10n.ticketErrorEventCapacity,
      TicketFailure.invalid => l10n.ticketErrorInvalid,
      TicketFailure.holderNameInvalid => l10n.holderErrorName,
      TicketFailure.holderPhoneInvalid => l10n.holderErrorPhone,
      TicketFailure.holderEmailInvalid => l10n.holderErrorEmail,
      TicketFailure.notEditable => l10n.ticketErrorNotEditable,
      TicketFailure.notSendable => l10n.ticketErrorNotSendable,
      TicketFailure.network => l10n.eventErrorNetwork,
      TicketFailure.unknown => l10n.eventErrorUnknown,
    };

/// Message d'une erreur de saisie du titulaire.
String holderProblemMessage(AppLocalizations l10n, HolderProblem problem) =>
    switch (problem) {
      HolderProblem.nameTooLong => l10n.holderErrorName,
      HolderProblem.phoneInvalid => l10n.holderErrorPhone,
      HolderProblem.emailInvalid => l10n.holderErrorEmail,
    };
