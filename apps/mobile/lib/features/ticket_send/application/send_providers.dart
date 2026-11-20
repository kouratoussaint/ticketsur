import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/brand_pdf.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/ticket_send/data/channel_ticket_sender.dart';
import 'package:ticketsur/features/ticket_send/domain/ticket_sender.dart';
import 'package:ticketsur/features/ticket_send/presentation/ticket_png.dart';
import 'package:ticketsur/features/ticket_templates/application/template_providers.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ouverture des applications d'envoi (canal Android ; faux en test).
final ticketSenderProvider = Provider<TicketSender>(
  (ref) => const ChannelTicketSender(),
);

/// Rendu de l'image d'un ticket avec le modèle de sa catégorie.
typedef TicketImageRenderer = Future<Uint8List> Function(
  BuildContext context, {
  required TicketArt art,
  required TicketSecret ticket,
});

/// Rendu hors écran (remplacé en test : `toImage` n'avance pas sans moteur).
final ticketImageRendererProvider = Provider<TicketImageRenderer>(
  (ref) => renderTicketPng,
);

/// Rendu du fond d'une catégorie pour le PDF (`null` : fond simple).
typedef TicketBackgroundRenderer = Future<Uint8List?> Function(
  BuildContext context, {
  required TicketArt art,
  required TicketTemplate template,
  required String categoryName,
  bool invitation,
});

/// Rendu hors écran des fonds (remplacé en test).
final ticketBackgroundRendererProvider = Provider<TicketBackgroundRenderer>(
  (ref) => renderTicketBackground,
);

/// PDF des [tickets] avec le modèle de leur catégorie : un fond rendu par
/// catégorie, QR et textes en vecteurs. [sheet] : planche A4 à découper.
Future<Uint8List> buildTicketsPdfFor(
  BuildContext context,
  WidgetRef ref, {
  required TicketEvent event,
  required List<TicketSecret> tickets,
  bool sheet = false,
}) async {
  final l10n = context.l10n;
  final render = ref.read(ticketBackgroundRendererProvider);
  final art = await loadTicketArt(ref, event, [
    for (final ticket in tickets) ticket.ticketId,
  ]);
  final backgrounds = <String, Uint8List>{};
  for (final ticket in tickets) {
    final key = ticketBackgroundKey(art, ticket);
    if (backgrounds.containsKey(key) || !context.mounted) continue;
    try {
      final png = await render(
        context,
        art: art,
        template: art.templateOfTicket(ticket.ticketId),
        categoryName: ticket.categoryName,
        invitation: ticket.isInvitation,
      );
      if (png != null) backgrounds[key] = png;
    } on Object {
      // Fond simple pour cette catégorie.
    }
  }
  final logo = await loadPdfLogo();
  return sheet
      ? await buildTicketsSheetPdf(
          event: event,
          tickets: tickets,
          organizationName: art.organizationName,
          logo: logo,
          art: art,
          backgrounds: backgrounds,
          numberText: l10n.ticketNumber,
          holderText: l10n.ticketCardHolder,
        )
      : await buildTicketsPdf(
          event: event,
          tickets: tickets,
          organizationName: art.organizationName,
          logo: logo,
          art: art,
          backgrounds: backgrounds,
          numberText: l10n.ticketNumber,
          holderText: l10n.ticketCardHolder,
        );
}

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
    final pdf = await buildTicketsPdfFor(
      context,
      ref,
      event: event,
      tickets: [secret],
    );
    attachment = (
      bytes: pdf,
      name: '${_prefix(ticket)}-${ticket.reference}.pdf',
      mimeType: 'application/pdf',
    );
  } else {
    final art = await loadTicketArt(ref, event, [secret.ticketId]);
    if (!context.mounted) return SendOutcome.failed;
    final png = await ref.read(ticketImageRendererProvider)(
      context,
      art: art,
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
