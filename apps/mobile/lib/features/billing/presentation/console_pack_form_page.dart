import 'dart:async';

import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/application/billing_admin_providers.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/console_packs_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

final List<TextInputFormatter> _digits = [
  FilteringTextInputFormatter.digitsOnly,
];

int? _int(TextEditingController controller) =>
    int.tryParse(controller.text.trim());

/// Brouillon d'une option dans le formulaire.
class _OptionDraft {
  new(this.option, PackOptionSetting? setting)
    : included = TextEditingController(
        text: setting?.included?.toString() ?? '',
      ),
      state = setting?.state ?? FeatureState.included,
      addon = setting?.addonAllowed ?? false,
      price = TextEditingController(
        text: setting?.addonPrice?.toString() ?? '',
      ),
      step = TextEditingController(text: '${setting?.addonStep ?? 1}'),
      cap = TextEditingController(text: setting?.addonCap?.toString() ?? '');

  final BillingOption option;
  final TextEditingController included;
  FeatureState state;
  bool addon;
  final TextEditingController price;
  final TextEditingController step;
  final TextEditingController cap;

  void dispose() {
    included.dispose();
    price.dispose();
    step.dispose();
    cap.dispose();
  }

  /// Réglage envoyé ; null : option absente du pack (illimitée ou comprise).
  PackOptionSetting? toSetting() {
    final withAddon = option.numeric ? addon : state == FeatureState.addon;
    final setting = PackOptionSetting(
      option: option,
      included: option.numeric ? _int(included) : null,
      state: state,
      addonPrice: withAddon ? (_int(price) ?? 0) : null,
      addonStep: option.numeric ? (_int(step) ?? 1).clamp(1, 1000000) : 1,
      addonCap: withAddon && option.numeric ? _int(cap) : null,
    );
    final isDefault = option.numeric
        ? setting.included == null && !withAddon
        : state == FeatureState.included;
    return isDefault ? null : setting;
  }
}

/// C2 · Créer ou modifier un pack.
class ConsolePackFormPage extends ConsumerStatefulWidget {
  const new({this.packId, super.key});

  /// Pack modifié ; null : nouveau pack.
  final String? packId;

  @override
  ConsumerState<ConsolePackFormPage> createState() =>
      _ConsolePackFormPageState();
}

class _ConsolePackFormPageState extends ConsumerState<ConsolePackFormPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _monthly = TextEditingController();
  final _trial = TextEditingController(text: '0');
  final _entry = TextEditingController();
  final _free = TextEditingController(text: '0');
  final _paymentDays = TextEditingController();
  final _sortOrder = TextEditingController(text: '0');
  final Map<BillingDuration, TextEditingController> _durationPrices = {
    for (final d in BillingDuration.offered) d: TextEditingController(),
  };
  final Set<BillingDuration> _durations = {};
  final Set<BillingDuration> _editedPrices = {};
  final List<({TextEditingController upTo, TextEditingController price})>
  _tiers = [];
  final Map<BillingOption, _OptionDraft> _options = {};

  BillingSystem _system = BillingSystem.flat;
  bool _featured = false;
  bool _ready = false;
  bool _busy = false;
  String? _error;
  BillingPack? _original;

  @override
  void initState() {
    super.initState();
    _monthly.addListener(_syncPrices);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _monthly,
      _trial,
      _entry,
      _free,
      _paymentDays,
      _sortOrder,
      ..._durationPrices.values,
    ]) {
      controller.dispose();
    }
    for (final tier in _tiers) {
      tier.upTo.dispose();
      tier.price.dispose();
    }
    for (final option in _options.values) {
      option.dispose();
    }
    super.dispose();
  }

  /// Prix des durées calculés depuis le prix mensuel, sauf ceux modifiés.
  void _syncPrices() {
    final monthly = _int(_monthly);
    if (monthly == null) return;
    for (final duration in BillingDuration.offered) {
      if (_editedPrices.contains(duration)) continue;
      _durationPrices[duration]!.text = '${monthly * duration.months}';
    }
  }

  void _init(BillingPack? pack) {
    if (_ready) return;
    _ready = true;
    _original = pack;
    for (final option in BillingOption.values) {
      _options[option] = _OptionDraft(option, pack?.options[option]);
    }
    if (pack == null) {
      _durations.add(BillingDuration.month);
      return;
    }
    _system = pack.system;
    _featured = pack.featured;
    _name.text = pack.name;
    _description.text = pack.description ?? '';
    _sortOrder.text = '${pack.sortOrder}';
    _trial.text = '${pack.trialDays}';
    _monthly.text = pack.monthlyPrice?.toString() ?? '';
    for (final MapEntry(:key, :value) in pack.durations.entries) {
      if (!BillingDuration.offered.contains(key)) continue;
      _durations.add(key);
      _durationPrices[key]!.text = '$value';
      _editedPrices.add(key);
    }
    _entry.text = pack.entryPrice?.toString() ?? '';
    _free.text = '${pack.freeEntries}';
    _paymentDays.text = pack.paymentDays?.toString() ?? '';
    for (final tier in pack.tiers) {
      _tiers.add((
        upTo: TextEditingController(text: tier.upTo?.toString() ?? ''),
        price: TextEditingController(text: '${tier.price}'),
      ));
    }
  }

  BillingPack _draft() => BillingPack(
    id: widget.packId ?? '',
    code: _original?.code,
    name: _name.text.trim(),
    description: _description.text.trim().isEmpty
        ? null
        : _description.text.trim(),
    system: _system,
    status: _original?.status ?? PackStatus.draft,
    sortOrder: _int(_sortOrder) ?? 0,
    featured: _featured,
    monthlyPrice: _int(_monthly),
    // Packs du système : leurs durées ne se règlent pas ici.
    durations: _original?.isSystem ?? false
        ? _original!.durations
        : {
            for (final duration in BillingDuration.offered)
              if (_durations.contains(duration))
                duration: _int(_durationPrices[duration]!) ?? 0,
          },
    trialDays: _int(_trial) ?? 0,
    entryPrice: _int(_entry),
    freeEntries: _int(_free) ?? 0,
    tiers: [
      for (final tier in _tiers)
        if (_int(tier.price) case final price?)
          (upTo: _int(tier.upTo), price: price),
    ],
    paymentDays: _int(_paymentDays),
    options: {
      for (final draft in _options.values) draft.option: ?draft.toSetting(),
    },
  );

  String? _validate(AppLocalizations l10n, BillingPack pack) {
    if (pack.name.length < 2 || pack.name.length > 60) {
      return l10n.billingFormNameInvalid;
    }
    if (pack.system == BillingSystem.flat &&
        !pack.isSystem &&
        (pack.monthlyPrice == null || pack.durations.isEmpty)) {
      return l10n.billingFormFlatInvalid;
    }
    if (pack.system == BillingSystem.usage &&
        pack.entryPrice == null &&
        pack.tiers.isEmpty) {
      return l10n.billingFormUsageInvalid;
    }
    return null;
  }

  Future<void> _save({required bool publish}) async {
    final l10n = context.l10n;
    final pack = _draft();
    if (_validate(l10n, pack) case final message?) {
      setState(() => _error = message);
      return;
    }
    final toast = Toaster.of(context);
    final repository = ref.read(billingAdminRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await repository.savePack(widget.packId, pack);
      if (publish && pack.status != PackStatus.published) {
        await repository.setPackStatus(id, PackStatus.published);
      }
      ref.invalidate(adminBillingProvider);
      toast.success(
        publish ? l10n.billingPackPublishedToast : l10n.billingFormSaved,
      );
      if (mounted) context.popOr(AppRoutes.consolePacks);
    } on Object catch (error) {
      if (mounted) setState(() => _error = billingFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _preview() {
    final pack = _draft();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => PackPreview(pack: pack),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(adminBillingProvider);
    if (widget.packId != null && billing is! AsyncData) {
      return Scaffold(
        appBar: TikeoAppBar(title: Text(l10n.billingFormEditTitle)),
        body: Padding(
          padding: const EdgeInsets.all(TikeoSizes.screenMargin),
          child: switch (billing) {
            AsyncError(:final error) => BillingLoadError(
              error: error,
              onRetry: () => ref.invalidate(adminBillingProvider),
            ),
            _ => const BillingLoading(),
          },
        ),
      );
    }
    _init(billing.value?.packById(widget.packId));
    final editing = widget.packId != null;
    final system = _original?.isSystem ?? false;
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(
          editing ? l10n.billingFormEditTitle : l10n.billingFormNewTitle,
        ),
        actions: [
          TextButton(
            key: const Key('billing-form-preview'),
            onPressed: _busy ? null : _preview,
            child: Text(l10n.billingFormPreview),
          ),
        ],
      ),
      body: SingleChildScrollView(
        key: const Key('billing-form'),
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
                key: const Key('billing-form-error'),
                tint: context.tints.red,
                icon: Icons.error_rounded,
                title: error,
              ),
              const SizedBox(height: TikeoSizes.cardGap),
            ],
            if (!editing) ...[
              TikeoFieldLabel(label: l10n.billingFormSystem),
              Row(
                children: [
                  for (final (i, value) in BillingSystem.values.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: SelectableOption(
                        key: Key('billing-form-system-${value.wireName}'),
                        label: systemLabel(l10n, value),
                        icon: value == BillingSystem.flat
                            ? Icons.workspace_premium_rounded
                            : Icons.confirmation_number_rounded,
                        selected: _system == value,
                        onTap: () => setState(() => _system = value),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: TikeoSizes.cardGap),
            ] else
              Align(
                alignment: Alignment.centerLeft,
                child: TikeoPill(
                  label: systemLabel(l10n, _system),
                  tint: systemTint(context.tints, _system),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('billing-form-name'),
              controller: _name,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.billingFormName),
            ),
            TextField(
              key: const Key('billing-form-description'),
              controller: _description,
              maxLength: 300,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.billingFormDescription,
                alignLabelWithHint: true,
              ),
            ),
            _NumberField(
              fieldKey: const Key('billing-form-sort'),
              controller: _sortOrder,
              label: l10n.billingFormSortOrder,
            ),
            SwitchListTile(
              key: const Key('billing-form-featured'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.billingPackFeatured),
              value: _featured,
              onChanged: (value) => setState(() => _featured = value),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            if (_system == BillingSystem.flat)
              ..._flatFields(l10n, system)
            else
              ..._usageFields(l10n),
            const SizedBox(height: TikeoSizes.sectionGap),
            SectionHeader(
              title: l10n.billingFormNumericOptions,
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.billingFormNumericHelp(
                _system == BillingSystem.flat
                    ? l10n.billingPerMonthShort
                    : l10n.billingPerEventShort,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final option in BillingOption.values.where((o) => o.numeric))
              if (_system == BillingSystem.flat ||
                  (option != BillingOption.structures &&
                      option != BillingOption.ticketsPerPeriod))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NumericOptionCard(
                    draft: _options[option]!,
                    onChanged: () => setState(() {}),
                  ),
                ),
            const SizedBox(height: TikeoSizes.cardGap),
            SectionHeader(
              title: l10n.billingFormFeatures,
              icon: Icons.toggle_on_rounded,
            ),
            const SizedBox(height: 8),
            for (final option in BillingOption.values.where((o) => !o.numeric))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FeatureCard(
                  draft: _options[option]!,
                  onChanged: () => setState(() {}),
                ),
              ),
            const SizedBox(height: TikeoSizes.sectionGap),
            if ((_original?.status ?? PackStatus.draft) != PackStatus.published)
              TikeoPrimaryButton(
                key: const Key('billing-form-publish'),
                busy: _busy,
                onPressed: _busy ? null : () => unawaited(_save(publish: true)),
                icon: Icons.rocket_launch_rounded,
                label: l10n.billingFormPublish,
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('billing-form-save'),
              onPressed: _busy ? null : () => unawaited(_save(publish: false)),
              icon: const Icon(Icons.save_rounded),
              label: Text(
                (_original?.status ?? PackStatus.draft) == PackStatus.published
                    ? l10n.billingFormSave
                    : l10n.billingFormSaveDraft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _flatFields(AppLocalizations l10n, bool system) => [
    SectionHeader(title: l10n.billingFormPrices, icon: Icons.sell_rounded),
    const SizedBox(height: 8),
    _NumberField(
      fieldKey: const Key('billing-form-monthly'),
      controller: _monthly,
      label: l10n.billingFormMonthly,
      suffix: 'FCFA',
    ),
    if (!system) ...[
      const SizedBox(height: 8),
      Text(
        l10n.billingFormDurations,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      for (final duration in BillingDuration.offered)
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                key: Key('billing-form-duration-${duration.wireName}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(durationLabel(l10n, duration)),
                value: _durations.contains(duration),
                onChanged: (value) => setState(
                  () => value ?? false
                      ? _durations.add(duration)
                      : _durations.remove(duration),
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                key: Key('billing-form-duration-price-${duration.wireName}'),
                controller: _durationPrices[duration],
                enabled: _durations.contains(duration),
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                decoration: const InputDecoration(suffixText: 'FCFA'),
                onChanged: (_) => _editedPrices.add(duration),
              ),
            ),
          ],
        ),
    ],
    const SizedBox(height: 8),
    _NumberField(
      fieldKey: const Key('billing-form-trial'),
      controller: _trial,
      label: l10n.billingFormTrial,
    ),
  ];

  List<Widget> _usageFields(AppLocalizations l10n) => [
    SectionHeader(title: l10n.billingFormPrices, icon: Icons.sell_rounded),
    const SizedBox(height: 8),
    _NumberField(
      fieldKey: const Key('billing-form-entry'),
      controller: _entry,
      label: l10n.billingFormEntryPrice,
      suffix: 'FCFA',
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: _NumberField(
            fieldKey: const Key('billing-form-free'),
            controller: _free,
            label: l10n.billingFormFreeEntries,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NumberField(
            fieldKey: const Key('billing-form-payment-days'),
            controller: _paymentDays,
            label: l10n.billingFormPaymentDays,
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    Text(l10n.billingFormTiers, style: Theme.of(context).textTheme.titleSmall),
    Text(
      l10n.billingFormTiersHelp,
      style: Theme.of(context).textTheme.bodySmall,
    ),
    for (final (i, tier) in _tiers.indexed)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: Key('billing-form-tier-upto-$i'),
                controller: tier.upTo,
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                decoration: InputDecoration(
                  labelText: l10n.billingFormTierUpTo,
                  hintText: '∞',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: Key('billing-form-tier-price-$i'),
                controller: tier.price,
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                decoration: InputDecoration(
                  labelText: l10n.billingFormTierPrice,
                  suffixText: 'FCFA',
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.billingFormTierRemove,
              onPressed: () => setState(() {
                final removed = _tiers.removeAt(i);
                removed.upTo.dispose();
                removed.price.dispose();
              }),
              icon: const Icon(Icons.delete_rounded),
            ),
          ],
        ),
      ),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('billing-form-tier-add'),
        onPressed: () => setState(
          () => _tiers.add((
            upTo: TextEditingController(),
            price: TextEditingController(),
          )),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.billingFormTierAdd),
      ),
    ),
  ];
}

class _NumberField extends StatelessWidget {
  const new({
    required this.fieldKey,
    required this.controller,
    required this.label,
    this.suffix,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: _digits,
    decoration: InputDecoration(labelText: label, suffixText: suffix),
  );
}

class _NumericOptionCard extends StatelessWidget {
  const new({required this.draft, required this.onChanged});

  final _OptionDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = draft.option.key;
    final tint = context.tints.blue;
    return TikeoCard(
      key: Key('billing-form-option-$key'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: tint.background,
                child: Icon(
                  optionIcon(draft.option),
                  size: 20,
                  color: tint.icon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  draft.option.label(l10n),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              SizedBox(
                width: 96,
                child: TextField(
                  key: Key('billing-form-option-$key-included'),
                  controller: draft.included,
                  keyboardType: TextInputType.number,
                  inputFormatters: _digits,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: l10n.billingFormIncluded,
                    hintText: '∞',
                  ),
                ),
              ),
            ],
          ),
          SwitchListTile(
            key: Key('billing-form-option-$key-addon'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.billingFormAddonAllowed),
            value: draft.addon,
            onChanged: (value) {
              draft.addon = value;
              onChanged();
            },
          ),
          if (draft.addon)
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    fieldKey: Key('billing-form-option-$key-price'),
                    controller: draft.price,
                    label: l10n.billingFormAddonPrice,
                    suffix: 'FCFA',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    fieldKey: Key('billing-form-option-$key-step'),
                    controller: draft.step,
                    label: l10n.billingFormAddonStep,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    fieldKey: Key('billing-form-option-$key-cap'),
                    controller: draft.cap,
                    label: l10n.billingFormAddonCap,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const new({required this.draft, required this.onChanged});

  final _OptionDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = draft.option.key;
    final tint = context.tints.violet;
    return TikeoCard(
      key: Key('billing-form-feature-$key'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: tint.background,
                child: Icon(
                  optionIcon(draft.option),
                  size: 20,
                  color: tint.icon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  draft.option.label(l10n),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<FeatureState>(
            showSelectedIcon: false,
            segments: [
              for (final state in FeatureState.values)
                ButtonSegment(
                  value: state,
                  label: Text(
                    featureStateLabel(l10n, state),
                    key: Key('billing-form-feature-$key-${state.wireName}'),
                  ),
                ),
            ],
            selected: {draft.state},
            onSelectionChanged: (selection) {
              draft.state = selection.single;
              onChanged();
            },
          ),
          if (draft.state == FeatureState.addon) ...[
            const SizedBox(height: 8),
            _NumberField(
              fieldKey: Key('billing-form-feature-$key-price'),
              controller: draft.price,
              label: l10n.billingFormAddonPrice,
              suffix: 'FCFA',
            ),
          ],
        ],
      ),
    );
  }
}

/// Aperçu d'un pack tel que le promoteur le verra (P2, P3).
class PackPreview extends StatelessWidget {
  const new({required this.pack, super.key});

  final BillingPack pack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    Widget line(IconData icon, Color color, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return SingleChildScrollView(
      key: const Key('billing-preview'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pack.featured)
            TikeoPill(
              label: l10n.billingPackFeatured,
              tint: tints.vip,
              icon: Icons.star_rounded,
            ),
          const SizedBox(height: 8),
          Text(pack.name, style: theme.textTheme.titleLarge),
          if (pack.description case final text?) Text(text),
          const SizedBox(height: 8),
          Text(
            packPriceLabel(l10n, pack),
            style: TikeoTextStyles.tileNumber.copyWith(color: tints.mint.text),
          ),
          for (final option in BillingOption.values)
            switch (pack.options[option]) {
              null => line(
                Icons.check_circle_rounded,
                tints.green.icon,
                option.numeric
                    ? l10n.billingPreviewUnlimited(option.label(l10n))
                    : option.label(l10n),
              ),
              PackOptionSetting(state: FeatureState.unavailable)
                  when !option.numeric =>
                line(Icons.cancel_rounded, tints.gray.icon, option.label(l10n)),
              PackOptionSetting(
                state: FeatureState.addon,
                addonPrice: final price?,
              )
                  when !option.numeric =>
                line(
                  Icons.add_circle_rounded,
                  tints.blue.icon,
                  l10n.billingPreviewAddon(
                    option.label(l10n),
                    money(l10n, price),
                  ),
                ),
              final setting => line(
                Icons.check_circle_rounded,
                tints.green.icon,
                [
                  if (option.numeric)
                    l10n.billingPreviewIncluded(
                      setting.included?.toString() ?? '∞',
                      option.label(l10n),
                    )
                  else
                    option.label(l10n),
                  if (option.numeric && setting.addonPrice != null)
                    l10n.billingPreviewMore(
                      money(l10n, setting.addonPrice!),
                      setting.addonStep,
                    ),
                ].join(' · '),
              ),
            },
        ],
      ),
    );
  }
}
