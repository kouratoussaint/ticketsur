import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';

/// Dépôt des organisations (Supabase au démarrage, faux dépôt en test).
final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) => throw UnimplementedError(
    'organizationRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Préférences locales (chargées au démarrage).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Organisations de l'utilisateur et organisation active.
@immutable
final class OrganizationsState {
  /// Crée l'état.
  const new({required this.all, required this.active});

  /// Toutes les organisations dont l'utilisateur est membre.
  final List<Organization> all;

  /// Organisation de travail courante, `null` si aucune.
  final Organization? active;

  /// Vrai si l'utilisateur doit d'abord créer (ou rejoindre) une organisation.
  bool get isEmpty => all.isEmpty;
}

/// Organisations de l'utilisateur connecté. L'organisation active est
/// mémorisée sur l'appareil, par utilisateur.
class OrganizationsController extends AsyncNotifier<OrganizationsState> {
  String? get _prefsKey {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    return userId == null ? null : 'active_organization.$userId';
  }

  @override
  Future<OrganizationsState> build() async {
    // Recharge à chaque changement d'utilisateur.
    ref.watch(currentUserProvider);
    final all = await ref
        .read(organizationRepositoryProvider)
        .myOrganizations();
    return _withActive(all, _storedActiveId());
  }

  String? _storedActiveId() {
    final key = _prefsKey;
    return key == null
        ? null
        : ref.read(sharedPreferencesProvider).getString(key);
  }

  OrganizationsState _withActive(List<Organization> all, String? activeId) {
    final active =
        all.where((o) => o.id == activeId).firstOrNull ?? all.firstOrNull;
    return OrganizationsState(all: all, active: active);
  }

  /// Crée une organisation et en fait l'organisation active.
  /// Lève une [OrganizationFailure] en cas d'échec.
  Future<Organization> create(String name) async {
    final created = await ref.read(organizationRepositoryProvider).create(name);
    final all = await ref
        .read(organizationRepositoryProvider)
        .myOrganizations();
    await _remember(created.id);
    state = AsyncData(_withActive(all, created.id));
    return created;
  }

  /// Change d'organisation active.
  Future<void> select(Organization organization) async {
    final current = state.value;
    if (current == null) return;
    await _remember(organization.id);
    state = AsyncData(_withActive(current.all, organization.id));
  }

  /// Recharge depuis le serveur.
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> _remember(String organizationId) async {
    final key = _prefsKey;
    if (key == null) return;
    await ref.read(sharedPreferencesProvider).setString(key, organizationId);
  }
}

/// Organisations de l'utilisateur connecté.
///
/// Pas de relance automatique (Riverpod 3 en fait par défaut) : en cas
/// d'échec, l'utilisateur voit l'erreur et un bouton « Réessayer » plutôt
/// qu'un chargement qui tourne sans explication.
final organizationsProvider =
    AsyncNotifierProvider<OrganizationsController, OrganizationsState>(
      OrganizationsController.new,
      retry: (retryCount, error) => null,
    );

/// Organisation active (raccourci).
final activeOrganizationProvider = Provider<Organization?>(
  (ref) => ref.watch(organizationsProvider).value?.active,
);
