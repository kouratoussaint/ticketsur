import 'package:flutter/foundation.dart' show immutable;

/// Règle d'entrée d'une catégorie (ADR 0024).
enum EntryPolicy {
  /// Une seule entrée (par défaut).
  single('single'),

  /// Une entrée par jour, dans le fuseau de l'événement.
  perDay('per_day'),

  /// N entrées au total ([TicketCategory.maxEntries]).
  limited('limited');

  new(this.wireName);

  /// Valeur échangée avec le serveur.
  final String wireName;

  /// Règle correspondant à [value] ; [single] si inconnue.
  static EntryPolicy fromWire(Object? value) {
    for (final policy in values) {
      if (policy.wireName == value) return policy;
    }
    return single;
  }
}

/// Bornes d'un pass à N entrées (contrainte serveur).
const int minPassEntries = 2;
const int maxPassEntries = 100;

/// Catégorie de tickets d'un événement, avec ses compteurs (EVT-03).
@immutable
final class TicketCategory {
  const new({
    required this.id,
    required this.eventId,
    required this.name,
    this.capacity,
    this.isInvitation = false,
    this.indicativePrice,
    this.issued = 0,
    this.redeemed = 0,
    this.entryPolicy = EntryPolicy.single,
    this.maxEntries,
  });

  /// Lit une ligne de `event_categories` ou de `ticket_categories`.
  factory fromJson(Map<String, Object?> json) => TicketCategory(
    id: json['id']! as String,
    eventId: json['event_id']! as String,
    name: json['name']! as String,
    capacity: (json['capacity'] as num?)?.toInt(),
    isInvitation: json['is_invitation'] == true,
    indicativePrice: (json['indicative_price'] as num?)?.toInt(),
    issued: (json['issued'] as num?)?.toInt() ?? 0,
    redeemed: (json['redeemed'] as num?)?.toInt() ?? 0,
    entryPolicy: EntryPolicy.fromWire(json['entry_policy']),
    maxEntries: (json['max_entries'] as num?)?.toInt(),
  );

  final String id;
  final String eventId;
  final String name;

  /// Quota ; `null` : illimité (dans la limite de la capacité de l'événement).
  final int? capacity;

  /// Catégorie d'invitations : ses tickets sont présentés comme des
  /// invitations (carte, PDF, message). Le contrôle à l'entrée est le même.
  final bool isInvitation;

  /// Prix indicatif en FCFA, affiché sur la fiche publique (facultatif).
  final int? indicativePrice;

  /// Tickets émis non révoqués.
  final int issued;

  /// Tickets entrés au moins une fois.
  final int redeemed;

  /// Règle d'entrée ; figée dès la première entrée d'un ticket.
  final EntryPolicy entryPolicy;

  /// Nombre d'entrées d'un pass [EntryPolicy.limited], `null` sinon.
  final int? maxEntries;

  /// Ticket valable pour plusieurs entrées.
  bool get isPass => entryPolicy != EntryPolicy.single;

  /// Copie avec quelques champs remplacés.
  TicketCategory copyWith({
    String? name,
    int? Function()? capacity,
    bool? isInvitation,
    int? Function()? indicativePrice,
    EntryPolicy? entryPolicy,
    int? Function()? maxEntries,
  }) => TicketCategory(
    id: id,
    eventId: eventId,
    name: name ?? this.name,
    capacity: capacity == null ? this.capacity : capacity(),
    isInvitation: isInvitation ?? this.isInvitation,
    indicativePrice: indicativePrice == null
        ? this.indicativePrice
        : indicativePrice(),
    issued: issued,
    redeemed: redeemed,
    entryPolicy: entryPolicy ?? this.entryPolicy,
    maxEntries: maxEntries == null ? this.maxEntries : maxEntries(),
  );

  /// Taux de remplissage du quota (0 à 1), `null` si illimité.
  double? get fill => capacity == null || capacity == 0
      ? null
      : (issued / capacity!).clamp(0, 1).toDouble();

  @override
  bool operator ==(Object other) =>
      other is TicketCategory &&
      other.id == id &&
      other.eventId == eventId &&
      other.name == name &&
      other.capacity == capacity &&
      other.isInvitation == isInvitation &&
      other.indicativePrice == indicativePrice &&
      other.issued == issued &&
      other.redeemed == redeemed &&
      other.entryPolicy == entryPolicy &&
      other.maxEntries == maxEntries;

  @override
  int get hashCode => Object.hash(
    id,
    eventId,
    name,
    capacity,
    isInvitation,
    indicativePrice,
    issued,
    redeemed,
    entryPolicy,
    maxEntries,
  );
}

/// Porte (point de contrôle) d'un événement (EVT-04).
@immutable
final class Checkpoint {
  const new({
    required this.id,
    required this.eventId,
    required this.name,
    required this.active,
  });

  /// Lit une ligne de `checkpoints`.
  factory fromJson(Map<String, Object?> json) => Checkpoint(
    id: json['id']! as String,
    eventId: json['event_id']! as String,
    name: json['name']! as String,
    active: json['active']! as bool,
  );

  final String id;
  final String eventId;
  final String name;

  /// Une porte inactive refuse tous les scans.
  final bool active;

  @override
  bool operator ==(Object other) =>
      other is Checkpoint &&
      other.id == id &&
      other.eventId == eventId &&
      other.name == name &&
      other.active == active;

  @override
  int get hashCode => Object.hash(id, eventId, name, active);
}

/// Échecs des catégories et des portes (codes de la migration 0700).
enum SetupFailure implements Exception {
  /// Élément inconnu ou droits insuffisants.
  notFound,

  /// Nom vide ou trop long.
  nameInvalid,

  /// Nom déjà utilisé dans l'événement.
  nameTaken,

  /// Quota hors limites.
  capacityInvalid,

  /// Quota inférieur aux tickets déjà émis.
  capacityBelowIssued,

  /// Suppression impossible : des tickets existent.
  hasTickets,

  /// Événement clôturé, annulé ou archivé.
  locked,

  /// Règle d'entrée invalide (2 à 100 entrées pour un pass).
  entriesInvalid,

  /// Règle d'entrée figée : des tickets de la catégorie sont déjà entrés.
  entriesLocked,

  /// Serveur injoignable.
  network,

  /// Toute autre erreur.
  unknown;

  /// Échec correspondant au code serveur [code].
  static SetupFailure fromServerCode(String? code) => switch (code) {
    'category_not_found' ||
    'checkpoint_not_found' ||
    'event_not_found' => notFound,
    'category_name_invalid' || 'checkpoint_name_invalid' => nameInvalid,
    'category_name_taken' || 'checkpoint_name_taken' => nameTaken,
    'category_capacity_invalid' => capacityInvalid,
    'category_capacity_below_issued' => capacityBelowIssued,
    'category_has_tickets' => hasTickets,
    'category_entries_invalid' => entriesInvalid,
    'category_has_entries' => entriesLocked,
    'event_locked' => locked,
    _ => unknown,
  };
}

/// Accès aux catégories et aux portes d'un événement.
abstract interface class EventSetupRepository {
  /// Catégories avec compteurs (organisateurs uniquement).
  Future<List<TicketCategory>> categories(String eventId);

  Future<TicketCategory> createCategory(
    String eventId,
    String name,
    int? capacity, {
    bool isInvitation = false,
  });

  Future<TicketCategory> updateCategory(
    String categoryId,
    String name,
    int? capacity, {
    required bool isInvitation,
  });

  /// Prix indicatif en FCFA (`null` pour le retirer).
  Future<void> setCategoryPrice(String categoryId, int? price);

  /// Règle d'entrée ([maxEntries] pour [EntryPolicy.limited] seulement).
  Future<void> setCategoryEntries(
    String categoryId,
    EntryPolicy policy,
    int? maxEntries,
  );

  Future<void> deleteCategory(String categoryId);

  /// Portes visibles (organisateurs et contrôleurs affectés).
  Future<List<Checkpoint>> checkpoints(String eventId);

  Future<Checkpoint> createCheckpoint(String eventId, String name);

  /// Renomme et/ou active/désactive une porte.
  Future<Checkpoint> updateCheckpoint(
    String checkpointId,
    String name, {
    required bool active,
  });
}
