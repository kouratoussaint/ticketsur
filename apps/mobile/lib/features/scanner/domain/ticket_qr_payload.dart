import 'package:flutter/foundation.dart' show immutable;

/// Contenu d'un QR TicketSûr : `TS1.` suivi de 43 caractères base64url
/// (256 bits aléatoires générés par le serveur).
///
/// Le jeton est un secret au porteur : [toString] le masque pour qu'il ne
/// fuite jamais dans les journaux, les rapports de crash ou l'analytique.
@immutable
final class TicketQrPayload {
  const new _(this.token);

  static final RegExp _format = RegExp(r'^TS1\.[A-Za-z0-9_-]{43}$');

  /// Jeton complet, à n'envoyer qu'au serveur de validation.
  final String token;

  /// Retourne le jeton si [raw] a le format TicketSûr, sinon `null`.
  ///
  /// Un QR étranger (URL, Wi-Fi, autre billetterie) est écarté localement,
  /// sans appel réseau ; il ne produit jamais de verdict positif.
  static TicketQrPayload? tryParse(String? raw) {
    final value = raw?.trim();
    if (value == null || !_format.hasMatch(value)) return null;
    return TicketQrPayload._(value);
  }

  @override
  bool operator ==(Object other) =>
      other is TicketQrPayload && other.token == token;

  @override
  int get hashCode => token.hashCode;

  @override
  String toString() => 'TicketQrPayload(TS1.***)';
}
