import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;
import 'package:ticketsur/features/profile/domain/profile.dart';

/// Faux dépôt de profil, piloté par les tests.
class FakeProfileRepository implements ProfileRepository {
  new([UserProfile? profile])
    : profile =
          profile ?? const UserProfile(id: 'u1', displayName: 'Awa Ouédraogo');

  UserProfile profile;

  /// Échec du prochain appel (chargement ou écriture), puis effacé.
  ProfileFailure? nextFailure;

  final List<({String name, String? phone})> updateCalls = [];
  final List<CoverImage> avatarCalls = [];
  final List<bool> deletionCalls = [];

  void _fail() {
    if (nextFailure case final failure?) {
      nextFailure = null;
      throw failure;
    }
  }

  @override
  Future<UserProfile> load() async {
    _fail();
    return profile;
  }

  @override
  Future<UserProfile> update({
    required String displayName,
    String? phone,
    String locale = 'fr',
  }) async {
    updateCalls.add((name: displayName, phone: phone));
    _fail();
    final digits = phone?.replaceAll(RegExp('[^0-9]'), '') ?? '';
    return profile = UserProfile(
      id: profile.id,
      displayName: displayName.trim().replaceAll(RegExp(r'\s+'), ' '),
      avatarPath: profile.avatarPath,
      avatarUrl: profile.avatarUrl,
      phone: digits.isEmpty
          ? null
          : digits.length == 8
          ? '+226$digits'
          : '+$digits',
      locale: locale,
      deletionRequestedAt: profile.deletionRequestedAt,
    );
  }

  @override
  Future<UserProfile> setAvatar(UserProfile current, CoverImage image) async {
    avatarCalls.add(image);
    _fail();
    final path = '${current.id}/avatar-${avatarCalls.length}.jpg';
    return profile = UserProfile(
      id: current.id,
      displayName: current.displayName,
      avatarPath: path,
      avatarUrl: 'https://avatars.test/$path',
      phone: current.phone,
      locale: current.locale,
      deletionRequestedAt: current.deletionRequestedAt,
    );
  }

  @override
  Future<DateTime?> requestDeletion({required bool requested}) async {
    deletionCalls.add(requested);
    _fail();
    return requested ? DateTime.utc(2030) : null;
  }
}
