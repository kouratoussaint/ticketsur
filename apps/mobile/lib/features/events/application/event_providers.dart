import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

/// Dépôt des événements (Supabase au démarrage, faux dépôt en test).
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => throw UnimplementedError(
    'eventRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Ordre d'affichage : événements actifs du plus proche au plus lointain,
/// puis terminés du plus récent au plus ancien.
List<TicketEvent> sortEvents(Iterable<TicketEvent> events) {
  final active = [
    for (final e in events)
      if (e.status.isActive) e,
  ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  final done = [
    for (final e in events)
      if (!e.status.isActive) e,
  ]..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  return [...active, ...done];
}

/// Événements de l'organisation active. Les écritures passent par le
/// serveur ; la liste locale est mise à jour avec la ligne qu'il renvoie.
class EventsController extends AsyncNotifier<List<TicketEvent>> {
  @override
  Future<List<TicketEvent>> build() async {
    final organization = ref.watch(activeOrganizationProvider);
    if (organization == null) return const [];
    final events = await ref
        .read(eventRepositoryProvider)
        .list(organization.id);
    return sortEvents(events);
  }

  /// Crée un événement dans l'organisation active.
  /// Lève une [EventFailure] en cas d'échec.
  Future<TicketEvent> create(EventDraft draft) async {
    final organization = ref.read(activeOrganizationProvider);
    if (organization == null) throw EventFailure.notFound;
    final created = await ref
        .read(eventRepositoryProvider)
        .create(organization.id, draft);
    _put(created);
    return created;
  }

  /// Modifie un événement.
  Future<TicketEvent> edit(String eventId, EventDraft draft) async {
    final updated = await ref
        .read(eventRepositoryProvider)
        .update(eventId, draft);
    _put(updated);
    return updated;
  }

  /// Rend l'événement visible (ou non) dans l'Explorer public.
  Future<TicketEvent> setPublic(String eventId, {required bool public}) async {
    final updated = await ref
        .read(eventRepositoryProvider)
        .setPublic(eventId, public: public);
    _put(updated);
    return updated;
  }

  /// Change le statut d'un événement (transition contrôlée par le serveur).
  Future<TicketEvent> changeStatus(String eventId, EventStatus status) async {
    final updated = await ref
        .read(eventRepositoryProvider)
        .setStatus(eventId, status);
    _put(updated);
    return updated;
  }

  /// Envoie et rattache une photo de couverture.
  /// Lève une [EventFailure] en cas d'échec.
  Future<TicketEvent> setCover(String eventId, CoverImage image) async {
    if (!acceptedCoverTypes.contains(image.mimeType) ||
        image.bytes.length > CoverImage.maxBytes) {
      throw EventFailure.coverInvalid;
    }
    final event = state.value?.where((e) => e.id == eventId).firstOrNull;
    if (event == null) throw EventFailure.notFound;
    final updated = await ref
        .read(eventRepositoryProvider)
        .setCover(event, image);
    _put(updated);
    return updated;
  }

  /// Duplique un événement ; la liste est relue. Renvoie l'identifiant de
  /// la copie. Lève une [EventFailure] en cas d'échec.
  Future<String> duplicate(
    TicketEvent source, {
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final id = await ref
        .read(eventRepositoryProvider)
        .duplicate(source, title: title, startsAt: startsAt, endsAt: endsAt);
    await reload();
    return id;
  }

  /// Recharge depuis le serveur.
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  void _put(TicketEvent event) {
    final current = state.value ?? const <TicketEvent>[];
    state = AsyncData(
      sortEvents([
        for (final e in current)
          if (e.id != event.id) e,
        event,
      ]),
    );
  }
}

/// Événements de l'organisation active (sans relance automatique : l'erreur
/// est montrée avec un bouton « Réessayer »).
final AsyncNotifierProvider<EventsController, List<TicketEvent>>
eventsProvider =
    AsyncNotifierProvider.autoDispose<EventsController, List<TicketEvent>>(
      EventsController.new,
      retry: (retryCount, error) => null,
    );

/// Un événement de la liste chargée, `null` s'il n'y figure pas.
final ProviderFamily<TicketEvent?, String> eventByIdProvider = Provider
    .autoDispose
    .family<TicketEvent?, String>(
      (ref, id) => ref
          .watch(eventsProvider)
          .value
          ?.where((event) => event.id == id)
          .firstOrNull,
    );
