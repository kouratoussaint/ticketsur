import 'package:ticketsur/design_system/verdict_colors.dart';

/// Codes de verdict du contrat `validate_scan` (version 1).
enum ScanResult {
  /// Entrée autorisée, billet consommé par CETTE requête.
  accepted('accepted', VerdictKind.admitted),

  /// Billet déjà consommé par une validation antérieure.
  alreadyUsed('already_used', VerdictKind.refused),

  /// Billet annulé par l'organisateur.
  revoked('revoked', VerdictKind.refused),

  /// Billet expiré.
  expired('expired', VerdictKind.refused),

  /// Jeton inconnu.
  notFound('not_found', VerdictKind.refused),

  /// Billet d'un autre événement.
  wrongEvent('wrong_event', VerdictKind.refused),

  /// Agent non autorisé pour cet événement ou cette porte.
  unauthorized('unauthorized', VerdictKind.refused),

  /// Événement fermé au contrôle.
  eventInactive('event_inactive', VerdictKind.refused),

  /// Trop de tentatives : aucun verdict positif.
  rateLimited('rate_limited', VerdictKind.indeterminate),

  /// Résultat encore inconnu : rejouer la même requête.
  pending('pending', VerdictKind.indeterminate),

  /// Serveur injoignable ou réponse inexploitable (produit par le mobile).
  unavailable('unavailable', VerdictKind.indeterminate);

  new(this.wireName, this.kind);

  /// Valeur transmise par le serveur.
  final String wireName;

  /// Nature du verdict pour l'agent.
  final VerdictKind kind;

  /// Retrouve un code à partir de sa valeur serveur, `null` si inconnue.
  static ScanResult? fromWire(Object? value) {
    for (final result in values) {
      if (result.wireName == value) return result;
    }
    return null;
  }
}

/// Verdict d'un scan tel que l'application l'affiche.
///
/// Règle de sûreté : seul un `accepted` valide, de version connue, portant un
/// `validation_id` et répondant à la bonne `request_id` peut devenir
/// [VerdictKind.admitted]. Toute autre réponse inattendue devient
/// [ScanResult.unavailable], donc indéterminée — jamais verte.
final class ScanVerdict {
  /// Crée un verdict (préférer [ScanVerdict.fromServer]).
  const new({
    required this.requestId,
    required this.result,
    this.validationId,
    this.publicReference,
    this.category,
    this.firstValidatedAt,
    this.checkpointLabel,
    this.serverTime,
  });

  /// Verdict produit localement quand le serveur ne répond pas.
  const new unavailable(this.requestId)
    : result = ScanResult.unavailable,
      validationId = null,
      publicReference = null,
      category = null,
      firstValidatedAt = null,
      checkpointLabel = null,
      serverTime = null;

  /// Interprète la réponse JSON de `validate_scan`.
  factory fromServer(Object? json, {required String expectedRequestId}) {
    if (json is! Map<String, Object?>) {
      return ScanVerdict.unavailable(expectedRequestId);
    }
    final result = ScanResult.fromWire(json['result']);
    final sameRequest = json['request_id'] == expectedRequestId;
    // `unauthorized` sans session est renvoyé sans numéro de version.
    final knownVersion =
        json['version'] == supportedVersion ||
        (json['version'] == null && result == ScanResult.unauthorized);
    if (result == null || !sameRequest || !knownVersion) {
      return ScanVerdict.unavailable(expectedRequestId);
    }

    final validationId = _string(json['validation_id']);
    if (result == ScanResult.accepted && validationId == null) {
      return ScanVerdict.unavailable(expectedRequestId);
    }

    final ticket = json['ticket'];
    final ticketMap = ticket is Map<String, Object?> ? ticket : null;
    return ScanVerdict(
      requestId: expectedRequestId,
      result: result,
      validationId: validationId,
      publicReference: _string(ticketMap?['public_reference']),
      category: _string(ticketMap?['category']),
      firstValidatedAt: _date(json['first_validated_at']),
      checkpointLabel: _string(json['checkpoint_label']),
      serverTime: _date(json['server_time']),
    );
  }

  /// Version du contrat comprise par cette application.
  static const int supportedVersion = 1;

  /// Identifiant stable de la requête (rejeu idempotent).
  final String requestId;

  /// Code de verdict.
  final ScanResult result;

  /// Identifiant de la validation acceptée.
  final String? validationId;

  /// Référence imprimée du billet (jamais le jeton).
  final String? publicReference;

  /// Catégorie du billet.
  final String? category;

  /// Heure serveur (UTC) de la première validation effective.
  final DateTime? firstValidatedAt;

  /// Porte de la première validation.
  final String? checkpointLabel;

  /// Heure du serveur au moment de la réponse (UTC).
  final DateTime? serverTime;

  /// Nature du verdict pour l'agent.
  VerdictKind get kind => result.kind;

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
