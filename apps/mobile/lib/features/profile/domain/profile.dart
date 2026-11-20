import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;

/// Profil de l'utilisateur connecté.
@immutable
final class UserProfile {
  const new({
    required this.id,
    required this.displayName,
    this.avatarPath,
    this.avatarUrl,
    this.phone,
    this.locale = 'fr',
    this.deletionRequestedAt,
    this.eventReminders = true,
  });

  /// Lit une ligne de `my_profile` ou de `profiles`.
  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? avatarUrlOf,
  }) {
    final avatarPath = json['avatar_path'] as String?;
    final deletion = json['deletion_requested_at'] as String?;
    return UserProfile(
      id: json['id']! as String,
      displayName: json['display_name']! as String,
      avatarPath: avatarPath,
      avatarUrl: avatarPath == null ? null : avatarUrlOf?.call(avatarPath),
      phone: json['phone'] as String?,
      locale: (json['locale'] as String?) ?? 'fr',
      deletionRequestedAt: deletion == null
          ? null
          : DateTime.parse(deletion).toUtc(),
      eventReminders: json['event_reminders'] != false,
    );
  }

  final String id;
  final String displayName;
  final String? avatarPath;
  final String? avatarUrl;

  /// Téléphone au format international (+226…).
  final String? phone;

  /// Langue préférée (`fr` ou `en`).
  final String locale;

  /// Demande de suppression du compte en cours, depuis cette date.
  final DateTime? deletionRequestedAt;

  /// Rappels avant les événements dont un ticket est dans « Mes tickets ».
  final bool eventReminders;

  /// Copie avec la demande de suppression ou les rappels remplacés.
  UserProfile copyWith({
    DateTime? Function()? deletionRequestedAt,
    bool? eventReminders,
  }) => UserProfile(
    id: id,
    displayName: displayName,
    avatarPath: avatarPath,
    avatarUrl: avatarUrl,
    phone: phone,
    locale: locale,
    deletionRequestedAt: deletionRequestedAt == null
        ? this.deletionRequestedAt
        : deletionRequestedAt(),
    eventReminders: eventReminders ?? this.eventReminders,
  );

  /// Délai avant la suppression effective.
  static const Duration deletionDelay = Duration(days: 30);

  /// Date prévue de suppression, si une demande est en cours.
  DateTime? get deletionDueAt => deletionRequestedAt?.add(deletionDelay);

  /// Initiales pour l'avatar sans photo.
  String get initials {
    final words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    String head(String word) => String.fromCharCode(word.runes.first);
    final last = words.length > 1 ? head(words.last) : '';
    return (head(words.first) + last).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.id == id &&
      other.displayName == displayName &&
      other.avatarPath == avatarPath &&
      other.avatarUrl == avatarUrl &&
      other.phone == phone &&
      other.locale == locale &&
      other.deletionRequestedAt == deletionRequestedAt &&
      other.eventReminders == eventReminders;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    avatarPath,
    avatarUrl,
    phone,
    locale,
    deletionRequestedAt,
    eventReminders,
  );
}

/// Échecs présentés à l'utilisateur (codes stables de la migration 1200).
enum ProfileFailure implements Exception {
  /// Nom hors limites (`profile_name_invalid`).
  nameInvalid,

  /// Téléphone invalide (`profile_phone_invalid`).
  phoneInvalid,

  /// Photo refusée (`profile_avatar_invalid`, refus du bucket).
  avatarInvalid,

  /// Serveur injoignable.
  network,

  /// Toute autre erreur.
  unknown;

  /// Échec correspondant au code serveur [code], [unknown] sinon.
  static ProfileFailure fromServerCode(String? code) => switch (code) {
    'profile_name_invalid' => nameInvalid,
    'profile_phone_invalid' => phoneInvalid,
    'profile_avatar_invalid' => avatarInvalid,
    _ => unknown,
  };
}

/// Accès au profil de l'utilisateur connecté.
abstract interface class ProfileRepository {
  /// Profil courant.
  Future<UserProfile> load();

  /// Modifie le nom, le téléphone et la langue.
  Future<UserProfile> update({
    required String displayName,
    String? phone,
    String locale = 'fr',
  });

  /// Envoie et rattache une photo de profil ; l'ancienne est supprimée.
  Future<UserProfile> setAvatar(UserProfile current, CoverImage image);

  /// Demande ([requested] vrai) ou annule la suppression du compte.
  /// Renvoie la date de la demande en cours, ou `null`.
  Future<DateTime?> requestDeletion({required bool requested});

  /// Active ou coupe les rappels avant l'événement ; renvoie le choix
  /// enregistré.
  Future<bool> setEventReminders({required bool enabled});
}

/// Validation locale d'un nom affiché (2 à 60 caractères).
bool isValidDisplayName(String value) {
  final length = value.trim().replaceAll(RegExp(r'\s+'), ' ').length;
  return length >= 2 && length <= 60;
}

/// Validation locale d'un téléphone : vide, ou 8 à 15 chiffres (un `+` ou
/// `00` en tête accepté). Le serveur normalise en format international.
bool isValidPhone(String value) {
  final text = value.trim();
  if (text.isEmpty) return true;
  if (!RegExp(r'^\+?[0-9 .\-()]+$').hasMatch(text)) return false;
  var digits = text.replaceAll(RegExp('[^0-9]'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  return digits.length >= 8 && digits.length <= 15;
}
