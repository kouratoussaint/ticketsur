import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/events/domain/event.dart';

/// Événement public de test.
PublicEventSummary publicEvent({
  String id = 'pub-1',
  String title = 'Soirée Afro-Jazz',
  EventKind kind = EventKind.concert,
  DateTime? startsAt,
  String? venue = 'Jardin de la musique',
  String? city = 'Ouagadougou',
  String organizationName = 'Faso Live',
  int? minPrice,
  String? coverUrl,
}) {
  final start = startsAt ?? DateTime.utc(2030, 6, 20, 20);
  return PublicEventSummary(
    id: id,
    title: title,
    kind: kind,
    startsAt: start,
    endsAt: start.add(const Duration(hours: 4)),
    timezone: 'Africa/Ouagadougou',
    venue: venue,
    city: city,
    organizationName: organizationName,
    minPrice: minPrice,
    coverUrl: coverUrl,
  );
}

/// Faux catalogue : filtre [events] comme le serveur (recherche sans casse,
/// catégories, ville).
class FakeCatalogRepository implements CatalogRepository {
  new([
    List<PublicEventSummary>? events,
    Map<String, PublicEventDetail>? details,
  ]) : events = [...?events],
       details = {...?details};

  final List<PublicEventSummary> events;
  final Map<String, PublicEventDetail> details;
  final List<CatalogQuery> queries = [];
  CatalogFailure? failure;

  /// Pages publiques des structures, par identifiant.
  final Map<String, PublicOrganization> organizations = {};

  /// Structures suivies (identifiants) et appels de suivi.
  final Set<String> followedIds = {};
  final List<String> followCalls = [];

  @override
  Future<({bool following, int followers})> follow(
    String organizationId, {
    required bool follow,
  }) async {
    followCalls.add('${follow ? 'follow' : 'unfollow'} $organizationId');
    if (failure case final failure?) throw failure;
    final page = organizations[organizationId];
    final before = page?.followers ?? 0;
    final was = followedIds.contains(organizationId);
    if (follow) {
      followedIds.add(organizationId);
    } else {
      followedIds.remove(organizationId);
    }
    final followers =
        before + (follow && !was ? 1 : 0) - (!follow && was ? 1 : 0);
    final state = (following: follow, followers: followers);
    if (page != null) organizations[organizationId] = page.withFollow(state);
    return state;
  }

  @override
  Future<List<FollowedOrganization>> followed() async {
    if (failure case final failure?) throw failure;
    return [
      for (final id in followedIds)
        if (organizations[id] case final page?)
          (
            id: id,
            name: page.name,
            city: page.city,
            logoUrl: page.logoUrl,
            upcoming: page.events.length,
          ),
    ];
  }

  @override
  Future<PublicOrganization> organization(String id) async {
    if (failure case final failure?) throw failure;
    return organizations[id] ?? (throw CatalogFailure.notFound);
  }

  /// « À la une » choisis ; `null` : les 5 premiers (comme le serveur).
  List<PublicEventSummary>? featuredEvents;

  @override
  Future<List<PublicEventSummary>> featured() async {
    if (failure case final failure?) throw failure;
    return featuredEvents ?? events.take(5).toList();
  }

  @override
  Future<List<PublicEventSummary>> search(
    CatalogQuery query, {
    required DateTime now,
    int offset = 0,
    int limit = 30,
  }) async {
    queries.add(query);
    if (failure case final failure?) throw failure;
    final search = query.search.trim().toLowerCase();
    return events
        .where(
          (e) =>
              (query.kinds.isEmpty || query.kinds.contains(e.kind)) &&
              (query.city == null || e.city == query.city) &&
              (search.isEmpty ||
                  '${e.title} ${e.venue} ${e.city} ${e.organizationName}'
                      .toLowerCase()
                      .contains(search)),
        )
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<PublicEventDetail> event(String id) async {
    if (failure case final failure?) throw failure;
    return details[id] ??
        PublicEventDetail(
          summary: events.firstWhere(
            (e) => e.id == id,
            orElse: () => throw CatalogFailure.notFound,
          ),
          categories: const [],
        );
  }
}
