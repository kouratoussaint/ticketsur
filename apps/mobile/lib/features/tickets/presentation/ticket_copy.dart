import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
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

/// Icône et couleur d'un statut (couleurs de verdict, contraste vérifié
/// sur fond clair).
({IconData icon, Color color}) ticketStatusStyle(TicketStatus status) =>
    switch (status) {
      TicketStatus.issued => (
        icon: Icons.confirmation_number_outlined,
        color: TicketSurColors.blueText,
      ),
      TicketStatus.redeemed => (
        icon: Icons.how_to_reg_rounded,
        color: TicketSurColors.successStrong,
      ),
      TicketStatus.revoked => (
        icon: Icons.block_rounded,
        color: const Color(0xFFB02A37),
      ),
      TicketStatus.expired => (
        icon: Icons.timer_off_outlined,
        color: const Color(0xFF52627A),
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
