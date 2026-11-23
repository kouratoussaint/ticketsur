import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/notifications/application/event_topics.dart';
import 'package:ticketsur/features/notifications/application/push_providers.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/profile/presentation/account_sheets.dart';
import 'package:ticketsur/features/profile/presentation/appearance_card.dart';
import 'package:ticketsur/features/profile/presentation/feedback_settings_card.dart';
import 'package:ticketsur/features/settings/presentation/language_card.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cacheSize = ref.watch(imageCacheSizeProvider).value ?? 0;
    Widget section(String title, IconData icon) => Padding(
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.xs,
        TicketSurSpacing.lg,
        TicketSurSpacing.xs,
        TicketSurSpacing.xs,
      ),
      child: SectionHeader(title: title, icon: icon),
    );
    return Scaffold(
      body: ListView(
        key: const Key('settings'),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
        ),
        children: [
          TikeoHeroHeader(
            title: l10n.settingsTitle,
            subtitle: l10n.settingsHeroSubtitle,
            illustration: TikeoIllustration.settings,
            onBack: () => context.popOr(AppRoutes.profile),
            overlap: 0,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TikeoSizes.screenMargin,
              TikeoSizes.cardGap,
              TikeoSizes.screenMargin,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UpdateBanner(),
                const AppearanceCard(),
                const SizedBox(height: TicketSurSpacing.md),
                const LanguageCard(),
                const SizedBox(height: TicketSurSpacing.md),
                const FeedbackSettingsCard(),
                section(
                  l10n.settingsNotifications,
                  Icons.notifications_rounded,
                ),
                const _PushCard(),
                section(l10n.settingsStorage, Icons.storage_rounded),
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
                            onPressed: () =>
                                unawaited(_clearImages(context, ref)),
                            child: Text(l10n.settingsImageCacheClear),
                          ),
                  ),
                ),
                if (ref.watch(currentUserProvider).value != null) ...[
                  section(l10n.settingsAccount, Icons.manage_accounts_rounded),
                  TikeoCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        SettingsRow(
                          key: const Key('settings-password'),
                          icon: Icons.password_rounded,
                          tint: context.tints.blue,
                          title: l10n.profileChangePassword,
                          onTap: () =>
                              unawaited(showChangePasswordSheet(context)),
                        ),
                        SettingsRow(
                          key: const Key('settings-email'),
                          icon: Icons.alternate_email_rounded,
                          tint: context.tints.mint,
                          title: l10n.profileChangeEmail,
                          onTap: () => unawaited(showChangeEmailSheet(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notifications : réglage et état sur ce téléphone.
class _PushCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(pushEnabledProvider);
    final status = ref.watch(pushSyncProvider).value;
    final unavailable = status == PushStatus.unavailable;
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
          if (!unavailable && enabled)
            SwitchListTile(
              key: const Key('settings-push-new-events'),
              secondary: Icon(
                Icons.campaign_rounded,
                color: context.palette.accentText,
              ),
              title: Text(l10n.settingsNewEvents),
              subtitle: Text(switch (ref.watch(
                catalogQueryProvider.select((q) => q.city),
              )) {
                final city? when city.trim().isNotEmpty =>
                  l10n.settingsNewEventsCity(city),
                _ => l10n.settingsNewEventsAllCities,
              }, key: const Key('settings-push-new-events-scope')),
              value: ref.watch(newEventsProvider),
              onChanged: (value) => unawaited(
                ref.read(newEventsProvider.notifier).set(enabled: value),
              ),
            ),
          if (!unavailable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  switch (ref.watch(lastPushReceivedProvider).value) {
                    final at? => l10n.settingsPushLastReceived(
                      formatDateAtTime(at),
                    ),
                    null => l10n.settingsPushNeverReceived,
                  },
                  key: const Key('settings-push-last'),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.palette.mutedText),
                ),
              ),
            ),
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
