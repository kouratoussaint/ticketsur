import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Libellé d'un rôle.
String roleLabel(AppLocalizations l10n, MemberRole role) => switch (role) {
  MemberRole.owner => l10n.roleOwner,
  MemberRole.manager => l10n.roleManager,
  MemberRole.controller => l10n.roleController,
};

/// Message d'un échec.
String organizationFailureMessage(
  AppLocalizations l10n,
  OrganizationFailure failure,
) => switch (failure) {
  OrganizationFailure.invalidName => l10n.orgErrorInvalidName,
  OrganizationFailure.limitReached => l10n.orgErrorLimit,
  OrganizationFailure.notFound => l10n.orgErrorNotFound,
  OrganizationFailure.phoneInvalid => l10n.orgErrorPhone,
  OrganizationFailure.emailInvalid => l10n.orgErrorEmail,
  OrganizationFailure.cityInvalid => l10n.orgErrorCity,
  OrganizationFailure.logoInvalid => l10n.orgErrorLogo,
  OrganizationFailure.lastOwner => l10n.orgErrorLastOwner,
  OrganizationFailure.network => l10n.authErrorNetwork,
  OrganizationFailure.unknown => l10n.authErrorUnknown,
};

/// Teinte d'un rôle : propriétaire menthe, gestionnaire bleu, contrôleur
/// violet (direction artistique, section 3).
TikeoTint roleTint(MemberRole role, TikeoTints tints) => switch (role) {
  MemberRole.owner => tints.mint,
  MemberRole.manager => tints.blue,
  MemberRole.controller => tints.violet,
};

/// Icône d'un rôle : couronne, calendrier, viseur de scan.
IconData roleIcon(MemberRole role) => switch (role) {
  MemberRole.owner => Icons.workspace_premium_rounded,
  MemberRole.manager => Icons.event_note_rounded,
  MemberRole.controller => Icons.qr_code_scanner_rounded,
};
