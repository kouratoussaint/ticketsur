import 'package:ticketsur/features/security/domain/security.dart';

ConnectedDevice connectedDevice({
  String id = 's1',
  String? label = 'Tecno Spark 10',
  String? platform = 'android',
  bool current = false,
}) => ConnectedDevice(
  sessionId: id,
  label: label,
  platform: platform,
  signedInAt: DateTime.utc(2030, 5, 20, 9),
  lastSeenAt: DateTime.utc(2030, 5, 31, 18),
  current: current,
);

/// Appareils en mémoire.
class FakeDeviceSecurityRepository implements DeviceSecurityRepository {
  new({List<ConnectedDevice>? devices})
    : list = devices ?? [connectedDevice(id: 'here', current: true)];

  final List<ConnectedDevice> list;
  final List<DeviceIdentity> registered = [];
  final List<String> calls = [];

  /// Prochaine inscription refusée (ex. [DeviceFailure.sessionRevoked]).
  DeviceFailure? nextRegisterFailure;

  @override
  Future<void> register(DeviceIdentity device) async {
    registered.add(device);
    if (nextRegisterFailure case final failure?) {
      nextRegisterFailure = null;
      throw failure;
    }
  }

  @override
  Future<List<ConnectedDevice>> devices() async => [...list];

  @override
  Future<void> revoke(String sessionId) async {
    calls.add('revoke $sessionId');
    list.removeWhere((d) => d.sessionId == sessionId);
  }

  @override
  Future<int> revokeOthers() async {
    calls.add('others');
    final before = list.length;
    list.removeWhere((d) => !d.current);
    return before - list.length;
  }
}

/// Empreinte simulée.
class FakeBiometricService implements BiometricService {
  new({this.available = true, this.succeed = true});

  bool available;
  bool succeed;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return succeed;
  }
}
