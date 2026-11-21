import 'package:ticketsur/features/platform/domain/platform_status.dart';

/// État de la plateforme réglable dans les tests.
class FakePlatformRepository implements PlatformRepository {
  new({this.value = const PlatformStatus()});

  PlatformStatus value;
  int reads = 0;

  @override
  Future<PlatformStatus> status() async {
    reads++;
    return value;
  }
}
