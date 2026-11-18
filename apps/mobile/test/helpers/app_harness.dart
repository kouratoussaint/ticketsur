import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_camera.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';

import 'fake_auth_repository.dart';
import 'fake_event_repository.dart';
import 'fake_event_setup_repository.dart';
import 'fake_organization_repository.dart';
import 'fake_scan_camera.dart';
import 'fake_scan_repository.dart';
import 'fake_sound_player.dart';
import 'fake_team_repository.dart';
import 'fake_ticket_repository.dart';

/// Surcharges communes pour monter `TicketSurApp` dans un test.
///
/// Par défaut : une organisation de test sans événement, préférences vides,
/// sortie de l'application neutralisée.
Future<List<Override>> appOverrides({
  required FakeAuthRepository auth,
  FakeOrganizationRepository? organizations,
  FakeEventRepository? events,
  FakeEventSetupRepository? setup,
  FakeTeamRepository? team,
  Future<void> Function(String text)? share,
  FakeTicketRepository? tickets,
  FakeScanRepository? scan,
  FakeSoundPlayer? sounds,
  FakeCameraFeed? camera,
  Future<void> Function(List<SharedFile> files, {String? text})? shareFiles,
  Future<void> Function()? onExit,
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  return [
    authRepositoryProvider.overrideWithValue(auth),
    organizationRepositoryProvider.overrideWithValue(
      organizations ?? FakeOrganizationRepository([testOrganization]),
    ),
    eventRepositoryProvider.overrideWithValue(events ?? FakeEventRepository()),
    eventSetupRepositoryProvider.overrideWithValue(
      setup ?? FakeEventSetupRepository(),
    ),
    teamRepositoryProvider.overrideWithValue(team ?? FakeTeamRepository()),
    shareTextProvider.overrideWithValue(share ?? (_) async {}),
    ticketRepositoryProvider.overrideWithValue(
      tickets ?? FakeTicketRepository(),
    ),
    shareFilesProvider.overrideWithValue(
      shareFiles ?? (files, {text}) async {},
    ),
    scanRepositoryProvider.overrideWithValue(scan ?? FakeScanRepository()),
    scanRetryDelaysProvider.overrideWithValue(const [
      Duration.zero,
      Duration.zero,
    ]),
    soundPlayerProvider.overrideWithValue(sounds ?? FakeSoundPlayer()),
    scanCameraBuilderProvider.overrideWithValue(
      (camera ?? FakeCameraFeed()).builder,
    ),
    sharedPreferencesProvider.overrideWithValue(prefs),
    appExitProvider.overrideWithValue(onExit ?? () async {}),
  ];
}
