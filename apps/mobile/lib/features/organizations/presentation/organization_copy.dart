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
  OrganizationFailure.network => l10n.authErrorNetwork,
  OrganizationFailure.unknown => l10n.authErrorUnknown,
};
