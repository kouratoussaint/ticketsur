import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_copy.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Mes scans récents (S27) : 7 jours, sans jeton.
class RecentScansPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scans = ref.watch(recentScansProvider);
    final value = scans.value;
    final withSummary = scans is AsyncData && value != null && value.isNotEmpty;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(recentScansProvider.future),
        child: ListView(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TikeoHeroHeader(
                  title: l10n.historyTitle,
                  subtitle: l10n.historyHeroSubtitle,
                  illustration: TikeoIllustration.stats,
                  overlap: withSummary ? TikeoSizes.heroOverlap : 0,
                ),
                if (withSummary)
                  TikeoOverlapCard(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _Summary(scans: value),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TikeoSizes.screenMargin,
                TikeoSizes.cardGap,
                TikeoSizes.screenMargin,
                0,
              ),
              child: switch (scans) {
                AsyncData(:final value) when value.isEmpty => Column(
                  children: [
                    const SizedBox(height: 32),
                    const TikeoIllustrationView(TikeoIllustration.scanner),
                    const SizedBox(height: 16),
                    Text(
                      l10n.historyEmpty,
                      key: const Key('history-empty'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                AsyncData(:final value) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final scan in value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ScanTile(scan: scan),
                      ),
                  ],
                ),
                AsyncError() => Column(
                  children: [
                    TintedBanner(
                      tint: context.tints.red,
                      icon: Icons.wifi_off_rounded,
                      title: l10n.historyLoadError,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(recentScansProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.orgRetry),
                    ),
                  ],
                ),
                _ => Shimmer(
                  child: Column(
                    children: [
                      for (var i = 0; i < 6; i++)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: SkeletonBox(height: 76, radius: 16),
                        ),
                    ],
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Acceptés, refusés, incertains sur les 7 jours.
class _Summary extends StatelessWidget {
  const new({required this.scans});

  final List<RecentScan> scans;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    int count(VerdictKind kind) =>
        scans.where((s) => s.outcome.kind == kind).length;
    return StatStrip(
      key: const Key('history-summary'),
      items: [
        (
          value: '${count(VerdictKind.admitted)}',
          label: l10n.scannerAdmitted,
          color: tints.green.text,
        ),
        (
          value: '${count(VerdictKind.refused)}',
          label: l10n.scannerRefused,
          color: tints.red.text,
        ),
        (
          value: '${count(VerdictKind.indeterminate)}',
          label: l10n.historyUncertain,
          color: tints.amber.text,
        ),
      ],
    );
  }
}

class _ScanTile extends StatelessWidget {
  const new({required this.scan});

  final RecentScan scan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    final kind = scan.outcome.kind;
    final (tint, icon) = switch (kind) {
      VerdictKind.admitted => (tints.green, Icons.check_circle_rounded),
      VerdictKind.refused => (tints.red, Icons.cancel_rounded),
      _ => (tints.amber, Icons.help_rounded),
    };
    return TikeoListRow(
      key: Key('history-${scan.id}'),
      stripe: tint.icon,
      chevron: false,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: tint.background,
        child: Icon(icon, color: tint.icon),
      ),
      title:
          '${verdictTitle(l10n, kind)} · ${verdictReason(l10n, scan.outcome)}',
      lines: [
        [
          formatLocalDateTime(scan.serverTime),
          ?scan.checkpointName,
        ].join(' · '),
        [?scan.reference, ?scan.category, ?scan.eventTitle].join(' · '),
      ].where((line) => line.isNotEmpty).toList(),
    );
  }
}
