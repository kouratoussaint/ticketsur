import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/app_config.dart';
import 'package:ticketsur/app/configuration_error_app.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/data/supabase_admin_repository.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/data/supabase_admin_accounts_repository.dart';
import 'package:ticketsur/features/admin_events/application/admin_events_providers.dart';
import 'package:ticketsur/features/admin_events/data/supabase_admin_events_repository.dart';
import 'package:ticketsur/features/admin_orgs/application/admin_orgs_providers.dart';
import 'package:ticketsur/features/admin_orgs/data/supabase_admin_orgs_repository.dart';
import 'package:ticketsur/features/admin_tools/application/admin_tools_providers.dart';
import 'package:ticketsur/features/admin_tools/data/supabase_admin_tools_repository.dart';
import 'package:ticketsur/features/announcements/application/announcement_providers.dart';
import 'package:ticketsur/features/announcements/data/supabase_announcement_repository.dart';
import 'package:ticketsur/features/audience/application/audience_providers.dart';
import 'package:ticketsur/features/audience/data/supabase_audience_repository.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/data/supabase_auth_repository.dart';
import 'package:ticketsur/features/billing/application/billing_admin_providers.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/billing/data/supabase_billing_admin_repository.dart';
import 'package:ticketsur/features/billing/data/supabase_billing_repository.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/data/supabase_catalog_repository.dart';
import 'package:ticketsur/features/closed_orgs/application/closed_org_providers.dart';
import 'package:ticketsur/features/closed_orgs/data/supabase_closed_org_repository.dart';
import 'package:ticketsur/features/dashboard/application/dashboard_providers.dart';
import 'package:ticketsur/features/dashboard/data/supabase_dashboard_repository.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/data/supabase_event_repository.dart';
import 'package:ticketsur/features/events/data/supabase_event_setup_repository.dart';
import 'package:ticketsur/features/journal/data/supabase_journal_repository.dart';
import 'package:ticketsur/features/journal/presentation/journal_page.dart';
import 'package:ticketsur/features/legal/application/legal_providers.dart';
import 'package:ticketsur/features/legal/data/supabase_legal_repository.dart';
import 'package:ticketsur/features/moderation/application/moderation_providers.dart';
import 'package:ticketsur/features/moderation/data/supabase_moderation_repository.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/notifications/data/firebase_push_service.dart';
import 'package:ticketsur/features/notifications/data/supabase_push_repository.dart';
import 'package:ticketsur/features/notifications/data/tray_notifier.dart';
import 'package:ticketsur/features/org_settings/application/org_settings_providers.dart';
import 'package:ticketsur/features/org_settings/data/supabase_org_settings_repository.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/data/supabase_organization_repository.dart';
import 'package:ticketsur/features/platform/application/platform_providers.dart';
import 'package:ticketsur/features/platform/data/supabase_platform_repository.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/profile/data/supabase_profile_repository.dart';
import 'package:ticketsur/features/reports/application/report_providers.dart';
import 'package:ticketsur/features/reports/data/supabase_report_repository.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/data/supabase_scan_repository.dart';
import 'package:ticketsur/features/search/application/search_providers.dart';
import 'package:ticketsur/features/search/data/supabase_search_repository.dart';
import 'package:ticketsur/features/security/application/admin_mfa_providers.dart';
import 'package:ticketsur/features/security/application/security_providers.dart';
import 'package:ticketsur/features/security/data/supabase_admin_mfa_repository.dart';
import 'package:ticketsur/features/security/data/supabase_device_security_repository.dart';
import 'package:ticketsur/features/support/application/support_providers.dart';
import 'package:ticketsur/features/support/data/supabase_support_repository.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/team/data/supabase_team_repository.dart';
import 'package:ticketsur/features/ticket_templates/application/template_providers.dart';
import 'package:ticketsur/features/ticket_templates/data/supabase_ticket_template_repository.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/data/supabase_ticket_repository.dart';
import 'package:ticketsur/features/updates/application/update_providers.dart';
import 'package:ticketsur/features/updates/data/github_update_checker.dart';
import 'package:ticketsur/features/wallet/application/wallet_providers.dart';
import 'package:ticketsur/features/wallet/data/supabase_wallet_repository.dart';

/// Lancement : `flutter run --dart-define-from-file=config/staging.json`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final problem = config.problem;
  if (problem != null) {
    runApp(ConfigurationErrorApp(problem: problem));
    return;
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
  );
  final preferences = await SharedPreferences.getInstance();
  final client = Supabase.instance.client;
  await _setUpImageCache();

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          SupabaseAuthRepository(client.auth),
        ),
        organizationRepositoryProvider.overrideWithValue(
          SupabaseOrganizationRepository(client),
        ),
        eventRepositoryProvider.overrideWithValue(
          SupabaseEventRepository(client),
        ),
        eventSetupRepositoryProvider.overrideWithValue(
          SupabaseEventSetupRepository(client),
        ),
        dashboardRepositoryProvider.overrideWithValue(
          SupabaseDashboardRepository(client),
        ),
        catalogRepositoryProvider.overrideWithValue(
          SupabaseCatalogRepository(client),
        ),
        adminRepositoryProvider.overrideWithValue(
          SupabaseAdminRepository(client),
        ),
        moderationRepositoryProvider.overrideWithValue(
          SupabaseModerationRepository(client),
        ),
        audienceRepositoryProvider.overrideWithValue(
          SupabaseAudienceRepository(client),
        ),
        billingAdminRepositoryProvider.overrideWithValue(
          SupabaseBillingAdminRepository(client),
        ),
        billingRepositoryProvider.overrideWithValue(
          SupabaseBillingRepository(client),
        ),
        closedOrgRepositoryProvider.overrideWithValue(
          SupabaseClosedOrgRepository(client),
        ),
        reportRepositoryProvider.overrideWithValue(
          SupabaseReportRepository(client),
        ),
        teamRepositoryProvider.overrideWithValue(
          SupabaseTeamRepository(client),
        ),
        ticketRepositoryProvider.overrideWithValue(
          SupabaseTicketRepository(client),
        ),
        scanRepositoryProvider.overrideWithValue(
          SupabaseScanRepository(client),
        ),
        profileRepositoryProvider.overrideWithValue(
          SupabaseProfileRepository(client),
        ),
        supportRepositoryProvider.overrideWithValue(
          SupabaseSupportRepository(client),
        ),
        announcementRepositoryProvider.overrideWithValue(
          SupabaseAnnouncementRepository(client),
        ),
        legalRepositoryProvider.overrideWithValue(
          SupabaseLegalRepository(client),
        ),
        updateCheckerProvider.overrideWithValue(const GitHubUpdateChecker()),
        walletRepositoryProvider.overrideWithValue(
          SupabaseWalletRepository(client),
        ),
        deviceSecurityRepositoryProvider.overrideWithValue(
          SupabaseDeviceSecurityRepository(client),
        ),
        searchRepositoryProvider.overrideWithValue(
          SupabaseSearchRepository(client),
        ),
        orgSettingsRepositoryProvider.overrideWithValue(
          SupabaseOrgSettingsRepository(client),
        ),
        adminMfaRepositoryProvider.overrideWithValue(
          SupabaseAdminMfaRepository(client),
        ),
        adminAccountsRepositoryProvider.overrideWithValue(
          SupabaseAdminAccountsRepository(client),
        ),
        adminOrgsRepositoryProvider.overrideWithValue(
          SupabaseAdminOrgsRepository(client),
        ),
        adminEventsRepositoryProvider.overrideWithValue(
          SupabaseAdminEventsRepository(client),
        ),
        adminToolsRepositoryProvider.overrideWithValue(
          SupabaseAdminToolsRepository(client),
        ),
        platformRepositoryProvider.overrideWithValue(
          SupabasePlatformRepository(client),
        ),
        ticketTemplateRepositoryProvider.overrideWithValue(
          SupabaseTicketTemplateRepository(client),
        ),
        journalRepositoryProvider.overrideWithValue(
          SupabaseJournalRepository(client),
        ),
        pushRepositoryProvider.overrideWithValue(
          SupabasePushRepository(client),
        ),
        if (FirebaseConfig.configured)
          pushServiceProvider.overrideWithValue(FirebasePushService()),
        trayNotifierProvider.overrideWithValue(AndroidTrayNotifier()),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const TicketSurApp(),
    ),
  );
}

/// Cache disque des images (lot 3c) : jamais bloquant.
Future<void> _setUpImageCache() async {
  try {
    final root = await getApplicationCacheDirectory();
    final directory = Directory('${root.path}/images');
    networkImageCacheDirectory = directory;
    unawaited(pruneNetworkImageCache(directory));
  } on Object {
    // Sans cache : les images se chargent depuis le réseau.
  }
}
