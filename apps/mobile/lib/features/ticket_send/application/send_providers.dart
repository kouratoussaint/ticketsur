import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/ticket_send/data/channel_ticket_sender.dart';
import 'package:ticketsur/features/ticket_send/domain/ticket_sender.dart';
import 'package:ticketsur/features/ticket_send/presentation/ticket_png.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ouverture des applications d'envoi (canal Android ; faux en test).
final ticketSenderProvider = Provider<TicketSender>(
  (ref) => const ChannelTicketSender(),
);

/// Rendu de l'image d'un ticket.
typedef TicketImageRenderer = Future<Uint8List> Function(
  BuildContext context, {
  required TicketEvent event,
  required TicketSecret ticket,
});

/// Rendu hors écran (remplacé en test : `toImage` n'avance pas sans moteur).
final ticketImageRendererProvider = Provider<TicketImageRenderer>(
  (ref) => renderTicketPng,
);

/// Message accompagnant le ticket (le jeton n'y figure jamais).
String ticketMessage(
  AppLocalizations l10n,
  TicketEvent event, {
  String? holderName,
  bool invitation = false,
}) {
  final date = pdfEventDates(event);
  final place = [?event.venue, ?event.city].join(', ');
  final placeText = place.isEmpty ? '' : ' — $place';
  return switch ((holderName, invitation)) {
    (null, false) => l10n.sendMessage(event.title, date, placeText),
    (final String name, false) => l10n.sendMessageNamed(
      name,
      event.title,
      date,
      placeText,
    ),
    (null, true) => l10n.invitationMessage(event.title, date, placeText),
    (final String name, true) => l10n.invitationMessageNamed(
      name,
      event.title,
      date,
      placeText,
    ),
  };
}

/// Prépare et ouvre l'envoi d'un ticket par [channel] : jeton relu si besoin
/// (ré-export audité), image (WhatsApp, SMS) ou PDF (e-mail) joint.
///
/// Rien n'est enregistré ici : l'envoi n'est consigné que lorsque
/// l'organisateur confirme qu'il est parti. Lève une [TicketFailure] si le
/// jeton ne peut pas être relu.
Future<SendOutcome> openTicketSend(
  BuildContext context,
  WidgetRef ref, {
  required TicketEvent event,
  required TicketSummary ticket,
  required DeliveryChannel channel,
}) async {
  final l10n = context.l10n;
  final secrets = await ref.read(ticketActionsProvider).ensureSecrets([
    ticket.id,
  ]);
  final known = secrets[ticket.id];
  if (known == null) throw TicketFailure.notSendable;
  final secret = TicketSecret(
    ticketId: known.ticketId,
    reference: known.reference,
    token: known.token,
    categoryName: known.categoryName,
    status: known.status,
    holderName: ticket.holder.name,
    isInvitation: known.isInvitation || ticket.isInvitation,
  );
  if (!context.mounted) return SendOutcome.failed;

  final SendAttachment attachment;
  if (channel == DeliveryChannel.email) {
    final pdf = await buildTicketsPdf(
      event: event,
      tickets: [secret],
      organizationName: ref.read(activeOrganizationProvider)?.name ?? '',
    );
    attachment = (
      bytes: pdf,
      name: '${_prefix(ticket)}-${ticket.reference}.pdf',
      mimeType: 'application/pdf',
    );
  } else {
    final png = await ref.read(ticketImageRendererProvider)(
      context,
      event: event,
      ticket: secret,
    );
    attachment = (
      bytes: png,
      name: '${_prefix(ticket)}-${ticket.reference}.png',
      mimeType: 'image/png',
    );
  }
  return await ref
      .read(ticketSenderProvider)
      .send(
        channel: channel,
        holder: ticket.holder,
        text: ticketMessage(
          l10n,
          event,
          holderName: ticket.holder.name,
          invitation: ticket.isInvitation,
        ),
        subject: ticket.isInvitation
            ? l10n.invitationSubject(event.title)
            : l10n.sendSubject(event.title),
        attachment: attachment,
      );
}

String _prefix(TicketSummary ticket) =>
    ticket.isInvitation ? 'Invitation' : 'Ticket';
