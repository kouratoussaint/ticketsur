import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/audience/domain/audience.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

final audienceRepositoryProvider = Provider<AudienceRepository>(
  (ref) => throw UnimplementedError(
    'audienceRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Vues de la fiche publique d'un événement (promoteur).
final FutureProviderFamily<AudienceSeries, String> eventViewsProvider =
    FutureProvider.autoDispose.family<AudienceSeries, String>(
      (ref, id) => ref.read(audienceRepositoryProvider).eventViews(id),
      retry: (retryCount, error) => null,
    );

/// Abonnés d'une structure (promoteur).
final FutureProviderFamily<AudienceSeries, String> followerStatsProvider =
    FutureProvider.autoDispose.family<AudienceSeries, String>(
      (ref, id) => ref.read(audienceRepositoryProvider).followerStats(id),
      retry: (retryCount, error) => null,
    );

/// Préférence : événements déjà comptés aujourd'hui sur cet appareil.
const String eventViewsPreference = 'audience.viewed';

/// Compte une vue de la fiche publique, une fois par appareil, par événement
/// et par jour (ADR 0051). Rien n'est envoyé d'autre que l'événement ; un
/// échec est ignoré (la vue sera comptée à la prochaine ouverture).
final FutureProviderFamily<void, String> eventViewRecorderProvider =
    FutureProvider.autoDispose.family<void, String>((ref, id) async {
      final prefs = ref.read(sharedPreferencesProvider);
      final now = ref.read(catalogClockProvider)().toUtc();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final saved = switch (prefs.getString(eventViewsPreference)) {
        final String raw => jsonDecode(raw),
        null => null,
      };
      final seen = <String>[
        if (saved
            case {'day': final String day, 'events': final List<Object?> ids}
            when day == today)
          for (final e in ids)
            if (e case final String eventId) eventId,
      ];
      if (seen.contains(id)) return;
      try {
        await ref.read(audienceRepositoryProvider).recordEventView(id);
      } on Object {
        return;
      }
      await prefs.setString(
        eventViewsPreference,
        jsonEncode({
          'day': today,
          'events': [...seen, id].reversed.take(200).toList(),
        }),
      );
    }, retry: (retryCount, error) => null);
