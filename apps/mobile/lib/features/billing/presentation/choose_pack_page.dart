import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/my_pack_page.dart';
import 'package:ticketsur/features/billing/presentation/pack_widgets.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// P2 et P3 · Choisir un pack : forfait (durées) ou à l'usage (simulateur).
class ChoosePackPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ChoosePackPage> createState() => _ChoosePackPageState();
}

class _ChoosePackPageState extends ConsumerState<ChoosePackPage> {
  BillingSystem _system = BillingSystem.flat;
  BillingDuration? _duration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(billingCatalogProvider);
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.billingChoosePack)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(billingCatalogProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            TikeoSizes.screenMargin,
            TikeoSizes.cardGap,
            TikeoSizes.screenMargin,
            MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          children: [
            StatusTabs<BillingSystem>(
              values: BillingSystem.values,
              selected: _system,
              labelOf: (value) => systemLabel(l10n, value),
              keyOf: (value) => Key('billing-choose-${value.wireName}'),
              onSelected: (value) => setState(() => _system = value),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            ...switch (catalog) {
              AsyncData(:final value) =>
                _system == BillingSystem.flat
                    ? _flat(context, value)
                    : [_UsageSection(packs: value)],
              AsyncError(:final error) => [
                TintedBanner(
                  tint: context.tints.red,
                  icon: Icons.cloud_off_rounded,
                  title: promoterBillingMessage(l10n, error),
                ),
              ],
              _ => [
                const Shimmer(
                  child: SkeletonBox(height: 320, radius: TikeoRadii.card),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _flat(BuildContext context, List<BillingPack> catalog) {
    final l10n = context.l10n;
    final packs = [
      for (final pack in catalog)
        if (pack.system == BillingSystem.flat && pack.code == null) pack,
    ];
    final durations = [
      for (final duration in BillingDuration.offered)
        if (packs.any((p) => p.durations.containsKey(duration))) duration,
    ];
    final selected = durations.contains(_duration)
        ? _duration!
        : durations.firstOrNull;
    return [
      if (durations.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final duration in durations)
              ChoiceChip(
                key: Key('billing-duration-${duration.wireName}'),
                label: Text(durationLabel(l10n, duration)),
                selected: duration == selected,
                onSelected: (_) => setState(() => _duration = duration),
              ),
          ],
        ),
      const SizedBox(height: TikeoSizes.cardGap),
      if (selected != null)
        for (final pack in packs)
          if (pack.durations[selected] case final price?)
            Padding(
              padding: const EdgeInsets.only(bottom: TikeoSizes.cardGap),
              child: _FlatPackCard(
                pack: pack,
                duration: selected,
                price: price,
              ),
            ),
      if (packs.isEmpty)
        Text(
          l10n.billingNoPacks,
          key: const Key('billing-no-packs'),
          textAlign: TextAlign.center,
        ),
      _EnterpriseCard(),
    ];
  }
}

class _FlatPackCard extends StatelessWidget {
  const new({required this.pack, required this.duration, required this.price});

  final BillingPack pack;
  final BillingDuration duration;
  final int price;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final perMonth = duration.months > 1
        ? (price / duration.months).round()
        : null;
    final card = TikeoCard(
      key: Key('billing-pack-card-${pack.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pack.featured) ...[
            TikeoPill(
              label: l10n.billingPackFeatured,
              tint: tints.vip,
              icon: Icons.star_rounded,
            ),
            const SizedBox(height: 8),
          ],
          Text(pack.name, style: theme.textTheme.titleLarge),
          if (pack.description case final text?)
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            money(l10n, price),
            style: TikeoTextStyles.bigNumber.copyWith(color: tints.mint.text),
          ),
          Text(
            perMonth == null
                ? durationLabel(l10n, duration)
                : l10n.billingPerMonthEquivalent(money(l10n, perMonth)),
            style: theme.textTheme.bodySmall,
          ),
          if (pack.trialDays > 0)
            Text(
              l10n.billingTrialDays(pack.trialDays),
              style: theme.textTheme.bodySmall?.copyWith(
                color: tints.blue.text,
              ),
            ),
          const SizedBox(height: 4),
          PackOptionLines(pack: pack),
          const SizedBox(height: 12),
          TikeoPrimaryButton(
            key: Key('billing-choose-pack-${pack.id}'),
            onPressed: () => unawaited(
              context.push(AppRoutes.billingAddonsFor(pack.id, duration)),
            ),
            icon: Icons.arrow_forward_rounded,
            label: l10n.billingChooseThis,
          ),
        ],
      ),
    );
    if (!pack.featured) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TikeoRadii.card + 2),
        border: Border.all(color: TicketSurColors.mint, width: 2),
      ),
      child: card,
    );
  }
}

class _EnterpriseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TikeoCard(
      key: const Key('billing-enterprise'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.billingEnterprise,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(l10n.billingEnterpriseBody),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('billing-enterprise-contact'),
            onPressed: () => unawaited(context.push(AppRoutes.supportNew)),
            icon: const Icon(Icons.support_agent_rounded),
            label: Text(l10n.billingEnterpriseContact),
          ),
        ],
      ),
    );
  }
}

/// P3 : packs à l'usage, « comment ça marche », simulateur.
class _UsageSection extends ConsumerStatefulWidget {
  const new({required this.packs});

  final List<BillingPack> packs;

  @override
  ConsumerState<_UsageSection> createState() => _UsageSectionState();
}

class _UsageSectionState extends ConsumerState<_UsageSection> {
  double _entries = 300;
  String? _simulated;

  Future<void> _useFor(BillingPack pack) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final billing = await ref.read(myBillingProvider.future);
    if (!mounted) return;
    final organization = billing.organizations.length == 1
        ? billing.organizations.single
        : await showModalBottomSheet<BillingOrganization>(
            context: context,
            useRootNavigator: true,
            showDragHandle: true,
            builder: (context) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    l10n.billingUseForWhich,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final organization in billing.organizations)
                    ListTile(
                      key: Key('billing-use-org-${organization.id}'),
                      leading: const Icon(Icons.storefront_rounded),
                      title: Text(organization.name),
                      onTap: () => Navigator.of(context).pop(organization),
                    ),
                ],
              ),
            ),
          );
    if (organization == null) return;
    try {
      await ref
          .read(billingRepositoryProvider)
          .setOrganizationBilling(
            organization.id,
            BillingSystem.usage,
            pack.id,
          );
      ref.invalidate(myBillingProvider);
      toast.success(l10n.billingUsageChosen(organization.name));
    } on Object catch (error) {
      toast.error(promoterBillingMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final packs = [
      for (final pack in widget.packs)
        if (pack.system == BillingSystem.usage) pack,
    ];
    final simulated =
        packs.where((p) => p.id == _simulated).firstOrNull ?? packs.firstOrNull;
    final estimate = simulated == null
        ? null
        : usageEstimate(simulated, _entries.round());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TikeoCard(
          key: const Key('billing-usage-how'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.billingUsageHow,
                icon: Icons.lightbulb_rounded,
              ),
              for (final (i, step) in [
                l10n.billingUsageStep1,
                l10n.billingUsageStep2,
                l10n.billingUsageStep3,
              ].indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: tints.mint.background,
                        child: Text(
                          '${i + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: tints.mint.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(step)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: TikeoSizes.cardGap),
        for (final pack in packs)
          Padding(
            padding: const EdgeInsets.only(bottom: TikeoSizes.cardGap),
            child: TikeoCard(
              key: Key('billing-pack-card-${pack.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pack.name, style: theme.textTheme.titleLarge),
                  if (pack.description case final text?) Text(text),
                  const SizedBox(height: 8),
                  Text(
                    packPriceLabel(l10n, pack),
                    style: TikeoTextStyles.tileNumber.copyWith(
                      color: tints.blue.text,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      TikeoPill(label: l10n.billingNoMinimum, tint: tints.mint),
                      if (pack.freeEntries > 0)
                        TikeoPill(
                          label: l10n.billingFreeEntries(pack.freeEntries),
                          tint: tints.green,
                        ),
                    ],
                  ),
                  for (final tier in pack.tiers)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        tier.upTo == null
                            ? l10n.billingTierBeyond(money(l10n, tier.price))
                            : l10n.billingTierUpTo(
                                tier.upTo!,
                                money(l10n, tier.price),
                              ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  PackOptionLines(pack: pack, onlyNotable: true),
                  const SizedBox(height: 12),
                  TikeoPrimaryButton(
                    key: Key('billing-use-${pack.id}'),
                    onPressed: () => unawaited(_useFor(pack)),
                    icon: Icons.check_rounded,
                    label: l10n.billingUseForStructure,
                  ),
                ],
              ),
            ),
          ),
        if (packs.isEmpty)
          Text(
            l10n.billingNoPacks,
            key: const Key('billing-no-usage-packs'),
            textAlign: TextAlign.center,
          ),
        if (simulated != null && estimate != null)
          TikeoCard(
            key: const Key('billing-simulator'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: l10n.billingSimulator,
                  icon: Icons.calculate_rounded,
                ),
                if (packs.length > 1)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final pack in packs)
                        ChoiceChip(
                          label: Text(pack.name),
                          selected: pack.id == simulated.id,
                          onSelected: (_) =>
                              setState(() => _simulated = pack.id),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(l10n.billingSimulatorEntries(_entries.round())),
                Slider(
                  key: const Key('billing-simulator-slider'),
                  value: _entries,
                  max: 5000,
                  divisions: 100,
                  label: '${_entries.round()}',
                  onChanged: (value) => setState(() => _entries = value),
                ),
                if (simulated.freeEntries > 0)
                  Text(
                    l10n.billingSimulatorFree(
                      simulated.freeEntries.clamp(0, _entries.round()),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                for (final tier in estimate.tiers)
                  Text(
                    l10n.billingSimulatorTier(
                      tier.from,
                      tier.to,
                      money(l10n, tier.price),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 6),
                Text(
                  money(l10n, estimate.amount),
                  key: const Key('billing-simulator-total'),
                  style: TikeoTextStyles.bigNumber.copyWith(
                    color: tints.blue.text,
                  ),
                ),
                Text(
                  l10n.billingSimulatorHint,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
