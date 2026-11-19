import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/tabular_figures.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/support/application/support_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

final _count = NumberFormat.decimalPattern('fr');

/// Accueil de la console : chiffres de la plateforme et accès aux modules.
class ConsolePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final overview = ref.watch(adminOverviewProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consoleTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(adminOverviewProvider)
            ..invalidate(supportCountsProvider);
          try {
            await ref.read(adminOverviewProvider.future);
          } on Object {
            // L'échec s'affiche dans la page.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          children: [
            switch (overview) {
              AsyncError(:final error) => Card(
                key: Key(
                  error == AdminFailure.forbidden
                      ? 'console-forbidden'
                      : 'console-error',
                ),
                child: ListTile(
                  leading: Icon(
                    error == AdminFailure.forbidden
                        ? Icons.lock_outline_rounded
                        : Icons.cloud_off_rounded,
                  ),
                  title: Text(consoleFailureMessage(l10n, error)),
                  trailing: error == AdminFailure.forbidden
                      ? null
                      : TextButton(
                          onPressed: () =>
                              ref.invalidate(adminOverviewProvider),
                          child: Text(l10n.consoleRetry),
                        ),
                ),
              ),
              AsyncData(:final value) => FadeSlideIn(
                child: _Overview(overview: value),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(TicketSurSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            if (overview.error != AdminFailure.forbidden) ...[
              const SizedBox(height: TicketSurSpacing.lg),
              _NavTile(
                key: const Key('console-nav-organizations'),
                icon: Icons.apartment_rounded,
                title: l10n.consoleNavOrganizations,
                subtitle: l10n.consoleNavOrganizationsHint,
                route: AppRoutes.consoleOrganizations,
              ),
              _NavTile(
                key: const Key('console-nav-accounts'),
                icon: Icons.people_alt_rounded,
                title: l10n.consoleNavAccounts,
                subtitle: l10n.consoleNavAccountsHint,
                route: AppRoutes.consoleAccounts,
              ),
              _NavTile(
                key: const Key('console-nav-support'),
                icon: Icons.support_agent_rounded,
                title: l10n.consoleNavSupport,
                subtitle: switch (ref.watch(supportCountsProvider).value) {
                  final counts? when counts.unread > 0 =>
                    l10n.consoleNavSupportUnread(counts.unread),
                  _ => l10n.consoleNavSupportHint,
                },
                badge: ref.watch(supportCountsProvider).value?.unread ?? 0,
                route: AppRoutes.consoleSupport,
              ),
              _NavTile(
                key: const Key('console-nav-announcements'),
                icon: Icons.campaign_rounded,
                title: l10n.consoleNavAnnouncements,
                subtitle: l10n.consoleNavAnnouncementsHint,
                route: AppRoutes.consoleAnnouncements,
              ),
              _NavTile(
                key: const Key('console-nav-legal'),
                icon: Icons.gavel_rounded,
                title: l10n.consoleNavLegal,
                subtitle: l10n.consoleNavLegalHint,
                route: AppRoutes.consoleLegal,
              ),
              _NavTile(
                key: const Key('console-nav-catalog'),
                icon: Icons.travel_explore_rounded,
                title: l10n.consoleNavCatalog,
                subtitle: l10n.consoleNavCatalogHint,
                route: AppRoutes.consoleCatalog,
              ),
              _NavTile(
                key: const Key('console-nav-journal'),
                icon: Icons.receipt_long_rounded,
                title: l10n.consoleNavJournal,
                subtitle: l10n.consoleNavJournalHint,
                route: AppRoutes.consoleJournal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.badge = 0,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: context.palette.accentText),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge > 0)
              Badge.count(
                count: badge,
                backgroundColor: scheme.error,
                textColor: scheme.onError,
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () => unawaited(context.push(route)),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const new({required this.overview});

  final AdminOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final o = overview;
    String n(int value) => _count.format(value);
    final tiles = [
      _Stat(
        key: const Key('console-stat-organizations'),
        icon: Icons.apartment_rounded,
        title: l10n.consoleSectionOrganizations,
        value: n(o.organizations),
        lines: [
          (l10n.consoleStatActiveF, n(o.organizationsActive)),
          (l10n.consoleStatDisabledF, n(o.organizationsDisabled)),
          (l10n.consoleStatNew7d, n(o.organizationsNew7d)),
        ],
      ),
      _Stat(
        key: const Key('console-stat-accounts'),
        icon: Icons.people_alt_rounded,
        title: l10n.consoleSectionAccounts,
        value: n(o.accounts),
        lines: [
          (l10n.consoleStatDisabledM, n(o.accountsDisabled)),
          (l10n.consoleStatDeletion, n(o.accountsDeletionRequested)),
          (l10n.consoleStatDue, n(o.accountsDeletionDue)),
          (l10n.consoleStatNew7d, n(o.accountsNew7d)),
        ],
      ),
      _Stat(
        key: const Key('console-stat-events'),
        icon: Icons.event_rounded,
        title: l10n.consoleSectionEvents,
        value: n(o.events),
        lines: [
          (l10n.consoleStatUpcoming, n(o.eventsUpcoming)),
          (l10n.consoleStatInProgress, n(o.eventsInProgress)),
          (l10n.consoleStatListed, n(o.eventsListed)),
          (l10n.consoleStatBlocked, n(o.eventsBlocked)),
        ],
      ),
      _Stat(
        key: const Key('console-stat-tickets'),
        icon: Icons.confirmation_number_rounded,
        title: l10n.consoleSectionTickets,
        value: n(o.ticketsIssued),
        lines: [
          (l10n.consoleStatRedeemed, n(o.ticketsRedeemed)),
          (l10n.consoleStatNew7d, n(o.ticketsIssued7d)),
        ],
      ),
      _Stat(
        key: const Key('console-stat-scans'),
        icon: Icons.qr_code_scanner_rounded,
        title: l10n.consoleSectionScans,
        value: n(o.scansAccepted24h + o.scansRefused24h),
        lines: [
          (l10n.consoleStatAccepted, n(o.scansAccepted24h)),
          (l10n.consoleStatRefused, n(o.scansRefused24h)),
        ],
      ),
    ];
    return Column(
      key: const Key('console-overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.consoleUpdatedAt(
            DateFormat('HH:mm:ss', 'fr').format(o.serverTime.toLocal()),
          ),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.palette.mutedText),
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = TicketSurSpacing.sm;
            final width = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final tile in tiles)
                  SizedBox(
                    width: width,
                    child: TabularFigures(child: tile),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.value,
    required this.lines,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final List<(String, String)> lines;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: context.palette.accentText),
                const SizedBox(width: TicketSurSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            for (final (label, count) in lines)
              Text(l10n.consoleStatLine(label, count), style: muted),
          ],
        ),
      ),
    );
  }
}
