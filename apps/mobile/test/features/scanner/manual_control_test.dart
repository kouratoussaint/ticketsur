import 'package:flutter_test/flutter_test.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../../helpers/fake_scan_repository.dart';

/// Le contrôle ne dépend que de l'organisateur : « Démarrer le contrôle »
/// l'ouvre, « Arrêter le contrôle » le ferme ; plus aucune heure.
void main() {
  ScanPost post(EventStatus status) {
    final base = testPost();
    return ScanPost(
      eventId: base.eventId,
      eventTitle: base.eventTitle,
      eventStatus: status,
      timezone: base.timezone,
      // Événement terminé depuis longtemps : l'heure ne compte plus.
      startsAt: DateTime.utc(2020),
      endsAt: DateTime.utc(2020, 1, 2),
      organizationName: base.organizationName,
      checkpointId: base.checkpointId,
      checkpointName: base.checkpointName,
    );
  }

  test('état du contrôle selon le statut seulement', () {
    expect(post(EventStatus.published).window, ScanWindow.upcoming);
    expect(post(EventStatus.inProgress).window, ScanWindow.open);
    expect(post(EventStatus.closed).window, ScanWindow.closed);
  });

  test('« Arrêter le contrôle » depuis un contrôle en cours', () {
    final l10n = AppLocalizationsFr();
    expect(
      eventActionLabel(l10n, EventStatus.inProgress, EventStatus.published),
      'Démarrer le contrôle',
    );
    expect(
      eventActionLabel(l10n, EventStatus.closed, EventStatus.inProgress),
      'Arrêter le contrôle',
    );
    expect(
      eventActionLabel(l10n, EventStatus.closed, EventStatus.published),
      'Clôturer',
    );
    expect(
      eventConfirmBody(l10n, EventStatus.closed, EventStatus.inProgress),
      contains('Plus aucune entrée'),
    );
  });
}
