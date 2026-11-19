import 'package:flutter/foundation.dart' show immutable;

/// Titulaire facultatif d'un ticket nominatif (migration 1400).
///
/// Jamais dans le QR. Les règles de normalisation reproduisent celles du
/// serveur (`private.check_holder`) pour signaler les erreurs avant l'envoi ;
/// le serveur reste seul juge.
@immutable
final class TicketHolder {
  const new({this.name, this.phone, this.email});

  /// Lit les colonnes `holder_name`, `holder_phone`, `holder_email`.
  factory fromJson(Map<String, Object?> json) => TicketHolder(
    name: json['holder_name'] as String?,
    phone: json['holder_phone'] as String?,
    email: json['holder_email'] as String?,
  );

  static const TicketHolder none = TicketHolder();

  final String? name;

  /// Format international (`+226…`).
  final String? phone;
  final String? email;

  bool get isEmpty => name == null && phone == null && email == null;

  @override
  bool operator ==(Object other) =>
      other is TicketHolder &&
      other.name == name &&
      other.phone == phone &&
      other.email == email;

  @override
  int get hashCode => Object.hash(name, phone, email);
}

/// Erreur de saisie d'un titulaire.
enum HolderProblem {
  /// Nom de plus de 120 caractères.
  nameTooLong,

  /// Numéro de téléphone invalide.
  phoneInvalid,

  /// Adresse e-mail invalide.
  emailInvalid,
}

/// Longueur maximale du nom (identique au serveur).
const int holderNameMaxLength = 120;

final RegExp _spaces = RegExp(r'\s+');
final RegExp _nonDigits = RegExp('[^0-9]');
final RegExp _phonePattern = RegExp(r'^\+[1-9][0-9]{7,14}$');
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Texte sans espaces superflus ; `null` s'il est vide.
String? normalizeHolderText(String? value) {
  final text = (value ?? '').trim().replaceAll(_spaces, ' ');
  return text.isEmpty ? null : text;
}

/// Téléphone saisi librement (`+226 70 00 00 00`, `0022670000000`,
/// `70 00 00 00`) → format international ; `null` si vide. Un numéro à
/// 8 chiffres est burkinabè. Ne garantit pas la validité : voir
/// [validateHolder].
String? normalizePhone(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;
  final digits = raw.replaceAll(_nonDigits, '');
  if (raw.startsWith('+')) return '+$digits';
  if (digits.startsWith('00')) return '+${digits.substring(2)}';
  if (digits.length == 8) return '+226$digits';
  return '+$digits';
}

/// Normalise et contrôle un titulaire. Renvoie le titulaire normalisé, ou le
/// premier problème rencontré (nom, puis téléphone, puis e-mail).
({TicketHolder? holder, HolderProblem? problem}) validateHolder({
  String? name,
  String? phone,
  String? email,
}) {
  final cleanName = normalizeHolderText(name);
  final cleanPhone = normalizePhone(phone);
  final cleanEmail = normalizeHolderText(email)?.toLowerCase();
  // Caractères comptés comme côté serveur (char_length), pas en UTF-16.
  if (cleanName != null && cleanName.runes.length > holderNameMaxLength) {
    return (holder: null, problem: HolderProblem.nameTooLong);
  }
  if (cleanPhone != null && !_phonePattern.hasMatch(cleanPhone)) {
    return (holder: null, problem: HolderProblem.phoneInvalid);
  }
  if (cleanEmail != null &&
      (cleanEmail.length > 254 || !_emailPattern.hasMatch(cleanEmail))) {
    return (holder: null, problem: HolderProblem.emailInvalid);
  }
  return (
    holder: TicketHolder(name: cleanName, phone: cleanPhone, email: cleanEmail),
    problem: null,
  );
}

/// Ligne d'une émission nominative : une ligne = un ticket.
typedef TicketRow = ({String categoryId, TicketHolder holder});
