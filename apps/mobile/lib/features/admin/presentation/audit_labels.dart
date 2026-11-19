import 'package:ticketsur/l10n/l10n.dart';

/// Libellé lisible d'une action du journal ; l'action brute sinon.
String auditActionLabel(AppLocalizations l10n, String action) =>
    switch (action) {
      'admin.event_moderated' => l10n.auditAdminEventModerated,
      'admin.organization_status_changed' =>
        l10n.auditAdminOrganizationStatusChanged,
      'assignment.added' => l10n.auditAssignmentAdded,
      'assignment.removed' => l10n.auditAssignmentRemoved,
      'category.created' => l10n.auditCategoryCreated,
      'category.deleted' => l10n.auditCategoryDeleted,
      'category.price_changed' => l10n.auditCategoryPriceChanged,
      'category.updated' => l10n.auditCategoryUpdated,
      'checkpoint.created' => l10n.auditCheckpointCreated,
      'checkpoint.updated' => l10n.auditCheckpointUpdated,
      'event.cover_changed' => l10n.auditEventCoverChanged,
      'event.created' => l10n.auditEventCreated,
      'event.report_exported' => l10n.auditEventReportExported,
      'event.status_changed' => l10n.auditEventStatusChanged,
      'event.updated' => l10n.auditEventUpdated,
      'event.visibility_changed' => l10n.auditEventVisibilityChanged,
      'invitation.accepted' => l10n.auditInvitationAccepted,
      'invitation.created' => l10n.auditInvitationCreated,
      'invitation.revoked' => l10n.auditInvitationRevoked,
      'member.left' => l10n.auditMemberLeft,
      'member.updated' => l10n.auditMemberUpdated,
      'organization.created' => l10n.auditOrganizationCreated,
      'organization.logo_changed' => l10n.auditOrganizationLogoChanged,
      'organization.public_phone_changed' =>
        l10n.auditOrganizationPublicPhoneChanged,
      'organization.updated' => l10n.auditOrganizationUpdated,
      'ticket.holder_updated' => l10n.auditTicketHolderUpdated,
      'ticket.revoked' => l10n.auditTicketRevoked,
      'tickets.exported' => l10n.auditTicketsExported,
      'tickets.issued' => l10n.auditTicketsIssued,
      _ => action,
    };

/// Détails d'une ligne du journal, lisibles : « public : oui · quantité : 3 ».
String auditDetails(AppLocalizations l10n, Map<String, Object?> details) => [
  for (final MapEntry(:key, :value) in details.entries)
    '${_field(l10n, key)} : ${switch (value) {
      true => l10n.auditDetailYes,
      false => l10n.auditDetailNo,
      final List<Object?> list => list.join(', '),
      _ => '$value',
    }}',
].join(' · ');

String _field(AppLocalizations l10n, String key) => switch (key) {
  'public' => l10n.auditFieldPublic,
  'blocked' => l10n.auditFieldBlocked,
  'status' => l10n.auditFieldStatus,
  'quantity' => l10n.auditFieldQuantity,
  'count' => l10n.auditFieldCount,
  'removed' => l10n.auditFieldRemoved,
  'from' => l10n.auditFieldFrom,
  'to' => l10n.auditFieldTo,
  'role' => l10n.auditFieldRole,
  'capacity' => l10n.auditFieldCapacity,
  'fields' => l10n.auditFieldFields,
  'invitation' => l10n.auditFieldInvitation,
  'rows' => l10n.auditFieldRows,
  'channel' => l10n.auditFieldChannel,
  'price' => l10n.auditFieldPrice,
  _ => key,
};
