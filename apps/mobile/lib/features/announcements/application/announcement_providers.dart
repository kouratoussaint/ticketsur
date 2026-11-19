import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/announcements/domain/announcement.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

/// Annonces ; surchargé dans `main.dart` et dans les tests.
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => throw UnimplementedError(
    'announcementRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Clé des annonces masquées sur l'appareil.
const dismissedAnnouncementsKey = 'announcements.dismissed';

/// Annonces en cours pour l'appelant, relues à chaque changement de compte.
/// Un échec n'affiche rien : une annonce n'est jamais bloquante.
final FutureProvider<List<Announcement>> myAnnouncementsProvider =
    FutureProvider.autoDispose<List<Announcement>>((ref) async {
      ref.watch(currentUserProvider);
      try {
        return await ref.read(announcementRepositoryProvider).mine();
      } on AnnouncementFailure {
        return const [];
      }
    });

/// Annonces masquées par l'utilisateur sur cet appareil.
class DismissedAnnouncements extends Notifier<Set<String>> {
  @override
  Set<String> build() => {
    ...?ref
        .read(sharedPreferencesProvider)
        .getStringList(dismissedAnnouncementsKey),
  };

  Future<void> dismiss(String id) async {
    // On ne garde que les 50 dernières.
    final next = [...state, id];
    state = next.skip(next.length > 50 ? next.length - 50 : 0).toSet();
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(dismissedAnnouncementsKey, state.toList());
  }
}

final NotifierProvider<DismissedAnnouncements, Set<String>>
dismissedAnnouncementsProvider =
    NotifierProvider<DismissedAnnouncements, Set<String>>(
      DismissedAnnouncements.new,
    );
