import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';

/// Outils de la console ; surchargé dans `main.dart` et les tests.
final adminToolsRepositoryProvider = Provider<AdminToolsRepository>(
  (ref) => throw UnimplementedError(
    'adminToolsRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Recherche globale de la console, par texte.
final FutureProviderFamily<GlobalSearchResult, String> consoleSearchProvider =
    FutureProvider.autoDispose.family<GlobalSearchResult, String>(
      (ref, query) => ref.read(adminToolsRepositoryProvider).search(query),
      retry: (retryCount, error) => null,
    );
