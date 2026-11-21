import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/features/platform/application/platform_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Bandeau « Maintenance en cours », placé avec les annonces.
class MaintenanceBanner extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(platformStatusProvider).value;
    if (status == null || !status.maintenance) return const SizedBox.shrink();
    final l10n = context.l10n;
    return TintedBanner(
      key: const Key('maintenance-banner'),
      tint: context.tints.amber,
      icon: Icons.construction_rounded,
      title: l10n.maintenanceTitle,
      body: [
        ?status.message,
        if (status.writesBlocked) l10n.maintenanceWritesBlocked,
      ].join('\n'),
    );
  }
}
