import 'package:flutter/services.dart';
import 'package:ticketsur/features/ticket_send/domain/ticket_sender.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// [TicketSender] adossé au canal Android `ticketsur/send` (MainActivity).
class ChannelTicketSender implements TicketSender {
  const new([this._channel = const MethodChannel('ticketsur/send')]);

  final MethodChannel _channel;

  @override
  Future<SendOutcome> send({
    required DeliveryChannel channel,
    required TicketHolder holder,
    required String text,
    String? subject,
    SendAttachment? attachment,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>(channel.wireName, {
        'phone': holder.phone,
        'email': holder.email,
        'text': text,
        'subject': subject,
        'bytes': attachment?.bytes,
        'fileName': attachment?.name,
        'mimeType': attachment?.mimeType,
      });
      return switch (result) {
        'opened' => SendOutcome.opened,
        'app_missing' => SendOutcome.appMissing,
        _ => SendOutcome.failed,
      };
    } on PlatformException {
      return SendOutcome.failed;
    } on MissingPluginException {
      // Hors Android (tests, autres plateformes).
      return SendOutcome.appMissing;
    }
  }
}
