import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/moderation/domain/moderation.dart';

/// Groupe de signalements de test.
ReportGroup reportGroup({
  String id = 'ev-r1',
  ReportKind kind = ReportKind.event,
  String title = 'Concert douteux',
  int count = 2,
  Map<ReportReason, int>? reasons,
  List<ReportComment> comments = const [],
  ReportStatus status = ReportStatus.open,
  bool removed = false,
}) => ReportGroup(
  kind: kind,
  id: id,
  organizationId: 'org-r',
  organizationName: 'Faso Fake',
  title: title,
  count: count,
  reasons: reasons ?? {ReportReason.scam: count},
  comments: comments,
  firstAt: DateTime.utc(2030, 5, 30, 10),
  lastAt: DateTime.utc(2030, 5, 31, 18),
  status: status,
  removed: removed,
  startsAt: kind == ReportKind.event ? DateTime.utc(2030, 6, 20, 20) : null,
  handledAt: status == ReportStatus.open ? null : DateTime.utc(2030, 5, 31, 19),
);

/// Faux signalements : [reported] note chaque signalement, [open] et
/// [handled] sont les listes de la console ; [resolve] déplace un groupe.
class FakeModerationRepository implements ModerationRepository {
  new({List<ReportGroup>? open, List<ReportGroup>? handled})
    : open = [...?open],
      handled = [...?handled];

  final List<ReportGroup> open;
  final List<ReportGroup> handled;
  final List<String> reported = [];
  final List<String> calls = [];
  Exception? failure;

  @override
  Future<bool> report(
    ReportKind kind,
    String id,
    ReportReason reason, {
    String? comment,
  }) async {
    if (failure case final failure?) throw failure;
    final key = '${kind.name} $id';
    final already = reported.any((r) => r.startsWith('$key '));
    reported.add('$key ${reason.name} ${comment ?? '∅'}');
    return already;
  }

  @override
  Future<ReportsPage> reports({
    bool open = true,
    int offset = 0,
    int limit = 30,
  }) async {
    calls.add('reports ${open ? 'open' : 'handled'}');
    if (failure case final failure?) throw failure;
    final list = open ? this.open : handled;
    return (
      open: this.open.length,
      items: list.skip(offset).take(limit).toList(),
    );
  }

  @override
  Future<int> resolve(
    ReportKind kind,
    String id, {
    required bool remove,
    required String reason,
  }) async {
    calls.add(
      'resolve ${kind.name} $id ${remove ? 'remove' : 'dismiss'} $reason',
    );
    if (failure case final failure?) throw failure;
    final index = open.indexWhere((g) => g.kind == kind && g.id == id);
    if (index < 0) throw AdminFailure.notFound;
    final group = open.removeAt(index);
    handled.insert(
      0,
      reportGroup(
        id: group.id,
        kind: group.kind,
        title: group.title,
        count: group.count,
        status: remove ? ReportStatus.actioned : ReportStatus.dismissed,
        removed: remove,
      ),
    );
    return group.count;
  }
}
