import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/invoices_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Message d'un échec de la facturation côté promoteur.
String promoterBillingMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      BillingFailure.packInvalid => l10n.billingErrorPackUnavailable,
      BillingFailure.addonsInvalid => l10n.billingErrorAddons,
      BillingFailure.paymentInvalid => l10n.billingErrorTransaction,
      BillingFailure.requestProcessed => l10n.billingErrorProcessed,
      BillingFailure.noSubscription => l10n.billingErrorNoSubscription,
      BillingFailure.choiceInvalid => l10n.billingErrorChoice,
      BillingFailure.locked => l10n.billingErrorLocked,
      BillingFailure.trialUsed => l10n.billingErrorTrialUsed,
      BillingFailure.trialUnavailable => l10n.billingErrorTrialUnavailable,
      BillingFailure.forbidden => l10n.billingErrorForbidden,
      BillingFailure.network => l10n.billingErrorNetwork,
      _ => l10n.billingErrorLoad,
    };

/// P1 · Mon pack : pack actuel, consommation, structures, factures.
class MyPackPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final billing = ref.watch(myBillingProvider);
    final value = billing.value;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myBillingProvider.future),
        child: ListView(
          key: const Key('billing-my-pack'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TikeoHeroHeader(
                  title: l10n.billingMyPackTitle,
                  subtitle: l10n.billingMyPackSubtitle,
                  illustration: TikeoIllustration.wallet,
                  onBack: () => context.popOr(AppRoutes.profile),
                  overlap: value == null ? 0 : TikeoSizes.heroOverlap,
                ),
                if (value != null)
                  TikeoOverlapCard(child: _PlanCard(billing: value)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TikeoSizes.screenMargin,
                TikeoSizes.cardGap,
                TikeoSizes.screenMargin,
                0,
              ),
              child: switch (billing) {
                AsyncData(:final value) => _Body(billing: value),
                AsyncError(:final error) => Column(
                  children: [
                    TintedBanner(
                      key: const Key('billing-load-error'),
                      tint: context.tints.red,
                      icon: Icons.cloud_off_rounded,
                      title: promoterBillingMessage(l10n, error),
                    ),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(myBillingProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.consoleRetry),
                    ),
                  ],
                ),
                _ => const Shimmer(
                  child: Column(
                    children: [
                      SkeletonBox(height: 200, radius: TikeoRadii.card),
                      SizedBox(height: TikeoSizes.cardGap),
                      SkeletonBox(height: 160, radius: TikeoRadii.card),
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

class _PlanCard extends StatelessWidget {
  const new({required this.billing});

  final MyBilling billing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final plan = billing.plan;
    final (label, tint) = plan.isFree
        ? (l10n.billingPlanFree, tints.gray)
        : plan.isTrial
        ? (l10n.billingPlanTrial, tints.blue)
        : plan.grace
        ? (l10n.billingPlanGrace, tints.red)
        : (l10n.billingPlanActive, tints.green);
    return Column(
      key: const Key('billing-plan'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.billingPlanOverline.toUpperCase(),
          style: TikeoTextStyles.overline.copyWith(color: tints.mint.text),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                plan.pack.name,
                key: const Key('billing-plan-name'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            TikeoPill(
              key: const Key('billing-plan-state'),
              label: label,
              tint: tint,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (!plan.isFree) durationLabel(l10n, plan.duration),
            if (plan.periodEnd case final end? when !plan.isFree)
              l10n.billingUntil(billingDate(end))
            else if (plan.isFree)
              l10n.billingPlanFreeHint,
          ].join(' · '),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (plan.addons.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            addonsLabel(l10n, plan.addons),
            key: const Key('billing-plan-addons'),
            style: theme.textTheme.bodySmall?.copyWith(color: tints.blue.text),
          ),
        ],
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const new({required this.billing});

  final MyBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tints = context.tints;
    final plan = billing.plan;
    final due = billing.dueInvoices;
    final hasAddons = plan.pack.options.values.any((o) => o.addonAllowed);
    final gauges = [
      (BillingOption.structures, billing.usage.structures),
      (BillingOption.activeEvents, billing.usage.activeEvents),
      (BillingOption.ticketsPerPeriod, billing.usage.ticketsPeriod),
      (BillingOption.membersPerStructure, billing.usage.membersMax),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (billing.pending case final request?) ...[
          InkWell(
            onTap: () =>
                unawaited(context.push(AppRoutes.billingRequest(request.id))),
            borderRadius: BorderRadius.circular(TikeoRadii.card),
            child: TintedBanner(
              key: const Key('billing-pending'),
              tint: tints.amber,
              icon: Icons.hourglass_top_rounded,
              title: request.declared
                  ? l10n.billingPendingDeclared
                  : l10n.billingPendingToPay,
              body: l10n.billingPendingBody(
                request.reference,
                money(l10n, request.amount),
              ),
            ),
          ),
          const SizedBox(height: TikeoSizes.cardGap),
        ],
        if (due.isNotEmpty) ...[
          InkWell(
            onTap: () =>
                unawaited(context.push(AppRoutes.billingInvoicesToPay)),
            borderRadius: BorderRadius.circular(TikeoRadii.card),
            child: TintedBanner(
              key: const Key('billing-due'),
              tint: due.first.overdue ? tints.red : tints.amber,
              icon: Icons.receipt_long_rounded,
              title: l10n.billingDueInvoices(due.length),
              body: due.first.overdue ? l10n.billingOverdueBody : null,
            ),
          ),
          const SizedBox(height: TikeoSizes.cardGap),
        ],
        TikeoCard(
          key: const Key('billing-gauges'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: l10n.billingUsageTitle,
                icon: Icons.speed_rounded,
              ),
              for (final (option, used) in gauges)
                _Gauge(
                  option: option,
                  used: used,
                  limit: billing.limits[option],
                  addonPossible:
                      plan.isPaid &&
                      (plan.pack.options[option]?.addonAllowed ?? false),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final MapEntry(key: option, value: enabled)
                      in billing.features.entries)
                    TikeoPill(
                      label: option.label(l10n),
                      tint: enabled ? tints.green : tints.gray,
                      icon: enabled ? Icons.check_rounded : Icons.close_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TikeoSizes.cardGap),
        TikeoPrimaryButton(
          key: const Key('billing-change-pack'),
          onPressed: () => unawaited(context.push(AppRoutes.billingPacks)),
          icon: Icons.swap_horiz_rounded,
          label: plan.isFree ? l10n.billingChoosePack : l10n.billingChangePack,
        ),
        if (plan.isPaid && hasAddons) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('billing-addons'),
            onPressed: () =>
                unawaited(context.push(AppRoutes.billingAddonsCurrent)),
            icon: const Icon(Icons.add_circle_rounded),
            label: Text(l10n.billingAddonsTitle),
          ),
        ],
        const SizedBox(height: TikeoSizes.sectionGap),
        SectionHeader(
          title: l10n.billingByStructure,
          icon: Icons.storefront_rounded,
        ),
        const SizedBox(height: 8),
        for (final organization in billing.organizations)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TikeoCard(
              padding: const EdgeInsets.all(4),
              child: SettingsRow(
                key: Key('billing-org-${organization.id}'),
                icon: Icons.storefront_rounded,
                tint: systemTint(tints, organization.system),
                title: organization.name,
                subtitle: systemLabel(l10n, organization.system),
                onTap: () =>
                    unawaited(_chooseSystem(context, ref, organization)),
              ),
            ),
          ),
        const SizedBox(height: TikeoSizes.sectionGap),
        SectionHeader(
          title: l10n.billingInvoicesTitle,
          icon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 8),
        ...billingHistoryRows(context, billing, limit: 5),
        if (billing.invoices.isNotEmpty ||
            billing.requests.any((r) => r.status == RequestStatus.activated))
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const Key('billing-invoices-all'),
              onPressed: () =>
                  unawaited(context.push(AppRoutes.billingInvoices)),
              child: Text(l10n.billingSeeAll),
            ),
          ),
      ],
    );
  }

  Future<void> _chooseSystem(
    BuildContext context,
    WidgetRef ref,
    BillingOrganization organization,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final choice = await showModalBottomSheet<(BillingSystem, String?)>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          OrganizationBillingSheet(organization: organization),
    );
    if (choice == null) return;
    try {
      await ref
          .read(billingRepositoryProvider)
          .setOrganizationBilling(organization.id, choice.$1, choice.$2);
      ref.invalidate(myBillingProvider);
      toast.success(l10n.billingStructureSaved);
    } on Object catch (error) {
      toast.error(promoterBillingMessage(l10n, error));
    }
  }
}

class _Gauge extends StatelessWidget {
  const new({
    required this.option,
    required this.used,
    required this.limit,
    required this.addonPossible,
  });

  final BillingOption option;
  final int used;
  final int? limit;
  final bool addonPossible;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final max = limit;
    final full = max != null && used >= max;
    final tint = full ? tints.red : tints.mint;
    return Padding(
      key: Key('billing-gauge-${option.key}'),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.label(l10n),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                max == null
                    ? l10n.billingGaugeUnlimited(used)
                    : l10n.billingGaugeOf(used, max),
                style: theme.textTheme.labelLarge?.copyWith(color: tint.text),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max == null || max == 0
                  ? (max == 0 ? 1 : 0.08)
                  : (used / max).clamp(0, 1),
              minHeight: 8,
              color: tint.icon,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          if (full)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                addonPossible
                    ? l10n.billingGaugeFullAddon
                    : l10n.billingGaugeFull,
                key: Key('billing-gauge-full-${option.key}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tints.red.text,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Facturation par défaut d'une structure : forfait ou pack à l'usage.
class OrganizationBillingSheet extends ConsumerStatefulWidget {
  const new({required this.organization, super.key});

  final BillingOrganization organization;

  @override
  ConsumerState<OrganizationBillingSheet> createState() =>
      _OrganizationBillingSheetState();
}

class _OrganizationBillingSheetState
    extends ConsumerState<OrganizationBillingSheet> {
  late BillingSystem _system = widget.organization.system;
  late String? _pack = widget.organization.usagePackId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final catalog = ref.watch(billingCatalogProvider).value ?? const [];
    final usagePacks = [
      for (final pack in catalog)
        if (pack.system == BillingSystem.usage) pack,
    ];
    final valid =
        _system == BillingSystem.flat ||
        usagePacks.any((pack) => pack.id == _pack);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.organization.name, style: theme.textTheme.titleLarge),
            Text(l10n.billingStructureHelp, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SelectableOption(
              key: const Key('billing-org-flat'),
              label: l10n.billingSystemFlat,
              subtitle: l10n.billingStructureFlatHint,
              icon: Icons.workspace_premium_rounded,
              selected: _system == BillingSystem.flat,
              onTap: () => setState(() => _system = BillingSystem.flat),
            ),
            const SizedBox(height: 8),
            for (final pack in usagePacks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectableOption(
                  key: Key('billing-org-usage-${pack.id}'),
                  label: '${l10n.billingSystemUsage} · ${pack.name}',
                  subtitle: packPriceLabel(l10n, pack),
                  icon: Icons.confirmation_number_rounded,
                  selected: _system == BillingSystem.usage && _pack == pack.id,
                  onTap: () => setState(() {
                    _system = BillingSystem.usage;
                    _pack = pack.id;
                  }),
                ),
              ),
            const SizedBox(height: 8),
            TikeoPrimaryButton(
              key: const Key('billing-org-save'),
              onPressed: valid
                  ? () => Navigator.of(context).pop((
                      _system,
                      _system == BillingSystem.usage ? _pack : null,
                    ))
                  : null,
              icon: Icons.check_rounded,
              label: l10n.billingStructureSave,
            ),
          ],
        ),
      ),
    );
  }
}
