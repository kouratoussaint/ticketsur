import 'package:flutter/foundation.dart' show immutable;
import 'package:ticketsur/features/organizations/domain/organization.dart'
    show MemberRole;

/// Rôles d'administration (migration 4900, ADR 0038).
enum AdminRole {
  superAdmin('super'),
  support('support'),
  moderation('moderation'),
  finance('finance');

  new(this.wireName);

  final String wireName;

  static AdminRole? fromWire(Object? value) {
    for (final role in values) {
      if (role.wireName == value) return role;
    }
    return null;
  }
}

/// Permissions vérifiées par le serveur (`private.role_permissions`).
abstract final class AdminPermission {
  static const accounts = 'accounts';
  static const accountsDelete = 'accounts_delete';
  static const organizations = 'organizations';
  static const organizationsDelete = 'organizations_delete';
  static const orgStatus = 'org_status';
  static const events = 'events';
  static const tickets = 'tickets';
  static const catalog = 'catalog';
  static const announcements = 'announcements';
  static const support = 'support';
  static const billing = 'billing';
  static const legal = 'legal';
  static const admins = 'admins';
  static const settings = 'settings';
}

/// L'administrateur connecté : rôle, permissions, réglages de la console.
@immutable
final class AdminMe {
  const new({
    required this.role,
    this.permissions = const {},
    this.mfaEnrolled = false,
    this.notifyUsers = false,
    this.adminIssueTickets = false,
  });

  factory fromJson(Map<String, dynamic> json) => AdminMe(
    role: AdminRole.fromWire(json['role']) ?? AdminRole.support,
    permissions: {
      for (final p in (json['permissions'] as List<dynamic>? ?? []))
        p as String,
    },
    mfaEnrolled: json['mfa_enrolled'] as bool? ?? false,
    notifyUsers: json['notify_users'] as bool? ?? false,
    adminIssueTickets: json['admin_issue_tickets'] as bool? ?? false,
  );

  final AdminRole role;
  final Set<String> permissions;
  final bool mfaEnrolled;

  /// Réglage : prévenir la personne concernée (coché par défaut ou non).
  final bool notifyUsers;

  /// Réglage : émettre des tickets à la place d'un promoteur (lot 4-11c).
  final bool adminIssueTickets;

  bool can(String permission) => permissions.contains(permission);
}

@immutable
final class AccountOrganization {
  const new({
    required this.id,
    required this.name,
    required this.role,
    required this.memberActive,
    required this.organizationActive,
  });

  factory fromJson(Map<String, dynamic> json) => AccountOrganization(
    id: json['id']! as String,
    name: json['name']! as String,
    role: MemberRole.fromWire(json['role']),
    memberActive: json['active'] as bool? ?? true,
    organizationActive: json['status'] == 'active',
  );

  final String id;
  final String name;
  final MemberRole role;
  final bool memberActive;
  final bool organizationActive;
}

@immutable
final class AccountDevice {
  const new({
    required this.label,
    required this.platform,
    required this.lastSeenAt,
    this.appBuild,
  });

  factory fromJson(Map<String, dynamic> json) => AccountDevice(
    label: json['label']! as String,
    platform: json['platform']! as String,
    appBuild: (json['app_build'] as num?)?.toInt(),
    lastSeenAt: DateTime.parse(json['last_seen_at']! as String).toUtc(),
  );

  final String label;
  final String platform;
  final int? appBuild;
  final DateTime lastSeenAt;
}

/// Action de la console sur le compte, avec son motif.
@immutable
final class AccountAction {
  const new({
    required this.action,
    required this.at,
    required this.reason,
    required this.by,
  });

  factory fromJson(Map<String, dynamic> json) => AccountAction(
    action: json['action']! as String,
    at: DateTime.parse(json['at']! as String).toUtc(),
    reason: json['reason'] as String? ?? '',
    by: json['by'] as String? ?? '—',
  );

  final String action;
  final DateTime at;
  final String reason;
  final String by;
}

/// Fiche complète d'un compte (console).
@immutable
final class AccountDetail {
  const new({
    required this.id,
    required this.displayName,
    required this.active,
    required this.createdAt,
    this.email,
    this.phone,
    this.disabledReason,
    this.lastSignInAt,
    this.deletionRequestedAt,
    this.deletedAt,
    this.mustChangePassword = false,
    this.adminRole,
    this.mfaEnrolled = false,
    this.organizations = const [],
    this.walletTickets = 0,
    this.supportRequests = 0,
    this.supportOpen = 0,
    this.devices = const [],
    this.actions = const [],
  });

  factory fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? value) =>
        value is String ? DateTime.parse(value).toUtc() : null;
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) => [
      for (final item in (json[key] as List<dynamic>? ?? []))
        parse(item as Map<String, dynamic>),
    ];
    return AccountDetail(
      id: json['id']! as String,
      displayName: json['display_name']! as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      active: json['status'] == 'active',
      disabledReason: json['disabled_reason'] as String?,
      createdAt: date(json['created_at'])!,
      lastSignInAt: date(json['last_sign_in_at']),
      deletionRequestedAt: date(json['deletion_requested_at']),
      deletedAt: date(json['deleted_at']),
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      adminRole: AdminRole.fromWire(json['admin_role']),
      mfaEnrolled: json['mfa_enrolled'] as bool? ?? false,
      organizations: list('organizations', AccountOrganization.fromJson),
      walletTickets: (json['wallet_tickets'] as num?)?.toInt() ?? 0,
      supportRequests: (json['support_requests'] as num?)?.toInt() ?? 0,
      supportOpen: (json['support_open'] as num?)?.toInt() ?? 0,
      devices: list('devices', AccountDevice.fromJson),
      actions: list('actions', AccountAction.fromJson),
    );
  }

  final String id;
  final String displayName;
  final String? email;
  final String? phone;
  final bool active;
  final String? disabledReason;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final DateTime? deletionRequestedAt;
  final DateTime? deletedAt;
  final bool mustChangePassword;
  final AdminRole? adminRole;
  final bool mfaEnrolled;
  final List<AccountOrganization> organizations;
  final int walletTickets;
  final int supportRequests;
  final int supportOpen;
  final List<AccountDevice> devices;
  final List<AccountAction> actions;

  bool get deleted => deletedAt != null;
}

/// Administrateur de la plateforme.
@immutable
final class PlatformAdmin {
  const new({
    required this.id,
    required this.displayName,
    required this.role,
    this.email,
    this.mfaEnrolled = false,
  });

  factory fromJson(Map<String, dynamic> json) => PlatformAdmin(
    id: json['id']! as String,
    displayName: json['display_name']! as String,
    email: json['email'] as String?,
    role: AdminRole.fromWire(json['role']) ?? AdminRole.superAdmin,
    mfaEnrolled: json['mfa_enrolled'] as bool? ?? false,
  );

  final String id;
  final String displayName;
  final String? email;
  final AdminRole role;
  final bool mfaEnrolled;
}

/// Compte créé : le mot de passe provisoire n'est connu qu'ici, une fois.
typedef CreatedAccount = ({String userId, String password});

/// Échecs de la gestion des comptes, traduits pour l'écran.
enum AdminAccountsFailure implements Exception {
  network,

  /// Rôle sans cette permission.
  roleForbidden,

  /// Double authentification à activer pour cette action.
  mfaNeeded,

  /// Code de double authentification à saisir (session).
  mfaRequired,

  /// Compte d'un administrateur : réservé au super administrateur.
  adminProtected,
  self,
  reasonRequired,
  nameInvalid,
  phoneInvalid,
  emailInvalid,
  emailTaken,
  confirmationMismatch,
  lastSuperAdmin,
  deletionNotRequested,
  accountIsAdmin,
  notFound,

  /// Structures (lot 4-11b).
  orgNotFound,
  orgClosed,
  orgTrashed,
  orgNotTrashed,
  orgNameInvalid,
  cityInvalid,
  memberIsOwner,
  ownerInactive,
  accountInactive,
  structureLimit,

  /// Événements et tickets (lot 4-11c).
  eventTrashed,
  eventNotTrashed,
  eventLocked,
  eventTransition,
  eventEnded,
  eventIncomplete,
  eventHasTickets,
  eventNotTrashable,
  sameOrganization,
  eventHasInvoice,
  organizationInactive,
  eventFieldInvalid,
  capacityBelowIssued,
  ticketLocked,
  holderInvalid,
  issueDisabled,
  quantityInvalid,
  searchInvalid,
  billingBlocked,

  /// Messages ciblés (lot 4-11d).
  messageInvalid,
  messageNoRecipients,
  unknown;

  static AdminAccountsFailure fromCode(String? code) => switch (code) {
    'admin_role_forbidden' || 'forbidden' => roleForbidden,
    'admin_mfa_needed' => mfaNeeded,
    'mfa_required' => mfaRequired,
    'account_admin_protected' => adminProtected,
    'self_forbidden' => self,
    'reason_required' || 'reason_too_long' => reasonRequired,
    'profile_name_invalid' => nameInvalid,
    'profile_phone_invalid' => phoneInvalid,
    'account_email_invalid' => emailInvalid,
    'account_email_taken' => emailTaken,
    'confirmation_mismatch' => confirmationMismatch,
    'last_super_admin' => lastSuperAdmin,
    'deletion_not_requested' => deletionNotRequested,
    'account_is_admin' => accountIsAdmin,
    'account_not_found' || 'account_deleted' => notFound,
    'organization_not_found' ||
    'member_not_found' ||
    'invitation_not_found' => orgNotFound,
    'organization_closed' => orgClosed,
    'organization_trashed' => orgTrashed,
    'organization_not_trashed' => orgNotTrashed,
    'org_name_invalid' => orgNameInvalid,
    'org_phone_invalid' => phoneInvalid,
    'org_email_invalid' => emailInvalid,
    'org_city_invalid' => cityInvalid,
    'member_is_owner' => memberIsOwner,
    'owner_inactive' => ownerInactive,
    'account_inactive' => accountInactive,
    'billing_limit_structures' => structureLimit,
    'event_not_found' ||
    'ticket_not_found' ||
    'category_not_found' => orgNotFound,
    'event_trashed' => eventTrashed,
    'event_not_trashed' => eventNotTrashed,
    'event_locked' => eventLocked,
    'event_invalid_transition' => eventTransition,
    'event_already_ended' => eventEnded,
    'event_incomplete' => eventIncomplete,
    'event_has_tickets' => eventHasTickets,
    'event_not_trashable' => eventNotTrashable,
    'event_same_organization' => sameOrganization,
    'event_has_invoice' => eventHasInvoice,
    'organization_inactive' => organizationInactive,
    'event_title_invalid' ||
    'event_venue_invalid' ||
    'event_timezone_invalid' ||
    'event_dates_invalid' ||
    'event_capacity_invalid' ||
    'event_city_invalid' ||
    'event_address_invalid' ||
    'event_description_invalid' ||
    'event_tagline_invalid' => eventFieldInvalid,
    'event_capacity_below_issued' => capacityBelowIssued,
    'ticket_not_revocable' || 'ticket_not_editable' => ticketLocked,
    'holder_name_invalid' ||
    'holder_phone_invalid' ||
    'holder_email_invalid' => holderInvalid,
    'admin_issue_disabled' => issueDisabled,
    'issue_quantity_invalid' => quantityInvalid,
    'search_query_invalid' => searchInvalid,
    'message_title_invalid' ||
    'message_body_invalid' ||
    'message_days_invalid' ||
    'message_target_invalid' => messageInvalid,
    'message_no_recipients' => messageNoRecipients,
    final String code when code.startsWith('billing_') => billingBlocked,
    _ => unknown,
  };
}

/// Gestion des comptes depuis la console (migration 4900 et fonction
/// serveur `admin-accounts`), et drapeau « mot de passe à changer ».
abstract interface class AdminAccountsRepository {
  Future<AdminMe> me();

  /// Réglages de la console (null : inchangé).
  Future<AdminMe> saveSettings({bool? notifyUsers, bool? adminIssueTickets});

  Future<AccountDetail> detail(String userId);

  Future<List<PlatformAdmin>> platformAdmins();

  Future<CreatedAccount> create({
    required String email,
    required String displayName,
    required String reason,
    String? phone,
  });

  Future<void> update(
    String userId, {
    required String displayName,
    required String? phone,
    required String reason,
    bool? notify,
  });

  /// Nouveau mot de passe provisoire, renvoyé une seule fois.
  Future<String> resetPassword(
    String userId, {
    required String reason,
    bool? notify,
  });

  Future<void> changeEmail(
    String userId, {
    required String email,
    required String reason,
    bool? notify,
  });

  /// Déconnecte tous les appareils ; renvoie le nombre de sessions.
  Future<int> signOut(String userId, {required String reason, bool? notify});

  Future<void> cancelDeletion(
    String userId, {
    required String reason,
    bool? notify,
  });

  /// Suppression immédiate ; renvoie le nombre de structures suspendues.
  Future<int> deleteNow(
    String userId, {
    required String confirmEmail,
    required String reason,
  });

  Future<AdminRole?> setRole(
    String userId,
    AdminRole? role, {
    required String reason,
  });

  Future<void> removeMfa(String userId, {required String reason});

  /// Compte connecté : mot de passe provisoire à changer ?
  Future<bool> mustChangePassword();

  Future<void> clearMustChangePassword();
}
