import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/platform/domain/platform_status.dart';

/// [PlatformRepository] : fonction `platform_status` (migration 5300).
class SupabasePlatformRepository implements PlatformRepository {
  new(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<PlatformStatus> status() async => PlatformStatus.fromJson(
    await _client
        .rpc<Map<String, dynamic>>('platform_status')
        .timeout(const Duration(seconds: 15)),
  );
}
