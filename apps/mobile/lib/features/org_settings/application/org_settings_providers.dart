import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/org_settings/domain/org_settings.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

/// Réglages de la structure ; surchargé dans `main.dart` et dans les tests.
final orgSettingsRepositoryProvider = Provider<OrgSettingsRepository>(
  (ref) => throw UnimplementedError(
    'orgSettingsRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Vrai si le rôle permet de lire et modifier les réglages.
bool canManageSettings(Organization? organization) =>
    organization != null && organization.role != MemberRole.controller;

/// Réglages de la structure active (vides pour un contrôleur ou sans
/// structure, jamais d'erreur bloquante pour l'envoi d'un ticket).
final FutureProvider<OrgSettings> orgSettingsProvider =
    FutureProvider.autoDispose<OrgSettings>((ref) async {
      final organization = ref.watch(activeOrganizationProvider);
      if (!canManageSettings(organization)) return const OrgSettings();
      return await ref
          .read(orgSettingsRepositoryProvider)
          .read(organization!.id);
    });

/// Réglages connus, ou vides s'ils ne peuvent pas être lus (réseau…).
Future<OrgSettings> orgSettingsOrDefault(WidgetRef ref) async {
  try {
    return await ref.read(orgSettingsProvider.future);
  } on Object {
    return const OrgSettings();
  }
}

/// Enregistre les réglages de la structure active.
Future<OrgSettings> saveOrgSettings(WidgetRef ref, OrgSettings settings) async {
  final organization = ref.read(activeOrganizationProvider);
  if (!canManageSettings(organization)) throw OrgSettingsFailure.forbidden;
  final saved = await ref
      .read(orgSettingsRepositoryProvider)
      .save(organization!.id, settings);
  ref.invalidate(orgSettingsProvider);
  return saved;
}
