import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;

/// Rôle d'un membre dans une organisation (côté serveur : `member_role`).
enum MemberRole {
  /// Propriétaire : tous les droits sur l'organisation.
  owner('owner'),

  /// Gestionnaire : événements, tickets, équipe selon droits.
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

/// Organisation dont l'utilisateur est membre, avec son rôle et sa fiche.
@immutable
final class Organization {
  /// Crée une organisation.
  const new({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    this.logoPath,
    this.logoUrl,
    this.phone,
    this.contactEmail,
    this.city,
  });

  /// Lit une ligne de `my_organizations` ou la réponse de
  /// `create_organization`. [logoUrlOf] donne l'adresse publique du logo.
  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? logoUrlOf,
  }) {
    final logoPath = json['logo_path'] as String?;
    return Organization(
      id: json['id']! as String,
      name: json['name']! as String,
      slug: json['slug']! as String,
      role: MemberRole.fromWire(json['role']),
      logoPath: logoPath,
      logoUrl: logoPath == null ? null : logoUrlOf?.call(logoPath),
      phone: json['phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      city: json['city'] as String?,
    );
  }

  /// Identifiant.
  final String id;

  /// Nom affiché.
  final String name;

  /// Identifiant d'URL unique.
  final String slug;

  /// Rôle de l'utilisateur courant dans cette organisation.
  final MemberRole role;

  /// Chemin du logo dans le bucket `org-logos`.
  final String? logoPath;

  /// Adresse publique du logo.
  final String? logoUrl;

  /// Téléphone de contact (format international).
  final String? phone;

  /// E-mail de contact.
  final String? contactEmail;

  /// Ville du siège.
  final String? city;

  /// Copie avec le rôle [role] (la fiche serveur ne le renvoie pas).
  Organization withRole(MemberRole role) => Organization(
    id: id,
    name: name,
    slug: slug,
    role: role,
    logoPath: logoPath,
    logoUrl: logoUrl,
    phone: phone,
    contactEmail: contactEmail,
    city: city,
  );

  @override
  bool operator ==(Object other) =>
      other is Organization &&
      other.id == id &&
      other.name == name &&
      other.slug == slug &&
      other.role == role &&
      other.logoPath == logoPath &&
      other.logoUrl == logoUrl &&
      other.phone == phone &&
      other.contactEmail == contactEmail &&
      other.city == city;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    slug,
    role,
    logoPath,
    logoUrl,
    phone,
    contactEmail,
    city,
  );
}

/// Fiche saisie par le propriétaire.
@immutable
final class OrganizationDraft {
  const new({required this.name, this.phone, this.contactEmail, this.city});

  final String name;
  final String? phone;
  final String? contactEmail;
  final String? city;

  static String? _clean(String? text) {
    final value = text?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Paramètres de `update_organization`.
  Map<String, Object?> toParams() => {
    'p_name': name.trim(),
    'p_phone': _clean(phone),
    'p_contact_email': _clean(contactEmail),
    'p_city': _clean(city),
  };
}

/// Échecs présentés à l'utilisateur.
enum OrganizationFailure implements Exception {
  /// Nom vide ou hors limites.
  invalidName,

  /// Nombre maximal d'organisations atteint.
  limitReached,

  /// Organisation inconnue ou droits insuffisants (`org_not_found`).
  notFound,

  /// Téléphone invalide (`org_phone_invalid`).
  phoneInvalid,

  /// E-mail invalide (`org_email_invalid`).
  emailInvalid,

  /// Ville hors limites (`org_city_invalid`).
  cityInvalid,

  /// Logo refusé (`org_logo_invalid`, refus du bucket).
  logoInvalid,

  /// Dernier propriétaire : départ refusé (`org_last_owner`).
  lastOwner,

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

  /// Modifie la fiche (propriétaires seulement). Le rôle n'est pas renvoyé :
  /// l'appelant le conserve.
  Future<Organization> update(String organizationId, OrganizationDraft draft);

  /// Envoie et rattache un logo ; l'ancien fichier est supprimé.
  Future<Organization> setLogo(Organization organization, CoverImage image);

  /// Quitte l'organisation.
  Future<void> leave(String organizationId);
}
