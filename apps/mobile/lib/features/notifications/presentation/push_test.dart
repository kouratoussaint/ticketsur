import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Attente (côté serveur) avant l'envoi de la notification de test : le
/// temps de mettre l'application en arrière-plan.
const pushTestDelay = Duration(seconds: 8);

/// Notification de test vers ce téléphone (console, administrateurs) :
/// vérifie la chaîne complète d'envoi.
Future<void> sendTestNotification(BuildContext context, WidgetRef ref) async {
  final toaster = Toaster.of(context);
  final l10n = context.l10n;
  final service = ref.read(pushServiceProvider);
  final devices = ref.read(pushRepositoryProvider);
  try {
    // Jeton actuel du téléphone, au cas où il aurait changé.
    if (await service.token() case final token?) {
      await devices.register(token);
    }
    await devices.sendTest();
  } on PushTestException catch (error) {
    toaster.error(switch (error.failure) {
      PushTestFailure.noDevice => l10n.settingsPushTestNoDevice,
      PushTestFailure.rateLimited => l10n.settingsPushTestRateLimited,
      PushTestFailure.network => l10n.settingsPushTestNetwork,
    }, key: const Key('settings-push-test-error'));
    return;
  } on Object {
    toaster.error(
      l10n.settingsPushTestNetwork,
      key: const Key('settings-push-test-error'),
    );
    return;
  }
  toaster.info(
    l10n.settingsPushTestSent,
    key: const Key('settings-push-test-sent'),
    duration: pushTestDelay,
  );
  // L'attente se fait sur le serveur : en arrière-plan, le téléphone
  // suspend l'application et un minuteur local partirait en retard.
  await devices.flush(delay: pushTestDelay);
}
