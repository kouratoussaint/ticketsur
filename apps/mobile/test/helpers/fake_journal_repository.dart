import 'package:ticketsur/features/journal/domain/journal.dart';

/// Journal en mémoire, filtré par familles d'actions.
class FakeJournalRepository implements JournalRepository {
  new([List<JournalEntry>? entries]) : all = [...?entries];

  final List<JournalEntry> all;
  final List<JournalFilter> filters = [];

  @override
  Future<List<JournalEntry>> entries(
    String organizationId, {
    JournalFilter filter = JournalFilter.all,
    int offset = 0,
    int limit = 50,
  }) async {
    filters.add(filter);
    return [
      for (final e in all)
        if (filter.prefixes.isEmpty || filter.prefixes.any(e.action.startsWith))
          e,
    ].skip(offset).take(limit).toList();
  }
}
