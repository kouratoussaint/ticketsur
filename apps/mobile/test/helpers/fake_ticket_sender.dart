import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/ticket_send/domain/ticket_sender.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Ouverture d'une application d'envoi, telle que demandée.
typedef SentRequest = ({
  DeliveryChannel channel,
  TicketHolder holder,
  String text,
  String? subject,
  SendAttachment? attachment,
});

/// Faux canal d'envoi : note chaque demande et renvoie [outcome].
class FakeTicketSender implements TicketSender {
  SendOutcome outcome = SendOutcome.opened;
  final List<SentRequest> requests = [];

  @override
  Future<SendOutcome> send({
    required DeliveryChannel channel,
    required TicketHolder holder,
    required String text,
    String? subject,
    SendAttachment? attachment,
  }) async {
    requests.add((
      channel: channel,
      holder: holder,
      text: text,
      subject: subject,
      attachment: attachment,
    ));
    return outcome;
  }
}

/// Faux rendu d'image : quelques octets PNG, et la liste des tickets rendus.
class FakeTicketRenderer {
  final List<String> rendered = [];

  /// Modèle utilisé pour chaque rendu.
  final List<TicketTemplate> templates = [];

  Future<Uint8List> call(
    BuildContext context, {
    required TicketArt art,
    required TicketSecret ticket,
  }) async {
    rendered.add('${ticket.reference}:${ticket.holderName ?? '-'}');
    templates.add(art.templateOfTicket(ticket.ticketId));
    return Uint8List.fromList(const [0x89, 0x50, 0x4E, 0x47]);
  }
}
