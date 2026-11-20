import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/billing/application/billing_admin_providers.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/console_packs_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// C5 · Abonnements : recherche, états, gestes de la console.
class ConsoleSubscriptionsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleSubscriptionsPage> createState() =>
      _ConsoleSubscriptionsPageState();
}

class _ConsoleSubscriptionsPageState
    extends ConsumerState<ConsoleSubscriptionsPage> {
  String _search = '';
  SubscriptionState? _state;

  bool _matches(AdminSubscription sub) {
    final query = _search.toLowerCase();
    return query.isEmpty ||
        sub.accountName.toLowerCase().contains(query) ||
        (sub.accountEmail?.toLowerCase().contains(query) ?? false) ||
        sub.packName.toLowerCase().contains(query);
  }

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

  Future<void> _onAction(
    AdminSubscription sub,
    AdminBilling billing,
    _SubAction action,
  ) async {
    final l10n = context.l10n;
    final repository = ref.read(billingAdminRepositoryProvider);
    switch (action) {
      case _SubAction.extend:
        final now = ref.read(billingClockProvider)();
        final base = sub.endsAt ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: base.add(const Duration(days: 30)).toLocal(),
          firstDate: sub.startsAt.add(const Duration(days: 1)).toLocal(),
          lastDate: now.add(const Duration(days: 365 * 5)).toLocal(),
        );
        if (picked == null || !mounted) return;
        final note = await _askNote(
          l10n.billingExtendTitle,
          l10n.billingExtendBody(billingDate(picked)),
          l10n.billingExtend,
        );
        if (note == null) return;
        await _run(
          () => repository.extendSubscription(
            sub.id,
            DateTime.utc(picked.year, picked.month, picked.day, 23, 59),
            note,
          ),
          l10n.billingExtendedToast,
        );
      case _SubAction.changePack:
        final pack = await showModalBottomSheet<BillingPack>(
          context: context,
          useRootNavigator: true,
          showDragHandle: true,
          builder: (context) => _PackPicker(
            packs: [
              for (final pack in billing.packs)
                if (pack.system == BillingSystem.flat && pack.id != sub.packId)
                  pack,
            ],
          ),
        );
        if (pack == null || !mounted) return;
        final note = await _askNote(
          l10n.billingChangePackTitle,
          l10n.billingChangePackBody(pack.name),
          l10n.billingChangePack,
        );
        if (note == null) return;
        await _run(
          () => repository.changeSubscriptionPack(sub.id, pack.id, note),
          l10n.billingPackChangedToast,
        );
      case _SubAction.addons:
        final pack = billing.packById(sub.packId);
        final addons = await showModalBottomSheet<Map<String, int>>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => _AddonsSheet(pack: pack, initial: sub.addons),
        );
        if (addons == null || !mounted) return;
        final note = await _askNote(
          l10n.billingAddonsTitle,
          l10n.billingAddonsBody,
          l10n.billingAddonsSave,
        );
        if (note == null) return;
        await _run(
          () => repository.setSubscriptionAddons(sub.id, addons, note),
          l10n.billingAddonsSavedToast,
        );
      case _SubAction.cancel:
        final note = await showConsoleConfirm(
          context,
          title: l10n.billingCancelTitle,
          body: l10n.billingCancelBody(sub.accountName),
          confirmLabel: l10n.billingCancel,
          needsReason: true,
          confirmKey: const Key('billing-cancel-confirm'),
        );
        if (note == null) return;
        await _run(
          () => repository.cancelSubscription(sub.id, note),
          l10n.billingCancelledToast,
        );
    }
  }

  Future<String?> _askNote(String title, String body, String confirm) =>
      showConsoleConfirm(
        context,
        title: title,
        body: body,
        confirmLabel: confirm,
        needsReason: true,
        destructive: false,
        confirmKey: const Key('billing-note-confirm'),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(adminBillingProvider);
    final now = ref.watch(billingClockProvider)();
    final value = billing.value;
    final grace = value?.settings.graceDays ?? 7;
    int count(SubscriptionState state) =>
        value?.subscriptions
            .where((s) => s.stateAt(now, graceDays: grace) == state)
            .length ??
        0;
    final tints = context.tints;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.billingSubscriptionsTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminBillingProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            TikeoSizes.screenMargin,
            TikeoSizes.cardGap,
            TikeoSizes.screenMargin,
            MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          children: [
            ConsoleSearchField(
              key: const Key('billing-subscriptions-search'),
              hint: l10n.billingSubscriptionsSearch,
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, (state, label, tint, icon)) in [
                    (
                      SubscriptionState.active,
                      l10n.billingSubActive,
                      tints.green,
                      Icons.verified_rounded,
                    ),
                    (
                      SubscriptionState.endingSoon,
                      l10n.billingSubEndingSoon,
                      tints.amber,
                      Icons.hourglass_bottom_rounded,
                    ),
                    (
                      SubscriptionState.grace,
                      l10n.billingSubGrace,
                      tints.red,
                      Icons.timer_off_rounded,
                    ),
                  ].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: StatTile(
                        key: Key('billing-sub-tile-${state.name}'),
                        tint: _state == state ? tints.violet : tint,
                        icon: icon,
                        value: '${count(state)}',
                        label: label,
                        onTap: () => setState(
                          () => _state = _state == state ? null : state,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            TikeoPrimaryButton(
              key: const Key('billing-grant'),
              onPressed: value == null ? null : () => unawaited(_grant(value)),
              icon: Icons.card_giftcard_rounded,
              label: l10n.billingGrant,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('billing-event-change'),
              onPressed: value == null
                  ? null
                  : () => unawaited(_eventBilling(value)),
              icon: const Icon(Icons.event_repeat_rounded),
              label: Text(l10n.billingEventChange),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            ...switch (billing) {
              AsyncData(:final value) => [
                for (final sub in value.subscriptions)
                  if (_matches(sub) &&
                      (_state == null ||
                          sub.stateAt(now, graceDays: grace) == _state))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SubscriptionRow(
                        sub: sub,
                        state: sub.stateAt(now, graceDays: grace),
                        onAction: (action) =>
                            unawaited(_onAction(sub, value, action)),
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

  Future<void> _grant(AdminBilling billing) async {
    final l10n = context.l10n;
    final grant = await showModalBottomSheet<_Grant>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _GrantSheet(
        packs: [
          for (final pack in billing.packs)
            if (pack.system == BillingSystem.flat && !pack.isFree) pack,
        ],
      ),
    );
    if (grant == null) return;
    await _run(
      () => ref
          .read(billingAdminRepositoryProvider)
          .grantSubscription(
            accountId: grant.account.id,
            packId: grant.pack.id,
            duration: grant.duration,
            note: grant.note,
          ),
      l10n.billingGrantedToast,
    );
  }

  Future<void> _eventBilling(AdminBilling billing) async {
    final l10n = context.l10n;
    final done = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EventBillingSheet(
        usagePacks: [
          for (final pack in billing.packs)
            if (pack.system == BillingSystem.usage &&
                pack.status != PackStatus.archived)
              pack,
        ],
      ),
    );
    if (done ?? false) {
      if (mounted) Toaster.of(context).success(l10n.billingEventChangedToast);
    }
  }
}

enum _SubAction { extend, changePack, addons, cancel }

class _SubscriptionRow extends StatelessWidget {
  const new({required this.sub, required this.state, required this.onAction});

  final AdminSubscription sub;
  final SubscriptionState state;
  final ValueChanged<_SubAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    final (label, tint) = switch (state) {
      SubscriptionState.active => (l10n.billingSubActiveOne, tints.green),
      SubscriptionState.endingSoon => (l10n.billingSubEndingOne, tints.amber),
      SubscriptionState.grace => (l10n.billingSubGraceOne, tints.red),
      SubscriptionState.ended => (l10n.billingSubEndedOne, tints.gray),
    };
    return TikeoListRow(
      key: Key('billing-sub-${sub.id}'),
      stripe: tint.icon,
      chevron: false,
      title: sub.accountName,
      lines: [
        ?sub.accountEmail,
        [
          sub.packName,
          durationLabel(l10n, sub.duration),
          if (sub.endsAt case final end?)
            l10n.billingUntil(billingDate(end))
          else
            l10n.billingNoEnd,
        ].join(' · '),
        if (sub.addons.isNotEmpty) addonsLabel(l10n, sub.addons),
      ],
      badge: TikeoPill(label: label, tint: tint),
      menu: sub.packCode == 'decouverte'
          ? null
          : PopupMenuButton<_SubAction>(
              key: Key('billing-sub-menu-${sub.id}'),
              tooltip: l10n.billingPackActions,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: onAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: Key('billing-sub-extend-${sub.id}'),
                  value: _SubAction.extend,
                  child: Text(l10n.billingExtend),
                ),
                PopupMenuItem(
                  key: Key('billing-sub-pack-${sub.id}'),
                  value: _SubAction.changePack,
                  child: Text(l10n.billingChangePack),
                ),
                PopupMenuItem(
                  key: Key('billing-sub-addons-${sub.id}'),
                  value: _SubAction.addons,
                  child: Text(l10n.billingAddonsTitle),
                ),
                PopupMenuItem(
                  key: Key('billing-sub-cancel-${sub.id}'),
                  value: _SubAction.cancel,
                  child: Text(l10n.billingCancel),
                ),
              ],
            ),
    );
  }
}

class _PackPicker extends StatelessWidget {
  const new({required this.packs});

  final List<BillingPack> packs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            l10n.billingChangePackTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final pack in packs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableOption(
                key: Key('billing-pick-${pack.id}'),
                label: pack.name,
                subtitle: [
                  packPriceLabel(l10n, pack),
                  packStatusLabel(l10n, pack.status),
                ].join(' · '),
                icon: Icons.workspace_premium_rounded,
                selected: false,
                onTap: () => Navigator.of(context).pop(pack),
              ),
            ),
        ],
      ),
    );
  }
}

/// Suppléments d'un abonnement : compteurs par option à supplément.
class _AddonsSheet extends StatefulWidget {
  const new({required this.pack, required this.initial});

  final BillingPack? pack;
  final Map<String, int> initial;

  @override
  State<_AddonsSheet> createState() => _AddonsSheetState();
}

class _AddonsSheetState extends State<_AddonsSheet> {
  late final Map<String, int> _units = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = [
      for (final setting
          in widget.pack?.options.values ?? <PackOptionSetting>[])
        if (setting.addonAllowed) setting,
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.billingAddonsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (settings.isEmpty)
              Text(
                l10n.billingAddonsNone,
                key: const Key('billing-addons-none'),
              ),
            for (final setting in settings)
              _Counter(
                key: Key('billing-addon-${setting.option.key}'),
                label: setting.option.label(l10n),
                detail: l10n.billingAddonPrice(
                  money(l10n, setting.addonPrice!),
                  setting.addonStep,
                ),
                value: _units[setting.option.key] ?? 0,
                max: setting.option.numeric ? setting.addonCap : 1,
                onChanged: (value) =>
                    setState(() => _units[setting.option.key] = value),
              ),
            const SizedBox(height: 12),
            TikeoPrimaryButton(
              key: const Key('billing-addons-next'),
              onPressed: () => Navigator.of(context).pop(_units),
              icon: Icons.check_rounded,
              label: l10n.billingAddonsSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const new({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.max,
    super.key,
  });

  final String label;
  final String detail;
  final int value;
  final int? max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton.outlined(
            key: key == null ? null : ValueKey('$key-minus'),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton.outlined(
            key: key == null ? null : ValueKey('$key-plus'),
            onPressed: max == null || value < max!
                ? () => onChanged(value + 1)
                : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

typedef _Grant = ({
  AdminAccount account,
  BillingPack pack,
  BillingDuration duration,
  String note,
});

/// « Activer un pack sans demande » : compte, pack, durée, motif.
class _GrantSheet extends ConsumerStatefulWidget {
  const new({required this.packs});

  final List<BillingPack> packs;

  @override
  ConsumerState<_GrantSheet> createState() => _GrantSheetState();
}

class _GrantSheetState extends ConsumerState<_GrantSheet> {
  final _note = TextEditingController();
  List<AdminAccount> _accounts = const [];
  AdminAccount? _account;
  BillingPack? _pack;
  BillingDuration _duration = BillingDuration.month;
  bool _missing = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    if (value.length < 2) {
      setState(() => _accounts = const []);
      return;
    }
    try {
      final accounts = await ref
          .read(adminRepositoryProvider)
          .accounts(search: value, limit: 10);
      if (mounted) setState(() => _accounts = accounts);
    } on Object {
      if (mounted) setState(() => _accounts = const []);
    }
  }

  void _submit() {
    final account = _account;
    final pack = _pack;
    if (account == null || pack == null || _note.text.trim().length < 3) {
      setState(() => _missing = true);
      return;
    }
    Navigator.of(context).pop((
      account: account,
      pack: pack,
      duration: _duration,
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.billingGrant, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_account case final account?)
              SettingsRow(
                key: const Key('billing-grant-account'),
                icon: Icons.person_rounded,
                tint: context.tints.mint,
                title: account.displayName,
                subtitle: account.email,
                trailing: IconButton(
                  tooltip: l10n.consoleCancel,
                  onPressed: () => setState(() => _account = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              )
            else ...[
              ConsoleSearchField(
                key: const Key('billing-grant-search'),
                hint: l10n.billingGrantSearch,
                onChanged: (value) => unawaited(_search(value)),
              ),
              for (final account in _accounts)
                ListTile(
                  key: Key('billing-grant-account-${account.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_rounded),
                  title: Text(account.displayName),
                  subtitle: account.email == null ? null : Text(account.email!),
                  onTap: () => setState(() => _account = account),
                ),
            ],
            const SizedBox(height: 12),
            Text(l10n.billingGrantPack, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pack in widget.packs)
                  ChoiceChip(
                    key: Key('billing-grant-pack-${pack.id}'),
                    label: Text(pack.name),
                    selected: _pack?.id == pack.id,
                    onSelected: (_) => setState(() => _pack = pack),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.billingGrantDuration, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final duration in BillingDuration.offered)
                  ChoiceChip(
                    key: Key('billing-grant-duration-${duration.wireName}'),
                    label: Text(durationLabel(l10n, duration)),
                    selected: _duration == duration,
                    onSelected: (_) => setState(() => _duration = duration),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('billing-grant-note'),
              controller: _note,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: l10n.consoleReason,
                errorText: _missing ? l10n.billingGrantMissing : null,
              ),
            ),
            const SizedBox(height: 8),
            TikeoPrimaryButton(
              key: const Key('billing-grant-submit'),
              onPressed: _submit,
              icon: Icons.card_giftcard_rounded,
              label: l10n.billingGrantSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Facturation d'un événement : recherche, puis forfait ou usage.
class _EventBillingSheet extends ConsumerStatefulWidget {
  const new({required this.usagePacks});

  final List<BillingPack> usagePacks;

  @override
  ConsumerState<_EventBillingSheet> createState() => _EventBillingSheetState();
}

class _EventBillingSheetState extends ConsumerState<_EventBillingSheet> {
  final _note = TextEditingController();
  List<BillingEventRow> _events = const [];
  BillingEventRow? _event;
  BillingSystem _system = BillingSystem.flat;
  BillingPack? _pack;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    try {
      final events = await ref
          .read(billingAdminRepositoryProvider)
          .events(value);
      if (mounted) setState(() => _events = events);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = billingFailureMessage(context.l10n, error));
      }
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final event = _event;
    if (event == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(billingAdminRepositoryProvider)
          .setEventBilling(
            event.id,
            _system,
            _system == BillingSystem.usage ? _pack?.id : null,
            _note.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = billingFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final event = _event;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.billingEventChange, style: theme.textTheme.titleLarge),
            Text(l10n.billingEventChangeHelp, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            if (_error case final error?) ...[
              TintedBanner(
                key: const Key('billing-event-error'),
                tint: context.tints.red,
                icon: Icons.error_rounded,
                title: error,
              ),
              const SizedBox(height: 8),
            ],
            if (event == null) ...[
              ConsoleSearchField(
                key: const Key('billing-event-search'),
                hint: l10n.billingEventSearch,
                onChanged: (value) => unawaited(_search(value)),
              ),
              for (final row in _events)
                ListTile(
                  key: Key('billing-event-${row.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(row.title),
                  subtitle: Text(
                    [
                      row.organizationName,
                      systemLabel(l10n, row.system),
                      ?row.packName,
                    ].join(' · '),
                  ),
                  onTap: () => setState(() {
                    _event = row;
                    _system = row.system;
                  }),
                ),
            ] else ...[
              SettingsRow(
                icon: Icons.event_rounded,
                tint: context.tints.violet,
                title: event.title,
                subtitle: [
                  event.organizationName,
                  systemLabel(l10n, event.system),
                  if (event.locked) l10n.billingEventLocked,
                ].join(' · '),
                trailing: IconButton(
                  tooltip: l10n.consoleCancel,
                  onPressed: () => setState(() => _event = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const SizedBox(height: 8),
              for (final system in BillingSystem.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableOption(
                    key: Key('billing-event-system-${system.wireName}'),
                    label: systemLabel(l10n, system),
                    selected: _system == system,
                    onTap: () => setState(() => _system = system),
                  ),
                ),
              if (_system == BillingSystem.usage)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pack in widget.usagePacks)
                      ChoiceChip(
                        key: Key('billing-event-pack-${pack.id}'),
                        label: Text(pack.name),
                        selected: _pack?.id == pack.id,
                        onSelected: (_) => setState(() => _pack = pack),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('billing-event-note'),
                controller: _note,
                maxLength: 300,
                decoration: InputDecoration(labelText: l10n.consoleReason),
              ),
              TikeoPrimaryButton(
                key: const Key('billing-event-submit'),
                busy: _busy,
                onPressed: _busy ? null : () => unawaited(_submit()),
                icon: Icons.check_rounded,
                label: l10n.billingEventApply,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
