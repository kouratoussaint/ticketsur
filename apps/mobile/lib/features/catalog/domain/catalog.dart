import 'package:flutter/foundation.dart';
import 'package:ticketsur/features/events/domain/event.dart';

/// Période proposée dans les filtres du catalogue.
enum CatalogPeriod {
  /// Aucune limite (événements à venir et en cours).
  any,

  /// Aujourd'hui.
  today,

  /// Le week-end qui vient (ou en cours).
  weekend,

  /// Les 7 prochains jours.
  week;

  /// Bornes [from, to) pour [now] (heure du Burkina, UTC+0). `null` : pas
  /// de borne.
  ({DateTime? from, DateTime? to}) range(DateTime now) {
    final utc = now.toUtc();
    final today = DateTime.utc(utc.year, utc.month, utc.day);
    switch (this) {
      case CatalogPeriod.any:
        return (from: null, to: null);
      case CatalogPeriod.today:
        return (from: utc, to: today.add(const Duration(days: 1)));
      case CatalogPeriod.weekend:
        // Samedi 00:00 → lundi 00:00 ; pendant le week-end, à partir de
        // maintenant.
        final weekday = today.weekday; // lundi = 1, dimanche = 7
        if (weekday >= DateTime.saturday) {
          final monday = today.add(Duration(days: 8 - weekday));
          return (from: utc, to: monday);
        }
        final saturday = today.add(Duration(days: DateTime.saturday - weekday));
        return (from: saturday, to: saturday.add(const Duration(days: 2)));
      case CatalogPeriod.week:
        return (from: utc, to: today.add(const Duration(days: 8)));
    }
  }
}

/// Critères du catalogue public.
@immutable
final class CatalogQuery {
  const new({
    this.search = '',
    this.kinds = const {},
    this.city,
    this.period = CatalogPeriod.any,
    this.freeOnly = false,
  });

  final String search;
  final Set<EventKind> kinds;

  /// Ville exacte (liste `burkinaCities`), `null` = toutes les villes.
  final String? city;
  final CatalogPeriod period;
  final bool freeOnly;

  /// Nombre de filtres actifs (hors recherche et ville), pour le badge.
  int get filterCount =>
      kinds.length + (period == CatalogPeriod.any ? 0 : 1) + (freeOnly ? 1 : 0);

  /// Un critère réduit la liste (la mise en avant disparaît alors).
  bool get narrowed => search.trim().isNotEmpty || filterCount > 0;

  CatalogQuery copyWith({
    String? search,
    Set<EventKind>? kinds,
    String? city,
    bool clearCity = false,
    CatalogPeriod? period,
    bool? freeOnly,
  }) => CatalogQuery(
    search: search ?? this.search,
    kinds: kinds ?? this.kinds,
    city: clearCity ? null : city ?? this.city,
    period: period ?? this.period,
    freeOnly: freeOnly ?? this.freeOnly,
  );

  @override
  bool operator ==(Object other) =>
      other is CatalogQuery &&
      other.search == search &&
      setEquals(other.kinds, kinds) &&
      other.city == city &&
      other.period == period &&
      other.freeOnly == freeOnly;

  @override
  int get hashCode => Object.hash(
    search,
    Object.hashAllUnordered(kinds),
    city,
    period,
    freeOnly,
  );
}

/// Événement du catalogue public (champs de vitrine seulement).
@immutable
final class PublicEventSummary {
  const new({
    required this.id,
    required this.title,
    required this.kind,
    required this.startsAt,
    required this.endsAt,
    required this.timezone,
    required this.organizationName,
    this.venue,
    this.city,
    this.coverUrl,
    this.minPrice,
  });

  /// Lit une ligne de `public_events`.
  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? coverUrlOf,
  }) {
    final cover = json['cover_path'] as String?;
    return PublicEventSummary(
      id: json['id']! as String,
      title: json['title']! as String,
      kind: EventKind.fromWire(json['kind']),
      startsAt: DateTime.parse(json['starts_at']! as String).toUtc(),
      endsAt: DateTime.parse(json['ends_at']! as String).toUtc(),
      timezone: (json['timezone'] as String?) ?? 'Africa/Ouagadougou',
      venue: json['venue'] as String?,
      city: json['city'] as String?,
      // `cover_url` : ligne relue depuis l'appareil (voir [toJson]).
      coverUrl: cover == null
          ? json['cover_url'] as String?
          : coverUrlOf?.call(cover),
      organizationName: json['organization_name']! as String,
      minPrice: (json['min_price'] as num?)?.toInt(),
    );
  }

  final String id;
  final String title;
  final EventKind kind;
  final DateTime startsAt;
  final DateTime endsAt;
  final String timezone;
  final String? venue;
  final String? city;
  final String? coverUrl;
  final String organizationName;

  /// Plus petit prix indicatif, `null` si l'organisateur n'en donne pas.
  final int? minPrice;

  /// Ligne gardée sur l'appareil, relue par [PublicEventSummary.fromJson]
  /// (l'adresse de l'affiche y est déjà résolue).
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.wireName,
    'starts_at': startsAt.toIso8601String(),
    'ends_at': endsAt.toIso8601String(),
    'timezone': timezone,
    'venue': ?venue,
    'city': ?city,
    'cover_url': ?coverUrl,
    'organization_name': organizationName,
    'min_price': ?minPrice,
  };
}

/// Catégorie de ticket telle que le public la voit.
typedef PublicCategory = ({String name, int? price});

/// Fiche publique d'un événement.
@immutable
final class PublicEventDetail {
  const new({
    required this.summary,
    required this.categories,
    this.description,
    this.venueAddress,
    this.organizationLogoUrl,
    this.publicPhone,
    this.organizationId,
    this.latitude,
    this.longitude,
  });

  /// Lit la réponse de `public_event`.
  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? coverUrlOf,
    String Function(String path)? logoUrlOf,
  }) {
    final organization = Map<String, Object?>.from(
      json['organization']! as Map,
    );
    final logo = organization['logo_path'] as String?;
    return PublicEventDetail(
      summary: PublicEventSummary.fromJson({
        ...json,
        'organization_name': organization['name'],
      }, coverUrlOf: coverUrlOf),
      description: json['description'] as String?,
      venueAddress: json['venue_address'] as String?,
      organizationLogoUrl: logo == null ? null : logoUrlOf?.call(logo),
      publicPhone: organization['public_phone'] as String?,
      organizationId: organization['id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      categories: [
        for (final row in (json['categories'] as List?) ?? const [])
          (
            name: (row as Map)['name']! as String,
            price: (row['indicative_price'] as num?)?.toInt(),
          ),
      ],
    );
  }

  final PublicEventSummary summary;
  final String? description;
  final String? venueAddress;
  final String? organizationLogoUrl;

  /// Numéro WhatsApp public de l'organisation (format international).
  final String? publicPhone;

  /// Structure organisatrice (page publique) ; `null` avant la migration 5500.
  final String? organizationId;

  /// Position du lieu, si l'organisateur l'a indiquée.
  final double? latitude;
  final double? longitude;
  final List<PublicCategory> categories;
}

/// Page publique d'une structure (`public_organization`, ADR 0045).
@immutable
final class PublicOrganization {
  const new({
    required this.id,
    required this.name,
    required this.createdAt,
    this.city,
    this.logoUrl,
    this.publicPhone,
    this.pastEvents = 0,
    this.events = const [],
  });

  /// Lit la réponse de `public_organization`.
  factory fromJson(
    Map<String, Object?> json, {
    String Function(String path)? coverUrlOf,
    String Function(String path)? logoUrlOf,
  }) {
    final logo = json['logo_path'] as String?;
    return PublicOrganization(
      id: json['id']! as String,
      name: json['name']! as String,
      city: json['city'] as String?,
      logoUrl: logo == null ? null : logoUrlOf?.call(logo),
      publicPhone: json['public_phone'] as String?,
      createdAt: DateTime.parse(json['created_at']! as String).toUtc(),
      pastEvents: (json['past_events'] as num?)?.toInt() ?? 0,
      events: [
        for (final row in (json['events'] as List?) ?? const [])
          PublicEventSummary.fromJson(
            Map<String, Object?>.from(row as Map),
            coverUrlOf: coverUrlOf,
          ),
      ],
    );
  }

  final String id;
  final String name;
  final String? city;
  final String? logoUrl;

  /// Numéro WhatsApp public (format international).
  final String? publicPhone;

  /// Date d'arrivée sur Tikéo.
  final DateTime createdAt;

  /// Événements publics déjà terminés.
  final int pastEvents;

  /// Événements visibles au catalogue, par date.
  final List<PublicEventSummary> events;
}

/// Échecs du catalogue.
enum CatalogFailure implements Exception {
  /// Événement inconnu, privé ou terminé.
  notFound,

  /// Pas de réseau.
  network,

  /// Autre erreur.
  unknown,
}

/// Lecture du catalogue public (sans compte).
abstract interface class CatalogRepository {
  /// Événements publics correspondant à [query], par date de début.
  Future<List<PublicEventSummary>> search(
    CatalogQuery query, {
    required DateTime now,
    int offset = 0,
    int limit = 30,
  });

  /// Fiche publique d'un événement.
  Future<PublicEventDetail> event(String id);

  /// « À la une » : choisis par l'administrateur, dans l'ordre ; à défaut,
  /// les 5 prochains événements publics (ADR 0028).
  Future<List<PublicEventSummary>> featured();

  /// Page publique d'une structure ; [CatalogFailure.notFound] si elle est
  /// inconnue ou n'est plus active.
  Future<PublicOrganization> organization(String id);
}

/// Lien WhatsApp vers [phone] (format international) avec un message prêt.
Uri whatsAppUri(String phone, String message) => Uri.https(
  'wa.me',
  '/${phone.replaceAll(RegExp('[^0-9]'), '')}',
  {'text': message},
);

/// Itinéraire vers le lieu dans Google Maps (application ou site) : par la
/// position si elle est connue, sinon par le nom et l'adresse du lieu.
Uri directionsUri(PublicEventDetail detail) {
  if ((detail.latitude, detail.longitude) case (final lat?, final lng?)) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
    });
  }
  final event = detail.summary;
  final place = [?event.venue, ?detail.venueAddress, ?event.city].join(', ');
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': place.isEmpty ? event.title : place,
  });
}

/// Événement à ajouter à l'agenda du téléphone.
typedef CalendarEntry = ({
  String title,
  DateTime start,
  DateTime end,
  String? location,
  String? description,
});
