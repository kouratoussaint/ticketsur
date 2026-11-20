/// Lit le numéro de la dernière version publiée.
abstract interface class UpdateChecker {
  /// Dernier build publié, ou `null` s'il est inconnu (réseau, réponse
  /// inattendue). Ne lève jamais d'exception.
  Future<int?> latestBuild();
}

/// `pilote-81` → 81 ; `null` pour tout autre nom.
int? buildFromTag(Object? tag) => switch (tag) {
  final String value => int.tryParse(
    RegExp(r'^pilote-(\d+)$').firstMatch(value)?.group(1) ?? '',
  ),
  _ => null,
};
