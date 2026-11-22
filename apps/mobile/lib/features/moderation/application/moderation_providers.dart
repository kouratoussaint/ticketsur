import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/moderation/domain/moderation.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => throw UnimplementedError(
    'moderationRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Nombre de contenus signalés à traiter (pastille de la console) ; 0 en
/// cas d'échec (rôle sans la permission, réseau).
final FutureProvider<int> openReportsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
      try {
        final page = await ref
            .read(moderationRepositoryProvider)
            .reports(limit: 1);
        return page.open;
      } on Object {
        return 0;
      }
    });
