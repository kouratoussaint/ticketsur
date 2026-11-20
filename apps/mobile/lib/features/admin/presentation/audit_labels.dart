import 'package:ticketsur/l10n/l10n.dart';

/// Libellé lisible d'une action du journal ; l'action brute sinon.
String auditActionLabel(AppLocalizations l10n, String action) =>
    switch (action) {
      'admin.event_moderated' => l10n.auditAdminEventModerated,
      'admin.account_status_changed' => l10n.auditAdminAccountStatusChanged,
      'admin.account_purged' => l10n.auditAdminAccountPurged,
      'admin.support_replied' => l10n.auditAdminSupportReplied,
      'admin.announcement_published' => l10n.auditAdminAnnouncementPublished,
      'admin.announcement_archived' => l10n.auditAdminAnnouncementArchived,
      'admin.legal_updated' => l10n.auditAdminLegalUpdated,
      'ticket.claimed' => l10n.auditTicketClaimed,
      'scan.manual' => l10n.auditScanManual,
      'ticket.released' => l10n.auditTicketReleased,
      'admin.organization_status_changed' =>
        l10n.auditAdminOrganizationStatusChanged,
      'assignment.added' => l10n.auditAssignmentAdded,
      'assignment.removed' => l10n.auditAssignmentRemoved,
      'category.created' => l10n.auditCategoryCreated,
      'category.deleted' => l10n.auditCategoryDeleted,
      'category.entries_changed' => l10n.auditCategoryEntriesChanged,
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
      'event.duplicated' => l10n.auditEventDuplicated,
      'ticket_template.updated' => l10n.auditTicketTemplateUpdated,
      _ => action,
    };

/// Détails d'une ligne du journal, lisibles : « public : oui · quantité : 3 ».
String auditDetails(AppLocalizations l10n, Map<String, Object?> details) => [
  for (final MapEntry(:key, :value) in details.entries)
    // Identifiants techniques : jamais affichés.
    if (!_hidden.contains(key)) '${_field(l10n, key)} : ${_value(l10n, value)}',
].join(' · ');

String _value(AppLocalizations l10n, Object? value) => switch (value) {
  true => l10n.auditDetailYes,
  false => l10n.auditDetailNo,
  'owner_deleted' => l10n.auditValueOwnerDeleted,
  'accepted' => l10n.auditValueAccepted,
  'already_used' => l10n.auditValueAlreadyUsed,
  'builtin' => l10n.auditValueTemplateBuiltin,
  'custom' => l10n.auditValueTemplateCustom,
  'default' => l10n.auditValueTemplateDefault,
  'tagline' => l10n.auditValueTagline,
  'single' => l10n.auditValueEntrySingle,
  'per_day' => l10n.auditValueEntryPerDay,
  'limited' => l10n.auditValueEntryLimited,
  final String code when _refusals.contains(code) => l10n.auditValueRefused,
  final List<Object?> list => list.map((v) => _value(l10n, v)).join(', '),
  _ => '$value',
};

const _hidden = {'source', 'ticket_ids', 'request_id'};

const _refusals = {
  'revoked',
  'expired',
  'not_found',
  'wrong_event',
  'unauthorized',
  'event_inactive',
};

String _field(AppLocalizations l10n, String key) => switch (key) {
  'result' => l10n.auditFieldResult,
  'reason' => l10n.auditFieldReason,
  'bulk' => l10n.auditFieldBulk,
  'title' => l10n.auditFieldTitle,
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
  'structures_suspended' => l10n.auditFieldStructuresSuspended,
  'cause' => l10n.auditFieldCause,
  'audiences' => l10n.auditFieldAudiences,
  'level' => l10n.auditFieldLevel,
  'document' => l10n.auditFieldDocument,
  'kind' => l10n.auditFieldTemplateKind,
  'locale' => l10n.auditFieldLanguage,
  'policy' => l10n.auditFieldEntryPolicy,
  'max' => l10n.auditFieldMaxEntries,
  _ => key,
};
