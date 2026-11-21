import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/announcements/application/announcement_providers.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/billing/application/billing_admin_providers.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/dashboard/application/dashboard_providers.dart';
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/journal/presentation/journal_page.dart';
import 'package:ticketsur/features/legal/application/legal_providers.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';
import 'package:ticketsur/features/org_settings/application/org_settings_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/reports/application/report_providers.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_camera.dart';
import 'package:ticketsur/features/search/application/search_providers.dart';
import 'package:ticketsur/features/security/application/admin_mfa_providers.dart';
import 'package:ticketsur/features/security/application/security_providers.dart';
import 'package:ticketsur/features/security/domain/security.dart';
import 'package:ticketsur/features/support/application/support_providers.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/ticket_import/application/import_providers.dart';
import 'package:ticketsur/features/ticket_send/application/send_providers.dart';
import 'package:ticketsur/features/ticket_templates/application/template_providers.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/updates/application/update_providers.dart';
import 'package:ticketsur/features/wallet/application/wallet_providers.dart';

import 'fake_admin_accounts_repository.dart';
import 'fake_admin_mfa_repository.dart';
import 'fake_admin_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_billing_admin_repository.dart';
import 'fake_billing_repository.dart';
import 'fake_catalog_repository.dart';
import 'fake_dashboard_repository.dart';
import 'fake_device_security.dart';
import 'fake_event_repository.dart';
import 'fake_event_setup_repository.dart';
import 'fake_journal_repository.dart';
import 'fake_legal_repository.dart';
import 'fake_org_settings_repository.dart';
import 'fake_organization_repository.dart';
import 'fake_profile_repository.dart';
import 'fake_push.dart';
import 'fake_report_repository.dart';
import 'fake_scan_camera.dart';
import 'fake_scan_repository.dart';
import 'fake_search_repository.dart';
import 'fake_sound_player.dart';
import 'fake_support_repository.dart';
import 'fake_team_repository.dart';
import 'fake_ticket_repository.dart';
import 'fake_ticket_sender.dart';
import 'fake_ticket_template_repository.dart';
import 'fake_wallet_repository.dart';

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
  FakeReportRepository? report,
  FakeCatalogRepository? catalog,
  FakeAdminRepository? admin,
  FakeBillingAdminRepository? billingAdmin,
  FakeBillingRepository? billing,
  FakeSupportRepository? support,
  FakeAnnouncementRepository? announcements,
  FakeLegalRepository? legal,
  FakeWalletRepository? wallet,
  FakeDeviceSecurityRepository? devices,
  FakeSearchRepository? search,
  FakeOrgSettingsRepository? orgSettings,
  FakeAdminMfaRepository? mfa,
  FakeAdminAccountsRepository? adminAccounts,
  FakeBiometricService? biometric,
  FakePushService? push,
  FakePushRepository? pushDevices,
  FakeJournalRepository? journal,
  FakeTicketTemplateRepository? templates,
  List<Locale> deviceLocales = const [Locale('fr', 'BF')],
  TicketBackgroundRenderer? backgroundRenderer,
  Future<String?> Function()? qrFromImage,
  FakeUpdateChecker? updates,
  int installedBuild = 0,
  Future<bool> Function(Uri uri)? openLink,
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
    // Téléphone en français : l'app suit sa langue par défaut.
    deviceLocalesProvider.overrideWithValue(deviceLocales),
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
    catalogRepositoryProvider.overrideWithValue(
      catalog ?? FakeCatalogRepository(),
    ),
    adminRepositoryProvider.overrideWithValue(admin ?? FakeAdminRepository()),
    billingAdminRepositoryProvider.overrideWithValue(
      billingAdmin ?? FakeBillingAdminRepository(),
    ),
    billingRepositoryProvider.overrideWithValue(
      billing ?? FakeBillingRepository(),
    ),
    supportRepositoryProvider.overrideWithValue(
      support ?? FakeSupportRepository(),
    ),
    announcementRepositoryProvider.overrideWithValue(
      announcements ?? FakeAnnouncementRepository(),
    ),
    legalRepositoryProvider.overrideWithValue(legal ?? FakeLegalRepository()),
    walletRepositoryProvider.overrideWithValue(
      wallet ?? FakeWalletRepository(),
    ),
    deviceSecurityRepositoryProvider.overrideWithValue(
      devices ?? FakeDeviceSecurityRepository(),
    ),
    searchRepositoryProvider.overrideWithValue(
      search ?? FakeSearchRepository(),
    ),
    orgSettingsRepositoryProvider.overrideWithValue(
      orgSettings ?? FakeOrgSettingsRepository(),
    ),
    adminMfaRepositoryProvider.overrideWithValue(
      mfa ?? FakeAdminMfaRepository(),
    ),
    adminAccountsRepositoryProvider.overrideWithValue(
      adminAccounts ?? FakeAdminAccountsRepository(),
    ),
    biometricServiceProvider.overrideWithValue(
      biometric ?? FakeBiometricService(),
    ),
    deviceIdentityProvider.overrideWith(
      (ref) async => const DeviceIdentity(
        label: 'Tecno Spark 10',
        platform: 'android',
        appBuild: 139,
      ),
    ),
    qrFromImageProvider.overrideWithValue(qrFromImage ?? () async => null),
    pushServiceProvider.overrideWithValue(push ?? const NoPushService()),
    ticketTemplateRepositoryProvider.overrideWithValue(
      templates ?? FakeTicketTemplateRepository(),
    ),
    // Fond simple (sans rendu réel) dans les PDF.
    ticketBackgroundRendererProvider.overrideWithValue(
      backgroundRenderer ??
          (
            context, {
            required art,
            required template,
            required categoryName,
            invitation = false,
          }) async => null,
    ),
    journalRepositoryProvider.overrideWithValue(
      journal ?? FakeJournalRepository(),
    ),
    pushRepositoryProvider.overrideWithValue(
      pushDevices ?? FakePushRepository(),
    ),
    updateCheckerProvider.overrideWithValue(updates ?? FakeUpdateChecker()),
    installedBuildProvider.overrideWithValue(installedBuild),
    updateClockProvider.overrideWithValue(() => DateTime.utc(2030, 6)),
    externalLinkProvider.overrideWithValue(openLink ?? (_) async => true),
    catalogClockProvider.overrideWithValue(() => DateTime.utc(2030, 6)),
    reportRepositoryProvider.overrideWithValue(
      report ?? FakeReportRepository(),
    ),
    // Pas de rendu réel : toImage n'avance pas dans un test de widgets.
    ticketImageRendererProvider.overrideWithValue(
      (renderer ?? FakeTicketRenderer()).call,
    ),
  ];
}
