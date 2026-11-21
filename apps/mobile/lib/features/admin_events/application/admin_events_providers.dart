import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/admin_events/domain/admin_events.dart';

/// Événements et tickets de la console ; surchargé dans `main.dart` et les
/// tests.
final adminEventsRepositoryProvider = Provider<AdminEventsRepository>(
  (ref) => throw UnimplementedError(
    'adminEventsRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Fiche d'un événement (console).
final FutureProviderFamily<AdminEventDetail, String> adminEventDetailProvider =
    FutureProvider.autoDispose.family<AdminEventDetail, String>(
      (ref, id) => ref.read(adminEventsRepositoryProvider).eventDetail(id),
      retry: (retryCount, error) => null,
    );

/// Fiche d'un ticket (console).
final FutureProviderFamily<AdminTicketDetail, String>
adminTicketDetailProvider = FutureProvider.autoDispose
    .family<AdminTicketDetail, String>(
      (ref, id) => ref.read(adminEventsRepositoryProvider).ticketDetail(id),
      retry: (retryCount, error) => null,
    );
