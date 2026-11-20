import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';

/// Facturation du promoteur ; surchargé dans `main.dart` et dans les tests.
final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => throw UnimplementedError(
    'billingRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// « Mon pack » du compte connecté (relu à chaque changement de compte).
final FutureProvider<MyBilling> myBillingProvider =
    FutureProvider.autoDispose<MyBilling>((ref) {
      ref.watch(currentUserProvider);
      return ref.read(billingRepositoryProvider).myBilling();
    }, retry: (retryCount, error) => null);

/// Packs publiés.
final FutureProvider<List<BillingPack>> billingCatalogProvider =
    FutureProvider.autoDispose<List<BillingPack>>(
      (ref) => ref.read(billingRepositoryProvider).catalog(),
      retry: (retryCount, error) => null,
    );

/// Facturation d'un événement (P9, vérifications de l'app).
final FutureProviderFamily<EventBilling, String> eventBillingProvider =
    FutureProvider.autoDispose.family<EventBilling, String>(
      (ref, eventId) =>
          ref.read(billingRepositoryProvider).eventBilling(eventId),
      retry: (retryCount, error) => null,
    );
