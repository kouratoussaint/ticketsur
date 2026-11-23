import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:shared_preferences/shared_preferences.dart';
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

/// Préférence : numéro d'installation (32 caractères tirés au hasard,
/// sans lien avec le téléphone ni le compte).
const String installationIdPreference = 'audience.device';

/// Numéro d'installation envoyé avec une vue (ADR 0052) ; créé au premier
/// besoin. Le serveur n'en garde qu'une empreinte du jour.
String installationId(SharedPreferences prefs) {
  final saved = prefs.getString(installationIdPreference);
  if (saved != null && RegExp(r'^[A-Za-z0-9-]{16,64}$').hasMatch(saved)) {
    return saved;
  }
  final random = Random.secure();
  final id = [
    for (var i = 0; i < 16; i++)
      random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
  unawaited(prefs.setString(installationIdPreference, id));
  return id;
}

/// Préférence : événements déjà comptés aujourd'hui sur cet appareil.
const String eventViewsPreference = 'audience.viewed';

/// Compte une vue de la fiche publique, une fois par appareil, par événement
/// et par jour (ADR 0051). C'est le serveur qui garantit l'unicité
/// (ADR 0052) ; ce filtre évite seulement des appels inutiles. Un échec est
/// ignoré (la vue sera envoyée à la prochaine ouverture).
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
        await ref
            .read(audienceRepositoryProvider)
            .recordEventView(id, device: installationId(prefs));
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
