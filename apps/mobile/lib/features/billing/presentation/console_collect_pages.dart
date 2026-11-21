import 'dart:async';

import 'package:flutter/services.dart' show FilteringTextInputFormatter;
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
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/billing/application/billing_admin_providers.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/console_packs_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Onglets de C3.
enum CollectFilter { toCheck, overdue, done }

/// C3 · À encaisser : demandes d'activation et factures à l'usage.
class ConsoleCollectPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleCollectPage> createState() => _ConsoleCollectPageState();
}

class _ConsoleCollectPageState extends ConsumerState<ConsoleCollectPage> {
  CollectFilter _filter = CollectFilter.toCheck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(adminBillingProvider);
    final value = billing.value;
    final overdue = value?.invoices.where((i) => i.overdue).length ?? 0;
    final labels = {
      CollectFilter.toCheck: l10n.billingCollectToCheck,
      CollectFilter.overdue: overdue == 0
          ? l10n.billingCollectOverdue
          : '${l10n.billingCollectOverdue} ($overdue)',
      CollectFilter.done: l10n.billingCollectDone,
    };
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.billingCollectTitle)),
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
            StatusTabs<CollectFilter>(
              values: CollectFilter.values,
              selected: _filter,
              labelOf: (value) => labels[value]!,
              keyOf: (value) => Key('billing-collect-${value.name}'),
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            ...switch (billing) {
              AsyncData(:final value) => _items(context, value),
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

  List<Widget> _items(BuildContext context, AdminBilling billing) {
    final l10n = context.l10n;
    final cards = switch (_filter) {
      CollectFilter.toCheck => [
        for (final request in billing.requests) _RequestCard(request: request),
        for (final invoice in billing.invoices)
          if (!invoice.overdue) _InvoiceCard(invoice: invoice),
      ],
      CollectFilter.overdue => [
        for (final invoice in billing.invoices)
          if (invoice.overdue) _InvoiceCard(invoice: invoice),
      ],
      CollectFilter.done => [
        for (final item in billing.history) _HistoryRow(item: item),
      ],
    };
    if (cards.isEmpty) {
      return [
        const SizedBox(height: 32),
        Text(
          l10n.billingCollectEmpty,
          key: const Key('billing-collect-empty'),
          textAlign: TextAlign.center,
        ),
      ];
    }
    return [
      for (final card in cards)
        Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
    ];
  }
}

/// Montant, référence, moyen déclaré : lignes communes des cartes.
class _CollectCard extends StatelessWidget {
  const new({
    required this.cardKey,
    required this.kind,
    required this.tint,
    required this.icon,
    required this.account,
    required this.object,
    required this.amount,
    required this.details,
    required this.onCheck,
    required this.checkKey,
  });

  final Key cardKey;
  final String kind;
  final TikeoTint tint;
  final IconData icon;
  final String account;
  final String object;
  final int amount;
  final List<String> details;
  final VoidCallback onCheck;
  final Key checkKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return TikeoCard(
      key: cardKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TikeoPill(label: kind, tint: tint, icon: icon),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account, style: theme.textTheme.titleSmall),
                    Text(object, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  money(l10n, amount),
                  textAlign: TextAlign.end,
                  style: TikeoTextStyles.tileNumber.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          for (final detail in details) Text(detail, style: muted),
          const SizedBox(height: 12),
          TikeoPrimaryButton(
            key: checkKey,
            onPressed: onCheck,
            icon: Icons.fact_check_rounded,
            label: l10n.billingCollectCheck,
          ),
        ],
      ),
    );
  }
}

String _accountLine(String name, String? email) =>
    email == null ? name : '$name · $email';

String requestObject(AppLocalizations l10n, BillingRequest request) =>
    request.addonsOnly
    ? l10n.billingRequestAddons(
        request.packName ?? '—',
        addonsLabel(l10n, request.addons),
      )
    : [
        l10n.billingRequestPack(
          request.packName ?? '—',
          request.duration == null
              ? '—'
              : durationLabel(l10n, request.duration!),
        ),
        if (request.addons.isNotEmpty) addonsLabel(l10n, request.addons),
      ].join(' · ');

class _RequestCard extends StatelessWidget {
  const new({required this.request});

  final BillingRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    return _CollectCard(
      cardKey: Key('billing-request-${request.id}'),
      checkKey: Key('billing-request-check-${request.id}'),
      kind: request.addonsOnly
          ? l10n.billingKindAddons
          : l10n.billingKindActivation,
      tint: tints.mint,
      icon: Icons.workspace_premium_rounded,
      account: _accountLine(request.accountName, request.accountEmail),
      object: requestObject(l10n, request),
      amount: request.amount,
      details: [
        l10n.billingReferenceLine(
          request.reference,
          billingDate(request.createdAt),
        ),
        if (request.declaredChannel case final channel?)
          l10n.billingDeclaredLine(
            channelLabel(l10n, channel),
            request.declaredTransaction ?? '—',
          )
        else
          l10n.billingNotDeclared,
      ],
      onCheck: () =>
          unawaited(context.push(AppRoutes.consoleCollectRequest(request.id))),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const new({required this.invoice});

  final DueInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    return _CollectCard(
      cardKey: Key('billing-invoice-${invoice.id}'),
      checkKey: Key('billing-invoice-check-${invoice.id}'),
      kind: invoice.overdue ? l10n.billingKindOverdue : l10n.billingKindInvoice,
      tint: invoice.overdue ? tints.red : tints.blue,
      icon: Icons.receipt_long_rounded,
      account: _accountLine(invoice.accountName, invoice.accountEmail),
      object: l10n.billingInvoiceObject(invoice.eventTitle, invoice.entries),
      amount: invoice.amount,
      details: [l10n.billingDueLine(billingDate(invoice.dueAt))],
      onCheck: () =>
          unawaited(context.push(AppRoutes.consoleCollectInvoice(invoice.id))),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const new({required this.item});

  final BillingHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    final (label, tint) = switch (item.status) {
      'activated' => (l10n.billingStatusActivated, tints.green),
      'paid' => (l10n.billingStatusPaid, tints.green),
      'refused' => (l10n.billingStatusRefused, tints.red),
      _ => (l10n.billingStatusCancelled, tints.gray),
    };
    return TikeoListRow(
      key: Key('billing-history-${item.id}'),
      chevron: false,
      stripe: tint.icon,
      title: item.accountName,
      lines: [
        [?item.label, money(l10n, item.amount)].join(' · '),
        [
          ?item.reference,
          if (item.channel case final channel?) channelLabel(l10n, channel),
          if (item.decidedAt case final at?) billingDate(at),
        ].join(' · '),
      ],
      badge: TikeoPill(label: label, tint: tint),
    );
  }
}

/// C4 · Valider un paiement : demande d'activation ou facture à l'usage.
class ConsolePaymentPage extends ConsumerStatefulWidget {
  const new({required this.id, required this.invoice, super.key});

  final String id;

  /// Facture à l'usage (sinon : demande d'activation).
  final bool invoice;

  @override
  ConsumerState<ConsolePaymentPage> createState() => _ConsolePaymentPageState();
}

class _ConsolePaymentPageState extends ConsumerState<ConsolePaymentPage> {
  final _received = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  PaymentChannel _channel = PaymentChannel.orangeMoney;
  DateTime? _paidAt;
  bool _ready = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _received.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  void _init(int amount, PaymentChannel? channel, String? transaction) {
    if (_ready) return;
    _ready = true;
    _received.text = '$amount';
    _channel = channel ?? PaymentChannel.orangeMoney;
    _reference.text = transaction ?? '';
  }

  Future<void> _pickDate() async {
    final now = ref.read(billingClockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: (_paidAt ?? now).toLocal(),
      firstDate: now.subtract(const Duration(days: 90)).toLocal(),
      lastDate: now.toLocal(),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  /// Note envoyée : montant reçu s'il diffère du montant attendu.
  String? _noteFor(AppLocalizations l10n, int expected) {
    final received = int.tryParse(_received.text.trim());
    final parts = [
      if (received != null && received != expected)
        l10n.billingReceivedNote(money(l10n, received)),
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Future<void> _validate(int expected) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final repository = ref.read(billingAdminRepositoryProvider);
    final payment = (
      channel: _channel,
      operatorReference: _reference.text.trim().isEmpty
          ? null
          : _reference.text.trim(),
      paidAt: _paidAt?.toUtc(),
      note: _noteFor(l10n, expected),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.invoice) {
        await repository.markInvoicePaid(widget.id, payment);
      } else {
        await repository.activateRequest(widget.id, payment);
      }
      ref.invalidate(adminBillingProvider);
      toast.success(
        widget.invoice
            ? l10n.billingInvoicePaidToast
            : l10n.billingActivatedToast,
      );
      if (mounted) context.popOr(AppRoutes.consoleCollect);
    } on Object catch (error) {
      if (mounted) setState(() => _error = billingFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refuse() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final note = await showConsoleConfirm(
      context,
      title: l10n.billingRefuseTitle,
      body: l10n.billingRefuseBody,
      confirmLabel: l10n.billingRefuse,
      needsReason: true,
      confirmKey: const Key('billing-refuse-confirm'),
    );
    if (note == null) return;
    try {
      await ref
          .read(billingAdminRepositoryProvider)
          .refuseRequest(widget.id, note);
      ref.invalidate(adminBillingProvider);
      toast.success(l10n.billingRefusedToast);
      if (mounted) context.popOr(AppRoutes.consoleCollect);
    } on Object catch (error) {
      toast.error(billingFailureMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(adminBillingProvider);
    final value = billing.value;
    final request = widget.invoice
        ? null
        : value?.requests.where((r) => r.id == widget.id).firstOrNull;
    final invoice = widget.invoice
        ? value?.invoices.where((i) => i.id == widget.id).firstOrNull
        : null;
    final title = widget.invoice
        ? l10n.billingPaymentInvoiceTitle
        : l10n.billingPaymentRequestTitle;
    if (value == null || (request == null && invoice == null)) {
      return Scaffold(
        appBar: TikeoAppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(TikeoSizes.screenMargin),
          child: switch (billing) {
            AsyncError(:final error) => BillingLoadError(
              error: error,
              onRetry: () => ref.invalidate(adminBillingProvider),
            ),
            AsyncData() => Text(
              l10n.billingErrorProcessed,
              key: const Key('billing-payment-missing'),
            ),
            _ => const BillingLoading(),
          },
        ),
      );
    }
    final expected = request?.amount ?? invoice!.amount;
    _init(expected, request?.declaredChannel, request?.declaredTransaction);
    final received = int.tryParse(_received.text.trim());
    return Scaffold(
      appBar: TikeoAppBar(title: Text(title)),
      body: SingleChildScrollView(
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
                key: const Key('billing-payment-error'),
                tint: context.tints.red,
                icon: Icons.error_rounded,
                title: error,
              ),
              const SizedBox(height: TikeoSizes.cardGap),
            ],
            TikeoCard(
              key: const Key('billing-payment-summary'),
              child: request != null
                  ? _RequestSummary(request: request, billing: value)
                  : _InvoiceSummary(invoice: invoice!),
            ),
            const SizedBox(height: TikeoSizes.sectionGap),
            SectionHeader(
              title: l10n.billingPaymentReceived,
              icon: Icons.payments_rounded,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('billing-payment-amount'),
              controller: _received,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.billingPaymentAmount,
                suffixText: 'FCFA',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (received != null && received != expected) ...[
              const SizedBox(height: 8),
              TintedBanner(
                key: const Key('billing-payment-mismatch'),
                tint: context.tints.amber,
                icon: Icons.warning_rounded,
                title: l10n.billingPaymentMismatch(money(l10n, expected)),
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<PaymentChannel>(
              showSelectedIcon: false,
              segments: [
                for (final channel in PaymentChannel.values)
                  ButtonSegment(
                    value: channel,
                    label: Text(
                      channelLabel(l10n, channel),
                      key: Key('billing-payment-channel-${channel.wireName}'),
                    ),
                  ),
              ],
              selected: {_channel},
              onSelectionChanged: (value) =>
                  setState(() => _channel = value.single),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('billing-payment-reference'),
              controller: _reference,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: l10n.billingPaymentReference,
              ),
            ),
            SettingsRow(
              key: const Key('billing-payment-date'),
              icon: Icons.event_rounded,
              tint: context.tints.blue,
              title: l10n.billingPaymentDate,
              subtitle: _paidAt == null
                  ? l10n.billingPaymentToday
                  : billingDate(_paidAt!),
              onTap: () => unawaited(_pickDate()),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('billing-payment-note'),
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.billingPaymentNote),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            TikeoPrimaryButton(
              key: const Key('billing-payment-validate'),
              busy: _busy,
              onPressed: _busy ? null : () => unawaited(_validate(expected)),
              icon: Icons.verified_rounded,
              label: widget.invoice
                  ? l10n.billingMarkPaid
                  : request!.addonsOnly
                  ? l10n.billingActivateAddons
                  : l10n.billingActivate,
            ),
            if (!widget.invoice) ...[
              const SizedBox(height: 8),
              TikeoDangerButton(
                key: const Key('billing-payment-refuse'),
                onPressed: _busy ? null : () => unawaited(_refuse()),
                icon: Icons.block_rounded,
                label: l10n.billingRefuse,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Début d'un abonnement activé maintenant : un renouvellement commence à
/// la fin de l'abonnement payant en cours (comme `admin_activate_request`).
DateTime subscriptionStart(
  AdminBilling billing,
  String accountId,
  DateTime now,
) {
  var start = now;
  for (final sub in billing.subscriptions) {
    final end = sub.endsAt;
    if (sub.accountId != accountId ||
        sub.packCode != null ||
        end == null ||
        sub.duration == BillingDuration.event ||
        !end.isAfter(start)) {
      continue;
    }
    start = end;
  }
  return start;
}

class _RequestSummary extends ConsumerWidget {
  const new({required this.request, required this.billing});

  final BillingRequest request;
  final AdminBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = ref.watch(billingClockProvider)();
    final duration = request.duration;
    final start = subscriptionStart(billing, request.accountId, now);
    final end = duration?.endFrom(start);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          money(l10n, request.amount),
          style: TikeoTextStyles.bigNumber.copyWith(
            color: context.tints.mint.text,
          ),
        ),
        Text(l10n.billingExpected, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(
          _accountLine(request.accountName, request.accountEmail),
          style: theme.textTheme.titleSmall,
        ),
        Text(requestObject(l10n, request)),
        Text(
          l10n.billingReferenceLine(
            request.reference,
            billingDate(request.createdAt),
          ),
          style: theme.textTheme.bodySmall,
        ),
        if (!request.addonsOnly && duration != null) ...[
          const SizedBox(height: 8),
          TikeoPill(
            key: const Key('billing-payment-dates'),
            label: duration == BillingDuration.event
                ? l10n.billingDatesEvent(billingDate(start))
                : l10n.billingDates(
                    billingDate(start),
                    end == null ? '∞' : billingDate(end),
                  ),
            tint: context.tints.blue,
            icon: Icons.date_range_rounded,
          ),
        ],
      ],
    );
  }
}

class _InvoiceSummary extends StatelessWidget {
  const new({required this.invoice});

  final DueInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          money(l10n, invoice.amount),
          style: TikeoTextStyles.bigNumber.copyWith(
            color: context.tints.blue.text,
          ),
        ),
        Text(l10n.billingExpected, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(
          _accountLine(invoice.accountName, invoice.accountEmail),
          style: theme.textTheme.titleSmall,
        ),
        Text(invoice.eventTitle),
        Text(
          l10n.billingInvoiceDetail(
            invoice.entries,
            invoice.freeEntries,
            money(l10n, invoice.entriesAmount),
            money(l10n, invoice.addonsAmount),
          ),
          style: theme.textTheme.bodySmall,
        ),
        Text(
          l10n.billingDueLine(billingDate(invoice.dueAt)),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
