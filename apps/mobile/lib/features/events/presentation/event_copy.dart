import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
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

/// Libellé du bouton qui mène au statut [target] depuis [from].
String eventActionLabel(
  AppLocalizations l10n,
  EventStatus target, [
  EventStatus? from,
]) => switch (target) {
  EventStatus.published => l10n.eventActionPublish,
  EventStatus.inProgress => l10n.eventActionStart,
  EventStatus.closed when from == EventStatus.inProgress =>
    l10n.eventActionStop,
  EventStatus.closed => l10n.eventActionClose,
  EventStatus.archived => l10n.eventActionArchive,
  EventStatus.draft => l10n.eventActionDraft,
  EventStatus.cancelled => l10n.eventActionCancel,
};

/// Conséquence annoncée avant de passer au statut [target] depuis [from].
String eventConfirmBody(
  AppLocalizations l10n,
  EventStatus target, [
  EventStatus? from,
]) => switch (target) {
  EventStatus.published => l10n.eventConfirmPublish,
  EventStatus.inProgress => l10n.eventConfirmStart,
  EventStatus.closed when from == EventStatus.inProgress =>
    l10n.eventConfirmStop,
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

/// Couleurs d'une pastille de statut (direction artistique, section 3) :
/// en cours vert (« en direct »), à venir bleu, brouillon ambre, terminé et
/// archivé gris, annulé rouge. Fond pâle, icône et texte de la même teinte.
({Color background, Color foreground, Color icon, IconData glyph})
eventStatusStyle(
  EventStatus status, [
  Brightness brightness = Brightness.light,
]) {
  final tints = brightness == Brightness.dark
      ? TikeoTints.dark
      : TikeoTints.light;
  final (TikeoTint tint, IconData glyph) = switch (status) {
    EventStatus.draft => (tints.amber, Icons.edit_note_rounded),
    EventStatus.published => (tints.blue, Icons.public_rounded),
    EventStatus.inProgress => (tints.live, Icons.sensors_rounded),
    EventStatus.closed => (tints.gray, Icons.lock_rounded),
    EventStatus.archived => (tints.gray, Icons.inventory_2_rounded),
    EventStatus.cancelled => (tints.red, Icons.event_busy_rounded),
  };
  return (
    background: tint.background,
    foreground: tint.text,
    icon: tint.icon,
    glyph: glyph,
  );
}

/// Date longue, dans le fuseau de l'événement : « sam. 20 déc. 2026 ».
String formatEventDay(DateTime wall) =>
    DateFormat.yMMMEd(appLocaleTag).format(wall);

/// Heure : « 20:00 ».
String formatEventTime(DateTime wall) =>
    DateFormat('HH:mm', appLocaleTag).format(wall);

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
