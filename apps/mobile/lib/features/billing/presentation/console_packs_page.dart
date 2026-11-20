import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/application/billing_admin_providers.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Onglets de la liste des packs (C1).
enum PacksFilter { all, flat, usage, archived }

/// C1 · Packs : liste, filtres, création, publication, archivage.
class ConsolePacksPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsolePacksPage> createState() => _ConsolePacksPageState();
}

class _ConsolePacksPageState extends ConsumerState<ConsolePacksPage> {
  PacksFilter _filter = PacksFilter.all;

  bool _accepts(BillingPack pack) => switch (_filter) {
    PacksFilter.all => pack.status != PackStatus.archived,
    PacksFilter.flat =>
      pack.system == BillingSystem.flat && pack.status != PackStatus.archived,
    PacksFilter.usage =>
      pack.system == BillingSystem.usage && pack.status != PackStatus.archived,
    PacksFilter.archived => pack.status == PackStatus.archived,
  };

  Future<void> _run(Future<void> Function() action, String done) async {
    final toast = Toaster.of(context);
    final l10n = context.l10n;
    try {
      await action();
      ref.invalidate(adminBillingProvider);
      toast.success(done);
    } on Object catch (error) {
      toast.error(billingFailureMessage(l10n, error));
    }
  }

  Future<void> _onMenu(BillingPack pack, _PackAction action) async {
    final l10n = context.l10n;
    final repository = ref.read(billingAdminRepositoryProvider);
    switch (action) {
      case _PackAction.edit:
        unawaited(context.push(AppRoutes.consolePack(pack.id)));
      case _PackAction.duplicate:
        await _run(
          () => repository.savePack(
            null,
            BillingPack(
              id: '',
              name: l10n.billingPackCopyName(pack.name),
              description: pack.description,
              system: pack.system,
              sortOrder: pack.sortOrder,
              monthlyPrice: pack.monthlyPrice,
              durations: {
                for (final e in pack.durations.entries)
                  if (e.key != BillingDuration.unlimited) e.key: e.value,
              },
              trialDays: pack.trialDays,
              entryPrice: pack.entryPrice,
              freeEntries: pack.freeEntries,
              tiers: pack.tiers,
              paymentDays: pack.paymentDays,
              options: pack.options,
            ),
          ),
          l10n.billingPackDuplicated,
        );
      case _PackAction.publish:
        await _run(
          () => repository.setPackStatus(pack.id, PackStatus.published),
          l10n.billingPackPublishedToast,
        );
      case _PackAction.draft:
        await _run(
          () => repository.setPackStatus(pack.id, PackStatus.draft),
          l10n.billingPackDraftToast,
        );
      case _PackAction.archive:
        await _run(
          () => repository.setPackStatus(pack.id, PackStatus.archived),
          l10n.billingPackArchivedToast,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(adminBillingProvider);
    final labels = {
      PacksFilter.all: l10n.billingFilterAll,
      PacksFilter.flat: l10n.billingSystemFlat,
      PacksFilter.usage: l10n.billingSystemUsage,
      PacksFilter.archived: l10n.billingPackArchivedPlural,
    };
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.billingPacksTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('billing-pack-new'),
        heroTag: 'billing-pack-new',
        onPressed: () => unawaited(context.push(AppRoutes.consolePackNew)),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.billingPackNew),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminBillingProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            TikeoSizes.screenMargin,
            TikeoSizes.cardGap,
            TikeoSizes.screenMargin,
            96,
          ),
          children: [
            StatusTabs<PacksFilter>(
              values: PacksFilter.values,
              selected: _filter,
              labelOf: (value) => labels[value]!,
              keyOf: (value) => Key('billing-packs-${value.name}'),
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            ...switch (billing) {
              AsyncData(:final value) => [
                for (final pack in value.packs.where(_accepts))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PackRow(
                      pack: pack,
                      onAction: (action) => unawaited(_onMenu(pack, action)),
                    ),
                  ),
                if (!value.packs.any(_accepts))
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      l10n.billingPacksEmpty,
                      key: const Key('billing-packs-empty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
              AsyncError(:final error) => [
                BillingLoadError(
                  error: error,
                  onRetry: () => ref.invalidate(adminBillingProvider),
                ),
              ],
              _ => [const BillingLoading()],
            },
          ],
        ),
      ),
    );
  }
}

enum _PackAction { edit, duplicate, publish, draft, archive }

class _PackRow extends StatelessWidget {
  const new({required this.pack, required this.onAction});

  final BillingPack pack;
  final ValueChanged<_PackAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    final count = pack.system == BillingSystem.flat
        ? l10n.billingPackSubscriptions(pack.subscriptions)
        : l10n.billingPackEvents(pack.events);
    return TikeoListRow(
      key: Key('billing-pack-${pack.id}'),
      stripe: systemTint(tints, pack.system).icon,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: systemTint(tints, pack.system).background,
        child: Icon(
          pack.system == BillingSystem.flat
              ? Icons.workspace_premium_rounded
              : Icons.confirmation_number_rounded,
          color: systemTint(tints, pack.system).icon,
        ),
      ),
      title: pack.name,
      lines: [packPriceLabel(l10n, pack), count],
      badge: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          TikeoPill(
            label: systemLabel(l10n, pack.system),
            tint: systemTint(tints, pack.system),
          ),
          TikeoPill(
            key: Key('billing-pack-status-${pack.id}'),
            label: packStatusLabel(l10n, pack.status),
            tint: packStatusTint(tints, pack.status),
          ),
          if (pack.featured)
            TikeoPill(
              label: l10n.billingPackFeatured,
              tint: tints.vip,
              icon: Icons.star_rounded,
            ),
        ],
      ),
      chevron: false,
      menu: PopupMenuButton<_PackAction>(
        key: Key('billing-pack-menu-${pack.id}'),
        tooltip: l10n.billingPackActions,
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: onAction,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _PackAction.edit,
            child: Text(l10n.billingPackEdit),
          ),
          if (!pack.isSystem)
            PopupMenuItem(
              key: Key('billing-pack-duplicate-${pack.id}'),
              value: _PackAction.duplicate,
              child: Text(l10n.billingPackDuplicate),
            ),
          if (pack.status != PackStatus.published)
            PopupMenuItem(
              key: Key('billing-pack-publish-${pack.id}'),
              value: _PackAction.publish,
              child: Text(l10n.billingPackPublish),
            ),
          if (pack.status == PackStatus.published && !pack.isFree)
            PopupMenuItem(
              value: _PackAction.draft,
              child: Text(l10n.billingPackUnpublish),
            ),
          if (pack.status != PackStatus.archived && !pack.isFree)
            PopupMenuItem(
              key: Key('billing-pack-archive-${pack.id}'),
              value: _PackAction.archive,
              child: Text(l10n.billingPackArchive),
            ),
        ],
      ),
      onTap: () => unawaited(context.push(AppRoutes.consolePack(pack.id))),
    );
  }
}

/// Chargement des écrans de facturation.
class BillingLoading extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      children: [
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SkeletonBox(height: 96, radius: 16),
          ),
      ],
    ),
  );
}

/// Échec de chargement, avec nouvel essai.
class BillingLoadError extends StatelessWidget {
  const new({required this.error, required this.onRetry, super.key});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TintedBanner(
          key: const Key('billing-error'),
          tint: context.tints.red,
          icon: Icons.cloud_off_rounded,
          title: billingFailureMessage(l10n, error),
        ),
        if (error != BillingAdminFailure.forbidden)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.consoleRetry),
          ),
      ],
    );
  }
}
