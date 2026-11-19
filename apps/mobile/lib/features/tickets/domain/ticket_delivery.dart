import 'package:ticketsur/features/tickets/domain/ticket_holder.dart';

/// Canal d'envoi d'un ticket (côté serveur : `delivery_channel`).
enum DeliveryChannel {
  whatsapp('whatsapp'),
  sms('sms'),
  email('email');

  new(this.wireName);

  final String wireName;

  /// Canal correspondant à [value], `null` s'il est inconnu.
  static DeliveryChannel? fromWire(Object? value) {
    for (final channel in values) {
      if (channel.wireName == value) return channel;
    }
    return null;
  }

  /// Vrai si le titulaire a le moyen de contact qu'exige ce canal.
  bool reaches(TicketHolder holder) => switch (this) {
    DeliveryChannel.whatsapp || DeliveryChannel.sms => holder.phone != null,
    DeliveryChannel.email => holder.email != null,
  };
}

/// Dernier envoi confirmé d'un ticket.
typedef TicketDelivery = ({DeliveryChannel channel, DateTime at});
