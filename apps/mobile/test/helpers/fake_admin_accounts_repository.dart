import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';

/// Permissions d'un rôle, comme `private.role_permissions`
/// (migrations 4900 et 5000).
Set<String> permissionsOf(AdminRole role) => switch (role) {
  AdminRole.superAdmin => {
    'accounts',
    'accounts_delete',
    'organizations',
    'organizations_delete',
    'org_status',
    'events',
    'tickets',
    'catalog',
    'announcements',
    'support',
    'billing',
    'legal',
    'admins',
    'settings',
  },
  AdminRole.support => {
    'accounts',
    'organizations',
    'org_status',
    'tickets',
    'support',
  },
  AdminRole.moderation => {'org_status', 'events', 'catalog', 'announcements'},
  AdminRole.finance => {'billing'},
};

/// Fiche de test.
AccountDetail accountDetail({
  String id = 'u-awa',
  String name = 'Awa Ouédraogo',
  String? email = 'awa@exemple.bf',
  String? phone = '+22670112233',
  AdminRole? adminRole,
  bool mfaEnrolled = false,
  DateTime? deletionRequestedAt,
}) => AccountDetail(
  id: id,
  displayName: name,
  email: email,
  phone: phone,
  active: true,
  createdAt: DateTime.utc(2026, 11),
  adminRole: adminRole,
  mfaEnrolled: mfaEnrolled,
  deletionRequestedAt: deletionRequestedAt,
);

/// Gestion des comptes en mémoire.
class FakeAdminAccountsRepository implements AdminAccountsRepository {
  new({
    AdminRole role = AdminRole.superAdmin,
    bool mfaEnrolled = true,
    Map<String, AccountDetail>? accounts,
  }) : meValue = AdminMe(
         role: role,
         permissions: permissionsOf(role),
         mfaEnrolled: mfaEnrolled,
       ),
       accounts = accounts ?? {};

  AdminMe meValue;
  final Map<String, AccountDetail> accounts;
  List<PlatformAdmin> admins = [];
  final List<String> calls = [];

  /// Échec de la prochaine action.
  AdminAccountsFailure? failure;
  bool mustChange = false;
  String nextPassword = 'AAAA-BBBB-CCCC';

  void _fail() {
    if (failure case final f?) {
      failure = null;
      throw f;
    }
  }

  @override
  Future<AdminMe> me() async => meValue;

  @override
  Future<AdminMe> saveSettings({
    bool? notifyUsers,
    bool? adminIssueTickets,
  }) async {
    calls.add('settings $notifyUsers $adminIssueTickets');
    _fail();
    return meValue = AdminMe(
      role: meValue.role,
      permissions: meValue.permissions,
      mfaEnrolled: meValue.mfaEnrolled,
      notifyUsers: notifyUsers ?? meValue.notifyUsers,
      adminIssueTickets: adminIssueTickets ?? meValue.adminIssueTickets,
      doubleScanSeconds: meValue.doubleScanSeconds,
    );
  }

  @override
  Future<AdminMe> saveDoubleScanSeconds(int seconds) async {
    calls.add('double-scan $seconds');
    _fail();
    return meValue = meValue.withDoubleScanSeconds(seconds);
  }

  @override
  Future<AccountDetail> detail(String userId) async {
    final account = accounts[userId];
    if (account == null) throw AdminAccountsFailure.notFound;
    return account;
  }

  @override
  Future<List<PlatformAdmin>> platformAdmins() async => admins;

  @override
  Future<CreatedAccount> create({
    required String email,
    required String displayName,
    required String reason,
    String? phone,
  }) async {
    calls.add('create $email $displayName ${phone ?? '-'} $reason');
    _fail();
    final id = 'u-new-${accounts.length}';
    accounts[id] = accountDetail(
      id: id,
      name: displayName,
      email: email,
      phone: phone,
    );
    return (userId: id, password: nextPassword);
  }

  void _replace(String userId, AccountDetail Function(AccountDetail) change) {
    accounts[userId] = change(accounts[userId]!);
  }

  @override
  Future<void> update(
    String userId, {
    required String displayName,
    required String? phone,
    required String reason,
    bool? notify,
  }) async {
    calls.add('update $userId $displayName ${phone ?? '-'} $reason $notify');
    _fail();
    _replace(
      userId,
      (a) => accountDetail(
        id: a.id,
        name: displayName,
        email: a.email,
        phone: phone,
        adminRole: a.adminRole,
        mfaEnrolled: a.mfaEnrolled,
      ),
    );
  }

  @override
  Future<String> resetPassword(
    String userId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('password $userId $reason $notify');
    _fail();
    return nextPassword;
  }

  @override
  Future<void> changeEmail(
    String userId, {
    required String email,
    required String reason,
    bool? notify,
  }) async {
    calls.add('email $userId $email $reason $notify');
    _fail();
  }

  @override
  Future<int> signOut(
    String userId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('signout $userId $reason $notify');
    _fail();
    return 2;
  }

  @override
  Future<void> cancelDeletion(
    String userId, {
    required String reason,
    bool? notify,
  }) async {
    calls.add('cancel-deletion $userId $reason $notify');
    _fail();
  }

  @override
  Future<int> deleteNow(
    String userId, {
    required String confirmEmail,
    required String reason,
  }) async {
    calls.add('delete $userId $confirmEmail $reason');
    _fail();
    return 1;
  }

  @override
  Future<AdminRole?> setRole(
    String userId,
    AdminRole? role, {
    required String reason,
  }) async {
    calls.add('role $userId ${role?.wireName ?? 'none'} $reason');
    _fail();
    return role;
  }

  @override
  Future<void> removeMfa(String userId, {required String reason}) async {
    calls.add('remove-mfa $userId $reason');
    _fail();
  }

  @override
  Future<bool> mustChangePassword() async => mustChange;

  @override
  Future<void> clearMustChangePassword() async {
    calls.add('clear-must-change');
    mustChange = false;
  }
}
