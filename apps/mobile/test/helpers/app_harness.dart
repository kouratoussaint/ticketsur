import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

import 'fake_auth_repository.dart';
import 'fake_event_repository.dart';
import 'fake_organization_repository.dart';

/// Surcharges communes pour monter `TicketSurApp` dans un test.
///
/// Par défaut : une organisation de test sans événement, préférences vides,
/// sortie de l'application neutralisée.
Future<List<Override>> appOverrides({
  required FakeAuthRepository auth,
  FakeOrganizationRepository? organizations,
  FakeEventRepository? events,
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
    sharedPreferencesProvider.overrideWithValue(prefs),
    appExitProvider.overrideWithValue(onExit ?? () async {}),
  ];
}
