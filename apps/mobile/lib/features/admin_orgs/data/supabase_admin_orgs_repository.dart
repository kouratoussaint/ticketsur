import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/admin_accounts/data/supabase_admin_accounts_repository.dart'
    show mapAdminAccountsError;
import 'package:ticketsur/features/admin_orgs/domain/admin_orgs.dart';
import 'package:ticketsur/features/notifications/data/supabase_push_repository.dart'
    show flushPushOutbox;
import 'package:ticketsur/features/organizations/domain/organization.dart'
    show MemberRole;

/// [AdminOrgsRepository] : fonctions SQL de la migration 5000.
class SupabaseAdminOrgsRepository implements AdminOrgsRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  static const _timeout = Duration(seconds: 30);

  Future<T> _rpc<T>(String name, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc<T>(name, params: params).timeout(_timeout);
    } on Object catch (error) {
      throw mapAdminAccountsError(error);
    }
  }

  /// Notification éventuelle : la file part tout de suite.
  void _flush() => unawaited(flushPushOutbox(_client));

  @override
  String logoUrl(String path) =>
      _client.storage.from('org-logos').getPublicUrl(path);

  @override
  Future<OrganizationDetail> detail(String organizationId) async =>
      OrganizationDetail.fromJson(
        await _rpc<Map<String, dynamic>>('admin_organization_detail', {
          'p_organization_id': organizationId,
        }),
      );

  @override
  Future<String> create({
    required String ownerId,
    required String name,
    required String reason,
    String? city,
    bool? notify,
  }) async {
    final id = await _rpc<String>('admin_create_organization', {
      'p_owner_id': ownerId,
      'p_name': name,
      'p_city': city,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
    return id;
  }

  @override
  Future<void> update(
    String organizationId, {
    required String name,
    required String reason,
    String? city,
    String? phone,
    String? contactEmail,
    String? publicPhone,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_update_organization', {
      'p_organization_id': organizationId,
      'p_name': name,
      'p_city': city,
      'p_phone': phone,
      'p_contact_email': contactEmail,
      'p_public_phone': publicPhone,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<void> removeLogo(
    String organizationId, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_remove_organization_logo', {
      'p_organization_id': organizationId,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<void> setMemberRole(
    String organizationId,
    String userId,
    MemberRole role, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_set_member_role', {
      'p_organization_id': organizationId,
      'p_user_id': userId,
      'p_role': role.wireName,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<void> removeMember(
    String organizationId,
    String userId, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_remove_member', {
      'p_organization_id': organizationId,
      'p_user_id': userId,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<void> revokeInvitation(
    String invitationId, {
    required String reason,
  }) => _rpc<Object?>('admin_revoke_invitation', {
    'p_invitation_id': invitationId,
    'p_reason': reason,
  });

  @override
  Future<OrgDeletePreview> deletePreview(String organizationId) async =>
      OrgDeletePreview.fromJson(
        await _rpc<Map<String, dynamic>>('admin_organization_delete_preview', {
          'p_organization_id': organizationId,
        }),
      );

  @override
  Future<OrgDeleteOutcome> delete(
    String organizationId, {
    required String confirmName,
    required String reason,
    bool? notify,
  }) async {
    final outcome = OrgDeleteOutcome.fromJson(
      await _rpc<Map<String, dynamic>>('admin_delete_organization', {
        'p_organization_id': organizationId,
        'p_confirm_name': confirmName,
        'p_reason': reason,
        'p_notify': notify,
      }),
    );
    // Détenteurs de tickets prévenus de l'annulation.
    _flush();
    return outcome;
  }

  @override
  Future<List<TrashItem>> trash() async {
    final rows = await _rpc<List<dynamic>>('admin_trash');
    return [
      for (final row in rows)
        TrashItem.fromJson((row as Map).cast<String, dynamic>()),
    ];
  }

  @override
  Future<void> restore(
    String organizationId, {
    required String reason,
    bool? notify,
  }) async {
    await _rpc<Object?>('admin_restore_organization', {
      'p_organization_id': organizationId,
      'p_reason': reason,
      'p_notify': notify,
    });
    _flush();
  }

  @override
  Future<void> purgeNow(
    String organizationId, {
    required String confirmName,
    required String reason,
  }) => _rpc<Object?>('admin_purge_organization_now', {
    'p_organization_id': organizationId,
    'p_confirm_name': confirmName,
    'p_reason': reason,
  });
}
