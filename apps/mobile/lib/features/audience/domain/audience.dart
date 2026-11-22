/// Mesures d'audience du promoteur (lot 4-12c, ADR 0051).
library;

/// Nombre d'un jour (heure UTC, celle du Burkina Faso).
typedef DailyCount = ({DateTime day, int count});

/// Une série : [total] (toutes les vues, ou les abonnés actuels), [recent]
/// (vues sur 7 jours, ou arrivées sur 30 jours) et les 30 derniers jours,
/// du plus ancien à aujourd'hui.
final class AudienceSeries {
  const new({required this.total, required this.recent, required this.days});

  factory fromJson(
    Map<String, Object?> json, {
    required String totalKey,
    required String recentKey,
  }) => AudienceSeries(
    total: (json[totalKey] as num? ?? 0).toInt(),
    recent: (json[recentKey] as num? ?? 0).toInt(),
    days: [
      for (final raw in (json['days'] as List?) ?? const [])
        if (raw case {'day': final String day, 'count': final num count})
          (
            // Jour seul (« 2030-06-01 ») : minuit UTC.
            day: DateTime.parse(day.length == 10 ? '${day}T00:00:00Z' : day),
            count: count.toInt(),
          ),
    ],
  );

  final int total;
  final int recent;
  final List<DailyCount> days;
}

enum AudienceFailure implements Exception { network, notFound, unknown }

abstract interface class AudienceRepository {
  /// Une vue de la fiche publique (visiteurs compris) ; sans effet si
  /// l'événement n'est pas au catalogue.
  Future<void> recordEventView(String eventId);

  /// Vues de la fiche publique : total, 7 jours, 30 jours (propriétaire ou
  /// gestionnaire).
  Future<AudienceSeries> eventViews(String eventId);

  /// Abonnés de la structure : nombre, arrivées sur 30 jours, par jour.
  Future<AudienceSeries> followerStats(String organizationId);
}
