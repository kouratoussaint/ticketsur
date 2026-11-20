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
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/my_pack_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Libellé court de la facturation d'un événement (fiche de l'événement).
String eventBillingSummary(AppLocalizations l10n, EventBilling billing) => [
  if (billing.mode == EventBillingMode.inherit) l10n.billingEventInherit,
  systemLabel(l10n, billing.system),
  if (billing.system == BillingSystem.usage) ?billing.packName,
].join(' · ');

/// P9 · Facturation d'un événement : comme la structure, forfait ou à
/// l'usage ; figée au premier ticket ; estimation en direct.
class EventBillingPage extends ConsumerStatefulWidget {
  const new({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<EventBillingPage> createState() => _EventBillingPageState();
}

class _EventBillingPageState extends ConsumerState<EventBillingPage> {
  EventBillingMode? _mode;
  String? _pack;
  bool _busy = false;
  String? _error;

  Future<void> _save(EventBilling current) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(billingRepositoryProvider)
          .setEventBilling(
            widget.eventId,
            _mode ?? current.mode,
            (_mode ?? current.mode) == EventBillingMode.usage
                ? _pack ?? current.usagePackId
                : null,
          );
      ref.invalidate(eventBillingProvider(widget.eventId));
      setState(() {
        _mode = null;
        _pack = null;
      });
      toast.success(l10n.billingEventSaved);
    } on Object catch (error) {
      if (mounted) setState(() => _error = promoterBillingMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(eventBillingProvider(widget.eventId));
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(l10n.billingEventTitle),
        leading: BackButton(
          onPressed: () => context.popOr(AppRoutes.eventDetail(widget.eventId)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(eventBillingProvider(widget.eventId).future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            TikeoSizes.screenMargin,
            TikeoSizes.cardGap,
            TikeoSizes.screenMargin,
            MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          child: switch (billing) {
            AsyncValue(:final EventBilling value) => _content(context, value),
            AsyncValue(:final error?) => TintedBanner(
              key: const Key('event-billing-error'),
              tint: context.tints.red,
              icon: Icons.cloud_off_rounded,
              title: promoterBillingMessage(l10n, error),
            ),
            _ => const Shimmer(
              child: SkeletonBox(height: 320, radius: TikeoRadii.card),
            ),
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, EventBilling billing) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final usagePacks = [
      for (final pack
          in ref.watch(billingCatalogProvider).value ?? const <BillingPack>[])
        if (pack.system == BillingSystem.usage) pack,
    ];
    final mode = _mode ?? billing.mode;
    final pack = _pack ?? billing.usagePackId;
    final changed =
        mode != billing.mode ||
        (mode == EventBillingMode.usage && pack != billing.usagePackId);
    final owner =
        ref.watch(activeOrganizationProvider)?.role == MemberRole.owner;
    final estimate = billing.estimate;
    final invoice = billing.invoice;
    void choose(EventBillingMode value, [String? packId]) {
      if (billing.locked) return;
      setState(() {
        _mode = value;
        _pack = packId;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TintedBanner(
          key: Key(
            billing.locked ? 'event-billing-locked' : 'event-billing-open',
          ),
          tint: billing.locked ? tints.amber : tints.blue,
          icon: billing.locked ? Icons.lock_rounded : Icons.info_rounded,
          title: billing.locked
              ? l10n.billingEventLockedBanner
              : l10n.billingEventLockHint,
          body: eventBillingSummary(l10n, billing),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: TikeoSizes.cardGap),
          TintedBanner(
            key: const Key('event-billing-save-error'),
            tint: tints.red,
            icon: Icons.error_rounded,
            title: error,
          ),
        ],
        const SizedBox(height: TikeoSizes.sectionGap),
        SectionHeader(title: l10n.billingEventChoice, icon: Icons.tune_rounded),
        const SizedBox(height: 8),
        SelectableOption(
          key: const Key('event-billing-inherit'),
          label: l10n.billingEventInherit,
          subtitle: l10n.billingEventInheritHint,
          icon: Icons.storefront_rounded,
          selected: mode == EventBillingMode.inherit,
          onTap: billing.locked ? null : () => choose(EventBillingMode.inherit),
        ),
        const SizedBox(height: 8),
        SelectableOption(
          key: const Key('event-billing-flat'),
          label: l10n.billingSystemFlat,
          subtitle: l10n.billingStructureFlatHint,
          icon: Icons.workspace_premium_rounded,
          selected: mode == EventBillingMode.flat,
          onTap: billing.locked ? null : () => choose(EventBillingMode.flat),
        ),
        for (final usage in usagePacks)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SelectableOption(
              key: Key('event-billing-usage-${usage.id}'),
              label: '${l10n.billingSystemUsage} · ${usage.name}',
              subtitle: packPriceLabel(l10n, usage),
              icon: Icons.confirmation_number_rounded,
              selected: mode == EventBillingMode.usage && pack == usage.id,
              onTap: billing.locked
                  ? null
                  : () => choose(EventBillingMode.usage, usage.id),
            ),
          ),
        if (!billing.locked) ...[
          const SizedBox(height: TikeoSizes.cardGap),
          TikeoPrimaryButton(
            key: const Key('event-billing-save'),
            busy: _busy,
            onPressed: changed && !_busy
                ? () => unawaited(_save(billing))
                : null,
            icon: Icons.check_rounded,
            label: l10n.billingStructureSave,
          ),
        ],
        if (billing.addons.isNotEmpty) ...[
          const SizedBox(height: TikeoSizes.sectionGap),
          TikeoCard(
            key: const Key('event-billing-addons'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: l10n.billingAddonsTitle,
                  icon: Icons.add_circle_rounded,
                ),
                const SizedBox(height: 4),
                Text(
                  addonsLabel(l10n, {
                    for (final MapEntry(:key, :value) in billing.addons.entries)
                      key.key: value,
                  }),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
        if (estimate != null && invoice == null) ...[
          const SizedBox(height: TikeoSizes.sectionGap),
          TikeoCard(
            key: const Key('event-billing-estimate'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: l10n.billingEventEstimate,
                  icon: Icons.insights_rounded,
                ),
                const SizedBox(height: 8),
                _Line(
                  label: l10n.billingSimulatorEntries(estimate.entries),
                  value: '',
                ),
                if (estimate.freeEntries > 0)
                  _Line(
                    label: l10n.billingFreeEntries(estimate.freeEntries),
                    value: money(l10n, 0),
                  ),
                _Line(
                  label: l10n.billingEventEntriesAmount(
                    estimate.billableEntries,
                  ),
                  value: money(l10n, estimate.entriesAmount),
                ),
                if (estimate.addonsAmount > 0)
                  _Line(
                    label: l10n.billingAddonsTitle,
                    value: money(l10n, estimate.addonsAmount),
                  ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.billingTotalEstimate,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      money(l10n, estimate.amount),
                      key: const Key('event-billing-estimate-total'),
                      style: TikeoTextStyles.tileNumber.copyWith(
                        color: tints.mint.text,
                      ),
                    ),
                  ],
                ),
                Text(
                  l10n.billingEventInvoiceWhen,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
        if (invoice != null) ...[
          const SizedBox(height: TikeoSizes.sectionGap),
          TikeoCard(
            padding: const EdgeInsets.all(4),
            child: SettingsRow(
              key: const Key('event-billing-invoice'),
              icon: Icons.receipt_long_rounded,
              tint: invoice.paid ? tints.green : tints.amber,
              title: l10n.billingEventInvoice(money(l10n, invoice.amount)),
              subtitle: invoice.paid
                  ? l10n.billingStatusPaid
                  : l10n.billingDueOn(billingDate(invoice.dueAt)),
              onTap: owner
                  ? () => unawaited(
                      context.push(AppRoutes.billingInvoice(invoice.id)),
                    )
                  : null,
            ),
          ),
        ],
        if (billing.system == BillingSystem.usage &&
            billing.limits.values.any((v) => v != null)) ...[
          const SizedBox(height: TikeoSizes.sectionGap),
          TikeoCard(
            key: const Key('event-billing-limits'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: l10n.billingEventLimits,
                  icon: Icons.speed_rounded,
                ),
                const SizedBox(height: 4),
                for (final MapEntry(:key, :value) in billing.limits.entries)
                  if (value != null && key != BillingOption.structures)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            optionIcon(key),
                            size: 18,
                            color: tints.blue.icon,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(key.label(l10n))),
                          Text('$value', style: theme.textTheme.labelLarge),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}
