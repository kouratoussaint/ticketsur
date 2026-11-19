import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/dashboard/application/dashboard_providers.dart';
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_camera.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/ticket_import/application/import_providers.dart';
import 'package:ticketsur/features/ticket_send/application/send_providers.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';

import 'fake_auth_repository.dart';
import 'fake_dashboard_repository.dart';
import 'fake_event_repository.dart';
import 'fake_event_setup_repository.dart';
import 'fake_organization_repository.dart';
import 'fake_profile_repository.dart';
import 'fake_scan_camera.dart';
import 'fake_scan_repository.dart';
import 'fake_sound_player.dart';
import 'fake_team_repository.dart';
import 'fake_ticket_repository.dart';
import 'fake_ticket_sender.dart';

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
  CoverPicker? coverPicker,
  CoverPicker? squarePicker,
  FakeProfileRepository? profile,
  FakeDashboardRepository? dashboard,
  Future<PickedFile?> Function()? importPicker,
  FakeTicketSender? sender,
  FakeTicketRenderer? renderer,
  Duration dashboardRefresh = const Duration(hours: 1),
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
    // Aucun sélecteur système en test : annulation par défaut.
    coverPickerProvider.overrideWithValue(coverPicker ?? (_) async => null),
    squareImagePickerProvider.overrideWithValue(
      squarePicker ?? (_) async => null,
    ),
    profileRepositoryProvider.overrideWithValue(
      profile ?? FakeProfileRepository(),
    ),
    dashboardRepositoryProvider.overrideWithValue(
      dashboard ?? FakeDashboardRepository(),
    ),
    // Actualisation automatique neutralisée par défaut dans les tests.
    dashboardRefreshIntervalProvider.overrideWithValue(dashboardRefresh),
    // Aucun sélecteur système en test : renoncement par défaut.
    importFilePickerProvider.overrideWithValue(
      importPicker ?? () async => null,
    ),
    ticketSenderProvider.overrideWithValue(sender ?? FakeTicketSender()),
    // Pas de rendu réel : toImage n'avance pas dans un test de widgets.
    ticketImageRendererProvider.overrideWithValue(
      (renderer ?? FakeTicketRenderer()).call,
    ),
  ];
}
