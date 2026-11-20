import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/legal/domain/legal_document.dart';

/// Documents légaux ; surchargé dans `main.dart` et dans les tests.
final legalRepositoryProvider = Provider<LegalRepository>(
  (ref) => throw UnimplementedError(
    'legalRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

final FutureProviderFamily<LegalDocument, LegalSlug> legalDocumentProvider =
    FutureProvider.autoDispose.family<LegalDocument, LegalSlug>(
      (ref, slug) => ref.read(legalRepositoryProvider).fetch(slug),
      retry: (retryCount, error) => null,
    );
