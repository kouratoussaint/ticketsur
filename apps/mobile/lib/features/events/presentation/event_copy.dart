import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/l10n/gen/app_localizations.dart';

/// Libellé d'un statut.
String eventStatusLabel(AppLocalizations l10n, EventStatus status) =>
    switch (status) {
      EventStatus.draft => l10n.eventStatusDraft,
      EventStatus.published => l10n.eventStatusPublished,
      EventStatus.inProgress => l10n.eventStatusInProgress,
      EventStatus.closed => l10n.eventStatusClosed,
      EventStatus.archived => l10n.eventStatusArchived,
      EventStatus.cancelled => l10n.eventStatusCancelled,
    };

/// Explication du statut courant.
String eventLifecycleHint(AppLocalizations l10n, EventStatus status) =>
    switch (status) {
      EventStatus.draft => l10n.eventLifecycleDraft,
      EventStatus.published => l10n.eventLifecyclePublished,
      EventStatus.inProgress => l10n.eventLifecycleInProgress,
      EventStatus.closed => l10n.eventLifecycleClosed,
      EventStatus.archived => l10n.eventLifecycleArchived,
      EventStatus.cancelled => l10n.eventLifecycleCancelled,
    };

/// Libellé du bouton qui mène au statut [target].
String eventActionLabel(AppLocalizations l10n, EventStatus target) =>
    switch (target) {
      EventStatus.published => l10n.eventActionPublish,
      EventStatus.inProgress => l10n.eventActionStart,
      EventStatus.closed => l10n.eventActionClose,
      EventStatus.archived => l10n.eventActionArchive,
      EventStatus.draft => l10n.eventActionDraft,
      EventStatus.cancelled => l10n.eventActionCancel,
    };

/// Conséquence annoncée avant de passer au statut [target].
String eventConfirmBody(AppLocalizations l10n, EventStatus target) =>
    switch (target) {
      EventStatus.published => l10n.eventConfirmPublish,
      EventStatus.inProgress => l10n.eventConfirmStart,
      EventStatus.closed => l10n.eventConfirmClose,
      EventStatus.archived => l10n.eventConfirmArchive,
      EventStatus.draft => l10n.eventConfirmDraft,
      EventStatus.cancelled => l10n.eventConfirmCancel,
    };

/// Libellé d'un type d'événement.
String eventKindLabel(AppLocalizations l10n, EventKind kind) => switch (kind) {
  EventKind.concert => l10n.eventKindConcert,
  EventKind.conference => l10n.eventKindConference,
  EventKind.worship => l10n.eventKindWorship,
  EventKind.sport => l10n.eventKindSport,
  EventKind.wedding => l10n.eventKindWedding,
  EventKind.training => l10n.eventKindTraining,
  EventKind.gala => l10n.eventKindGala,
  EventKind.other => l10n.eventKindOther,
};

/// Icône d'un type d'événement.
IconData eventKindIcon(EventKind kind) => switch (kind) {
  EventKind.concert => Icons.music_note_rounded,
  EventKind.conference => Icons.mic_external_on_rounded,
  EventKind.worship => Icons.church_rounded,
  EventKind.sport => Icons.sports_soccer_rounded,
  EventKind.wedding => Icons.favorite_rounded,
  EventKind.training => Icons.school_rounded,
  EventKind.gala => Icons.nightlife_rounded,
  EventKind.other => Icons.celebration_rounded,
};

/// Transition sans retour possible (bouton et confirmation en rouge).
bool isFinalTransition(EventStatus target) =>
    target == EventStatus.closed ||
    target == EventStatus.cancelled ||
    target == EventStatus.archived;

/// Message d'un échec.
String eventFailureMessage(AppLocalizations l10n, EventFailure failure) =>
    switch (failure) {
      EventFailure.notFound => l10n.eventErrorNotFound,
      EventFailure.titleInvalid => l10n.eventErrorTitle,
      EventFailure.venueInvalid => l10n.eventErrorVenue,
      EventFailure.datesInvalid => l10n.eventErrorDates,
      EventFailure.timezoneInvalid => l10n.eventErrorTimezone,
      EventFailure.capacityInvalid => l10n.eventErrorCapacity,
      EventFailure.capacityBelowIssued => l10n.eventErrorCapacityBelowIssued,
      EventFailure.locked => l10n.eventErrorLocked,
      EventFailure.invalidTransition => l10n.eventErrorInvalidTransition,
      EventFailure.hasTickets => l10n.eventErrorHasTickets,
      EventFailure.alreadyEnded => l10n.eventErrorAlreadyEnded,
      EventFailure.incomplete => l10n.eventErrorIncomplete,
      EventFailure.cityInvalid => l10n.eventErrorCity,
      EventFailure.addressInvalid => l10n.eventErrorAddress,
      EventFailure.descriptionInvalid => l10n.eventErrorDescription,
      EventFailure.coverInvalid => l10n.eventErrorCover,
      EventFailure.blocked => l10n.eventErrorBlocked,
      EventFailure.network => l10n.eventErrorNetwork,
      EventFailure.unknown => l10n.eventErrorUnknown,
    };

/// Couleurs d'une pastille de statut : fond teinté, texte bleu nuit en
/// clair et presque blanc en sombre (contraste ≥ 7:1 sur toutes les
/// teintes), icône colorée.
({Color background, Color foreground, Color icon, IconData glyph})
eventStatusStyle(
  EventStatus status, [
  Brightness brightness = Brightness.light,
]) => brightness == Brightness.dark
    ? _darkStatusStyle(status)
    : _lightStatusStyle(status);

const _darkInk = Color(0xFFE6ECF4);

({Color background, Color foreground, Color icon, IconData glyph})
_darkStatusStyle(EventStatus status) {
  final light = _lightStatusStyle(status);
  final (Color background, Color icon) = switch (status) {
    EventStatus.draft ||
    EventStatus.closed => (const Color(0xFF22344F), const Color(0xFFB8C4D6)),
    EventStatus.published => (const Color(0xFF0B3A63), const Color(0xFF7CC8FB)),
    EventStatus.inProgress => (
      const Color(0xFF0F4220),
      const Color(0xFF7FE08F),
    ),
    EventStatus.archived => (const Color(0xFF1C2B42), const Color(0xFFB8C4D6)),
    EventStatus.cancelled => (const Color(0xFF4A1A20), const Color(0xFFFFB4AB)),
  };
  return (
    background: background,
    foreground: _darkInk,
    icon: icon,
    glyph: light.glyph,
  );
}

({Color background, Color foreground, Color icon, IconData glyph})
_lightStatusStyle(EventStatus status) => switch (status) {
  EventStatus.draft => (
    background: const Color(0xFFE3E8EF),
    foreground: TicketSurColors.navy,
    icon: const Color(0xFF52627A),
    glyph: Icons.edit_note_rounded,
  ),
  EventStatus.published => (
    background: const Color(0xFFDDF0FD),
    foreground: TicketSurColors.navy,
    icon: TicketSurColors.mintDeep,
    glyph: Icons.public_rounded,
  ),
  EventStatus.inProgress => (
    background: const Color(0xFFDCF5E1),
    foreground: TicketSurColors.navy,
    icon: TicketSurColors.successStrong,
    glyph: Icons.sensors_rounded,
  ),
  EventStatus.closed => (
    background: const Color(0xFFE3E8EF),
    foreground: TicketSurColors.navy,
    icon: const Color(0xFF52627A),
    glyph: Icons.lock_rounded,
  ),
  EventStatus.archived => (
    background: const Color(0xFFEDEFF3),
    foreground: TicketSurColors.navy,
    icon: const Color(0xFF52627A),
    glyph: Icons.inventory_2_rounded,
  ),
  EventStatus.cancelled => (
    background: const Color(0xFFFBE2E4),
    foreground: TicketSurColors.navy,
    icon: const Color(0xFFB02A37),
    glyph: Icons.event_busy_rounded,
  ),
};

/// Date longue, dans le fuseau de l'événement : « sam. 20 déc. 2026 ».
String formatEventDay(DateTime wall) =>
    DateFormat('EEE d MMM y', 'fr').format(wall);

/// Heure : « 20:00 ».
String formatEventTime(DateTime wall) => DateFormat('HH:mm', 'fr').format(wall);

/// Plage horaire d'un événement dans son fuseau :
/// « sam. 20 déc. 2026 · 20:00 – 23:30 » ou, sur plusieurs jours,
/// « sam. 20 déc. 2026 · 20:00 → dim. 21 déc. 2026 · 02:00 ».
String formatEventRange(TicketEvent event) {
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
