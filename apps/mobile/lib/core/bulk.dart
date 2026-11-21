/// Résultat d'une action groupée faite élément par élément.
final class BulkOutcome {
  const new({this.done = 0, this.failed = 0, this.skipped = 0});

  /// Éléments traités.
  final int done;

  /// Éléments refusés par le serveur (ou non tentés après un arrêt).
  final int failed;

  /// Éléments laissés de côté avant l'envoi (déjà dans l'état voulu, ou
  /// action impossible pour eux).
  final int skipped;

  /// Nombre total d'éléments choisis.
  int get total => done + failed + skipped;
}

/// Applique [action] à chaque élément de [items], l'un après l'autre (le
/// serveur vérifie chaque élément et journalise chaque action). Un échec
/// n'arrête pas les suivants, sauf si [stopOn] le demande (réseau coupé,
/// limite du pack atteinte) : les éléments restants comptent alors comme
/// échoués. [skipped] s'ajoute au résultat.
Future<BulkOutcome> runBulk<T>(
  Iterable<T> items,
  Future<void> Function(T item) action, {
  bool Function(Object error)? stopOn,
  int skipped = 0,
}) async {
  final list = items.toList();
  var done = 0;
  var failed = 0;
  for (var i = 0; i < list.length; i++) {
    try {
      await action(list[i]);
      done++;
    } on Object catch (error) {
      failed++;
      if (stopOn?.call(error) ?? false) {
        failed += list.length - i - 1;
        break;
      }
    }
  }
  return BulkOutcome(done: done, failed: failed, skipped: skipped);
}
