import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:ticketsur/features/events/domain/event.dart' show EventKind;

/// Catégorie proposée à la création d'un événement.
@immutable
final class DefaultCategory {
  const new({
    required this.name,
    this.capacity,
    this.price,
    this.invitation = false,
  });

  factory fromJson(Map<String, dynamic> json) => DefaultCategory(
    name: json['name'] as String,
    capacity: (json['capacity'] as num?)?.toInt(),
    price: (json['price'] as num?)?.toInt(),
    invitation: json['invitation'] as bool? ?? false,
  );

  final String name;

  /// Quota (`null` = illimité).
  final int? capacity;

  /// Prix indicatif en FCFA (`null` = non affiché).
  final int? price;

  /// Catégorie d'invitations.
  final bool invitation;

  Map<String, Object?> toJson() => {
    'name': name,
    'capacity': capacity,
    'price': price,
    'invitation': invitation,
  };

  @override
  bool operator ==(Object other) =>
      other is DefaultCategory &&
      other.name == name &&
      other.capacity == capacity &&
      other.price == price &&
      other.invitation == invitation;

  @override
  int get hashCode => Object.hash(name, capacity, price, invitation);
}

/// Réglages d'une structure : messages d'envoi et valeurs par défaut d'un
/// nouvel événement (migration 4600). Lus par toute l'équipe de gestion.
@immutable
final class OrgSettings {
  const new({
    this.ticketMessage,
    this.invitationMessage,
    this.defaultTimezone,
    this.defaultCity,
    this.defaultKind,
    this.defaultCategories = const [],
    this.defaultCheckpoints = const [],
  });

  factory fromJson(Map<String, dynamic> json) => OrgSettings(
    ticketMessage: json['ticket_message'] as String?,
    invitationMessage: json['invitation_message'] as String?,
    defaultTimezone: json['default_timezone'] as String?,
    defaultCity: json['default_city'] as String?,
    defaultKind: switch (json['default_kind']) {
      final String kind => EventKind.fromWire(kind),
      _ => null,
    },
    defaultCategories: [
      for (final item in (json['default_categories'] as List<dynamic>? ?? []))
        DefaultCategory.fromJson(item as Map<String, dynamic>),
    ],
    defaultCheckpoints: [
      for (final item in (json['default_checkpoints'] as List<dynamic>? ?? []))
        item as String,
    ],
  );

  /// Message d'envoi d'un ticket (`null` = message par défaut de l'app).
  final String? ticketMessage;

  /// Message d'envoi d'une invitation (`null` = message par défaut).
  final String? invitationMessage;
  final String? defaultTimezone;
  final String? defaultCity;
  final EventKind? defaultKind;
  final List<DefaultCategory> defaultCategories;
  final List<String> defaultCheckpoints;

  /// Vrai si des catégories ou des portes sont proposées.
  bool get hasProposals =>
      defaultCategories.isNotEmpty || defaultCheckpoints.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is OrgSettings &&
      other.ticketMessage == ticketMessage &&
      other.invitationMessage == invitationMessage &&
      other.defaultTimezone == defaultTimezone &&
      other.defaultCity == defaultCity &&
      other.defaultKind == defaultKind &&
      listEquals(other.defaultCategories, defaultCategories) &&
      listEquals(other.defaultCheckpoints, defaultCheckpoints);

  @override
  int get hashCode => Object.hash(
    ticketMessage,
    invitationMessage,
    defaultTimezone,
    defaultCity,
    defaultKind,
    Object.hashAll(defaultCategories),
    Object.hashAll(defaultCheckpoints),
  );
}

/// Nombre de catégories et de portes ajoutées à un événement.
typedef AppliedDefaults = ({int categories, int checkpoints});

/// Échecs des réglages, traduits pour l'écran.
enum OrgSettingsFailure implements Exception {
  network,
  forbidden,
  message,
  timezone,
  city,
  categories,
  checkpoints,
  unknown,
}

/// Champs à insérer dans un message d'envoi. Jamais le jeton du QR.
enum MessageField {
  firstName('{prenom}'),
  event('{evenement}'),
  date('{date}'),
  place('{lieu}'),
  category('{categorie}');

  new(this.token);

  /// Repère inséré dans le texte.
  final String token;
}

/// Longueur maximale d'un message d'envoi.
const int maxSendMessageLength = 600;

/// Nombre maximal de catégories ou de portes proposées.
const int maxDefaultItems = 10;

/// Remplit [template] : chaque champ absent est retiré, puis les espaces
/// orphelins avant une virgule ou un point et les espaces doubles sont
/// nettoyés.
String fillSendMessage(
  String template, {
  required String event,
  required String date,
  String? firstName,
  String? place,
  String? category,
}) {
  final values = {
    MessageField.firstName: firstName ?? '',
    MessageField.event: event,
    MessageField.date: date,
    MessageField.place: place ?? '',
    MessageField.category: category ?? '',
  };
  var text = template;
  for (final MapEntry(:key, :value) in values.entries) {
    text = text.replaceAll(key.token, value.trim());
  }
  return text
      .replaceAll(RegExp(r'\(\s*\)'), '')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      // Espace avant « , » ou « . » laissé par un champ vide (« Bonjour , »).
      .replaceAllMapped(RegExp(r'[ \t]+([,.])'), (match) => match[1]!)
      .trim();
}

/// Réglages de la structure (serveur).
abstract interface class OrgSettingsRepository {
  Future<OrgSettings> read(String organizationId);

  Future<OrgSettings> save(String organizationId, OrgSettings settings);

  /// Ajoute à l'événement les catégories et portes proposées absentes.
  Future<AppliedDefaults> applyToEvent(String eventId);
}
