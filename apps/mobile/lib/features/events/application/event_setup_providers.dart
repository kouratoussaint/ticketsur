import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show AsyncNotifierProviderFamily;
import 'package:ticketsur/features/events/domain/event_setup.dart';

/// Dépôt des catégories et portes (Supabase au démarrage, faux en test).
final eventSetupRepositoryProvider = Provider<EventSetupRepository>(
  (ref) => throw UnimplementedError(
    'eventSetupRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Catégories d'un événement. Après chaque écriture, la liste est relue :
/// les compteurs restent ceux du serveur.
class CategoriesController extends AsyncNotifier<List<TicketCategory>> {
  new(this.eventId);

  final String eventId;

  EventSetupRepository get _repository =>
      ref.read(eventSetupRepositoryProvider);

  @override
  Future<List<TicketCategory>> build() => _repository.categories(eventId);

  /// Lève une [SetupFailure] en cas d'échec.
  Future<void> create(
    String name,
    int? capacity, {
    bool isInvitation = false,
    int? price,
  }) async {
    final created = await _repository.createCategory(
      eventId,
      name,
      capacity,
      isInvitation: isInvitation,
    );
    if (price != null) {
      await _repository.setCategoryPrice(created.id, price);
    }
    await _refresh();
  }

  Future<void> edit(
    String categoryId,
    String name,
    int? capacity, {
    required bool isInvitation,
    int? price,
    int? previousPrice,
  }) async {
    await _repository.updateCategory(
      categoryId,
      name,
      capacity,
      isInvitation: isInvitation,
    );
    if (price != previousPrice) {
      await _repository.setCategoryPrice(categoryId, price);
    }
    await _refresh();
  }

  Future<void> delete(String categoryId) async {
    await _repository.deleteCategory(categoryId);
    await _refresh();
  }

  Future<void> _refresh() async {
    state = AsyncData(await _repository.categories(eventId));
  }
}

/// Catégories d'un événement (organisateurs).
final AsyncNotifierProviderFamily<
  CategoriesController,
  List<TicketCategory>,
  String
>
categoriesProvider = AsyncNotifierProvider.autoDispose
    .family<CategoriesController, List<TicketCategory>, String>(
      CategoriesController.new,
      retry: (retryCount, error) => null,
    );

/// Portes d'un événement.
class CheckpointsController extends AsyncNotifier<List<Checkpoint>> {
  new(this.eventId);

  final String eventId;

  EventSetupRepository get _repository =>
      ref.read(eventSetupRepositoryProvider);

  @override
  Future<List<Checkpoint>> build() => _repository.checkpoints(eventId);

  /// Lève une [SetupFailure] en cas d'échec.
  Future<void> create(String name) async {
    final created = await _repository.createCheckpoint(eventId, name);
    state = AsyncData([...?state.value, created]);
  }

  Future<void> edit(
    String checkpointId,
    String name, {
    required bool active,
  }) async {
    final updated = await _repository.updateCheckpoint(
      checkpointId,
      name,
      active: active,
    );
    final current = state.value ?? const <Checkpoint>[];
    state = AsyncData(
      current.map((c) => c.id == updated.id ? updated : c).toList(),
    );
  }
}

/// Portes d'un événement.
final AsyncNotifierProviderFamily<
  CheckpointsController,
  List<Checkpoint>,
  String
>
checkpointsProvider = AsyncNotifierProvider.autoDispose
    .family<CheckpointsController, List<Checkpoint>, String>(
      CheckpointsController.new,
      retry: (retryCount, error) => null,
    );
