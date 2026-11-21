import 'package:ticketsur/features/org_settings/domain/org_settings.dart';

/// Réglages en mémoire, comme le serveur : un par structure, les
/// propositions ajoutées seulement si leur nom manque à l'événement.
class FakeOrgSettingsRepository implements OrgSettingsRepository {
  new([Map<String, OrgSettings>? settings]) : settings = settings ?? {};

  final Map<String, OrgSettings> settings;
  final List<String> calls = [];
  OrgSettingsFailure? failure;

  /// Résultat renvoyé par [applyToEvent].
  AppliedDefaults applied = (categories: 0, checkpoints: 0);

  @override
  Future<OrgSettings> read(String organizationId) async {
    calls.add('read $organizationId');
    if (failure case final f?) throw f;
    return settings[organizationId] ?? const OrgSettings();
  }

  @override
  Future<OrgSettings> save(String organizationId, OrgSettings value) async {
    calls.add('save $organizationId');
    if (failure case final f?) throw f;
    return settings[organizationId] = value;
  }

  @override
  Future<AppliedDefaults> applyToEvent(String eventId) async {
    calls.add('apply $eventId');
    if (failure case final f?) throw f;
    return applied;
  }
}
