import 'package:flutter/foundation.dart';

/// État public de la plateforme (lot 4-11d) : maintenance et inscriptions.
@immutable
final class PlatformStatus {
  const new({
    this.maintenance = false,
    this.message,
    this.writesBlocked = false,
    this.signupsOpen = true,
  });

  factory fromJson(Map<String, dynamic> json) => PlatformStatus(
    maintenance: json['maintenance'] as bool? ?? false,
    message: switch (json['message']) {
      final String text when text.trim().isNotEmpty => text.trim(),
      _ => null,
    },
    writesBlocked: json['writes_blocked'] as bool? ?? false,
    signupsOpen: json['signups_open'] as bool? ?? true,
  );

  /// Bandeau « Maintenance » pour tous.
  final bool maintenance;

  /// Message de l'équipe (300 caractères au plus).
  final String? message;

  /// Modifications bloquées pour les comptes qui ne sont pas
  /// administrateurs (le contrôle à l'entrée continue).
  final bool writesBlocked;

  /// Fermées : un compte ne se crée qu'avec un code d'invitation.
  final bool signupsOpen;
}

/// Lecture de l'état public (`platform_status`, avec ou sans compte).
abstract interface class PlatformRepository {
  Future<PlatformStatus> status();
}
