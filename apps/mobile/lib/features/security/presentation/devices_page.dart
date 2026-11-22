import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/confirm.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/security/application/security_providers.dart';
import 'package:ticketsur/features/security/domain/security.dart';
import 'package:ticketsur/l10n/l10n.dart';

String deviceFailureMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      DeviceFailure.current => l10n.devicesErrorCurrent,
      DeviceFailure.notFound => l10n.devicesErrorNotFound,
      DeviceFailure.network => l10n.devicesErrorNetwork,
      _ => l10n.devicesErrorUnknown,
    };

/// Appareils connectés au compte (lot 4-6a) : cet appareil d'abord ;
/// déconnecter un appareil, ou tous les autres.
class DevicesPage extends ConsumerWidget {
  const new({super.key});

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required Key confirmKey,
  }) => confirmAction(
    context,
    icon: Icons.phonelink_erase_rounded,
    title: title,
    body: body,
    cancelLabel: context.l10n.profileCancel,
    confirmLabel: context.l10n.devicesSignOut,
    danger: true,
    confirmKey: confirmKey,
  );

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    ConnectedDevice device,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final name = device.label ?? l10n.devicesUnknown;
    if (!await _confirm(
      context,
      title: l10n.devicesSignOutTitle(name),
      body: l10n.devicesSignOutBody,
      confirmKey: const Key('device-revoke-confirm'),
    )) {
      return;
    }
    try {
      await ref.read(deviceSecurityRepositoryProvider).revoke(device.sessionId);
      toast.success(l10n.devicesSignedOut(name));
    } on DeviceFailure catch (failure) {
      toast.error(deviceFailureMessage(l10n, failure));
    }
    ref.invalidate(connectedDevicesProvider);
  }

  Future<void> _revokeOthers(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    if (!await _confirm(
      context,
      title: l10n.devicesSignOutOthers,
      body: l10n.devicesSignOutOthersBody,
      confirmKey: const Key('devices-revoke-others-confirm'),
    )) {
      return;
    }
    try {
      final count = await ref
          .read(deviceSecurityRepositoryProvider)
          .revokeOthers();
      toast.success(l10n.devicesSignedOutOthers(count));
    } on DeviceFailure catch (failure) {
      toast.error(deviceFailureMessage(l10n, failure));
    }
    ref.invalidate(connectedDevicesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final devices = ref.watch(connectedDevicesProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(connectedDevicesProvider.future),
        child: ListView(
          key: const Key('devices-list'),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          children: [
            TikeoHeroHeader(
              title: l10n.devicesTitle,
              subtitle: l10n.devicesSubtitle,
              illustration: TikeoIllustration.lock,
              onBack: () => context.popOr(AppRoutes.profile),
              overlap: 0,
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            ...switch (devices) {
              AsyncValue(:final value?) => [
                for (final device in value)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TikeoSizes.screenMargin,
                      0,
                      TikeoSizes.screenMargin,
                      TikeoSizes.cardGap,
                    ),
                    child: _DeviceCard(
                      device: device,
                      onRevoke: () => unawaited(_revoke(context, ref, device)),
                    ),
                  ),
                if (value.where((d) => !d.current).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TikeoSizes.screenMargin,
                    ),
                    child: TikeoDangerButton(
                      key: const Key('devices-revoke-others'),
                      icon: Icons.devices_other_rounded,
                      label: l10n.devicesSignOutOthers,
                      onPressed: () => unawaited(_revokeOthers(context, ref)),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TikeoSizes.screenMargin,
                    ),
                    child: Text(
                      l10n.devicesOnlyThis,
                      key: const Key('devices-only-this'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
              AsyncValue(:final error?) => [
                Padding(
                  padding: const EdgeInsets.all(TikeoSizes.screenMargin),
                  child: Column(
                    children: [
                      Text(
                        deviceFailureMessage(l10n, error),
                        key: const Key('devices-error'),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(connectedDevicesProvider),
                        child: Text(l10n.devicesRetry),
                      ),
                    ],
                  ),
                ),
              ],
              _ => const [
                Padding(
                  padding: EdgeInsets.all(TikeoSizes.screenMargin),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const new({required this.device, required this.onRevoke});

  final ConnectedDevice device;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final tint = device.current ? tints.mint : tints.blue;
    return TikeoCard(
      key: Key('device-${device.sessionId}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.background,
              shape: BoxShape.circle,
            ),
            child: Icon(switch (device.platform) {
              'android' || 'ios' => Icons.smartphone_rounded,
              null => Icons.devices_rounded,
              _ => Icons.computer_rounded,
            }, color: tint.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      device.label ?? l10n.devicesUnknown,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (device.current)
                      TikeoPill(
                        key: const Key('device-current'),
                        label: l10n.devicesThis,
                        tint: tints.mint,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  device.current
                      ? l10n.devicesActiveNow
                      : l10n.devicesLastSeen(
                          formatDateAtTime(device.lastSeenAt.toLocal()),
                        ),
                  style: muted,
                ),
                Text(
                  l10n.devicesSince(
                    formatDateAtTime(device.signedInAt.toLocal()),
                  ),
                  style: muted,
                ),
                if (!device.current) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      key: Key('device-revoke-${device.sessionId}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: onRevoke,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(l10n.devicesSignOut),
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
