import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:math' show Random;

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/core/image_upload.dart';
import 'package:ticketsur/design_system/image_rules.dart';
import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;
import 'package:ticketsur/features/profile/domain/profile.dart';

/// [ProfileRepository] adossé aux fonctions `my_profile`,
/// `update_my_profile`, `set_my_avatar`, `request_account_deletion`
/// (migration 1200) et au bucket `avatars`.
class SupabaseProfileRepository implements ProfileRepository {
  new(this._client, {Random? random}) : _random = random ?? Random.secure();

  final supabase.SupabaseClient _client;
  final Random _random;

  /// Bucket des photos de profil.
  static const avatarBucket = 'avatars';

  String _avatarUrl(String path) =>
      _client.storage.from(avatarBucket).getPublicUrl(path);

  UserProfile _read(Map<String, Object?> json) =>
      UserProfile.fromJson(json, avatarUrlOf: _avatarUrl);

  @override
  Future<UserProfile> load() => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>('my_profile');
    if (rows.isEmpty) throw ProfileFailure.unknown;
    return _read(Map<String, Object?>.from(rows.first as Map));
  });

  @override
  Future<UserProfile> update({
    required String displayName,
    String? phone,
    String locale = 'fr',
  }) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'update_my_profile',
      params: {
        'p_display_name': displayName.trim(),
        'p_phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        'p_locale': locale,
      },
    );
    return _read(Map<String, Object?>.from(rows.first as Map));
  });

  @override
  Future<bool> setEventReminders({required bool enabled}) => _guard(
    () async =>
        await _client.rpc<bool?>(
          'set_event_reminders',
          params: {'p_enabled': enabled},
        ) ??
        enabled,
  );

  @override
  Future<UserProfile> setAvatar(UserProfile current, CoverImage image) =>
      _guard(() async {
        final name = List.generate(
          16,
          (_) => _random.nextInt(16).toRadixString(16),
        ).join();
        // Carré 400 au plus, ≤ 150 Ko ; vignette 128 pour les listes.
        final prepared = await prepareImage(
          image.bytes,
          image.mimeType,
          ImageRules.avatar,
        );
        final path = '${current.id}/$name.${prepared.extension}';
        await uploadWithThumbnail(
          _client.storage.from(avatarBucket),
          path,
          prepared,
        );
        final List<dynamic> rows;
        try {
          rows = await _client.rpc<List<dynamic>>(
            'set_my_avatar',
            params: {'p_path': path},
          );
        } on Object {
          await _removeQuietly(path);
          rethrow;
        }
        if (current.avatarPath case final old? when old != path) {
          await _removeQuietly(old);
        }
        return _read(Map<String, Object?>.from(rows.first as Map));
      });

  @override
  Future<DateTime?> requestDeletion({required bool requested}) =>
      _guard(() async {
        final value = await _client.rpc<String?>(
          'request_account_deletion',
          params: {'p_requested': requested},
        );
        return value == null ? null : DateTime.parse(value).toUtc();
      });

  Future<void> _removeQuietly(String path) =>
      removeWithThumbnail(_client.storage.from(avatarBucket), path);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw mapProfileError(error);
    }
  }
}

/// Traduit une erreur PostgREST, Storage ou réseau en [ProfileFailure].
ProfileFailure mapProfileError(Object error) {
  if (error is ProfileFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is supabase.AuthRetryableFetchException) {
    return ProfileFailure.network;
  }
  if (error is supabase.StorageException) return ProfileFailure.avatarInvalid;
  if (error is supabase.PostgrestException) {
    return ProfileFailure.fromServerCode(error.message);
  }
  return ProfileFailure.unknown;
}
