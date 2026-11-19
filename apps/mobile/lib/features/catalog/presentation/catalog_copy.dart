import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/l10n/gen/app_localizations.dart';

/// Libellé pluriel d'une catégorie d'événement (puces de l'Explorer).
String exploreKindLabel(AppLocalizations l10n, EventKind kind) =>
    switch (kind) {
      EventKind.concert => l10n.exploreKindConcert,
      EventKind.conference => l10n.exploreKindConference,
      EventKind.worship => l10n.exploreKindWorship,
      EventKind.sport => l10n.exploreKindSport,
      EventKind.wedding => l10n.exploreKindWedding,
      EventKind.training => l10n.exploreKindTraining,
      EventKind.gala => l10n.exploreKindGala,
      EventKind.other => l10n.exploreKindOther,
    };

/// Catégories proposées en puces, dans l'ordre (les mariages, presque
/// toujours privés, restent dans les filtres).
const List<EventKind> exploreKinds = [
  EventKind.concert,
  EventKind.conference,
  EventKind.sport,
  EventKind.gala,
  EventKind.training,
  EventKind.worship,
  EventKind.other,
];

/// Teinte du bloc date d'une catégorie (texte blanc, ≥ 4,5:1).
Color exploreKindColor(EventKind kind) => switch (kind) {
  EventKind.concert => const Color(0xFF0A3A66),
  EventKind.conference => const Color(0xFF00695C),
  EventKind.sport => const Color(0xFFB23A0E),
  EventKind.gala => const Color(0xFF3B2C6B),
  EventKind.training => const Color(0xFF1F5F8B),
  EventKind.worship => const Color(0xFF6B3A2C),
  EventKind.wedding => const Color(0xFF8A2A5A),
  EventKind.other => const Color(0xFF34495E),
};

/// « 2 000 FCFA ».
String formatFcfa(AppLocalizations l10n, int amount) =>
    l10n.explorePrice(NumberFormat.decimalPattern('fr').format(amount));

/// Prix affiché sur une carte : « Dès 2 000 FCFA », « Entrée gratuite » ou
/// rien.
String? summaryPrice(AppLocalizations l10n, PublicEventSummary event) =>
    switch (event.minPrice) {
      null => null,
      0 => l10n.exploreFree,
      final price => l10n.exploreFromPrice(formatFcfa(l10n, price)),
    };

/// Date courte : « sam. 22 nov. · 20:00 ».
String summaryWhen(PublicEventSummary event) {
  final start = wallTimeIn(event.timezone, event.startsAt);
  return '${DateFormat('EEE d MMM', 'fr').format(start)} · '
      '${formatEventTime(start)}';
}

/// Plage complète, dans le fuseau de l'événement.
String summaryRange(PublicEventSummary event) {
  final start = wallTimeIn(event.timezone, event.startsAt);
  final end = wallTimeIn(event.timezone, event.endsAt);
  final sameDay =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  return sameDay
      ? '${formatEventDay(start)} · ${formatEventTime(start)} – '
            '${formatEventTime(end)}'
      : '${formatEventDay(start)} · ${formatEventTime(start)} → '
            '${formatEventDay(end)} · ${formatEventTime(end)}';
}

/// Lieu : « Jardin de la musique · Ouagadougou ».
String summaryPlace(PublicEventSummary event) =>
    [?event.venue, ?event.city].join(' · ');
