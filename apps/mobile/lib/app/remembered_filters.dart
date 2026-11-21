import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

/// Filtres mémorisés sur l'appareil (préférences `filters.…`).
///
/// Ceux d'un compte (`filters.<compte>.<nom>`) ne servent qu'à ce compte et
/// sont oubliés à sa déconnexion ; ceux de l'appareil (`filters.device.…`,
/// la ville de l'Explorer) restent, même sans compte.
final class RememberedFilters {
  const new(this._prefs, this._userId);

  final SharedPreferences _prefs;
  final String? _userId;

  static const prefix = 'filters.';

  String? _key(String name, {required bool device}) => device
      ? '${prefix}device.$name'
      : _userId == null
      ? null
      : '$prefix$_userId.$name';

  /// Valeur mémorisée, ou `null`.
  String? read(String name, {bool device = false}) =>
      switch (_key(name, device: device)) {
        final key? => _prefs.getString(key),
        null => null,
      };

  /// Mémorise [value] (`null` : oublie).
  void write(String name, String? value, {bool device = false}) {
    final key = _key(name, device: device);
    if (key == null) return;
    unawaited(
      value == null ? _prefs.remove(key) : _prefs.setString(key, value),
    );
  }

  /// Oublie tous les filtres du compte [userId].
  static Future<void> forgetAccount(
    SharedPreferences prefs,
    String userId,
  ) async {
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('$prefix$userId.')) await prefs.remove(key);
    }
  }
}

/// Filtres mémorisés du compte connecté (et de l'appareil).
final rememberedFiltersProvider = Provider<RememberedFilters>(
  (ref) => RememberedFilters(
    ref.watch(sharedPreferencesProvider),
    ref.watch(currentUserProvider.select((user) => user.value?.id)),
  ),
);

/// Lit une valeur d'énumération mémorisée par son nom.
T? enumByName<T extends Enum>(List<T> values, String? name) =>
    values.where((v) => v.name == name).firstOrNull;
