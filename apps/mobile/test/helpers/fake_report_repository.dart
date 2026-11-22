import 'package:ticketsur/features/reports/domain/report.dart';

/// Faux dépôt du rapport : renvoie [data] (ou lève [failure]).
class FakeReportRepository implements ReportRepository {
  new([this.data = const []]);

  List<ReportRow> data;
  ReportFailure? failure;
  final List<String> calls = [];

  @override
  Future<List<ReportRow>> rows(String eventId, {bool closed = false}) async {
    calls.add(closed ? 'closed:$eventId' : eventId);
    if (failure case final failure?) throw failure;
    return data;
  }
}
