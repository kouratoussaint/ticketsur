import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(recentScansProvider.future),
        child: switch (scans) {
          AsyncData(:final value) when value.isEmpty => ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text(l10n.historyEmpty, key: const Key('history-empty')),
              ),
            ],
          ),
          AsyncData(:final value) => ListView.separated(
            padding: const EdgeInsets.all(TicketSurSpacing.md),
            itemCount: value.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: TicketSurSpacing.xs),
            itemBuilder: (context, index) => _ScanTile(scan: value[index]),
          ),
          AsyncError() => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text(l10n.historyLoadError)),
              Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(recentScansProvider),
                  child: Text(l10n.orgRetry),
                ),
              ),
            ],
          ),
          _ => const SkeletonList(count: 6),
        },
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  const new({required this.scan});

  final RecentScan scan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.verdictColors;
    final kind = scan.outcome.kind;
    return Card(
      key: Key('history-${scan.id}'),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.background(kind),
          foregroundColor: colors.foreground(kind),
          child: Icon(switch (kind) {
            VerdictKind.admitted => Icons.check_rounded,
            VerdictKind.refused => Icons.close_rounded,
            _ => Icons.help_outline_rounded,
          }),
        ),
        title: Text(
          '${verdictTitle(l10n, kind)} · ${verdictReason(l10n, scan.outcome)}',
        ),
        subtitle: Text(
          [
            formatLocalDateTime(scan.serverTime),
            ?scan.reference,
            ?scan.category,
            ?scan.checkpointName,
            ?scan.eventTitle,
          ].join(' · '),
        ),
      ),
    );
  }
}
