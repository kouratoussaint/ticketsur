// Base complète : les versions réduites (« latest », « latest_10y ») omettent
// les alias IANA comme Africa/Ouagadougou, Africa/Dakar ou Africa/Kinshasa.
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Fuseau proposé dans le formulaire d'événement.
typedef TimeZoneChoice = ({String id, String label});

/// Fuseaux proposés, Afrique de l'Ouest d'abord. Tous existent dans la base
/// IANA côté serveur (`pg_timezone_names`) et côté application.
const List<TimeZoneChoice> eventTimeZones = [
  (id: 'Africa/Ouagadougou', label: 'Burkina Faso — Ouagadougou'),
  (id: 'Africa/Abidjan', label: "Côte d'Ivoire — Abidjan"),
  (id: 'Africa/Bamako', label: 'Mali — Bamako'),
  (id: 'Africa/Niamey', label: 'Niger — Niamey'),
  (id: 'Africa/Dakar', label: 'Sénégal — Dakar'),
  (id: 'Africa/Lome', label: 'Togo — Lomé'),
  (id: 'Africa/Porto-Novo', label: 'Bénin — Porto-Novo'),
  (id: 'Africa/Accra', label: 'Ghana — Accra'),
  (id: 'Africa/Conakry', label: 'Guinée — Conakry'),
  (id: 'Africa/Lagos', label: 'Nigeria — Lagos'),
  (id: 'Africa/Douala', label: 'Cameroun — Douala'),
  (id: 'Africa/Libreville', label: 'Gabon — Libreville'),
  (id: 'Africa/Kinshasa', label: 'RD Congo — Kinshasa'),
  (id: 'Africa/Casablanca', label: 'Maroc — Casablanca'),
  (id: 'Europe/Paris', label: 'France — Paris'),
  (id: 'Europe/Brussels', label: 'Belgique — Bruxelles'),
  (id: 'America/Toronto', label: 'Canada — Toronto / Montréal'),
  (id: 'UTC', label: 'UTC'),
];

/// Fuseau par défaut des nouveaux événements.
const String defaultEventTimeZone = 'Africa/Ouagadougou';

bool _loaded = false;

/// Charge la base des fuseaux (une fois, à la première utilisation).
void ensureTimeZonesLoaded() {
  if (_loaded) return;
  tz_data.initializeTimeZones();
  _loaded = true;
}

tz.Location _location(String zone) {
  ensureTimeZonesLoaded();
  try {
    return tz.getLocation(zone);
  } on tz.LocationNotFoundException {
    // Fuseau accepté par le serveur mais absent de la base embarquée :
    // affichage en UTC plutôt qu'un écran en erreur.
    return tz.UTC;
  }
}

/// Libellé lisible d'un fuseau (son identifiant s'il n'est pas proposé).
String timeZoneLabel(String zone) =>
    eventTimeZones.where((z) => z.id == zone).firstOrNull?.label ?? zone;

/// Heure murale, dans [zone], de l'instant [instant].
DateTime wallTimeIn(String zone, DateTime instant) {
  final local = tz.TZDateTime.from(instant.toUtc(), _location(zone));
  return DateTime(local.year, local.month, local.day, local.hour, local.minute);
}

/// Instant UTC de l'heure murale [wall] (année…minute) vécue dans [zone].
DateTime instantFromWallTime(String zone, DateTime wall) => tz.TZDateTime(
  _location(zone),
  wall.year,
  wall.month,
  wall.day,
  wall.hour,
  wall.minute,
).toUtc();

/// Décalage UTC de [zone] à l'instant [instant].
Duration utcOffsetOf(String zone, DateTime instant) =>
    tz.TZDateTime.from(instant.toUtc(), _location(zone)).timeZoneOffset;

/// Décalage UTC de [zone] à l'instant [instant], par exemple « UTC+1 ».
String utcOffsetLabel(String zone, DateTime instant) {
  final offset = tz.TZDateTime.from(
    instant.toUtc(),
    _location(zone),
  ).timeZoneOffset;
  if (offset == Duration.zero) return 'UTC';
  final sign = offset.isNegative ? '−' : '+';
  final minutes = offset.inMinutes.abs();
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0
      ? 'UTC$sign$hours'
      : 'UTC$sign$hours:${rest.toString().padLeft(2, '0')}';
}
