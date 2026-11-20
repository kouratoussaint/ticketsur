import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/legal/presentation/legal_pages.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/profile/presentation/appearance_card.dart';
import 'package:ticketsur/features/profile/presentation/feedback_settings_card.dart';
import 'package:ticketsur/features/settings/presentation/language_card.dart';
import 'package:ticketsur/features/updates/application/update_providers.dart';
import 'package:ticketsur/features/updates/presentation/update_banner.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Taille du cache des images, en octets (0 sans cache).
final FutureProvider<int> imageCacheSizeProvider =
    FutureProvider.autoDispose<int>((ref) async {
      final directory = networkImageCacheDirectory;
      if (directory == null || !directory.existsSync()) return 0;
      var total = 0;
      for (final entity in directory.listSync()) {
        if (entity is File) total += entity.lengthSync();
      }
      return total;
    });

String _megabytes(int bytes) {
  final value = bytes / (1024 * 1024);
  return '${value.toStringAsFixed(value < 10 ? 1 : 0).replaceAll('.', ',')} Mo';
}

/// Paramètres : apparence, sons, stockage, version, mentions légales.
/// Ouverte à tous, avec ou sans compte.
class SettingsPage extends ConsumerWidget {
  const new({super.key});

  Future<void> _clearImages(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final directory = networkImageCacheDirectory;
    if (directory != null && directory.existsSync()) {
      try {
        await directory.delete(recursive: true);
      } on Object {
        // Fichier en cours d'écriture : il partira au prochain élagage.
      }
    }
    PaintingBinding.instance.imageCache.clear();
    ref.invalidate(imageCacheSizeProvider);
    toast.success(l10n.settingsImageCacheCleared);
  }

  Future<void> _checkUpdate(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    await ref.read(availableUpdateProvider.notifier).checkNow();
    final state = ref.read(availableUpdateProvider);
    if (state.value == null) {
      // Pas de version plus récente connue : à jour, ou vérification ratée.
      final failed = ref.read(installedBuildProvider) > 0 && state.hasError;
      toast.info(failed ? l10n.settingsCheckFailed : l10n.settingsUpToDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final installed = ref.watch(installedBuildProvider);
    final cacheSize = ref.watch(imageCacheSizeProvider).value ?? 0;
    final checking = ref.watch(availableUpdateProvider).isLoading;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.xs,
        TicketSurSpacing.lg,
        TicketSurSpacing.xs,
        TicketSurSpacing.xs,
      ),
      child: Text(title, style: textTheme.titleSmall),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: BackButton(onPressed: () => context.popOr(AppRoutes.profile)),
      ),
      body: ListView(
        key: const Key('settings'),
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          const UpdateBanner(),
          const AppearanceCard(),
          const SizedBox(height: TicketSurSpacing.md),
          const LanguageCard(),
          const SizedBox(height: TicketSurSpacing.md),
          const FeedbackSettingsCard(),
          section(l10n.settingsNotifications),
          const _PushCard(),
          section(l10n.settingsStorage),
          Card(
            child: ListTile(
              key: const Key('settings-image-cache'),
              leading: Icon(
                Icons.photo_library_rounded,
                color: context.palette.accentText,
              ),
              title: Text(l10n.settingsImageCache),
              subtitle: Text(
                cacheSize == 0
                    ? l10n.settingsImageCacheEmpty
                    : l10n.settingsImageCacheSize(_megabytes(cacheSize)),
              ),
              trailing: cacheSize == 0
                  ? null
                  : TextButton(
                      key: const Key('settings-image-cache-clear'),
                      onPressed: () => unawaited(_clearImages(context, ref)),
                      child: Text(l10n.settingsImageCacheClear),
                    ),
            ),
          ),
          section(l10n.settingsAbout),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(TicketSurSpacing.md),
                  child: Row(
                    children: [
                      const TikeoLogo(height: 32),
                      const SizedBox(width: TicketSurSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.appSlogan, style: textTheme.bodyMedium),
                            Text(
                              installed > 0
                                  ? l10n.settingsVersion(installed)
                                  : l10n.settingsVersionDev,
                              key: const Key('settings-version'),
                              style: textTheme.bodySmall?.copyWith(
                                color: context.palette.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('settings-check-update'),
                  enabled: installed > 0 && !checking,
                  leading: checking
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update_rounded),
                  title: Text(l10n.settingsCheckUpdate),
                  onTap: () => unawaited(_checkUpdate(context, ref)),
                ),
                for (final slug in LegalSlug.values)
                  ListTile(
                    key: Key('settings-legal-${slug.wireName}'),
                    leading: Icon(
                      slug == LegalSlug.terms
                          ? Icons.gavel_rounded
                          : Icons.privacy_tip_rounded,
                    ),
                    title: Text(legalTitle(l10n, slug)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => unawaited(context.push(AppRoutes.legal(slug))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.xl),
        ],
      ),
    );
  }
}

/// Attente (côté serveur) avant l'envoi de la notification de test : le
/// temps de mettre l'application en arrière-plan.
const pushTestDelay = Duration(seconds: 8);

/// Notifications : réglage et état sur ce téléphone.
class _PushCard extends ConsumerWidget {
  const new();

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(pushEnabledProvider);
    final status = ref.watch(pushSyncProvider).value;
    final unavailable = status == PushStatus.unavailable;
    final canTest =
        status == PushStatus.active &&
        ref.watch(currentUserProvider).value != null;
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            key: const Key('settings-push'),
            secondary: Icon(
              enabled && !unavailable
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: context.palette.accentText,
            ),
            title: Text(l10n.settingsPushSwitch),
            subtitle: Text(switch (status) {
              PushStatus.unavailable => l10n.settingsPushUnavailable,
              PushStatus.denied => l10n.settingsPushDenied,
              PushStatus.disabled => l10n.settingsPushDisabled,
              _ => l10n.settingsPushActive,
            }, key: const Key('settings-push-status')),
            value: enabled && !unavailable,
            onChanged: unavailable
                ? null
                : (value) => unawaited(
                    ref.read(pushEnabledProvider.notifier).set(enabled: value),
                  ),
          ),
          if (canTest) ...[
            const Divider(height: 1),
            ListTile(
              key: const Key('settings-push-test'),
              leading: const Icon(Icons.send_rounded),
              title: Text(l10n.settingsPushTest),
              subtitle: Text(l10n.settingsPushTestHint),
              onTap: () => unawaited(_sendTest(context, ref)),
            ),
          ],
          if (ref.watch(currentUserProvider).value != null)
            const _RemindersTile(),
        ],
      ),
    );
  }
}

/// Rappels avant les événements dont un ticket est dans « Mes tickets »
/// (réglage du compte, lu par le serveur).
class _RemindersTile extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_RemindersTile> createState() => _RemindersTileState();
}

class _RemindersTileState extends ConsumerState<_RemindersTile> {
  bool _busy = false;

  Future<void> _set(bool enabled) async {
    final l10n = context.l10n;
    final toaster = Toaster.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(profileProvider.notifier)
          .setEventReminders(enabled: enabled);
    } on Object {
      toaster.error(
        l10n.settingsRemindersError,
        key: const Key('settings-reminders-error'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = ref.watch(profileProvider).value;
    if (profile == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        SwitchListTile(
          key: const Key('settings-reminders'),
          secondary: Icon(
            Icons.event_available_rounded,
            color: context.palette.accentText,
          ),
          title: Text(l10n.settingsReminders),
          subtitle: Text(l10n.settingsRemindersHint),
          value: profile.eventReminders,
          onChanged: _busy ? null : (value) => unawaited(_set(value)),
        ),
      ],
    );
  }
}
