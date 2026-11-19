import 'dart:typed_data';

import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Issue de l'ouverture d'une application d'envoi.
enum SendOutcome {
  /// L'application est ouverte, prête à envoyer : l'organisateur appuie
  /// lui-même sur « Envoyer ». Rien n'est encore parti.
  opened,

  /// Aucune application installée pour ce canal.
  appMissing,

  /// Ouverture impossible.
  failed,
}

/// Pièce jointe d'un envoi.
typedef SendAttachment = ({Uint8List bytes, String name, String mimeType});

/// Ouvre WhatsApp, l'application SMS ou l'e-mail du téléphone, prérempli.
abstract interface class TicketSender {
  Future<SendOutcome> send({
    required DeliveryChannel channel,
    required TicketHolder holder,
    required String text,
    String? subject,
    SendAttachment? attachment,
  });
}
