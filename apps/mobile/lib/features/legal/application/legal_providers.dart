import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/legal/domain/legal_document.dart';

/// Documents légaux ; surchargé dans `main.dart` et dans les tests.
final legalRepositoryProvider = Provider<LegalRepository>(
  (ref) => throw UnimplementedError(
    'legalRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Un document dans une langue.
final FutureProviderFamily<LegalDocument, LegalKey> legalDocumentProvider =
    FutureProvider.autoDispose.family<LegalDocument, LegalKey>(
      (ref, key) =>
          ref.read(legalRepositoryProvider).fetch(key.slug, locale: key.locale),
      retry: (retryCount, error) => null,
    );

/// Console : langue des mentions légales en cours de relecture.
class ConsoleLegalLocale extends Notifier<String> {
  @override
  String build() => 'fr';

  // Appelée comme une action depuis la console (bouton de langue).
  // ignore: use_setters_to_change_properties
  void select(String locale) => state = locale;
}

final NotifierProvider<ConsoleLegalLocale, String> consoleLegalLocaleProvider =
    NotifierProvider<ConsoleLegalLocale, String>(ConsoleLegalLocale.new);
