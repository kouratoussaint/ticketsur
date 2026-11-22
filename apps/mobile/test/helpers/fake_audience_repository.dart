import 'package:ticketsur/features/audience/domain/audience.dart';

/// Série de test : 30 jours, [recent] arrivées aujourd'hui.
AudienceSeries audienceSeries({int total = 12, int recent = 3}) =>
    AudienceSeries(
      total: total,
      recent: recent,
      days: [
        for (var i = 0; i < 30; i++)
          (
            day: DateTime.utc(2030, 5, 3).add(Duration(days: i)),
            count: i == 29 ? recent : (i % 4 == 0 ? 1 : 0),
          ),
      ],
    );

/// Fausses mesures : [recorded] note les vues envoyées.
class FakeAudienceRepository implements AudienceRepository {
  new({this.views, this.followers});

  AudienceSeries? views;
  AudienceSeries? followers;
  final List<String> recorded = [];
  AudienceFailure? failure;

  @override
  Future<void> recordEventView(String eventId) async {
    if (failure case final failure?) throw failure;
    recorded.add(eventId);
  }

  @override
  Future<AudienceSeries> eventViews(String eventId) async {
    if (failure case final failure?) throw failure;
    return views ?? audienceSeries(total: 0, recent: 0);
  }

  @override
  Future<AudienceSeries> followerStats(String organizationId) async {
    if (failure case final failure?) throw failure;
    return followers ?? audienceSeries(total: 0, recent: 0);
  }
}
