import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/closed_orgs/application/closed_org_providers.dart';
import 'package:ticketsur/features/closed_orgs/domain/closed_org.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_status_chip.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/reports/presentation/report_sheet.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

/// Structures fermées du compte, en consultation seule (ADR 0044).
class ClosedOrganizationsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final organizations = ref.watch(closedOrganizationsProvider);
    final content = switch (organizations) {
      AsyncData(:final value) when value.isEmpty => [
        Text(
          l10n.closedOrgsEmpty,
          key: const Key('closed-orgs-empty'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
      AsyncData(:final value) => [
        for (final organization in value)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TikeoListRow(
              key: Key('closed-org-${organization.id}'),
              leading: const Icon(Icons.inventory_2_rounded),
              title: organization.name,
              subtitle: l10n.closedOrgClosedOn(_day(organization.closedAt)),
              lines: [
                [
                  l10n.closedOrgEventCount(organization.eventCount),
                  roleLabel(l10n, organization.role),
                ].join(' · '),
              ],
              onTap: () => unawaited(
                context.push(AppRoutes.closedOrganization(organization.id)),
              ),
            ),
          ),
      ],
      AsyncError() => [
        TintedBanner(
          key: const Key('closed-orgs-error'),
          tint: context.tints.red,
          icon: Icons.wifi_off_rounded,
          title: l10n.closedOrgsLoadError,
        ),
      ],
      _ => [const Shimmer(child: SkeletonBox(height: 88, radius: 16))],
    };
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(closedOrganizationsProvider);
          try {
            await ref.read(closedOrganizationsProvider.future);
          } on Object {
            // L'échec s'affiche dans la page.
          }
        },
        child: ListView(
          key: const Key('closed-orgs-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          children: [
            TikeoHeroHeader(
              title: l10n.closedOrgsTitle,
              subtitle: l10n.closedOrgsSubtitle,
              onBack: () => context.popOr(AppRoutes.profile),
              overlap: 0,
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            for (final child in content)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TikeoSizes.screenMargin,
                ),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

/// Une structure fermée : bandeau « consultation seule », factures,
/// événements (un appui ouvre l'export du bilan ou de la liste des tickets).
class ClosedOrganizationPage extends ConsumerWidget {
  const new({required this.organizationId, super.key});

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final detail = ref.watch(closedOrganizationProvider(organizationId));
    final title = detail.value?.organization.name ?? l10n.closedOrgsTitle;
    final content = switch (detail) {
      AsyncData(:final value) => [
        TintedBanner(
          key: const Key('closed-org-readonly'),
          tint: tints.amber,
          icon: Icons.lock_rounded,
          title: l10n.closedOrgReadOnlyTitle(_day(value.organization.closedAt)),
          body: l10n.closedOrgReadOnlyBody,
        ),
        const SizedBox(height: TikeoSizes.cardGap),
        if (value.organization.role == MemberRole.owner) ...[
          TikeoCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SettingsRow(
              key: const Key('closed-org-invoices'),
              icon: Icons.receipt_long_rounded,
              tint: tints.blue,
              title: l10n.closedOrgInvoices,
              subtitle: l10n.closedOrgInvoicesHint,
              onTap: () => unawaited(context.push(AppRoutes.billing)),
            ),
          ),
          const SizedBox(height: TikeoSizes.cardGap),
        ],
        SectionHeader(
          title: l10n.closedOrgEventsTitle,
          icon: Icons.event_rounded,
        ),
        const SizedBox(height: 4),
        Text(l10n.closedOrgEventsHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        if (value.events.isEmpty)
          Text(
            l10n.closedOrgEventCount(0),
            key: const Key('closed-org-no-events'),
            style: theme.textTheme.bodyLarge,
          ),
        for (final item in value.events)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TikeoListRow(
              key: Key('closed-event-${item.event.id}'),
              title: item.event.title,
              subtitle: formatEventRange(item.event),
              lines: [
                l10n.closedOrgEventCounts(
                  item.issued,
                  item.admitted,
                  item.revoked,
                ),
              ],
              badge: EventStatusChip(status: item.event.status),
              trailing: const Icon(Icons.download_rounded),
              onTap: () => unawaited(
                showReportSheet(
                  context,
                  item.event,
                  closedOrganization: value.organization.name,
                ),
              ),
            ),
          ),
      ],
      AsyncError(:final error) => [
        TintedBanner(
          key: const Key('closed-org-error'),
          tint: tints.red,
          icon: error == ClosedOrgFailure.notFound
              ? Icons.block_rounded
              : Icons.wifi_off_rounded,
          title: error == ClosedOrgFailure.notFound
              ? l10n.closedOrgNotFound
              : l10n.closedOrgsLoadError,
        ),
      ],
      _ => [const Shimmer(child: SkeletonBox(height: 120, radius: 16))],
    };
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(closedOrganizationProvider(organizationId));
          try {
            await ref.read(closedOrganizationProvider(organizationId).future);
          } on Object {
            // L'échec s'affiche dans la page.
          }
        },
        child: ListView(
          key: const Key('closed-org-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          children: [
            TikeoHeroHeader(
              title: title,
              subtitle: l10n.closedOrgsSubtitle,
              onBack: () => context.popOr(AppRoutes.closedOrganizations),
              overlap: 0,
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            for (final child in content)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TikeoSizes.screenMargin,
                ),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
