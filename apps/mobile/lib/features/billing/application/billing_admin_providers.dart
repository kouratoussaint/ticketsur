import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';

/// Console de facturation ; surchargé dans `main.dart` et dans les tests.
final billingAdminRepositoryProvider = Provider<BillingAdminRepository>(
  (ref) => throw UnimplementedError(
    'billingAdminRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Packs, demandes, abonnements, factures et réglages de la console.
final FutureProvider<AdminBilling> adminBillingProvider =
    FutureProvider.autoDispose<AdminBilling>(
      (ref) => ref.read(billingAdminRepositoryProvider).load(),
      retry: (retryCount, error) => null,
    );

/// Horloge de la console (tests).
final billingClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
