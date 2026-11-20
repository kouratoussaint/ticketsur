import 'package:ticketsur/features/events/domain/event_setup.dart';

/// Faux dépôt des catégories et portes, piloté par les tests.
class FakeEventSetupRepository implements EventSetupRepository {
  new({List<TicketCategory>? categories, List<Checkpoint>? checkpoints})
    : categoryRows = [...?categories],
      checkpointRows = [...?checkpoints];

  final List<TicketCategory> categoryRows;
  final List<Checkpoint> checkpointRows;

  SetupFailure? nextLoadFailure;
  SetupFailure? nextWriteFailure;

  /// Refus du seul appel `setCategoryEntries`.
  SetupFailure? nextEntriesFailure;
  final List<String> calls = [];
  int _ids = 0;

  void _write(String call) {
    calls.add(call);
    if (nextWriteFailure case final failure?) {
      nextWriteFailure = null;
      throw failure;
    }
  }

  @override
  Future<List<TicketCategory>> categories(String eventId) async {
    if (nextLoadFailure case final failure?) {
      nextLoadFailure = null;
      throw failure;
    }
    return [
      for (final c in categoryRows)
        if (c.eventId == eventId) c,
    ];
  }

  @override
  Future<TicketCategory> createCategory(
    String eventId,
    String name,
    int? capacity, {
    bool isInvitation = false,
  }) async {
    _write(
      'createCategory $name $capacity${isInvitation ? ' invitation' : ''}',
    );
    final created = TicketCategory(
      id: 'cat-${++_ids}',
      eventId: eventId,
      name: name.trim(),
      capacity: capacity,
      isInvitation: isInvitation,
    );
    categoryRows.add(created);
    return created;
  }

  @override
  Future<TicketCategory> updateCategory(
    String categoryId,
    String name,
    int? capacity, {
    required bool isInvitation,
  }) async {
    _write(
      'updateCategory $categoryId $name $capacity'
      '${isInvitation ? ' invitation' : ''}',
    );
    final index = categoryRows.indexWhere((c) => c.id == categoryId);
    final old = categoryRows[index];
    final updated = old.copyWith(
      name: name.trim(),
      capacity: () => capacity,
      isInvitation: isInvitation,
    );
    categoryRows[index] = updated;
    return updated;
  }

  @override
  Future<void> setCategoryPrice(String categoryId, int? price) async {
    _write('price $categoryId $price');
    final index = categoryRows.indexWhere((c) => c.id == categoryId);
    final old = categoryRows[index];
    categoryRows[index] = old.copyWith(indicativePrice: () => price);
  }

  @override
  Future<void> setCategoryEntries(
    String categoryId,
    EntryPolicy policy,
    int? maxEntries,
  ) async {
    _write('entries $categoryId ${policy.wireName} $maxEntries');
    if (nextEntriesFailure case final failure?) {
      nextEntriesFailure = null;
      throw failure;
    }
    final index = categoryRows.indexWhere((c) => c.id == categoryId);
    categoryRows[index] = categoryRows[index].copyWith(
      entryPolicy: policy,
      maxEntries: () => policy == EntryPolicy.limited ? maxEntries : null,
    );
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    _write('deleteCategory $categoryId');
    categoryRows.removeWhere((c) => c.id == categoryId);
  }

  @override
  Future<List<Checkpoint>> checkpoints(String eventId) async => [
    for (final c in checkpointRows)
      if (c.eventId == eventId) c,
  ];

  @override
  Future<Checkpoint> createCheckpoint(String eventId, String name) async {
    _write('createCheckpoint $name');
    final created = Checkpoint(
      id: 'cp-${++_ids}',
      eventId: eventId,
      name: name.trim(),
      active: true,
    );
    checkpointRows.add(created);
    return created;
  }

  @override
  Future<Checkpoint> updateCheckpoint(
    String checkpointId,
    String name, {
    required bool active,
  }) async {
    _write('updateCheckpoint $checkpointId $name $active');
    final index = checkpointRows.indexWhere((c) => c.id == checkpointId);
    final updated = Checkpoint(
      id: checkpointId,
      eventId: checkpointRows[index].eventId,
      name: name.trim(),
      active: active,
    );
    checkpointRows[index] = updated;
    return updated;
  }
}
