import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/app_config.dart';
import 'package:ticketsur/app/configuration_error_app.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/data/supabase_auth_repository.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/data/supabase_catalog_repository.dart';
import 'package:ticketsur/features/dashboard/application/dashboard_providers.dart';
import 'package:ticketsur/features/dashboard/data/supabase_dashboard_repository.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/data/supabase_event_repository.dart';
import 'package:ticketsur/features/events/data/supabase_event_setup_repository.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/data/supabase_organization_repository.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/profile/data/supabase_profile_repository.dart';
import 'package:ticketsur/features/reports/application/report_providers.dart';
import 'package:ticketsur/features/reports/data/supabase_report_repository.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/data/supabase_scan_repository.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/team/data/supabase_team_repository.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/data/supabase_ticket_repository.dart';

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
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const TicketSurApp(),
    ),
  );
}
