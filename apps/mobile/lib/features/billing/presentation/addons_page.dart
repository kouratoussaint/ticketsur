import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/my_pack_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// P4 · Suppléments : avec un pack choisi ([packId] et [duration]), ou en
/// cours d'abonnement (au prorata des jours restants).
class AddonsPage extends ConsumerStatefulWidget {
  const new({this.packId, this.duration, super.key});

  final String? packId;
  final BillingDuration? duration;

  @override
  ConsumerState<AddonsPage> createState() => _AddonsPageState();
}

class _AddonsPageState extends ConsumerState<AddonsPage> {
  final Map<BillingOption, int> _units = {};
  bool _busy = false;
  String? _error;

  bool get _forPack => widget.packId != null && widget.duration != null;

  Future<void> _continue() async {
    final l10n = context.l10n;
    final repository = ref.read(billingRepositoryProvider);
    final addons = {
      for (final MapEntry(:key, :value) in _units.entries)
        if (value > 0) key.key: value,
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = _forPack
          ? await repository.requestPack(
              widget.packId!,
              widget.duration!,
              addons,
            )
          : await repository.requestAddons(addons);
      ref.invalidate(myBillingProvider);
      if (mounted) {
        context.pushReplacement(AppRoutes.billingRequest(created.id));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = promoterBillingMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(billingCatalogProvider);
    final billing = ref.watch(myBillingProvider);
    final pack = _forPack
        ? catalog.value?.where((p) => p.id == widget.packId).firstOrNull
        : billing.value?.plan.pack;
    final failure = catalog.error ?? billing.error;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.billingAddonsTitle)),
      body: switch ((pack, failure)) {
        (final BillingPack pack, _) => _content(
          context,
          pack,
          billing.value,
          catalog.value ?? const [],
        ),
        (_, final Object error) => Padding(
          padding: const EdgeInsets.all(TikeoSizes.screenMargin),
          child: TintedBanner(
            tint: context.tints.red,
            icon: Icons.cloud_off_rounded,
            title: promoterBillingMessage(l10n, error),
          ),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(TikeoSizes.screenMargin),
          child: Shimmer(
            child: SkeletonBox(height: 320, radius: TikeoRadii.card),
          ),
        ),
      },
    );
  }

  Widget _content(
    BuildContext context,
    BillingPack pack,
    MyBilling? billing,
    List<BillingPack> catalog,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final duration = widget.duration;
    final months = _forPack ? duration!.months : null;
    final now = DateTime.now().toUtc();
    // En cours d'abonnement : prorata des jours restants (estimation ; le
    // serveur fait le calcul exact).
    final end = billing?.plan.periodEnd;
    final prorata = _forPack
        ? months!.toDouble()
        : billing?.plan.duration == BillingDuration.event
        ? 1.0
        : end == null
        ? 0.0
        : (end.difference(now).inHours / 24 / 30).clamp(0, 120).toDouble();
    final settings = [
      for (final setting in pack.options.values)
        if (setting.addonAllowed) setting,
    ];
    final unavailable = [
      for (final setting in pack.options.values)
        if (!setting.option.numeric &&
            setting.state == FeatureState.unavailable)
          setting.option,
    ];
    int subtotal(PackOptionSetting setting) =>
        ((_units[setting.option] ?? 0) * setting.addonPrice! * prorata).round();
    final addonsTotal = settings.fold(0, (sum, s) => sum + subtotal(s));
    final packPrice = _forPack ? pack.durations[duration] ?? 0 : 0;
    final total = packPrice + addonsTotal;
    final perPeriod = _forPack
        ? l10n.billingPerMonthShort
        : l10n.billingProrataShort;
    return SingleChildScrollView(
      key: const Key('billing-addons-page'),
      padding: EdgeInsets.fromLTRB(
        TikeoSizes.screenMargin,
        TikeoSizes.cardGap,
        TikeoSizes.screenMargin,
        MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error case final error?) ...[
            TintedBanner(
              key: const Key('billing-addons-error'),
              tint: tints.red,
              icon: Icons.error_rounded,
              title: error,
            ),
            const SizedBox(height: TikeoSizes.cardGap),
          ],
          TikeoCard(
            key: const Key('billing-addons-pack'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.name, style: theme.textTheme.titleLarge),
                Text(
                  _forPack
                      ? '${durationLabel(l10n, duration!)} · '
                            '${money(l10n, packPrice)}'
                      : l10n.billingAddonsCurrent(
                          end == null ? '—' : billingDate(end),
                        ),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: TikeoSizes.cardGap),
          if (settings.isEmpty)
            Text(l10n.billingAddonsNone, key: const Key('billing-addons-none')),
          for (final setting in settings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TikeoCard(
                key: Key('billing-addon-card-${setting.option.key}'),
                child: setting.option.numeric
                    ? _NumericAddon(
                        setting: setting,
                        units: _units[setting.option] ?? 0,
                        subtotal: subtotal(setting),
                        perPeriod: perPeriod,
                        onChanged: (value) =>
                            setState(() => _units[setting.option] = value),
                      )
                    : SwitchListTile(
                        key: Key('billing-addon-${setting.option.key}'),
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(optionIcon(setting.option)),
                        title: Text(setting.option.label(l10n)),
                        subtitle: Text(
                          '${money(l10n, setting.addonPrice!)} $perPeriod',
                        ),
                        value: (_units[setting.option] ?? 0) > 0,
                        onChanged: (value) => setState(
                          () => _units[setting.option] = value ? 1 : 0,
                        ),
                      ),
              ),
            ),
          if (unavailable.isNotEmpty) ...[
            const SizedBox(height: 8),
            SectionHeader(
              title: l10n.billingAddonsUnavailable,
              icon: Icons.block_rounded,
            ),
            for (final option in unavailable)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(optionIcon(option), size: 18, color: tints.gray.icon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        switch (_packWith(catalog, option, pack)) {
                          final other? => l10n.billingAvailableWith(
                            option.label(l10n),
                            other.name,
                          ),
                          null => option.label(l10n),
                        },
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: TikeoSizes.sectionGap),
          TikeoCard(
            key: const Key('billing-addons-summary'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_forPack)
                  _SummaryLine(
                    label: '${pack.name} · ${durationLabel(l10n, duration!)}',
                    amount: money(l10n, packPrice),
                  ),
                _SummaryLine(
                  label: l10n.billingAddonsTitle,
                  amount: money(l10n, addonsTotal),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _forPack
                            ? l10n.billingTotal
                            : l10n.billingTotalEstimate,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        money(l10n, total),
                        key: const Key('billing-addons-total'),
                        textAlign: TextAlign.end,
                        style: TikeoTextStyles.tileNumber.copyWith(
                          color: tints.mint.text,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_forPack)
                  Text(
                    l10n.billingProrataHint,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(height: TikeoSizes.cardGap),
          TikeoPrimaryButton(
            key: const Key('billing-addons-continue'),
            busy: _busy,
            onPressed:
                _busy ||
                    (!_forPack &&
                        addonsTotal == 0 &&
                        _units.values.every((v) => v == 0))
                ? null
                : () => unawaited(_continue()),
            icon: Icons.payments_rounded,
            label: l10n.billingContinueToPayment,
          ),
        ],
      ),
    );
  }

  /// Pack forfait publié qui comprend [option] (pour l'orienter).
  BillingPack? _packWith(
    List<BillingPack> catalog,
    BillingOption option,
    BillingPack current,
  ) {
    for (final pack in catalog) {
      if (pack.id == current.id || pack.system != current.system) continue;
      final setting = pack.options[option];
      if (setting == null || setting.state != FeatureState.unavailable) {
        return pack;
      }
    }
    return null;
  }
}

class _NumericAddon extends StatelessWidget {
  const new({
    required this.setting,
    required this.units,
    required this.subtotal,
    required this.perPeriod,
    required this.onChanged,
  });

  final PackOptionSetting setting;
  final int units;
  final int subtotal;
  final String perPeriod;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final key = setting.option.key;
    final cap = setting.addonCap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(optionIcon(setting.option), color: context.tints.blue.icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                setting.option.label(l10n),
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        Text(
          [
            l10n.billingIncludedValue(setting.included?.toString() ?? '∞'),
            l10n.billingAddonPricePer(
              setting.addonStep,
              money(l10n, setting.addonPrice!),
              perPeriod,
            ),
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        Row(
          children: [
            IconButton.outlined(
              key: Key('billing-addon-$key-minus'),
              tooltip: l10n.billingAddonLess,
              onPressed: units > 0 ? () => onChanged(units - 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 72,
              child: Text(
                '+${units * setting.addonStep}',
                key: Key('billing-addon-$key-value'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton.outlined(
              key: Key('billing-addon-$key-plus'),
              tooltip: l10n.billingAddonMore,
              onPressed: cap == null || units < cap
                  ? () => onChanged(units + 1)
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
            Expanded(
              child: Text(
                money(l10n, subtotal),
                textAlign: TextAlign.end,
                style: theme.textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const new({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(amount, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}
