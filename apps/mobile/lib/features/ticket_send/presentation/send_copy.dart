import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/ticket_send/domain/ticket_sender.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Nom d'un canal d'envoi.
String channelLabel(AppLocalizations l10n, DeliveryChannel channel) =>
    switch (channel) {
      DeliveryChannel.whatsapp => l10n.sendChannelWhatsApp,
      DeliveryChannel.sms => l10n.sendChannelSms,
      DeliveryChannel.email => l10n.sendChannelEmail,
    };

/// Icône d'un canal d'envoi.
IconData channelIcon(DeliveryChannel channel) => switch (channel) {
  DeliveryChannel.whatsapp => Icons.chat_rounded,
  DeliveryChannel.sms => Icons.sms_outlined,
  DeliveryChannel.email => Icons.alternate_email_rounded,
};

/// Message d'une ouverture qui n'a pas abouti (`null` si l'application
/// s'est ouverte).
String? sendOutcomeMessage(
  AppLocalizations l10n,
  DeliveryChannel channel,
  SendOutcome outcome,
) => switch (outcome) {
  SendOutcome.opened => null,
  SendOutcome.failed => l10n.sendFailed,
  SendOutcome.appMissing => switch (channel) {
    DeliveryChannel.whatsapp => l10n.sendMissingWhatsApp,
    DeliveryChannel.sms => l10n.sendMissingSms,
    DeliveryChannel.email => l10n.sendMissingEmail,
  },
};

/// Demande à l'organisateur, au retour de l'application d'envoi, si le
/// message est parti. Seule une réponse « oui » enregistre l'envoi.
Future<bool> confirmSent(BuildContext context, DeliveryChannel channel) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      icon: Icon(channelIcon(channel)),
      title: Text(l10n.sendConfirmTitle),
      content: Text(l10n.sendConfirmBody(channelLabel(l10n, channel))),
      actions: [
        TextButton(
          key: const Key('send-confirm-no'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.sendConfirmNo),
        ),
        FilledButton(
          key: const Key('send-confirm-yes'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.sendConfirmYes),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
