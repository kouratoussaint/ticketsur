import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filtre demandé par un autre écran (l'Accueil), à poser dans une liste
/// même déjà ouverte (onglet gardé en mémoire). `seq` change à chaque
/// demande, pour que la même demande répétée soit encore appliquée.
typedef FilterRequest<T> = ({T value, int seq});

/// Dernière demande de filtre pour une liste.
class FilterRequestController<T> extends Notifier<FilterRequest<T>?> {
  @override
  FilterRequest<T>? build() => null;

  /// Demande d'afficher la liste filtrée sur [value].
  void request(T value) => state = (value: value, seq: (state?.seq ?? 0) + 1);
}
