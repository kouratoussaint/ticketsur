import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/ticket_send/application/send_providers.dart';
import 'package:ticketsur/features/ticket_templates/application/template_providers.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Partage des tickets en PDF : un par page au format du modèle, ou
/// planche A4 à imprimer et découper ([sheet]).
Future<void> shareTicketsPdf(
  BuildContext context,
  WidgetRef ref, {
  required TicketEvent event,
  required List<TicketSecret> tickets,
  bool sheet = false,
}) async {
  final l10n = context.l10n;
  final share = ref.read(shareFilesProvider);
  final bytes = await buildTicketsPdfFor(
    context,
    ref,
    event: event,
    tickets: tickets,
    sheet: sheet,
  );
  final invitations = tickets.every((t) => t.isInvitation);
  final name = sheet
      ? 'Planche-${tickets.length}.pdf'
      : switch ((tickets.length, invitations)) {
          (1, true) => 'Invitation-${tickets.single.reference}.pdf',
          (1, false) => 'Ticket-${tickets.single.reference}.pdf',
          (final n, true) => 'Invitations-$n.pdf',
          (final n, false) => 'Tickets-$n.pdf',
        };
  await share([
    (bytes: bytes, name: name, mimeType: 'application/pdf'),
  ], text: shareText(l10n, event, invitation: invitations));
}

/// Partage du ticket en image PNG, avec le modèle de sa catégorie.
Future<void> shareTicketImage(
  BuildContext context,
  WidgetRef ref, {
  required TicketEvent event,
  required TicketSecret ticket,
}) async {
  final l10n = context.l10n;
  final share = ref.read(shareFilesProvider);
  final render = ref.read(ticketImageRendererProvider);
  final art = await loadTicketArt(ref, event, [ticket.ticketId]);
  if (!context.mounted) return;
  final bytes = await render(context, art: art, ticket: ticket);
  final invitation = ticket.isInvitation;
  await share([
    (
      bytes: bytes,
      name: '${invitation ? 'Invitation' : 'Ticket'}-${ticket.reference}.png',
      mimeType: 'image/png',
    ),
  ], text: shareText(l10n, event, invitation: invitation));
}

/// Texte accompagnant un ticket (ou une invitation) partagé.
String shareText(
  AppLocalizations l10n,
  TicketEvent event, {
  bool invitation = false,
}) => invitation
    ? l10n.invitationShareText(event.title)
    : l10n.ticketShareText(event.title);
