import 'package:flutter/foundation.dart' show immutable;

/// Rôle d'un membre dans une organisation (côté serveur : `member_role`).
enum MemberRole {
  /// Propriétaire : tous les droits sur l'organisation.
  owner('owner'),

  /// Gestionnaire : événements, billets, équipe selon droits.
  manager('manager'),

  /// Contrôleur : scan aux portes qui lui sont affectées.
  controller('controller');

  new(this.wireName);

  /// Valeur transmise par le serveur.
  final String wireName;

  /// Rôle correspondant à [value] ; par prudence, le moins privilégié si
  /// la valeur est inconnue.
  static MemberRole fromWire(Object? value) => values.firstWhere(
    (role) => role.wireName == value,
    orElse: () => MemberRole.controller,
  );
}

/// Organisation dont l'utilisateur est membre, avec son rôle.
@immutable
final class Organization {
  /// Crée une organisation.
  const new({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
  });

  /// Lit une ligne de `my_organizations` ou la réponse de
  /// `create_organization`.
  factory fromJson(Map<String, Object?> json) => Organization(
    id: json['id']! as String,
    name: json['name']! as String,
    slug: json['slug']! as String,
    role: MemberRole.fromWire(json['role']),
  );

  /// Identifiant.
  final String id;

  /// Nom affiché.
  final String name;

  /// Identifiant d'URL unique.
  final String slug;

  /// Rôle de l'utilisateur courant dans cette organisation.
  final MemberRole role;

  @override
  bool operator ==(Object other) =>
      other is Organization &&
      other.id == id &&
      other.name == name &&
      other.slug == slug &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, name, slug, role);
}

/// Échecs présentés à l'utilisateur.
enum OrganizationFailure implements Exception {
  /// Nom vide ou hors limites.
  invalidName,

  /// Nombre maximal d'organisations atteint.
  limitReached,

  /// Serveur injoignable.
  network,

  /// Toute autre erreur.
  unknown,
}

/// Issue d'une saisie de code d'invitation.
enum JoinResult {
  /// Organisation rejointe.
  joined,

  /// Code inconnu ou révoqué.
  invalid,

  /// Code expiré ou déjà utilisé le nombre de fois prévu.
  expired,

  /// Déjà membre de cette organisation.
  alreadyMember,

  /// Trop d'essais : patienter un quart d'heure.
  rateLimited,

  /// Session absente ou compte désactivé.
  unauthorized;

  /// Valeur renvoyée par `accept_invitation`.
  static JoinResult fromWire(Object? value) => switch (value) {
    'joined' => joined,
    'expired' => expired,
    'already_member' => alreadyMember,
    'rate_limited' => rateLimited,
    'unauthorized' => unauthorized,
    _ => invalid,
  };
}

/// Résultat de `accept_invitation`.
@immutable
final class JoinOutcome {
  const new(this.result, [this.organization]);

  final JoinResult result;

  /// Organisation rejointe (si [result] vaut [JoinResult.joined]).
  final Organization? organization;
}

/// Accès aux organisations de l'utilisateur connecté.
abstract interface class OrganizationRepository {
  /// Organisations dont l'utilisateur est membre actif.
  Future<List<Organization>> myOrganizations();

  /// Crée une organisation dont l'utilisateur devient propriétaire.
  Future<Organization> create(String name);

  /// Rejoint une organisation avec un code d'invitation.
  Future<JoinOutcome> join(String code);
}
