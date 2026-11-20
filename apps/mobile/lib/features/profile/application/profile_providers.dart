import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;
import 'package:ticketsur/features/profile/domain/profile.dart';

/// Dépôt du profil (Supabase au démarrage, faux dépôt en test).
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => throw UnimplementedError(
    'profileRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Sélecteur de photo carrée (photo de profil, logo) : image plus petite.
final squareImagePickerProvider = Provider<CoverPicker>(
  (ref) =>
      (source) => pickImage(source, maxDimension: 512),
);

/// Taille maximale d'un avatar ou d'un logo (bucket : 1 Mo).
const int maxSquareImageBytes = 1024 * 1024;

/// Profil de l'utilisateur connecté.
class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() => ref.read(profileRepositoryProvider).load();

  /// Modifie le nom, le téléphone et la langue.
  /// Lève une [ProfileFailure] en cas d'échec.
  Future<UserProfile> save({
    required String displayName,
    String? phone,
    String? locale,
  }) async {
    final updated = await ref
        .read(profileRepositoryProvider)
        .update(
          displayName: displayName,
          phone: phone,
          locale: locale ?? state.value?.locale ?? 'fr',
        );
    state = AsyncData(updated);
    return updated;
  }

  /// Change la photo de profil.
  Future<UserProfile> setAvatar(CoverImage image) async {
    final current = state.value;
    if (current == null) throw ProfileFailure.unknown;
    if (!acceptedCoverTypes.contains(image.mimeType) ||
        image.bytes.length > maxSquareImageBytes) {
      throw ProfileFailure.avatarInvalid;
    }
    final updated = await ref
        .read(profileRepositoryProvider)
        .setAvatar(current, image);
    state = AsyncData(updated);
    return updated;
  }

  /// Demande ou annule la suppression du compte.
  Future<void> requestDeletion({required bool requested}) async {
    final at = await ref
        .read(profileRepositoryProvider)
        .requestDeletion(requested: requested);
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      UserProfile(
        id: current.id,
        displayName: current.displayName,
        avatarPath: current.avatarPath,
        avatarUrl: current.avatarUrl,
        phone: current.phone,
        locale: current.locale,
        deletionRequestedAt: at,
      ),
    );
  }
}

/// Profil de l'utilisateur connecté (libéré à la déconnexion).
final AsyncNotifierProvider<ProfileController, UserProfile> profileProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, UserProfile>(
      ProfileController.new,
      retry: (retryCount, error) => null,
    );

/// Langue du compte gardée égale à celle de l'application : le serveur
/// écrit les notifications dans la langue de leur destinataire. Tenu par
/// la coque connectée ; un échec est réessayé au prochain démarrage.
final FutureProvider<void> profileLocaleSyncProvider =
    FutureProvider.autoDispose<void>((ref) async {
      final tag = ref.watch(appLocaleProvider).languageCode;
      final UserProfile profile;
      try {
        profile = await ref.watch(profileProvider.future);
      } on Object {
        return;
      }
      if (profile.locale == tag) return;
      try {
        await ref
            .read(profileProvider.notifier)
            .save(
              displayName: profile.displayName,
              phone: profile.phone,
              locale: tag,
            );
      } on Object {
        // Réessayé au prochain démarrage.
      }
    });
