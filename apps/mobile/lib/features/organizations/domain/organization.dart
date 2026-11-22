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
    this.publicPhone,
    this.publicDescription,
    this.facebookUrl,
    this.instagramUrl,
    this.tiktokUrl,
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
      publicPhone: json['public_phone'] as String?,
      publicDescription: json['public_description'] as String?,
      facebookUrl: json['facebook_url'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      tiktokUrl: json['tiktok_url'] as String?,
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

  /// Numéro WhatsApp public (format international), affiché sur les fiches
  /// publiques des événements (« Obtenir un ticket »).
  final String? publicPhone;

  /// Présentation affichée sur la page publique (ADR 0047).
  final String? publicDescription;

  /// Pages Facebook, Instagram et TikTok (adresses complètes).
  final String? facebookUrl;
  final String? instagramUrl;
  final String? tiktokUrl;

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
    publicPhone: publicPhone,
    publicDescription: publicDescription,
    facebookUrl: facebookUrl,
    instagramUrl: instagramUrl,
    tiktokUrl: tiktokUrl,
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
      other.city == city &&
      other.publicPhone == publicPhone &&
      other.publicDescription == publicDescription &&
      other.facebookUrl == facebookUrl &&
      other.instagramUrl == instagramUrl &&
      other.tiktokUrl == tiktokUrl;

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
    publicPhone,
    publicDescription,
    facebookUrl,
    instagramUrl,
    tiktokUrl,
  );
}

/// Fiche saisie par le propriétaire.
@immutable
final class OrganizationDraft {
  const new({
    required this.name,
    this.phone,
    this.contactEmail,
    this.city,
    this.publicPhone,
    this.publicDescription,
    this.facebook,
    this.instagram,
    this.tiktok,
  });

  final String name;
  final String? phone;
  final String? contactEmail;
  final String? city;

  /// Numéro WhatsApp public (`set_organization_public_phone`).
  final String? publicPhone;

  /// Présentation publique et réseaux (adresse ou nom du compte,
  /// voir [socialUrl]) : `set_organization_profile`.
  final String? publicDescription;
  final String? facebook;
  final String? instagram;
  final String? tiktok;

  /// Paramètres de `set_organization_profile`.
  Map<String, Object?> profileParams() => {
    'p_description': _clean(publicDescription),
    'p_facebook_url': socialUrl(SocialNetwork.facebook, facebook),
    'p_instagram_url': socialUrl(SocialNetwork.instagram, instagram),
    'p_tiktok_url': socialUrl(SocialNetwork.tiktok, tiktok),
  };

  /// Numéro public nettoyé, `null` pour le retirer.
  String? get publicPhoneParam => _clean(publicPhone);

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

  /// Lien d'un réseau invalide (`org_link_invalid`, saisie).
  linkInvalid,

  /// Présentation trop longue (`org_description_invalid`).
  descriptionInvalid,

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

/// Réseaux affichés sur la page publique d'une structure.
enum SocialNetwork {
  facebook('www.facebook.com', ''),
  instagram('www.instagram.com', ''),
  tiktok('www.tiktok.com', '@');

  new(this.host, this.handlePrefix);

  final String host;

  /// Préfixe du nom de compte dans l'adresse (TikTok : « @ »).
  final String handlePrefix;

  /// Domaines acceptés par le serveur (sous-domaines compris).
  bool accepts(Uri uri) {
    final host = uri.host.toLowerCase();
    final roots = switch (this) {
      facebook => const ['facebook.com', 'fb.com'],
      instagram => const ['instagram.com'],
      tiktok => const ['tiktok.com'],
    };
    return roots.any((root) => host == root || host.endsWith('.$root'));
  }
}

/// Adresse complète d'un réseau à partir de ce qu'a saisi le propriétaire :
/// une adresse (`facebook.com/…`, `https://…`) ou un nom de compte
/// (`@faso.live`). `null` si vide ; [FormatException] si l'adresse pointe
/// vers un autre site.
String? socialUrl(SocialNetwork network, String? input) {
  final value = input?.trim() ?? '';
  if (value.isEmpty) return null;
  final looksLikeUrl = value.contains('/') || value.contains('.com');
  if (looksLikeUrl) {
    final uri = Uri.tryParse(
      value.startsWith('http') ? value : 'https://$value',
    );
    if (uri == null || !network.accepts(uri) || uri.path.length < 2) {
      throw const FormatException('social_url_invalid');
    }
    return uri.replace(scheme: 'https').toString();
  }
  final handle = value.replaceFirst(RegExp('^@'), '');
  if (!RegExp(r'^[A-Za-z0-9._-]{1,60}$').hasMatch(handle)) {
    throw const FormatException('social_url_invalid');
  }
  return 'https://${network.host}/${network.handlePrefix}$handle';
}
